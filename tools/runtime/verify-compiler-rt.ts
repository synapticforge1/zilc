// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Proves `zig build compiler-rt` against upstream's compiler-rt (the release tarball's pizfix/lib):
//
//   libyolort.a   member by member, IN ORDER: defined globals with their binding equal; undefined
//                 equal except what the compilers emit differently (upstream's release was built by
//                 GCC 11.4, zilc by Zig's clang; workarounds.md W-8), ratcheted; source paths and
//                 compile-unit names as upstream's (neither build has debug info: Release, no -g).
//   crtbegin.o crtend.o   the same checks.
//
//   bun tools/runtime/verify-compiler-rt.ts    

import { FILC_PREBUILT_TREE, PURE_ZIG_OUT, REPO, existsSync, linuxOnly, must, requireFilcSrc, run, ZIG, zigCacheArgs } from "../lib/tool.ts";
import { Oracle } from "./lib/objects.ts";

await linuxOnly(import.meta);

const src = await requireFilcSrc();
const builtins = `${src}/compiler-rt/lib/builtins`;
const theirLib = `${FILC_PREBUILT_TREE}/pizfix/lib`;
const prefix = PURE_ZIG_OUT;

// What GCC 11.4 as Ubuntu ships it and Zig's clang emit differently (W-8): GCC names the GOT symbol
// in PIC code; the two compilers pick different helper libcalls for the same operation (signed vs
// unsigned 128-bit division inside the overflow checks of muloti4/mulvti3; which __float128
// comparison and conversion helpers divtc3/multc3 use); and under clang glibc's headers fortify
// eprintf's fprintf as __vfprintf_chk where GCC's give __fprintf_chk (the same check). Since
// 2026-11-05 zilc compiles compiler-rt with Ubuntu GCC's hardening defaults too (build/pure_zig.zig,
// toolchain-quirks.md C-7b), so __stack_chk_fail and the fortified call are on both sides (until
// then they were listed here as GCC-only). Every helper named on either side is itself defined in
// libyolort; __vfprintf_chk/__fprintf_chk are libc's.
// -fstack-protector-strong's rule for WHICH functions to guard differs between the compilers: clang
// guards every function GCC 11.4 guards (the release's 9 members) and these 8 more (x87 long-double
// conversions, eprintf), measured 2026-11-05. So __stack_chk_fail may be ours-only, but only in
// exactly these members (checked below, both ways): stronger, never weaker, than the release.
const CLANG_EXTRA_SSP = ["eprintf.c.o", "fixunsxfdi.c.o", "fixunsxfsi.c.o", "fixunsxfti.c.o", "fixxfdi.c.o", "fixxfti.c.o", "floattixf.c.o", "floatuntixf.c.o"];
const oracle = new Oracle({
  oursOnlyUndef: new Set(["__udivti3", "__lttf2", "__vfprintf_chk", "__stack_chk_fail"]),
  theirsOnlyUndef: new Set(["_GLOBAL_OFFSET_TABLE_", "__fprintf_chk", "__divti3", "__gttf2", "__letf2", "__floatsitf"]),
  // No oursOnlyDefined: zilc builds compiler-rt with `_Float16` off, as the release was (W-10's
  // departure is zailc's), so every member must define exactly the release's symbols.
  why: "W-8",
  sourceForm: (p) => existsSync(p.startsWith("/") ? p : `${builtins}/${p}`),
});
// Objects whose undefined symbols differ: 14 (13 members + crtbegin.o; zailc, 0.686), 13 since
// 2026-11-05, when Ubuntu GCC's hardening flags made one member's undefined set equal the release's.
const UNDEF_BUDGET = 13;
const DEPARTED_BUDGET = 0; // zilc: no departure (zailc's W-10 had 2)

const b = await run([ZIG, "build", "compiler-rt", `-Dfilc-src=${src}`, "--prefix", prefix, ...zigCacheArgs()], { cwd: REPO, inherit: true });
if (b.code !== 0) {
  console.log("FAILED: zig build compiler-rt");
  process.exit(1);
}

const compared = await oracle.archives("libyolort.a", `${prefix}/lib/libyolort.a`, `${theirLib}/libyolort.a`);
const archiveUndef = oracle.undefDiffering;
console.log(`libyolort.a: ${compared} members compared in order; ${archiveUndef} with compiler-only undefined differences`);
for (const f of ["crtbegin.o", "crtend.o"]) {
  const d = await oracle.pair(f, `${prefix}/lib/${f}`, `${theirLib}/${f}`);
  console.log(`${f}: compared${d ? " (compiler-only undefined differences)" : ""}`);
}
// The stack protector: every member the release guards is guarded in ours, and ours guards exactly
// CLANG_EXTRA_SSP besides (nm -A: "<archive>:<member>: U __stack_chk_fail").
const sspMembers = async (a: string) => new Set((await must(["nm", "-A", "-u", a])).split("\n")
  .filter((l) => / __stack_chk_fail$/.test(l)).map((l) => l.split(":")[1]));
const sspOurs = await sspMembers(`${prefix}/lib/libyolort.a`), sspTheirs = await sspMembers(`${theirLib}/libyolort.a`);
const lostSsp = [...sspTheirs].filter((m) => !sspOurs.has(m));
const extraSsp = [...sspOurs].filter((m) => !sspTheirs.has(m)).sort();
if (lostSsp.length) oracle.fail(`STACK PROTECTOR MISSING in ${lostSsp.join(", ")} (the release guards them)`);
if (extraSsp.join(" ") !== [...CLANG_EXTRA_SSP].sort().join(" ")) oracle.fail(`stack-protector extras ${extraSsp.join(", ") || "none"}, expected exactly ${CLANG_EXTRA_SSP.join(", ")}`);
console.log(`stack protector: ${sspTheirs.size} members guarded in the release, all guarded in ours; ${extraSsp.length} more in ours (clang's rule)`);
oracle.ratchet("UNDEFINED", oracle.undefDiffering, UNDEF_BUDGET);
oracle.ratchet("DEPARTED-DEFINED", oracle.departedDefined, DEPARTED_BUDGET);
console.log(`departures: ${oracle.departedDefined} symbols defined only by ours (budget ${DEPARTED_BUDGET}: zilc is faithful)`);
oracle.ratchet("EMPTY-TU", oracle.emptyTu, 0);
console.log(oracle.failures ? `FAILED: ${oracle.failures}` : "OK: libyolort.a and crtbegin.o / crtend.o define exactly upstream's symbols, in upstream's member order");
process.exit(oracle.failures ? 1 : 0);
