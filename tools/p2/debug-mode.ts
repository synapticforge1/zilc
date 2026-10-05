// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Debug mode through the zilc driver: it should apply the -O0 + -fno-stack-check concessions itself
// and still trap correctly (cmem/known-issues.md KI-4). (2026-09-23)
// Linux (Fil-C); from Windows it runs inside WSL. Needs the Linux zilc built (zig-out/bin/zilc).
//
//   deno run -A tools/p2/debug-mode.ts
//   env: WORK (default ~/zilc-work)
//
// Builds examples/interop (c_caller.c + bounds.zig) with -O Debug and -O ReleaseSafe, runs each
// (expect exit 133, the same panic) and prints the binary sizes. Recorded in cmem/known-issues.md
// KI-4 and cmem/testing.md: 13,766,024 bytes (Debug) vs 127,424 (ReleaseSafe), same panic, same
// line. ZILC_FILC is pinned to the STOCK prebuilt clang, as in the shell version.
// Work in $WORK/drive-debug: interop-<mode>, run-<mode>.log.
//
// Converted from debug-mode.sh (2026-10-05).
import { FILC_PREBUILT_TREE, linuxOnly, mkdirp, REPO, run, show, size, WORK } from "../lib/tool.ts";

await linuxOnly(import.meta);
const ZILC = `${REPO}/zig-out/bin/zilc`;
const env = { ZILC_ZIG: `${WORK}/tools/zig-0.15.2/zig`, ZILC_FILC: `${FILC_PREBUILT_TREE}/build/bin/clang` };

const cwd = `${WORK}/drive-debug`;
await mkdirp(cwd);
await Deno.copyFile(`${REPO}/examples/interop/c_caller.c`, `${cwd}/c_caller.c`);
await Deno.copyFile(`${REPO}/examples/interop/bounds.zig`, `${cwd}/bounds.zig`);

const bar = "==================================================================";
for (const mode of ["Debug", "ReleaseSafe"]) {
  console.log(bar);
  console.log(`== -O ${mode}`);
  console.log(bar);
  console.log(`build exit=${await show([ZILC, "build", "c_caller.c", "bounds.zig", "-O", mode, "-o", `interop-${mode}`], { cwd, env })}`);
  // Capture first, THEN print: `prog | sed` would report sed's status, not the program's, and the
  // exit code is half of what this test asserts.
  const log = `${cwd}/run-${mode}.log`;
  const r = await run([`${cwd}/interop-${mode}`], { cwd, env, outFile: log });
  console.log(`   run exit=${r.code}  (expect 133)`);
  for (const l of lines(await Deno.readTextFile(log))) console.log(`   ${l}`);
  const n = await size(`${cwd}/interop-${mode}`);
  if (n === null) console.error(`ls: cannot access 'interop-${mode}': No such file or directory`);
  else console.log(`   binary: ${n} bytes`);
  console.log();
}

/** The text's lines (no trailing empty one), as sed sees them. */
function lines(text: string): string[] {
  const l = text.split("\n");
  if (l[l.length - 1] === "") l.pop();
  return l;
}
