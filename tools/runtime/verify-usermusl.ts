// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Proves `zig build usermusl` against upstream's user libc (the release tarball's pizfix/). Both are
// compiled by Fil-C's clang (the release by its prebuilt one, here by zilc's patched one), so unlike
// verify-yolomusl.ts no GCC-vs-clang allowance applies: the one undefined difference allowed is
// the patched clang's own, measured and named below.
// Fil-C's clang is not byte-reproducible (cmem/toolchain-quirks.md F-1), so nothing is compared by
// bytes but the headers.
//
//   libc.a      member by member, IN ORDER: defined globals with their type, undefined symbols,
//               compile-unit names in upstream's form (DWARF);
//   libm.a … libdl.a   all eight empty archives, on both sides;
//   libc.so     exports (name + type), undefined, NEEDED, dynamic-tag kinds (RUNPATH's VALUE is
//               the install's: setup.sh rewrites the release's, parity item 7);
//   include/    every header ours installs is byte-identical to the release's at the same path,
//               and the release has none we lack.
//
//   bun tools/runtime/verify-usermusl.ts      (env ZILC_FILC: the Fil-C clang that compiles it)

import { readdirSync, readFileSync, statSync } from "node:fs";
import { existsSync, filc, FILC_PREBUILT_TREE, linuxOnly, must, PURE_ZIG_OUT, REPO, requireFilcSrc, run, ZIG, zigCacheArgs } from "../lib/tool.ts";
import { Oracle } from "./lib/objects.ts";

await linuxOnly(import.meta);

