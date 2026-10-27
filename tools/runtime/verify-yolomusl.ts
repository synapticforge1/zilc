// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Proves `zig build yolomusl` against upstream's yolo musl (the release tarball's pizfix/lib):
//
//   libyoloc.a   member by member, IN ORDER (names repeat, so position pairs them; the importer
//                reproduces upstream's member order, which this checks name by name):
//                - the global symbols each member defines, with their type (strong vs weak), equal;
//                - undefined symbols equal, except differences drawn ONLY from what the two
//                  compilers emit differently (upstream's release was built by GCC 12.3, zilc by
//                  Zig's clang; workarounds.md W-8), and exactly UNDEF_BUDGET members of them;
//                - every source path a member carries in the form upstream's make (run in
//                  projects/yolomusl) spells it, and the same compile-unit names (DWARF).
//   crt1.o Scrt1.o rcrt1.o crti.o crtn.o   the same checks.
//   libyolom.a   both empty archives.
//
//   bun tools/runtime/verify-yolomusl.ts     

import { readFileSync } from "node:fs";
import { FILC_PREBUILT_TREE, PURE_ZIG_OUT, REPO, existsSync, linuxOnly, must, requireFilcSrc, run, ZIG, zigCacheArgs } from "../lib/tool.ts";
import { Oracle } from "./lib/objects.ts";

await linuxOnly(import.meta);

const src = await requireFilcSrc();
const tree = `${src}/projects/yolomusl`;
const theirLib = `${FILC_PREBUILT_TREE}/pizfix/lib`;
const prefix = PURE_ZIG_OUT;

// Undefined symbols the two compilers differ in, and nothing else: GCC's PIC code names the GOT
// symbol explicitly, and clang lowers some struct copies and zeroings to memcpy/memset calls that
// GCC inlines (both defined by this libc itself). W-8.
const oracle = new Oracle({
  oursOnlyUndef: new Set(["memcpy", "memset"]),
  theirsOnlyUndef: new Set(["_GLOBAL_OFFSET_TABLE_"]),
  why: "W-8",
  sourceForm: (p) => !p.startsWith("/") && existsSync(`${tree}/${p}`),
});
const UNDEF_BUDGET = 28; // members whose undefined symbols differ (within the sets above)
// A translation unit that compiles to nothing (src/linux/cache.c on x86_64: all three of its
// #ifdef SYS_* blocks are out) still gets a DWARF compile unit from GCC and none from clang.
// Allowed only when upstream's member defines and references nothing; counted. W-8.
const EMPTY_TU_BUDGET = 1;

const b = await run([ZIG, "build", "yolomusl", `-Dfilc-src=${src}`, "--prefix", prefix, ...zigCacheArgs()], { cwd: REPO, inherit: true });
if (b.code !== 0) {
  console.log("FAILED: zig build yolomusl");
  process.exit(1);
}

const compared = await oracle.archives("libyoloc.a", `${prefix}/lib/libyoloc.a`, `${theirLib}/libyoloc.a`);
const libcUndef = oracle.undefDiffering;
oracle.ratchet("UNDEFINED", libcUndef, UNDEF_BUDGET);
console.log(`libyoloc.a: ${compared} members compared in order; ${libcUndef} with compiler-only undefined differences (budget ${UNDEF_BUDGET})`);

for (const f of ["crt1.o", "Scrt1.o", "rcrt1.o", "crti.o", "crtn.o"]) {
  const d = await oracle.pair(f, `${prefix}/lib/${f}`, `${theirLib}/${f}`);
  console.log(`${f}: compared${d ? " (compiler-only undefined differences)" : ""}`);
}
const yolom = [`${prefix}/lib/libyolom.a`, `${theirLib}/libyolom.a`].map((p) => new TextDecoder().decode(readFileSync(p)));
if (yolom[0] !== "!<arch>\n" || yolom[1] !== "!<arch>\n") oracle.fail(`libyolom.a: not both empty archives`);
else console.log("libyolom.a: both empty archives");

