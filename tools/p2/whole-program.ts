// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// KI-5: a whole Zig program through the zilc driver, with no C file. (2026-09-23)
// Linux (Fil-C); from Windows it runs inside WSL. Needs the Linux zilc built (zig-out/bin/zilc).
//
//   deno run -A tools/p2/whole-program.ts
//   env: WORK (default ~/zilc-work)
//
// `zilc build examples/whole_program/hello.zig` (entry shim chosen automatically), shows the
// pipeline commands (`-v` lines starting with "+") and errors, runs it (expect exit 133, the panic
// at hello.zig under zilc_entry.zig) and prints the first 12 lines of the generated entry shim.
// Recorded in cmem/known-issues.md KI-5. ZILC_FILC is pinned to the STOCK prebuilt clang, as in
// the shell version. Work in $WORK/drive-whole: hello, run.log, hello.zilc-tmp/.
//
// Converted from whole-program.sh (2026-10-05). Two deliberate differences, both where the shell
// version printed a pipeline's status instead of the one it meant:
//   * "build exit=" is zilc's exit code. The shell's `zilc … | grep | sed; echo $?` reported sed's
//     status (always 0): the mistake debug-mode.sh's comment warns about.
//   * When hello.zilc-tmp/zilc_entry.zig is absent, the "(temps removed; …)" note now prints. In
//     the shell `sed … 2>/dev/null | sed … || echo` the echo could never run (sed's status again).
import { FILC_0685_PREBUILT_TREE, linuxOnly, mkdirp, REPO, run, WORK } from "../lib/tool.ts";

await linuxOnly(import.meta);
const ZILC = `${REPO}/zig-out/bin/zilc`;
const env = { ZILC_ZIG: `${WORK}/tools/zig-0.15.2/zig`, ZILC_FILC: `${FILC_0685_PREBUILT_TREE}/build/bin/clang` };

const cwd = `${WORK}/drive-whole`;
await mkdirp(cwd);
await Deno.copyFile(`${REPO}/examples/whole_program/hello.zig`, `${cwd}/hello.zig`);

console.log("== zilc build hello.zig   (entry shim chosen automatically)");
const b = await run([ZILC, "build", "hello.zig", "-o", "hello", "-v"], { cwd, env });
for (const l of lines(b.out).filter((l) => /^\+|error/.test(l))) console.log(`   ${l}`);
console.log(`   build exit=${b.code}`);

console.log();
console.log("== run");
const r = await run([`${cwd}/hello`], { cwd, env, outFile: `${cwd}/run.log` });
console.log(`   exit=${r.code}  (expect 133)`);
for (const l of lines(await Deno.readTextFile(`${cwd}/run.log`))) console.log(`   ${l}`);

console.log();
console.log("== the entry shim zilc generated");
const shim = await Deno.readTextFile(`${cwd}/hello.zilc-tmp/zilc_entry.zig`).catch(() => null);
if (shim === null) console.log("   (temps removed; re-run with --keep-temps to see it)");
else for (const l of lines(shim).slice(0, 12)) console.log(`   ${l}`);

/** The text's lines (no trailing empty one), as grep/sed see them. */
function lines(text: string): string[] {
  const l = text.split("\n");
  if (l[l.length - 1] === "") l.pop();
  return l;
}
