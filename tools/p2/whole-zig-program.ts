// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Test 2 retry: Fil-C's libc IS musl, so Zig must target musl symbol names. (2026-09-23)
// Linux (Fil-C); from Windows it runs inside WSL.
//
//   deno run -A tools/p2/whole-zig-program.ts
//   env: WORK (default ~/zilc-work)
//
// zig_oob.zig (a whole Zig program, libc malloc + printf) emitted as IR by stock Zig per release
// mode for x86_64-linux-musl (KI-6), datalayout rewritten into Fil-C's dialect, compiled and linked
// by the stock Fil-C clang, and run. Recorded in tools/p2/README.md: it links and runs, and then
// traps in Zig's start code before main (KI-5, since solved in the driver by a generated entry shim).
// Work and logs in $WORK/p2: m-<mode>.ll, m-<mode>-ni.ll, m-<mode>.log/.emit.log/.run, mprog-<mode>.
// zig_oob.zig is NOT copied here, as in the shell version: milestone.ts puts it in $WORK/p2.
//
// Converted from whole-zig-program.sh (2026-10-05).
import { FILC_0685_PREBUILT_TREE, linuxOnly, mkdirp, WORK } from "../lib/tool.ts";

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

for (const mode of ["ReleaseSmall", "ReleaseFast", "ReleaseSafe"]) {
  console.log(`-- ${mode}, target x86_64-linux-musl`);
  const ll = `m-${mode}.ll`;
  const emit = [ZIG, "build-exe", "zig_oob.zig", "-target", "x86_64-linux-musl", "-lc", "-O", mode, "-fno-emit-bin", `-femit-llvm-ir=${ll}`];
  if (await redirect(emit, "inherit", `m-${mode}.emit.log`) !== 0) {
    console.log("   emit failed");
    printIndented(lines(await read(`m-${mode}.emit.log`)).slice(0, 3), "      ");
    continue;
  }
  const ir = await read(ll);
  await patchDl(ir, `m-${mode}-ni.ll`);
  const { nl, defs, asm } = counts(ir);
  await write(`   ${nl} lines, ${defs} defines, ${asm} asm  `);
  if (await redirect([FILC, "-O1", "-g", "-o", `mprog-${mode}`, `m-${mode}-ni.ll`], "inherit", `m-${mode}.log`) === 0) {
    console.log("LINKED");
    const code = await redirect([`./mprog-${mode}`], `m-${mode}.run`, "&1");
    console.log(`   exit=${code}`);
    printIndented(lines(await read(`m-${mode}.run`)), "      ");
  } else {
    console.log("FAILED");
    printIndented(grepM(await read(`m-${mode}.log`), /error:|Assertion|Segmentation|undefined reference/, 5), "      ");
  }
  console.log();
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
