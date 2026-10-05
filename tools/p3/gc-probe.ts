// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// The GC protocol, observed (filc-abi.md §5b): where pass-compiled code polls for GC work,
// and how the runtime exits/enters around a blocking system call. Compiles gc-probe.c (a loop, so
// the pass emits pollchecks, and a blocking read) with STOCK Fil-C 0.685 and inspects its post-pass
// IR and the prebuilt libpizlo.so with nm/objdump. Findings: cmem/filc-abi.md (thread offsets,
// "Observed entry points").
//
//   deno run -A tools/p3/gc-probe.ts             (Linux; from Windows it runs inside WSL)
//   env: WORK (default ~/zilc-work; Fil-C expected at $WORK/tools/filc-0.685-linux-x86_64)
//
// Same commands, flags and printed sections as gc-probe.sh; each Unix pipeline's filter
// (awk/grep/sed/sort/head) is done in TypeScript on the program's output.
import { FILC_PREBUILT_TREE, linuxOnly, REPO } from "../lib/tool.ts";

await linuxOnly(import.meta);

const F = FILC_PREBUILT_TREE;
const CC = `${F}/build/bin/clang`;
const L = `${F}/pizfix/lib`;
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
/** awk's `/start/,/end/` range pattern: every line from a start match through the next end match. */
function range(ls: string[], start: RegExp, end: RegExp): string[] {
  const out: string[] = [];
  let inside = false;
  for (const l of ls) {
    if (!inside && start.test(l)) inside = true;
    if (inside) {
      out.push(l);
      if (end.test(l)) inside = false;
    }
  }
  return out;
}
/** `sort -u` / `sort` in the C locale (byte order). */
function sorted(ls: string[], unique = false): string[] {
  const s = [...ls].sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
  return unique ? s.filter((l, i) => i === 0 || l !== s[i - 1]) : s;
}
function say(ls: string[]): void {
  for (const l of ls) console.log(l);
}
/** A program's stdout; its stderr goes to this terminal, or nowhere with `quiet` (`2>/dev/null`). */
async function out(argv: string[], quiet = false): Promise<{ code: number; text: string }> {
  const r = await new Deno.Command(argv[0], { args: argv.slice(1), stdin: "null", stdout: "piped", stderr: quiet ? "null" : "inherit" }).output();
  return { code: r.code, text: new TextDecoder().decode(r.stdout) };
}
/** `nm -D --defined-only libpizlo.so | awk '{print $3}'`: the defined dynamic symbols' names. */
async function exports(): Promise<string[]> {
  return lines((await out(["nm", "-D", "--defined-only", `${L}/libpizlo.so`])).text).map((l) => l.trim().split(/\s+/)[2] ?? "");
}

let code = 0;
try {
  // The compile's messages go to the terminal; a failed compile ends the probe with exit 1.
  const cc = await new Deno.Command(CC, { args: ["-O1", "-S", "-emit-llvm", "-o", `${T}/g.ll`, `${S}/gc-probe.c`], stdin: "null", stdout: "inherit", stderr: "inherit" }).output();
  if (cc.code !== 0) {
    code = 1;
  } else {
    const ll = lines(await Deno.readTextFile(`${T}/g.ll`));

    console.log("== 1. pollcheck in spin(): runtime calls and thread-relative loads inside the loop");
    // Line numbers are within spin()'s definition (grep -n on awk's output).
    const spin = range(ll, /^define .*pizlonatedFIP[0-9]*_spin/, /^}/);
    say(grep(spin, /call .*@filc_|getelementptr i8, ptr %0, i64|load .*%filc_thread|pollcheck|br i1/, { n: true }).slice(0, 20));
    console.log("-- runtime functions the module declares:");
    // `grep -oE '^declare [^@]*@filc_[a-z_]+' | sed 's/.*@//' | sort -u`
    const declared = ll.map((l) => l.match(/^declare [^@]*@filc_[a-z_]+/)?.[0]).filter((m): m is string => !!m).map((m) => m.replace(/.*@/, ""));
    say(sorted(declared, true));

    console.log("== 2. runtime exports about safepoints");
    say(sorted(grep(await exports(), /pollcheck|handshake|safepoint|^filc_(enter|exit)|_enter$|_exit$|stop_the_world|soft/i)).slice(0, 30));

    console.log("== 3. does the runtime's read() wrapper exit/enter? calls made by filc_native_zsys_read");
    const read = lines((await out(["objdump", "-d", "--no-show-raw-insn", `${L}/libpizlo.so`, "--disassemble=filc_native_zsys_read"], true)).text);
    say(grep(read, /call/).map((l) => l.replace(/.*call */, "")).slice(0, 20));

    console.log("== 4. thread offsets: what filc_pollcheck-ish exports read from the thread");
    for (const s of grep(await exports(), /^filc_pollcheck/i).slice(0, 3)) {
      console.log(`-- ${s}`);
      // `sed -n '7,22p'`: skips objdump's file header, keeps the function's first instructions.
      say(lines((await out(["objdump", "-d", "--no-show-raw-insn", `${L}/libpizlo.so`, `--disassemble=${s}`], true)).text).slice(6, 22));
    }
  }
} finally {
  await Deno.remove(T, { recursive: true }).catch(() => {});
}
Deno.exit(code);
