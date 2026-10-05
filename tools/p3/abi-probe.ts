// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// P3 runtime-scoping probe (2026-09-30), read-only: how pass-compiled code calls into Fil-C's
// runtime, libpizlo's `pizlonated_zsys_write`, the link line, `NEEDED`/interpreter, and whether
// the symbol can be overridden. It compiles the one-line write() program (write1.c) with STOCK
// Fil-C 0.685 and inspects the post-pass IR, the prebuilt libraries and the public headers; it
// never reads the runtime's source. Findings: cmem/filc-abi.md.
//
//   deno run -A tools/p3/abi-probe.ts            (Linux; from Windows it runs inside WSL)
//   env: WORK (default ~/zilc-work; Fil-C expected at $WORK/tools/filc-0.685-linux-x86_64, as
//        set up in roadmap.md P1)
//
// Same commands, flags and printed sections as abi-probe.sh; each Unix pipeline's filter
// (grep/head/sed/tr) is done in TypeScript on the program's output.
import { FILC_0685_PREBUILT_TREE, glob, linuxOnly, REPO, run } from "../lib/tool.ts";

await linuxOnly(import.meta);

const F = FILC_0685_PREBUILT_TREE;
const CC = `${F}/build/bin/clang`;
const L = `${F}/pizfix/lib`;
const I = `${F}/pizfix/stdfil-include`;
const S = `${REPO}/tools/p3`;
const T = await Deno.makeTempDir();

// ---- local helpers: the shell pipeline pieces, on lines of text ----
/** A program's output as lines, as a pipe reads them (no extra empty line for the final newline). */
function lines(text: string): string[] {
  const l = text.split("\n");
  if (l.at(-1) === "") l.pop();
  return l;
}
/** `grep`: matching lines; `n` numbers them like `grep -n`, `v` inverts like `grep -v`. */
function grep(ls: string[], re: RegExp, o: { n?: boolean; v?: boolean } = {}): string[] {
  const out: string[] = [];
  ls.forEach((l, i) => {
    if (re.test(l) !== !!o.v) out.push(o.n ? `${i + 1}:${l}` : l);
  });
  return out;
}
function say(ls: string[]): void {
  for (const l of ls) console.log(l);
}
/**
 * A program's stdout. stderr: "inherit" (to this terminal, as in the shell), "null" (`2>/dev/null`)
 * or "merge" (`2>&1`, through `sh -c 'exec "$@" 2>&1'` so both streams share one pipe, in order).
 */
async function out(argv: string[], o: { cwd?: string; stderr?: "inherit" | "null" | "merge" } = {}): Promise<{ code: number; text: string }> {
  if (o.stderr === "merge") {
    const r = await run(["sh", "-c", 'exec "$@" 2>&1', "sh", ...argv], { cwd: o.cwd });
    return { code: r.code, text: r.out };
  }
  const r = await new Deno.Command(argv[0], {
    args: argv.slice(1), cwd: o.cwd, stdin: "null", stdout: "piped", stderr: o.stderr ?? "inherit",
  }).output();
  return { code: r.code, text: new TextDecoder().decode(r.stdout) };
}

try {
  console.log("== (a1) post-pass IR: how pass-compiled main is defined and how it calls write");
  say(lines((await out([CC, "-O1", "-S", "-emit-llvm", "-o", `${T}/w.ll`, `${S}/write1.c`], { stderr: "merge" })).text).slice(0, 3));
  const ll = lines(await Deno.readTextFile(`${T}/w.ll`).catch(() => ""));
  say(grep(ll, /^define|^declare/, { n: true }).slice(0, 20));
  console.log("-- call sites:");
  say(grep(ll, /call .*@(pizlonated_|filc_)/, { n: true }).slice(0, 12));

  console.log("== (a2) how checked musl's write() reaches the runtime");
  await out(["ar", "x", `${L}/libc.a`, "write.o"], { cwd: T, stderr: "null" });
  if (await Deno.stat(`${T}/write.o`).catch(() => null)) {
    console.log("write.o");
    say(lines((await out(["nm", "write.o"], { cwd: T })).text));
  }
  say(lines((await out(["objdump", "-d", "--no-show-raw-insn", "write.o"], { cwd: T, stderr: "null" })).text).slice(0, 60));

  console.log("== (a3) the header's view of zsys_write and the Fil-C calling-convention bits");
  say(grep(lines(await Deno.readTextFile(`${I}/pizlonated_syscalls.h`)), /zsys_write\b|zsys_write\(/, { n: true }));
  // `grep -n -i … $I/*.h`: several files, so each line is prefixed with its file, as grep does.
  const cc: string[] = [];
  for (const h of await glob(`${I}/*.h`)) {
    for (const l of grep(lines(await Deno.readTextFile(h)), /calling convention|filc_cc|cc_args|cc_rets/i, { n: true })) cc.push(`${h}:${l}`);
  }
  say(cc.slice(0, 20));

  console.log("== (a4) the runtime's own pizlonated_zsys_write: first instructions");
  say(lines((await out(["objdump", "-d", "--no-show-raw-insn", `${L}/libpizlo.so`, "--disassemble=pizlonated_zsys_write"], { stderr: "null" })).text).slice(0, 45));

  console.log("== (b1) the link: what filc clang actually links, and how");
  const link = lines((await out([CC, "-O1", "-o", "w", `${S}/write1.c`, "-v"], { cwd: T, stderr: "merge" })).text);
  // `grep ld-line | tr ' ' '\n' | grep wanted`: every word of the linker command line, one per line.
  const words = grep(link, /ld(\.lld)?"? /).flatMap((l) => l.split(" "));
  say(grep(words, /\.(so|a|o)$|^-l|^-L|dynamic-linker|^-rpath|whole-archive|Bstatic|Bdynamic/).slice(0, 30));
  console.log("-- NEEDED / interpreter:");
  say(grep(lines((await out(["readelf", "-d", "w"], { cwd: T })).text), /NEEDED|RPATH|RUNPATH/));
  say(grep(lines((await out(["readelf", "-l", "w"], { cwd: T })).text), /interpreter/i));
  const w = await out([`${T}/w`], { cwd: T });
  await Deno.stdout.write(new TextEncoder().encode(w.text));
  console.log(`exit ${w.code}`);

  console.log("== (b2) who defines pizlonated_zsys_write, and is it preemptible (default visibility, dynamic)?");
  say(grep(lines((await out(["readelf", "-W", "--dyn-syms", `${L}/libpizlo.so`])).text), / pizlonated_zsys_write$/));
  say(grep(lines((await out(["readelf", "-W", "--dyn-syms", `${L}/libc.so`])).text), / pizlonated_zsys_write$/));
  console.log("-- libpizlo DT_FLAGS (SYMBOLIC would defeat interposition):");
  say(grep(lines((await out(["readelf", "-d", `${L}/libpizlo.so`])).text), /FLAGS|SYMBOLIC/));
  console.log("-- libc.so DT_FLAGS:");
  say(grep(lines((await out(["readelf", "-d", `${L}/libc.so`])).text), /FLAGS|SYMBOLIC|NEEDED/));
} finally {
  await Deno.remove(T, { recursive: true }).catch(() => {});
}
