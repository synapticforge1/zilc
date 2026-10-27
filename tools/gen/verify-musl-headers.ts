// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Proves `zilc-gen musl-headers` against upstream, byte for byte (the pure-Zig track's oracle,
// cmem/roadmap.md; brought from zailc, 2026-10-27):
//   1. copies Fil-C's projects/yolomusl to $WORK/pure-zig/ref/yolomusl, runs its ./configure (needs
//      a host C compiler; the ORACLE only) and `make install-headers` into …/out/include;
//   2. builds zilc-gen and writes the same tree into $WORK/pure-zig/gen/yolo-include;
//   3. `diff -r` the two. Exit 0 only when they are identical.
//
//   bun tools/gen/verify-musl-headers.ts

import { PURE_ZIG_OUT, REPO, WORK, linuxOnly, mkdirp, must, requireFilcSrc, rmrf, run, ZIG, zigCacheArgs } from "../lib/tool.ts";

await linuxOnly(import.meta);

const src = await requireFilcSrc();
const musl = `${src}/projects/yolomusl`;
const arch = (await must(["uname", "-m"])).trim();

// 1. Upstream's headers.
const ref = `${WORK}/pure-zig/ref/yolomusl`;
await rmrf(ref);
await mkdirp(`${WORK}/pure-zig/ref`);
await must(["cp", "-r", musl, ref]);
await must(["./configure", `--prefix=${ref}/out`, "CC=clang"], { cwd: ref });
await must(["make", "install-headers"], { cwd: ref });

// 2. Ours.
await must([ZIG, "build", "--prefix", PURE_ZIG_OUT, ...zigCacheArgs()], { cwd: REPO });
const gen = `${WORK}/pure-zig/gen/yolo-include`;
await rmrf(gen);
await must([`${PURE_ZIG_OUT}/bin/zilc-gen`, "musl-headers", musl, gen, arch]);

// 3. Compare.
const count = async (d: string) => (await must(["sh", "-c", 'find "$0" -type f | wc -l', d])).trim();
const d = await run(["diff", "-r", `${ref}/out/include`, gen]);
console.log(`upstream: ${await count(`${ref}/out/include`)} files   zilc-gen: ${await count(gen)} files`);
if (d.code === 0) {
  console.log(`OK: yolo-include is byte-identical to upstream's make install-headers (${arch}, Fil-C checkout ${src})`);
} else {
  console.log(d.out.split("\n").slice(0, 60).join("\n"));
  console.log("FAILED: trees differ");
}
process.exit(d.code === 0 ? 0 : 1);
