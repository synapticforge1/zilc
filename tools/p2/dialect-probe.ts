// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// P2 experiment 1: what does the pass need beyond the two datalayout lines? (2026-09-23)
// Linux (Fil-C); from Windows it runs inside WSL.
//
//   deno run -A tools/p2/dialect-probe.ts
//   env: WORK (default ~/zilc-work)
//
// A. A HAND-WRITTEN module carrying Fil-C's two layout lines (tools/p2/minimal-dialect.ll) through
//    the stock Fil-C clang at -O1: accepted means the dialect is reproducible by hand and the
//    frontend that produced the IR does not matter.
// B. The same at -O0 (does the pass care about the optimization level?).
// C. Zig's tiny module with the patched layout ($WORK/p1/tiny-ni2.ll, made by
//    tools/p1/zig-ir-spike.sh), with the pass verbose: the last lines it printed before crashing.
// Work and logs in $WORK/p2: a.log, b.log, c.stdout, c.log, minimal.o, minimal0.o, tiny.o.
//
// Converted from dialect-probe.sh (2026-10-05). The one input change: the shell version copied
// p2-minimal.ll from a session scratchpad that no longer exists (the cp failed and the copy already
// in $WORK/p2 was used); this copies the committed tools/p2/minimal-dialect.ll, byte-identical to
// it. tiny-ni2.ll is still copied from $WORK/p1 only if present, as before (silently otherwise).
//
// 📌 RECORD (owner, 2026-10-05): tiny-ni2.ll (11.7 MB) is the ONE input of the phase experiments
// that has no committed source of its own. It is GENERATED: tools/p1/tiny.zig → (Zig 0.15.2)
// $WORK/p1/tiny.ll → tools/p1/zig-ir-spike.ts (patches in Fil-C's two data layouts) →
// $WORK/p1/tiny-ni2.ll → copied here. If $WORK/p1 is lost, rebuild it in that order: the exact
// Zig command for tiny.ll is in zig-ir-spike.ts's header (recovered and verified 2026-10-05: same
// code, only 3 debug-info path lines differ), then run zig-ir-spike.ts, then this tool. Copies on
// 2026-10-05: tiny.ll 11,669,818 bytes (sha256 5db471c2…), tiny-ni2.ll 11,669,936 bytes (sha256
// 3e81eb75…), in $WORK/p1 and $WORK/p2.
import { existsSync, FILC_PREBUILT_TREE, linuxOnly, mkdirp, REPO, WORK } from "../lib/tool.ts";

await linuxOnly(import.meta);
// The stock prebuilt on purpose: this records what Fil-C 0.685 itself accepts.
const FILC = `${FILC_PREBUILT_TREE}/build/bin/clang`;
const OUT = `${WORK}/p2`;
await mkdirp(OUT);
Deno.chdir(OUT);
await Deno.copyFile(`${REPO}/tools/p2/minimal-dialect.ll`, "p2-minimal.ll");

const bar = "==================================================================";
console.log(bar);
console.log("A. HAND-WRITTEN module in Fil-C's dialect (not from their frontend)");
console.log(bar);
if (await redirect([FILC, "-O1", "-c", "-o", "minimal.o", "p2-minimal.ll"], "inherit", "a.log") === 0) {
  console.log("ACCEPTED -- the dialect is reproducible by hand; frontend origin does NOT matter");
} else {
  console.log("REJECTED:");
  printIndented(grepM(await read("a.log"), /Assertion|error:|Segmentation/, 4), "   ");
}

console.log();
console.log(bar);
console.log("B. Same, at -O0 (does the pass care about the optimization level?)");
console.log(bar);
if (await redirect([FILC, "-O0", "-c", "-o", "minimal0.o", "p2-minimal.ll"], "inherit", "b.log") === 0) console.log("ACCEPTED");
else printIndented(grepM(await read("b.log"), /Assertion|error:|Segmentation/, 3), "   ");

console.log();
console.log(bar);
console.log("C. Zig's tiny module, patched layout, with the pass being verbose");
console.log(bar);
if (existsSync(`${WORK}/p1/tiny-ni2.ll`)) await Deno.copyFile(`${WORK}/p1/tiny-ni2.ll`, "tiny-ni2.ll");
const code = await redirect([FILC, "-O1", "-c", "-o", "tiny.o", "tiny-ni2.ll", "-mllvm", "-filc-light-verbose"], "c.stdout", "c.log");
console.log(`exit=${code}`);
console.log("-- last verbose lines before the crash:");
printIndented(lines(await read("c.stdout")).slice(-12), "   ");
console.log("-- crash summary:");
printIndented(grepM(await read("c.log"), /Assertion|Segmentation|error:/, 3), "   ");

// ---- local helpers -----------------------------------------------------------------------------

type Dest = "inherit" | "null" | string;
/** `cmd >stdout 2>stderr`, each a file path, "inherit" (this terminal) or "null"; the exit code. */
async function redirect(argv: string[], stdout: Dest, stderr: Dest): Promise<number> {
  const piped = (d: Dest) => d !== "inherit" && d !== "null";
  const open = (d: Dest) => piped(d) ? Deno.open(d, { write: true, create: true, truncate: true }) : Promise.resolve(undefined);
  const [fo, fe] = [await open(stdout), await open(stderr)];
  let child: Deno.ChildProcess;
  try {
    child = new Deno.Command(argv[0], {
      args: argv.slice(1), stdin: "null",
      stdout: piped(stdout) ? "piped" : stdout as "inherit" | "null",
      stderr: piped(stderr) ? "piped" : stderr as "inherit" | "null",
    }).spawn();
  } catch (e) {
    fo?.close();
    fe?.close();
    if (e instanceof Deno.errors.NotFound) return 127;
    throw e;
  }
  await Promise.all([fo && child.stdout.pipeTo(fo.writable), fe && child.stderr.pipeTo(fe.writable)]);
  return (await child.status).code;
}
async function read(p: string): Promise<string> {
  return await Deno.readTextFile(p).catch(() => "");
}
/** The text's lines (no trailing empty one), like `head`/`tail` see them. */
function lines(text: string): string[] {
  const l = text.split("\n");
  if (l[l.length - 1] === "") l.pop();
  return l;
}
/** `grep -m max -E re`. */
function grepM(text: string, re: RegExp, max: number): string[] {
  return lines(text).filter((l) => re.test(l)).slice(0, max);
}
/** `… | sed 's/^/<prefix>/'`. */
function printIndented(ls: string[], prefix: string): void {
  for (const l of ls) console.log(prefix + l);
}
