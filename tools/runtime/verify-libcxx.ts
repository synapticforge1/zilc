// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Proves `zig build libcxx` against upstream's libc++ / libc++abi (the release tarball's pizfix/lib
// and build/include). Both are compiled by Fil-C's clang++ (the release by its prebuilt one, here
// by zilc's patched one); no compiler-difference allowance is given. Fil-C's clang is not
// byte-reproducible (toolchain-quirks F-1), so libraries are compared by symbols, not bytes.
//
//   libc++.a, libc++abi.a, libc++experimental.a   member by member IN ORDER: defined globals with
//               type, undefined symbols, compile-unit names (each build's location stripped: CMake
//               compiles absolute paths), `__FILE__` strings (the same, as sets; F-3);
//   libc++.so.1.0, libc++abi.so.1.0   exports (name + type), undefined, NEEDED, SONAME, tag kinds
//               (RUNPATH's value is the install's: setup.sh rewrites the release's, parity item 7);
//   libc++.so   the linker script, byte for byte; the .so.1 / .so links, by target;
//   cxx-include/   every header byte-identical to the release's build/include, none missing.
//
//   bun tools/runtime/verify-libcxx.ts      (env ZILC_FILC: the Fil-C clang that compiles it)

import { readdirSync, readFileSync, readlinkSync, statSync } from "node:fs";
import { existsSync, filc, filcPackageDir, FILC_PREBUILT_TREE, linuxOnly, must, PURE_ZIG_OUT, REPO, requireFilcSrc, run, ZIG, zigCacheArgs } from "../lib/tool.ts";
import { Oracle } from "./lib/objects.ts";

await linuxOnly(import.meta);

// The FETCHED package, as `zig build` uses by default: FILC_SRC is a sparse checkout without
// libc/, which libc++'s charconv code includes (libc/shared/fp_bits.h).
await requireFilcSrc();
const src = await filcPackageDir();
const theirs = FILC_PREBUILT_TREE;
// The part of a path from the source tree's own directories on: the same file on both sides,
// wherever each build ran (or wherever its generated header tree sat).
const fromTree = (p: string) => p.replace(/^.*?\/((libcxx|libcxxabi|libc|runtimes)\/)/, "$1").replace(/^.*?(c\+\+\/v1\/)/, "$1");
const oracle = new Oracle({
  oursOnlyUndef: new Set(),
  theirsOnlyUndef: new Set(),
  why: "none allowed: both sides are Fil-C's clang++",
  sourceForm: () => true,
  sourceNormalize: fromTree,
  sourceUncomparable: (p) => p.endsWith("stdfil.h"),
  cuNormalize: fromTree,
});
const prefix = `${PURE_ZIG_OUT}-libcxx`;
await must(["rm", "-rf", prefix]);
const b = await run([ZIG, "build", "libcxx", `-Dfilc-src=${src}`, `-Dfilc-clang=${filc()}`, "--prefix", prefix, ...zigCacheArgs()], { cwd: REPO, inherit: true });
if (b.code !== 0) {
  console.log("FAILED: zig build libcxx");
  process.exit(1);
}

for (const a of ["libc++.a", "libc++abi.a", "libc++experimental.a"]) {
  const n = await oracle.archives(a, `${prefix}/lib/${a}`, `${theirs}/pizfix/lib/${a}`);
  console.log(`${a}: ${n} members compared in order`);
}
oracle.ratchet("UNDEFINED", oracle.undefDiffering, 0);
console.log(`compile unit names: ${oracle.cuCompared} equal; __FILE__ paths: ${oracle.sourceCompared} members equal, ${oracle.sourceSkipped} not comparable`);

