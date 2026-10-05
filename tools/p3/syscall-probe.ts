// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Run syscall-probe.c under Fil-C, one case per process so a trap names its case. The probe for
// KI-7 (Zig std's raw `syscall` asm): what Fil-C's libc syscall() accepts (186 gettid, 202 futex,
// 230 clock_nanosleep). First lists who exports syscall/gettid/futex/clock_nanosleep in STOCK
// Fil-C 0.685's libc.so and libpizlo.so. Results: cmem/known-issues.md KI-7, src/driver.zig
// (the syscall reroute, "Measured 2026-09-30 by tools/p3/syscall-probe.c").
//
//   deno run -A tools/p3/syscall-probe.ts        (Linux; from Windows it runs inside WSL)
//   env: WORK (default ~/zilc-work; Fil-C expected at $WORK/tools/filc-0.685-linux-x86_64)
//
// Same commands, flags and printed sections as syscall-probe.sh, with one deliberate change: the
// shell version's `exit $?` came after `probe | grep | head`, so it printed head's status (always
// 0) and a trapped case still said "exit 0". Here it is the probe's own status (a trap shows as
// 128 + signal, e.g. 133 for SIGTRAP). The shell's message for a case killed by a signal
// ("Trace/breakpoint trap") is printed the same way the shell did.
import { FILC_0685_PREBUILT_TREE, linuxOnly, REPO, run } from "../lib/tool.ts";

await linuxOnly(import.meta);

const F = FILC_0685_PREBUILT_TREE;
const S = `${REPO}/tools/p3`;
const T = await Deno.makeTempDir();

// ---- local helpers: the shell pipeline pieces, on lines of text ----
/** A program's output as lines, as a pipe reads them (no extra empty line for the final newline). */
function lines(text: string): string[] {
  const l = text.split("\n");
  if (l.at(-1) === "") l.pop();
  return l;
}
/** `grep`: matching lines; `v` inverts like `grep -v`. */
function grep(ls: string[], re: RegExp, o: { v?: boolean } = {}): string[] {
  return ls.filter((l) => re.test(l) !== !!o.v);
}
function say(ls: string[]): void {
  for (const l of ls) console.log(l);
}
/** A program's stdout; its stderr goes to this terminal, as in the shell. */
async function stdout(argv: string[]): Promise<string> {
  const r = await new Deno.Command(argv[0], { args: argv.slice(1), stdin: "null", stdout: "piped", stderr: "inherit" }).output();
  return new TextDecoder().decode(r.stdout);
}
/** What sh (dash) prints when a program it ran was killed by this signal. */
const SIGNAL_MESSAGE: Record<number, string> = {
  4: "Illegal instruction", 5: "Trace/breakpoint trap", 6: "Aborted", 7: "Bus error", 8: "Floating point exception",
  9: "Killed", 11: "Segmentation fault",
};

let code = 0;
try {
  console.log("== who exports syscall");
  // `grep -w`: whole words only (word characters are letters, digits and _).
  say(grep(lines(await stdout(["nm", "-D", "--defined-only", `${F}/pizfix/lib/libc.so`])), /(?<![A-Za-z0-9_])(syscall|gettid)(?![A-Za-z0-9_])/));
  say(grep(lines(await stdout(["nm", "-D", "--defined-only", `${F}/pizfix/lib/libpizlo.so`])), /zsys_(syscall|gettid|clock_nanosleep|futex[a-z_]*)$|^[0-9a-f]+ T pizlonated_zsys_[a-z_]*futex/i));
  const cc = await new Deno.Command(`${F}/build/bin/clang`, { args: ["-O1", "-g", "-o", `${T}/probe`, `${S}/syscall-probe.c`], stdin: "null", stdout: "inherit", stderr: "inherit" }).output();
  if (cc.code !== 0) {
    code = 1;
  } else {
    for (const c of ["gettid", "futex-ptr", "futex-err", "nanosleep", "futex-int"]) {
      console.log(`== ${c}`);
      // `probe c 2>&1`: both streams through one pipe, in order (exec keeps the probe's own status).
      const r = await run(["sh", "-c", 'exec "$0" "$1" 2>&1', `${T}/probe`, c]);
      // `grep -v '^    ' | head -4`: drop lines indented four spaces, keep the first four.
      say(grep(lines(r.out), /^ {4}/, { v: true }).slice(0, 4));
      if (r.code > 128 && SIGNAL_MESSAGE[r.code - 128]) console.log(SIGNAL_MESSAGE[r.code - 128]);
      console.log(`   exit ${r.code}`);
    }
  }
} finally {
  await Deno.remove(T, { recursive: true }).catch(() => {});
}
Deno.exit(code);
