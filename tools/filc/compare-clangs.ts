// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Prove the patched Fil-C clang emits BYTE-IDENTICAL objects to the 0.685 prebuilt, and time both
// (KI-22, cmem/workarounds.md). Every input is compiled by both; objects are compared byte for byte.
// Linux; from Windows it runs inside WSL.
//
//   deno run -A tools/filc/compare-clangs.ts [extra .ll/.c files…]      env: A, B (the two clangs)
//
// Default inputs: whatever IR is lying around from earlier measurements (KEEP the list explicit, so a
// reader can rerun it; a missing one is skipped), the gate's C examples, and zilc's syscall helper.
//
// ⚠️ Two rules learned 2026-10-01, or the comparison means nothing:
//  1. ASLR OFF (`setarch -R`). Fil-C's pass iterates hash tables keyed by pointer addresses, so the
//     SAME prebuilt clang on the SAME input gives different objects run to run with ASLR on.
//  2. Both binaries run from the SAME directory. Clang finds its headers relative to itself, and the
//     include paths land in the debug info. (Hence the prebuilt's clang-20 is copied next to ours.)
// For whole-suite equivalence, see run-filc-tests.ts (Fil-C's own 7,003 tests).
import { basename, env, exists, FILC_PATCHED_TREE, FILC_PREBUILT_TREE, glob, linuxOnly, mkdirp, must, pool, REPO, rmrf, run, WORK } from "../lib/tool.ts";

await linuxOnly(import.meta);
const t = `${FILC_PATCHED_TREE}/build/bin`;
await must(["cp", "-f", `${FILC_PREBUILT_TREE}/build/bin/clang-20`, `${t}/clang-prebuilt`]);
const sides = { A: env("A", `${t}/clang-prebuilt`), B: env("B", `${t}/clang-20`) };
const d = `${WORK}/perf/compare`;
await rmrf(d);
await mkdirp(d);

const p62 = `${WORK}/perf/v2-62_directories-ReleaseSafe/prog.zilc-tmp`;
const inputs: [string, string, string][] = [
  ["ki18-repro", `${REPO}/tools/p2/repro/filc-0.685-i21-global.ll`, "-O1"],
  ...(await glob(`${REPO}/examples/*.c`)).map((c): [string, string, string] => [`c-${basename(c).replace(/\.c$/, "")}`, c, "-O1"]),
  ["zilc_syscall", `${p62}/zilc_syscall.c`, "-O1"],
  ["allocas2000-O1", `${WORK}/perf/scale2/allocas-2000-O1.ll`, "-O1"],
  ["allocas2000-O0", `${WORK}/perf/scale2/allocas-2000-O0.ll`, "-O0"],
  ["62-O1", `${p62}/directories.filc.ll`, "-O1"],
  ["62-O0", `${p62}/directories.filc.ll`, "-O0"],
  ["69-O1", `${WORK}/perf/v2-69_http-client-ReleaseSafe/prog.zilc-tmp/http-client.filc.ll`, "-O1"],
  ...Deno.args.map((f): [string, string, string] => [`x-${basename(f)}`, f, "-O1"]),
];

await pool(inputs, inputs.length, async ([name, file, opt]) => {
  if (!(await exists(file))) return console.log(`${name.padEnd(30)} ${opt.padEnd(4)} (input missing: ${file})`);
  const extra = file.endsWith(".c") ? [] : ["-Wno-override-module"];
  const r: Record<string, { code: number; secs: number; log: string }> = {};
  for (const [side, cl] of Object.entries(sides)) {
    const t0 = performance.now();
    const res = await run(["setarch", "-R", cl, opt, "-g", ...extra, "-c", "-o", `${d}/${name}.${side}.o`, file], { outFile: `${d}/${name}.${side}.log` });
    r[side] = { code: res.code, secs: (performance.now() - t0) / 1000, log: await Deno.readTextFile(`${d}/${name}.${side}.log`) };
  }
  let verdict: string;
  if (r.A.code !== 0 || r.B.code !== 0) {
    verdict = r.A.code === r.B.code && r.A.log.includes("Assertion") && r.B.log.includes("Assertion") ? "both assert (same)" : `EXIT DIFFERS (${r.A.code} vs ${r.B.code})`;
  } else {
    const [a, b] = await Promise.all([Deno.readFile(`${d}/${name}.A.o`), Deno.readFile(`${d}/${name}.B.o`)]);
    verdict = a.length === b.length && a.every((x, i) => x === b[i]) ? `IDENTICAL (${a.length} bytes)` : "DIFFERENT";
  }
  console.log(`${name.padEnd(30)} ${opt.padEnd(4)} prebuilt ${r.A.secs.toFixed(1).padStart(7)}s  patched ${r.B.secs.toFixed(1).padStart(7)}s  ${verdict}`);
});