for (const so of ["libc++.so.1.0", "libc++abi.so.1.0"]) {
  const ourSo = `${prefix}/lib/${so}`, theirSo = `${theirs}/pizfix/lib/${so}`;
  const nmD = async (p: string, f: string[]) =>
    new Set((await must(["nm", "-D", ...f, p])).split("\n").filter((l) => l.trim() && !l.startsWith("nm: ")).map((l) => l.trim().split(/\s+/).slice(-2).reverse().join(" ")));
  const [dO, dT, uO, uT] = await Promise.all([nmD(ourSo, ["--defined-only"]), nmD(theirSo, ["--defined-only"]), nmD(ourSo, ["--undefined-only"]), nmD(theirSo, ["--undefined-only"])]);
  for (const [what, a, t] of [["EXPORTS", dO, dT], ["UNDEFINED", uO, uT]] as const) {
    const plus = [...a].filter((s) => !t.has(s)), minus = [...t].filter((s) => !a.has(s));
    if (plus.length || minus.length) oracle.fail(`${so} ${what} DIFFER: +${plus.slice(0, 8).join(",")} -${minus.slice(0, 8).join(",")} (${plus.length}/${minus.length})`);
  }
  const dyn = async (p: string) => (await must(["readelf", "-d", p])).split("\n");
  const [yO, yT] = await Promise.all([dyn(ourSo), dyn(theirSo)]);
  const kinds = (ls: string[]) => [...new Set(ls.map((l) => l.match(/^\s*0x[0-9a-f]+ \((\w+)\)/)?.[1]).filter(Boolean))].sort().join(" ");
  const named = (ls: string[], tag: string) => ls.map((l) => l.match(new RegExp(`\\(${tag}\\)\\s+[^\\[]*\\[(.+)\\]`))?.[1]).filter(Boolean).sort().join(" ");
  if (kinds(yO) !== kinds(yT)) oracle.fail(`${so} DYNAMIC TAGS DIFFER: ours ${kinds(yO)} / upstream's ${kinds(yT)}`);
  for (const tag of ["NEEDED", "SONAME"]) if (named(yO, tag) !== named(yT, tag)) oracle.fail(`${so} ${tag} DIFFER: ours ${named(yO, tag)} / upstream's ${named(yT, tag)}`);
  console.log(`${so}: ${dO.size} exports (upstream's ${dT.size}), ${uO.size} undefined; NEEDED ${named(yO, "NEEDED")}; SONAME ${named(yO, "SONAME")}`);
}

if (!readFileSync(`${prefix}/lib/libc++.so`).equals(readFileSync(`${theirs}/pizfix/lib/libc++.so`))) oracle.fail("libc++.so: the linker script differs");
for (const [l, to] of [["libc++.so.1", "libc++.so.1.0"], ["libc++abi.so.1", "libc++abi.so.1.0"], ["libc++abi.so", "libc++abi.so.1"]]) {
  const [a, t] = [`${prefix}/lib/${l}`, `${theirs}/pizfix/lib/${l}`].map((p) => (existsSync(p) ? readlinkSync(p) : "(missing)"));
  if (a !== to || t !== to) oracle.fail(`${l}: ours -> ${a}, upstream's -> ${t} (expected ${to})`);
}
console.log("libc++.so script and the .so links: checked");

{
  const walk = (root: string, rel = ""): string[] =>
    readdirSync(`${root}/${rel}`).flatMap((n) => {
      const p = rel ? `${rel}/${n}` : n;
      return statSync(`${root}/${p}`).isDirectory() ? walk(root, p) : [p];
    });
  const ours = walk(`${prefix}/cxx-include`);
  let differ = 0;
  for (const f of ours) {
    const t = `${theirs}/build/include/${f}`;
    if (!existsSync(t) || !readFileSync(`${prefix}/cxx-include/${f}`).equals(readFileSync(t))) if (differ++ < 5) oracle.fail(`cxx-include/${f}: ${existsSync(t) ? "differs from" : "not in"} the release's build/include`);
  }
  const mine = new Set(ours);
  const theirsOnly = walk(`${theirs}/build/include`).filter((f) => !mine.has(f));
  if (theirsOnly.length) oracle.fail(`build/include: the release has ${theirsOnly.length} we lack (${theirsOnly.slice(0, 5).join(", ")})`);
  console.log(`cxx-include/: ${ours.length} headers, ${differ} differ, release-only ${theirsOnly.length}`);
}

console.log(oracle.failures ? `FAILED: ${oracle.failures}` : "OK: the three archives define and need exactly upstream's symbols in upstream's member order; the two shared libraries export and need the same, with upstream's SONAMEs; the script, the links and the headers are upstream's");
process.exit(oracle.failures ? 1 : 0);
