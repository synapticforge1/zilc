// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// THE MILESTONE: Zig code + a C caller, both through Fil-C's pass, must trap. (2026-09-23)
// Linux (Fil-C); from Windows it runs inside WSL.
//
//   deno run -A tools/p2/milestone.ts
//   env: WORK (default ~/zilc-work)
//
// TEST 1: tiny.zig (zig_add/zig_sum) emitted as IR by stock Zig (ReleaseSafe), datalayout
// rewritten into Fil-C's dialect, compiled by the stock Fil-C clang, linked with c_caller.c, run.
// Recorded in cmem/testing.md ("The Zig ⇄ C gate, measured 2026-09-23"): exit 133, the fault
// attributed to tiny.zig:4:6 from the call site c_caller.c:15:5.
// TEST 2: a whole Zig program (zig_oob.zig, libc malloc + printf) per release mode, target
// x86_64-linux-gnu. (Fil-C's libc is musl, so this fails on glibc symbol names: KI-6; the musl
// retry is whole-zig-program.ts.)
// Work and logs in $WORK/p2: t1*.ll/.o/.log, prog1, z-<mode>*.
//
// Converted from milestone.sh (2026-10-05). Input change: the shell version copied c_caller.c from a
// session scratchpad and zig_oob.zig from $WORK/p1, both gone (the cps failed and the copies
// already in $WORK/p2 were used); this copies the committed tools/p2/c_caller.c and
// tools/p1/zig_oob.zig, byte-identical to them. tiny.zig is not copied here, as before
// (optmode-matrix.ts puts it in $WORK/p2).
import { FILC_PREBUILT_TREE, linuxOnly, mkdirp, REPO, WORK } from "../lib/tool.ts";

await linuxOnly(import.meta);
const ZIG = `${WORK}/tools/zig-0.15.2/zig`;
// The stock prebuilt on purpose: this records what Fil-C 0.685 itself does with Zig's IR.
const FILC = `${FILC_PREBUILT_TREE}/build/bin/clang`;
const OUT = `${WORK}/p2`;
// Fil-C's two layout lines. Position matters: LLVM compares layout strings textually, so `ni:0`
// goes right after `m:e` (cmem/known-issues.md KI-4).
const BEFORE = "e-m:e-ni:0-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128";
const AFTER = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128";
await mkdirp(OUT);
Deno.chdir(OUT);
await Deno.copyFile(`${REPO}/tools/p2/c_caller.c`, "c_caller.c");
await Deno.copyFile(`${REPO}/tools/p1/zig_oob.zig`, "zig_oob.zig");

const bar = "==================================================================";
console.log(bar);
console.log("TEST 1 — C main + Zig object (zig_add/zig_sum), ReleaseSafe");
console.log(bar);
await redirect([ZIG, "build-obj", "tiny.zig", "-target", "x86_64-linux-gnu", "-OReleaseSafe", "-fno-emit-bin", "-femit-llvm-ir=t1.ll"], "inherit", "null");
await patchDl(await read("t1.ll"), "t1-ni.ll");
if (await redirect([FILC, "-O1", "-c", "-o", "t1.o", "t1-ni.ll"], "inherit", "t1c.log") === 0) {
  console.log("-- Zig object compiled through the pass");
  if (await redirect([FILC, "-O1", "-g", "-o", "prog1", "c_caller.c", "t1.o"], "inherit", "t1l.log") === 0) {
    console.log("-- linked C + Zig");
    const code = await redirect(["./prog1"], "t1run.log", "&1");
    console.log(`-- exit=${code}`);
    printIndented(lines(await read("t1run.log")), "   ");
  } else {
    console.log("-- LINK FAILED:");
    printIndented(grepM(await read("t1l.log"), /error|undefined/, 6), "   ");
  }
} else {
  console.log("-- COMPILE FAILED:");
  printIndented(grepM(await read("t1c.log"), /error|Assertion|Segmentation/, 3), "   ");
}

