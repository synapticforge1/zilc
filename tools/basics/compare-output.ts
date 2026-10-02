#!/usr/bin/env -S deno run --allow-read
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Pre-publish "output comparison": does each tests/basics program print the same thing under zilc
// as natively (plain Zig 0.15.2, no Fil-C)? Exit codes alone were checked before; this compares
// stdout+stderr.
//
//   deno run --allow-read compare-output.ts <native1> <native2> <zilc-work> [modes] [langs]
//
//   native1, native2  two runs of tools/basics/run-native.sh (its zig-out/basics-run folder):
//                     <dir>/<lang>/<name>.out
//   zilc-work         the folder holding zilc-check.sh's results: basics-zilc-<MODE>/bin/<lang>/<name>/run.out
//   modes             comma list, default Debug,ReleaseSafe,ReleaseFast,ReleaseSmall
//   langs             comma list, default zig,c (a missing mode/lang folder is skipped)
//
// Verdicts per program and mode:
//   SAME           byte-identical to native
//   NATIVE-VARIES  native's two runs differ (times, random numbers, thread order), so zilc is
//                  compared by SHAPE: same line count, and the same lines once digits are masked
//                  ("shape ok" / "SHAPE DIFFERS")
//   DIFFERS        native is stable and zilc's output is not the same; the first lines of a diff
//                  are printed
//   EXPECTED       a program in the table below, whose output CANNOT match; the reason is printed.
//                  Kept short and each entry explained: a new difference anywhere else fails.
// The run is bounded (servers and signal waits time out after 15 s), so those outputs are
// whatever was printed before the timeout, which is itself compared.

// Measured 2026-10-02 (cmem/testing.md "Output comparison"); the same in C and Zig unless noted.
const EXPECTED: Record<string, string> = {
  "17_pointers": "prints a pointer's address",
  "27_goroutines": "two threads race to print; natively the same order twice by chance (seen in C)",
  "36_worker-pools": "thread scheduling decides which worker takes which job",
  "42_panic": "designed: under zilc the panic is reported by Fil-C (zerror), not Zig's handler",
  "46_string-formatting": "prints an address (native: fixed, non-PIE; zilc: differs per run)",
  "64_command-line-arguments": "prints its own path, which differs between the two harnesses",
  "74_execing-processes": "runs `ls -la` on its working directory (dates, link counts)",
  "75_spawning-processes": "runs `date` and `ls -la` on its working directory",
};

const [n1, n2, work, modesArg, langsArg] = Deno.args;
if (!n1 || !n2 || !work) {
  console.error("usage: compare-output.ts <native1> <native2> <zilc-work> [modes] [langs]");
  Deno.exit(2);
}
const modes = (modesArg ?? "Debug,ReleaseSafe,ReleaseFast,ReleaseSmall").split(",");
const langs = (langsArg ?? "zig,c").split(",");

const read = async (p: string): Promise<string | null> => {
  try {
    return await Deno.readTextFile(p);
  } catch {
    return null;
  }
};
const exists = async (p: string) => (await Deno.stat(p).catch(() => null)) !== null;
const lines = (s: string) => s.split("\n");
const shape = (s: string) => lines(s).map((l) => l.replace(/[0-9]+/g, "#"));

const diffHead = (a: string, b: string, max = 6): string[] => {
  const x = lines(a), y = lines(b);
  const out: string[] = [];
  for (let i = 0; i < Math.max(x.length, y.length) && out.length < max; i++) {
    if (x[i] === y[i]) continue;
    out.push(`    line ${i + 1}: native ${JSON.stringify(x[i] ?? "<none>").slice(0, 110)}`);
    out.push(`             zilc   ${JSON.stringify(y[i] ?? "<none>").slice(0, 110)}`);
  }
  return out;
};

const totals = { same: 0, expected: 0, varies: 0, variesBad: 0, differs: 0, missing: 0 };
for (const lang of langs) {
  const nativeDir1 = `${n1}/${lang}`;
  if (!(await exists(nativeDir1))) continue;
  const names = [] as string[];
  for await (const e of Deno.readDir(nativeDir1)) {
    if (e.isFile && e.name.endsWith(".out")) names.push(e.name.slice(0, -4));
  }
  names.sort();
  for (const mode of modes) {
    const zroot = `${work}/basics-zilc-${mode}/bin/${lang}`;
    if (!(await exists(zroot))) continue;
    const counts = { same: 0, expected: 0, varies: 0, variesBad: 0, differs: 0, missing: 0 };
    const report: string[] = [];
    for (const name of names) {
      const a = await read(`${n1}/${lang}/${name}.out`);
      const b = await read(`${n2}/${lang}/${name}.out`);
      const z = await read(`${zroot}/${name}/run.out`);
      if (a === null || z === null) {
        counts.missing++;
        report.push(`  MISSING        ${name}`);
        continue;
      }
      if (a === z) {
        counts.same++;
        continue;
      }
      if (EXPECTED[name]) {
        counts.expected++;
        report.push(`  EXPECTED       ${name}: ${EXPECTED[name]}`);
        continue;
      }
      if (b !== null && a !== b) {
        const ok = shape(a).join("\n") === shape(z).join("\n") || shape(b).join("\n") === shape(z).join("\n");
        if (ok) counts.varies++;
        else counts.variesBad++;
        report.push(`  NATIVE-VARIES  ${name}: ${ok ? "shape ok" : "SHAPE DIFFERS"}`);
        if (!ok) report.push(...diffHead(a, z));
        continue;
      }
      counts.differs++;
      report.push(`  DIFFERS        ${name}`);
      report.push(...diffHead(a, z));
    }
    console.log(
      `== ${lang} [${mode}]: ${counts.same} same, ${counts.expected} expected, ${counts.varies} native-varies (shape ok), ` +
        `${counts.variesBad} native-varies (shape differs), ${counts.differs} differ, ${counts.missing} missing / ${names.length}`,
    );
    for (const r of report) console.log(r);
    for (const k of Object.keys(totals) as (keyof typeof totals)[]) totals[k] += counts[k];
  }
}
console.log(`TOTAL: ${JSON.stringify(totals)}`);
Deno.exit(totals.differs + totals.variesBad + totals.missing > 0 ? 1 : 0);
