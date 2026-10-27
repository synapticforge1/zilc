// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Proves the Zig forwarder generator against Ruby, byte for byte (the pure-Zig track's oracle,
// cmem/roadmap.md; brought from zailc, 2026-10-27):
//   1. runs upstream's generate_pizlonated_forwarders.rb (from the Fil-C checkout at FILC_SHA) into
//      $WORK/pure-zig/ref/forwarders/src/libpas/ (the script writes to that fixed relative path);
//   2. builds zilc-gen and writes both files into $WORK/pure-zig/gen/;
//   3. compares. Exit 0 only when both files are identical.
//
//   bun tools/gen/verify-forwarders.ts

import { copyFile, readFile } from "node:fs/promises";
import { PURE_ZIG_OUT, REPO, WORK, linuxOnly, mkdirp, must, requireFilcSrc, run, sha256, ZIG, zigCacheArgs } from "../lib/tool.ts";

await linuxOnly(import.meta);

const src = await requireFilcSrc();
const rb = `${src}/libpas/src/libpas/generate_pizlonated_forwarders.rb`;
const files = ["filc_native.h", "filc_native_forwarders.c"];

// 1. Ruby's output.
const ref = `${WORK}/pure-zig/ref/forwarders`;
await mkdirp(`${ref}/src/libpas`);
await copyFile(rb, `${ref}/src/libpas/generate_pizlonated_forwarders.rb`);
for (const f of files) await must(["ruby", "src/libpas/generate_pizlonated_forwarders.rb", `src/libpas/${f}`], { cwd: ref });

// 2. Zig's output.
await must([ZIG, "build", "--prefix", PURE_ZIG_OUT, ...zigCacheArgs()], { cwd: REPO });
const gen = `${WORK}/pure-zig/gen`;
await mkdirp(gen);
await must([`${PURE_ZIG_OUT}/bin/zilc-gen`, "header", `${gen}/filc_native.h`]);
await must([`${PURE_ZIG_OUT}/bin/zilc-gen`, "forwarders", `${gen}/filc_native_forwarders.c`]);

// 3. Compare.
let ok = true;
for (const f of files) {
  const a = await readFile(`${ref}/src/libpas/${f}`);
  const b = await readFile(`${gen}/${f}`);
  const same = a.length === b.length && a.every((x, i) => x === b[i]);
  const lines = b.toString("latin1").split("\n").length - 1;
  console.log(`${same ? "SAME" : "DIFF"}  ${f}  ruby ${a.length} B  zig ${b.length} B  ${lines} lines  sha256(ruby) ${await sha256(new Uint8Array(a))}`);
  if (!same) {
    ok = false;
    const d = await run(["diff", "-u", `${ref}/src/libpas/${f}`, `${gen}/${f}`]);
    console.log(d.out.split("\n").slice(0, 60).join("\n"));
  }
}
console.log(ok ? `OK: zilc-gen's output is byte-identical to Ruby's (Fil-C checkout ${src})` : "FAILED: outputs differ");
process.exit(ok ? 0 : 1);
