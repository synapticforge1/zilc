// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// P3 runtime-scoping probe (2026-09-30), read-only: Fil-C's calling convention decoded. Prints the
// IR types, a full call through the fast and generic paths (main through the write wrapper, from
// the post-pass IR of write1.c compiled with STOCK Fil-C 0.685), `pizlonated_runtime.h`, and the
// capability vocabulary in `stdfil.h`. It never reads the runtime's source. Findings:
// cmem/filc-abi.md.
//
//   deno run -A tools/p3/cc-decode.ts            (Linux; from Windows it runs inside WSL)
//   env: WORK (default ~/zilc-work; Fil-C expected at $WORK/tools/filc-0.685-linux-x86_64, as
//        set up in roadmap.md P1)
//
// Same commands, flags and printed sections as cc-decode.sh; each Unix pipeline's filter
// (grep/sed/head) is done in TypeScript on the file's text.
import { FILC_0685_PREBUILT_TREE, linuxOnly, REPO } from "../lib/tool.ts";

await linuxOnly(import.meta);

const F = FILC_0685_PREBUILT_TREE;
const CC = `${F}/build/bin/clang`;
const I = `${F}/pizfix/stdfil-include`;
const S = `${REPO}/tools/p3`;
const T = await Deno.makeTempDir();

// ---- local helpers: the shell pipeline pieces, on lines of text ----
/** A file's text as lines, as a pipe reads them (no extra empty line for the final newline). */
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

try {
  // The compile's messages are dropped (`2>/dev/null` in the shell version).
  await new Deno.Command(CC, { args: ["-O1", "-S", "-emit-llvm", "-o", `${T}/w.ll`, `${S}/write1.c`], stdin: "null", stdout: "inherit", stderr: "null" }).output();
  const ll = lines(await Deno.readTextFile(`${T}/w.ll`).catch(() => ""));
  console.log("== types");
  say(grep(ll, /^%(filc|pizlonated)/, { n: true }));
  console.log("== IR, main through the write wrapper");
  // `sed -n '36,200p'`: line 36 is where pizlonated_main's definition starts in this IR; metadata
  // (`!…`) and blank lines are dropped.
  say(grep(grep(ll.slice(35, 200), /^!/, { v: true }), /^$/, { v: true }).slice(0, 150));
  console.log("== runtime header");
  say(grep(lines(await Deno.readTextFile(`${I}/pizlonated_runtime.h`)), /^ *$/, { v: true }).slice(0, 100));
  console.log("== stdfil.h: object / capability / function-object vocabulary");
  say(grep(lines(await Deno.readTextFile(`${I}/stdfil.h`)), /struct filc_|filc_object|flight|lower|upper|aux|function.?object|zgetlower|zgetupper/i, { n: true }).slice(0, 40));
} finally {
  await Deno.remove(T, { recursive: true }).catch(() => {});
}
