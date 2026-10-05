// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Shrink Zig's IR until it is small enough to inspect, and see if the crash follows. (2026-09-23)
// Linux (Fil-C); from Windows it runs inside WSL.
//
//   deno run -A tools/p2/optmode-matrix.ts
//   env: WORK (default ~/zilc-work)
//
// tiny.zig is emitted as LLVM IR by stock Zig in each optimize mode, the datalayout is rewritten
// into Fil-C's dialect (see patchDl), and the stock Fil-C clang compiles it at -O1. One line per
// mode: IR size, defines, inline-asm lines, and PASS OK or CRASH. The result recorded in
// tools/p2/README.md: ReleaseSmall / ReleaseFast / ReleaseSafe pass and only Debug crashes, the run
// that overturned the previous day's conclusion (cmem/known-issues.md KI-4).
// Work and logs in $WORK/p2: tiny-<mode>.ll, tiny-<mode>-ni.ll, tiny-<mode>.o, <mode>.log.
//
// Converted from optmode-matrix.sh (2026-10-05). The one input change: tiny.zig was copied from
// $WORK/p1, which no longer has it (the cp failed silently and the copy already in $WORK/p2 was
// used); this copies the committed tools/p2/tiny.zig, byte-identical to it.
import { FILC_0685_PREBUILT_TREE, linuxOnly, mkdirp, REPO, WORK } from "../lib/tool.ts";

await linuxOnly(import.meta);
const ZIG = `${WORK}/tools/zig-0.15.2/zig`;
// The stock prebuilt on purpose: this records what Fil-C 0.685 itself does with Zig's IR.
const FILC = `${FILC_0685_PREBUILT_TREE}/build/bin/clang`;
const OUT = `${WORK}/p2`;
// Fil-C's two layout lines. Position matters: LLVM compares layout strings textually, so `ni:0`
// goes right after `m:e` (cmem/known-issues.md KI-4).
const BEFORE = "e-m:e-ni:0-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128";
const AFTER = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128";
await mkdirp(OUT);
Deno.chdir(OUT);
await Deno.copyFile(`${REPO}/tools/p2/tiny.zig`, "tiny.zig");

for (const mode of ["Debug", "ReleaseSafe", "ReleaseSmall", "ReleaseFast"]) {
  const ll = `tiny-${mode}.ll`;
  await redirect([ZIG, "build-obj", "tiny.zig", "-target", "x86_64-linux-gnu", "-O", mode, "-fno-emit-bin", `-femit-llvm-ir=${ll}`], "inherit", "null");
  const ir = await read(ll);
  await patchDl(ir, `tiny-${mode}-ni.ll`);
  const { nl, defs, asm } = counts(ir);
  let verdict: string;
  if (await redirect([FILC, "-O1", "-c", "-o", `tiny-${mode}.o`, `tiny-${mode}-ni.ll`], "inherit", `${mode}.log`) === 0) {
    verdict = "PASS OK";
  } else {
    // grep -m1 -oE 'exit code [0-9]+|Assertion': every match on the first matching line.
    const first = lines(await read(`${mode}.log`)).find((l) => /exit code [0-9]+|Assertion/.test(l)) ?? "";
    verdict = `CRASH (${(first.match(/exit code [0-9]+|Assertion/g) ?? []).join("\n")})`;
  }
  console.log(`${mode.padEnd(14)} ${String(nl).padStart(7)} lines  ${String(defs).padStart(4)} defines  ${String(asm).padStart(3)} asm   ${verdict}`);
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
/** The text's lines (no trailing empty one), as awk/grep see them. */
function lines(text: string): string[] {
  const l = text.split("\n");
  if (l[l.length - 1] === "") l.pop();
  return l;
}