// libyoloc.so, which is also the dynamic loader (ld-fil1-x86_64.so links to it): what it exports
// (name + type), that it needs nothing, its dynamic-section entries and segment kinds, and that it
// starts at _dlstart — against the release's (added 2026-10-27).
{
  const ourSo = `${PURE_ZIG_OUT}/lib/libyoloc.so`, theirSo = `${theirLib}/libyoloc.so`;
  const nmD = async (p: string, f: string[]) =>
    new Set((await must(["nm", "-D", ...f, p])).split("\n").filter((l) => l.trim() && !l.startsWith("nm: ")).map((l) => l.trim().split(/\s+/).slice(-2).reverse().join(" ")));
  const [dO, dT, uO, uT] = await Promise.all([nmD(ourSo, ["--defined-only"]), nmD(theirSo, ["--defined-only"]), nmD(ourSo, ["--undefined-only"]), nmD(theirSo, ["--undefined-only"])]);
  const plus = [...dO].filter((s) => !dT.has(s)), minus = [...dT].filter((s) => !dO.has(s));
  if (plus.length || minus.length) oracle.fail(`libyoloc.so EXPORTS DIFFER: +${plus.slice(0, 12).join(",")}${plus.length > 12 ? "…" : ""} -${minus.slice(0, 12).join(",")}${minus.length > 12 ? "…" : ""} (${plus.length}/${minus.length})`);
  if (uO.size || uT.size) oracle.fail(`libyoloc.so UNDEFINED: ours ${[...uO].join(",") || "none"}, upstream's ${[...uT].join(",") || "none"}`);
  const tags = async (p: string) => new Set([...(await must(["readelf", "-d", p])).matchAll(/^\s*0x[0-9a-f]+ \((\w+)\)/gm)].map((m) => m[1]));
  const segs = async (p: string) => new Set([...(await must(["readelf", "-lW", p])).matchAll(/^\s+([A-Z_]+)\s+0x/gm)].map((m) => m[1]));
  // Linker and compiler differences, allowed by name (cmem/workarounds.md W-11, measured
  // 2026-10-27): LLD gives a shared object a PHDR segment and GNU ld does not; and every member of
  // the release's GCC-built archive carries .note.gnu.property (x86 ISA-used notes), from which GNU
  // ld makes GNU_PROPERTY, while Zig's clang emits no such note.
  const allowed = { "segment kinds": { ours: ["PHDR"], theirs: ["GNU_PROPERTY"] }, "dynamic tags": { ours: [], theirs: [] } } as const;
  for (const [what, f] of [["dynamic tags", tags], ["segment kinds", segs]] as const) {
    const [a, t] = await Promise.all([f(ourSo), f(theirSo)]);
    const ok = allowed[what];
    const ap = [...a].filter((x) => !t.has(x)), tp = [...t].filter((x) => !a.has(x));
    const same = (xs: string[], ys: readonly string[]) => xs.length === ys.length && xs.every((x) => ys.includes(x));
    if (!same(ap, ok.ours) || !same(tp, ok.theirs)) oracle.fail(`libyoloc.so ${what.toUpperCase()} DIFFER: ours only ${ap.join(",") || "-"}, upstream's only ${tp.join(",") || "-"} (allowed: ${ok.ours.join(",") || "-"} / ${ok.theirs.join(",") || "-"})`);
    else console.log(`libyoloc.so ${what}: the same${ap.length + tp.length ? ` but for the allowed ours ${ap.join(",")} / upstream's ${tp.join(",")}` : ""} (${[...a].filter((x) => t.has(x)).sort().join(" ")})`);
  }
  const entryAtDlstart = async (p: string) => {
    const entry = BigInt((await must(["readelf", "-h", p])).match(/Entry point address:\s+(0x[0-9a-f]+)/)![1]);
    const sym = (await must(["nm", p])).split("\n").find((l) => / _dlstart$/.test(l));
    return sym ? BigInt(`0x${sym.split(" ")[0]}`) === entry : null;
  };
  const [eO, eT] = await Promise.all([entryAtDlstart(ourSo), entryAtDlstart(theirSo)]);
  if (eO !== true) oracle.fail(`libyoloc.so ENTRY: ours does not start at _dlstart (${eO})`);
  console.log(`libyoloc.so: ${dO.size} exports (upstream's ${dT.size}), ${uO.size} undefined; entry at _dlstart: ours ${eO}, upstream's ${eT ?? "(stripped)"}`);
}

oracle.ratchet("EMPTY-TU", oracle.emptyTu, EMPTY_TU_BUDGET);
console.log(`compile unit names: ${oracle.cuCompared} equal to upstream's; ${oracle.emptyTu} empty translation unit(s) where only GCC emits one (budget ${EMPTY_TU_BUDGET})`);
console.log(oracle.failures ? `FAILED: ${oracle.failures}` : "OK: libyoloc.a and the crt objects define exactly upstream's symbols, in upstream's member order, with upstream's compile unit names; libyoloc.so exports exactly upstream's symbols and needs none");
process.exit(oracle.failures ? 1 : 0);
