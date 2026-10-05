// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Compile-check every tests/basics example for zilc's target (x86_64-linux-musl) with PLAIN Zig
// 0.15.2 and -lc (libc linked, as zilc builds): no Fil-C involved. It tells "does this example build
// at all" apart from "does it survive zilc", which is a later question. Runs on ANY OS (Zig cross-
// compiles): on Windows it uses C:\zig\0.15.2\zig.exe, elsewhere the WSL toolchain's Zig.
//
//   deno run -A tools/basics/compile-check.ts      env: ZIG (the Zig to use), ZIGDIR
// Writes one line per example to zig-out/basics-compile.txt and prints a summary.
//
// C examples are compiled AND linked, as their own repo builds them (`zig cc -lc`), in the default
// C dialect: -std=c99 hides POSIX declarations under musl and fails for the wrong reason.
import { basename, env, glob, isWindows, mkdirp, REPO, rmrf, run, ZIG } from "../lib/tool.ts";

const zig = env("ZIG", isWindows ? "C:\\zig\\0.15.2\\zig.exe" : ZIG);
const tests = `${REPO}/tests/basics`;
await mkdirp(`${REPO}/zig-out`);
const bin = `${REPO}/zig-out/basics-check`;
const lines: string[] = [];
const reason = (out: string) => (out.split("\n").find((l) => l.includes("error:")) ?? "").replace(/.*error: /, "");

for (const f of await glob(`${tests}/${env("ZIGDIR", "zig-0.15.2")}/*/*.zig`)) {
  const r = await run([zig, "build-exe", "-fno-emit-bin", "-lc", "-target", "x86_64-linux-musl", f]);
  lines.push(`zig ${basename(f.slice(0, f.lastIndexOf("/")))} ${r.code === 0 ? "ok" : `FAIL ${reason(r.out)}`}`);
}
for (const f of await glob(`${tests}/c/*/*.c`)) {
  const r = await run([zig, "cc", "-lc", "-target", "x86_64-linux-musl", "-o", bin, f]);
  lines.push(`c ${basename(f.slice(0, f.lastIndexOf("/")))} ${r.code === 0 ? "ok" : `FAIL ${reason(r.out)}`}`);
}
await rmrf(bin);
await rmrf(`${bin}.exe`);
await Deno.writeTextFile(`${REPO}/zig-out/basics-compile.txt`, lines.join("\n") + "\n");

for (const lang of ["zig", "c"]) {
  const mine = lines.filter((l) => l.startsWith(`${lang} `));
  console.log(`${lang.padEnd(3)} ok: ${mine.filter((l) => l.endsWith(" ok")).length} / ${mine.length}`);
}
console.log("-- failure reasons:");
const counts = new Map<string, number>();
for (const l of lines.filter((l) => l.includes(" FAIL "))) {
  const k = l.replace(/^([a-z]*) \S* FAIL /, "$1: ");
  counts.set(k, (counts.get(k) ?? 0) + 1);
}
for (const [k, n] of [...counts].sort((a, b) => b[1] - a[1])) console.log(`${String(n).padStart(7)} ${k}`);
