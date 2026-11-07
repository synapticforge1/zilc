// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// The oracle of sarcasm's port to Zig (cmem/roadmap.md Z1 "sarcasm in Zig", stage S0; owner,
// 2026-11-06: "Port sarcasm to Zig"). Runs upstream's sarcasm (the release's pizfix/bin/sarcasm,
// Luau under minilute) and a candidate over every `.s` file in Fil-C's own tests, as Fil-C's
// x86_64 driver runs it (`--x86_64`), in `-S` mode (the rewritten assembly, no `as`), and
// compares, byte for byte: the exit code, stdout, stderr (the input's path normalised) and the
// written assembly. The port replaces upstream's only when this is clean (workspace tooling rule).
//
//   bun tools/sarcasm/compare-sarcasm.ts [--candidate <sarcasm>]   env JOBS (16), ONLY (regex)
// Without --candidate, upstream is compared with ITSELF (two runs): the determinism baseline
// (2026-11-06: 1,431 files, 0 differ). Report: $WORK/sarcasm-compare/report.txt.

import { readdirSync, statSync } from "node:fs";
import { mkdir, writeFile } from "node:fs/promises";
import { ARGS, env, envInt, filcPackageDir, FILC_PREBUILT_TREE, linuxOnly, pool, rmrf, WORK } from "../lib/tool.ts";

await linuxOnly(import.meta);

const upstream = env("SARCASM_UPSTREAM", `${FILC_PREBUILT_TREE}/pizfix/bin/sarcasm`);
const ci = ARGS.indexOf("--candidate");
const candidate = ci >= 0 ? ARGS[ci + 1] : upstream;
const tests = `${await filcPackageDir()}/filc/tests`;
const out = `${WORK}/sarcasm-compare`;
await rmrf(out);
await mkdir(out, { recursive: true });

const files: string[] = [];
const walk = (d: string) => {
  for (const n of readdirSync(d)) {
    const p = `${d}/${n}`;
    if (statSync(p).isDirectory()) walk(p);
    else if (p.endsWith(".s")) files.push(p);
  }
};
walk(tests);
files.sort();
const only = new RegExp(env("ONLY", "."));
const corpus = files.filter((f) => only.test(f));

interface Run { code: number; stdout: string; stderr: string; asm: string }
async function sarcasm(bin: string, f: string, tag: string, i: number): Promise<Run> {
  const o = `${out}/${i}.${tag}.yolo.s`;
  const p = Bun.spawn([bin, "--x86_64", "-S", "-o", o, f], { stdout: "pipe", stderr: "pipe" });
  const [stdout, stderr] = await Promise.all([new Response(p.stdout).text(), new Response(p.stderr).text()]);
  const code = await p.exited;
  const file = Bun.file(o);
  const asm = (await file.exists()) ? await file.text() : "";
  return { code, stdout: stdout.replaceAll(f, "<input>"), stderr: stderr.replaceAll(f, "<input>"), asm };
}

const rel = (f: string) => f.slice(tests.length + 1);
const results = await pool(corpus, envInt("JOBS", 16), async (f, i) => {
  const [a, b] = [await sarcasm(upstream, f, "upstream", i), await sarcasm(candidate, f, "candidate", i)];
  const what = (["code", "stdout", "stderr", "asm"] as const).filter((k) => a[k] !== b[k]);
  return { f, accepted: a.code === 0, what, a, b };
});

const bad = results.filter((r) => r.what.length);
const lines = [
  `upstream:  ${upstream}`,
  `candidate: ${candidate}${candidate === upstream ? " (itself: the determinism baseline)" : ""}`,
  `corpus: ${corpus.length} .s files of ${tests} (upstream accepts ${results.filter((r) => r.accepted).length}, rejects ${results.filter((r) => !r.accepted).length})`,
  `differ: ${bad.length}`,
  ...bad.map((r) => `  ${rel(r.f)}: ${r.what.join(", ")}${r.what.includes("stderr") ? `\n    upstream:  ${r.a.stderr.split("\n")[0]}\n    candidate: ${r.b.stderr.split("\n")[0]}` : ""}`),
];
await writeFile(`${out}/report.txt`, lines.join("\n") + "\n");
console.log(lines.slice(0, 4 + Math.min(bad.length, 20)).join("\n"));
console.log(bad.length ? `FAILED: ${bad.length} of ${corpus.length} differ (${out}/report.txt)` : `OK: ${corpus.length} files, the same exit code, output, diagnostics and assembly`);
process.exit(bad.length ? 1 : 0);
