// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Run the milestone through the zilc DRIVER instead of hand-run commands. (2026-09-23)
// Linux (Fil-C); from Windows it runs inside WSL. Needs the Linux zilc built (zig-out/bin/zilc).
//
//   deno run -A tools/p2/driver-milestone.ts
//   env: WORK (default ~/zilc-work)
//
// zilc --version; `zilc build c_caller.c bounds.zig -v` (the whole pipeline in one command) and
// run it (expect exit 133); then the same at -O Debug, supported with the -O0 + -fno-stack-check
// concessions (cmem/known-issues.md KI-4), printing the first lines of the build, the run's exit
// code and semantic origin, and both binary sizes. ZILC_FILC is pinned to the STOCK prebuilt
// clang, as in the shell version.
// Work in $WORK/drive: interop, interop-debug, dbg-run.log.
//
// Converted from driver-milestone.sh (2026-10-05).
import { FILC_PREBUILT_TREE, linuxOnly, mkdirp, REPO, run, show, size, WORK } from "../lib/tool.ts";

await linuxOnly(import.meta);
const ZILC = `${REPO}/zig-out/bin/zilc`;
const env = { ZILC_ZIG: `${WORK}/tools/zig-0.15.2/zig`, ZILC_FILC: `${FILC_PREBUILT_TREE}/build/bin/clang` };

const cwd = `${WORK}/drive`;
await mkdirp(cwd);
await Deno.copyFile(`${REPO}/examples/interop/c_caller.c`, `${cwd}/c_caller.c`);
await Deno.copyFile(`${REPO}/examples/interop/bounds.zig`, `${cwd}/bounds.zig`);

console.log("== zilc --version");
await show([ZILC, "--version"], { cwd, env });

console.log();
console.log("== zilc build (the whole pipeline in one command)");
console.log(`build exit=${await show([ZILC, "build", "c_caller.c", "bounds.zig", "-o", "interop", "-v"], { cwd, env })}`);

console.log();
console.log("== run it");
console.log(`run exit=${await show([`${cwd}/interop`], { cwd, env })}`);

console.log();
console.log("== Debug mode: supported, with the -O0 + -fno-stack-check concessions (KI-4)");
// `2>&1 | head -4`: the build's first four lines of output, stdout and stderr together.
const dbg = await run([ZILC, "build", "c_caller.c", "bounds.zig", "-O", "Debug", "-o", "interop-debug"], { cwd, env });
for (const l of lines(dbg.out).slice(0, 4)) console.log(l);
const r = await run([`${cwd}/interop-debug`], { cwd, env, outFile: `${cwd}/dbg-run.log` });
console.log(`   run exit=${r.code}  (expect 133)`);
// grep -m1 "semantic origin" -A1: the first match and the line after it.
const log = lines(await Deno.readTextFile(`${cwd}/dbg-run.log`));
const at = log.findIndex((l) => l.includes("semantic origin"));
if (at >= 0) for (const l of log.slice(at, at + 2)) console.log(`   ${l}`);
// ls -l interop interop-debug | awk '{print "   " $NF ":", $5, "bytes"}'
for (const f of ["interop", "interop-debug"]) {
  const n = await size(`${cwd}/${f}`);
  if (n === null) console.error(`ls: cannot access '${f}': No such file or directory`);
  else console.log(`   ${f}: ${n} bytes`);
}

/** The text's lines (no trailing empty one), as head/grep see them. */
function lines(text: string): string[] {
  const l = text.split("\n");
  if (l[l.length - 1] === "") l.pop();
  return l;
}