console.log();
console.log(bar);
console.log("TEST 2 — a whole Zig program (zig_oob.zig, libc malloc + printf)");
console.log(bar);
for (const mode of ["ReleaseSmall", "ReleaseSafe", "ReleaseFast"]) {
  console.log(`-- ${mode}`);
  const emit = [ZIG, "build-exe", "zig_oob.zig", "-target", "x86_64-linux-gnu", "-lc", "-O", mode, "-fno-emit-bin", `-femit-llvm-ir=z-${mode}.ll`];
  if (await redirect(emit, "inherit", `z-${mode}.emit.log`) === 0) {
    const ir = await read(`z-${mode}.ll`);
    await patchDl(ir, `z-${mode}-ni.ll`);
    const { nl, defs, asm } = counts(ir);
    await write(`   ${nl} lines, ${defs} defines, ${asm} asm  `);
    if (await redirect([FILC, "-O1", "-g", "-o", `zprog-${mode}`, `z-${mode}-ni.ll`], "inherit", `z-${mode}.log`) === 0) {
      console.log("LINKED");
      const code = await redirect([`./zprog-${mode}`], `z-${mode}.run`, "&1");
      console.log(`   exit=${code}`);
      printIndented(lines(await read(`z-${mode}.run`)), "      ");
    } else {
      console.log("FAILED");
      printIndented(grepM(await read(`z-${mode}.log`), /error:|Assertion|Segmentation|undefined/, 4), "      ");
    }
  } else {
    console.log("   emit failed");
    printIndented(lines(await read(`z-${mode}.emit.log`)).slice(0, 3), "      ");
  }
}

// ---- local helpers -----------------------------------------------------------------------------

/**
 * The shell version's awk `patch_dl`: the FIRST `target datalayout = ` line becomes Fil-C's
 * "before" layout followed by a new `target datalayout_after_filc = ` line; any existing
 * `datalayout_after_filc` line is dropped; everything else is copied. Written to `dest`.
 */
async function patchDl(ir: string, dest: string): Promise<void> {
  const out: string[] = [];
  let done = false;
  for (const l of lines(ir)) {
    if (l.startsWith("target datalayout = ") && !done) {
      out.push(`target datalayout = "${BEFORE}"`, `target datalayout_after_filc = "${AFTER}"`);
      done = true;
    } else if (!l.startsWith("target datalayout_after_filc = ")) out.push(l);
  }
  await Deno.writeTextFile(dest, out.map((l) => l + "\n").join(""));
}
/** `wc -l`, `grep -c '^define'`, `grep -c 'asm '` of the IR. */
function counts(ir: string): { nl: number; defs: number; asm: number } {
  const ls = lines(ir);
  return {
    nl: (ir.match(/\n/g) ?? []).length,
    defs: ls.filter((l) => l.startsWith("define")).length,
    asm: ls.filter((l) => l.includes("asm ")).length,
  };
}

type Dest = "inherit" | "null" | string;
/**
 * `cmd >stdout 2>stderr`: each a file path, "inherit" (this terminal) or "null"; stderr "&1" means
 * `2>&1` (both streams into the stdout file, interleaved as produced). Returns the exit code.
 */
async function redirect(argv: string[], stdout: Dest, stderr: Dest | "&1"): Promise<number> {
  if (stderr === "&1") stderr = stdout === "inherit" || stdout === "null" ? stdout : "&1";
  const piped = (d: Dest) => d !== "inherit" && d !== "null";
  const open = (d: Dest) => piped(d) ? Deno.open(d, { write: true, create: true, truncate: true }) : Promise.resolve(undefined);
  const both = stderr === "&1"; // now only when stdout is a file
  const fo = await open(stdout);
  const fe = both ? undefined : await open(stderr);
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
  if (both) {
    const sink = async (s: ReadableStream<Uint8Array>) => {
      for await (const c of s) await fo!.write(c);
    };
    await Promise.all([sink(child.stdout), sink(child.stderr)]);
    fo!.close();
  } else {
    await Promise.all([fo && child.stdout.pipeTo(fo.writable), fe && child.stderr.pipeTo(fe.writable)]);
  }
  return (await child.status).code;
}
async function read(p: string): Promise<string> {
  return await Deno.readTextFile(p).catch(() => "");
}
/** `printf '%s'`: text with no newline. */
async function write(s: string): Promise<void> {
  await Deno.stdout.write(new TextEncoder().encode(s));
}
/** The text's lines (no trailing empty one), as awk/grep/sed see them. */
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