const src = await requireFilcSrc();
const tree = `${src}/projects/usermusl`;
const theirs = `${FILC_PREBUILT_TREE}/pizfix`;
// Both sides are Fil-C's clang, so the only undefined difference allowed is what zilc's PATCHED
// clang emits differently from the release's stock one (workarounds.md KI-22 / filc-pass-fixes):
// measured 2026-11-06, upstream's own `make` with the same patched clang gives the same
// difference, so it is the compiler, not zig build.
const oracle = new Oracle({
  oursOnlyUndef: new Set(["filc_object_ensure_aux_ptr_outline"]),
  theirsOnlyUndef: new Set(),
  why: "only the patched clang's difference is allowed",
  sourceForm: () => true,
  // `__FILE__` strings: Fil-C's own headers by the compiler tree's absolute path (each side its
  // own machine's), the rest as upstream's make names them; compared as sets with upstream's.
  sourceNormalize: (p) => p.replace(/^.*\/pizfix\/stdfil-include\//, "<filc>/pizfix/stdfil-include/"),
  // Members embedding the compiler tree's absolute stdfil.h path (or a piece of it): machine-
  // dependent layout, so not compared, counted (objects.ts sourceUncomparable).
  sourceUncomparable: (p) => p.endsWith("stdfil.h"),
});
const UNDEF_BUDGET = 2; // putc_unlocked, putchar (2026-11-06)
// A dedicated prefix: the shared PURE_ZIG_OUT also receives zilc's own include/zilc.h.
const prefix = `${PURE_ZIG_OUT}-usermusl`;
await must(["rm", "-rf", prefix]);

const b = await run([ZIG, "build", "usermusl", `-Dfilc-src=${src}`, `-Dfilc-clang=${filc()}`, "--prefix", prefix, ...zigCacheArgs()], { cwd: REPO, inherit: true });
if (b.code !== 0) {
  console.log("FAILED: zig build usermusl");
  process.exit(1);
}

const compared = await oracle.archives("libc.a", `${prefix}/lib/libc.a`, `${theirs}/lib/libc.a`);
oracle.ratchet("UNDEFINED", oracle.undefDiffering, UNDEF_BUDGET);
oracle.ratchet("SOURCE-PATHS-NOT-COMPARABLE", oracle.sourceSkipped, 11); // 2026-11-06
console.log(`libc.a: ${compared} members compared in order; compile unit names ${oracle.cuCompared} equal; __FILE__ paths ${oracle.sourceCompared} members equal, ${oracle.sourceSkipped} not comparable (stdfil.h's absolute path)`);

for (const n of ["m", "rt", "pthread", "crypt", "util", "xnet", "resolv", "dl"]) {
  const both = [`${prefix}/lib/lib${n}.a`, `${theirs}/lib/lib${n}.a`].map((p) => (existsSync(p) ? new TextDecoder().decode(readFileSync(p)) : "(missing)"));
  if (both[0] !== "!<arch>\n" || both[1] !== "!<arch>\n") oracle.fail(`lib${n}.a: not both empty archives (ours ${JSON.stringify(both[0].slice(0, 20))}, upstream's ${JSON.stringify(both[1].slice(0, 20))})`);
}
console.log("libm.a … libdl.a: checked (empty on both sides unless failed above)");

{
  const ourSo = `${prefix}/lib/libc.so`, theirSo = `${theirs}/lib/libc.so`;
  const nmD = async (p: string, f: string[]) =>
    new Set((await must(["nm", "-D", ...f, p])).split("\n").filter((l) => l.trim() && !l.startsWith("nm: ")).map((l) => l.trim().split(/\s+/).slice(-2).reverse().join(" ")));
  const [dO, dT, uO, uT] = await Promise.all([nmD(ourSo, ["--defined-only"]), nmD(theirSo, ["--defined-only"]), nmD(ourSo, ["--undefined-only"]), nmD(theirSo, ["--undefined-only"])]);
  const diff = (a: Set<string>, t: Set<string>) => [[...a].filter((s) => !t.has(s)), [...t].filter((s) => !a.has(s))];
  for (const [what, a, t] of [["EXPORTS", dO, dT], ["UNDEFINED", uO, uT]] as const) {
    const [plus, minus] = diff(a, t);
    if (plus.length || minus.length) oracle.fail(`libc.so ${what} DIFFER: +${plus.slice(0, 10).join(",")} -${minus.slice(0, 10).join(",")} (${plus.length}/${minus.length})`);
  }
  const dyn = async (p: string) => (await must(["readelf", "-d", p])).split("\n");
  const [yO, yT] = await Promise.all([dyn(ourSo), dyn(theirSo)]);
  const kinds = (ls: string[]) => [...new Set(ls.map((l) => l.match(/^\s*0x[0-9a-f]+ \((\w+)\)/)?.[1]).filter(Boolean))].sort().join(" ");
  const needed = (ls: string[]) => ls.map((l) => l.match(/\(NEEDED\)\s+Shared library: \[(.+)\]/)?.[1]).filter(Boolean).sort().join(" ");
  if (kinds(yO) !== kinds(yT)) oracle.fail(`libc.so DYNAMIC TAGS DIFFER: ours ${kinds(yO)} / upstream's ${kinds(yT)}`);
  if (needed(yO) !== needed(yT)) oracle.fail(`libc.so NEEDED DIFFER: ours ${needed(yO)} / upstream's ${needed(yT)}`);
  console.log(`libc.so: ${dO.size} exports (upstream's ${dT.size}), ${uO.size} undefined (${uT.size}); NEEDED ${needed(yO)}; tags ${kinds(yO)}`);
}

{
  const walk = (root: string, rel = ""): string[] =>
    readdirSync(`${root}/${rel}`).flatMap((n) => {
      const p = rel ? `${rel}/${n}` : n;
      return statSync(`${root}/${p}`).isDirectory() ? walk(root, p) : [p];
    });
  const ours = walk(`${prefix}/include`);
  let differ = 0;
  for (const f of ours) {
    const t = `${theirs}/include/${f}`;
    if (!existsSync(t) || !readFileSync(`${prefix}/include/${f}`).equals(readFileSync(t))) {
      if (differ++ < 5) oracle.fail(`include/${f}: ${existsSync(t) ? "differs from" : "not in"} the release's`);
    }
  }
  const mine = new Set(ours);
  const theirsOnly = walk(`${theirs}/include`).filter((f) => !mine.has(f));
  if (theirsOnly.length) oracle.fail(`include/: the release has ${theirsOnly.length} we lack (${theirsOnly.slice(0, 5).join(", ")})`);
  console.log(`include/: ${ours.length} headers, ${differ} differ, release-only ${theirsOnly.length}`);
}

console.log(oracle.failures ? `FAILED: ${oracle.failures}` : "OK: libc.a defines and needs exactly upstream's symbols in upstream's member order; libc.so exports and needs the same; the headers are upstream's, byte for byte");
process.exit(oracle.failures ? 1 : 0);
