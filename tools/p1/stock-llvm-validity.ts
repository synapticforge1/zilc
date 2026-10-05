// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Stock-LLVM acceptance test, via Zig's bundled clang (stock LLVM 21): how far Fil-C's IR dialect
// is from standard IR. Recorded in cmem/known-issues.md KI-4, "How far from standard IR is it,
// exactly? (measured 2026-09-23)": Fil-C's emitted IR is rejected only for its
// `datalayout_after_filc` line; without that line it is accepted; any `ni:0` layout is rejected
// ("address space 0 cannot be non-integral"); `ni:1` is accepted. Linux; from Windows it runs
// inside WSL.
//
//   deno run -A tools/p1/stock-llvm-validity.ts
//   env: WORK (default ~/zilc-work), ZILC_ZIG
// Inputs, in $WORK/p1 (made by hand during P1, 2026-09-23; not regenerated here): dl.ll (Fil-C's
// `-emit-llvm` output of dl.c), dl-stripped.ll (the same minus the datalayout_after_filc line),
// ni0.ll, plain.ll, ni1.ll (one small module with three datalayouts).
// Output: <input>.stock.log per input (the compiler's messages), the object in /tmp/t.o, and the
// same verdict table as the shell version (tools/p1/stock-llvm-validity.sh).
import { linuxOnly, run, WORK, ZIG } from "../lib/tool.ts";

await linuxOnly(import.meta);
const OUT = `${WORK}/p1`;
// Paths stay relative to $WORK/p1 (the shell version `cd`s there) so the compiler's messages read
// "dl.ll:4:8: error: …", as recorded.
const cwd = OUT;
const lines = (text: string) => text.split("\n").filter((_, i, a) => i < a.length - 1 || a[i] !== "");

async function tryOne(label: string, file: string): Promise<void> {
  await Deno.stdout.write(new TextEncoder().encode(label.padEnd(58)));
  // The log was `zig cc`'s stderr only (`2>`); `zig cc -c` writes nothing to stdout, so capturing
  // both is the same file.
  const r = await run([ZIG, "cc", "-c", file, "-o", "/tmp/t.o"], { cwd, outFile: `${OUT}/${file}.stock.log` });
  if (r.code === 0) {
    console.log("ACCEPTED");
  } else {
    console.log("REJECTED");
    // `grep -m2 -E "error" log | sed 's/^/      /'`
    const log = await Deno.readTextFile(`${OUT}/${file}.stock.log`);
    for (const l of lines(log).filter((l) => /error/.test(l)).slice(0, 2)) console.log(`      ${l}`);
  }
}

await tryOne("1. Fil-C's emitted IR, unmodified", "dl.ll");
await tryOne("2. ... with only the datalayout_after_filc line removed", "dl-stripped.ll");
await tryOne("3. a module whose datalayout has ni:0", "ni0.ll");
await tryOne("4. control: same module, no ni", "plain.ll");
await tryOne("5. ni on a NON-zero address space (ni:1)", "ni1.ll");

console.log();
console.log("== does the stripped Fil-C module still behave like normal IR? (symbols)");
const stripped = lines(await Deno.readTextFile(`${OUT}/dl-stripped.ll`));
console.log(stripped.slice(0, 3).join("\n")); // `head -3`
console.log(stripped.filter((l) => l.includes("pizlonated_")).length); // `grep -c pizlonated_`
