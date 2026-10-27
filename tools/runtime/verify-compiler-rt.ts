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

import { FILC_PREBUILT_TREE, PURE_ZIG_OUT, REPO, existsSync, linuxOnly, requireFilcSrc, run, ZIG, zigCacheArgs } from "../lib/tool.ts";
import { Oracle } from "./lib/objects.ts";

await linuxOnly(import.meta);

const src = await requireFilcSrc();
const builtins = `${src}/compiler-rt/lib/builtins`;
const theirLib = `${FILC_PREBUILT_TREE}/pizfix/lib`;
const prefix = PURE_ZIG_OUT;

// What GCC 11.4 as Ubuntu ships it and Zig's clang emit differently (W-8): Ubuntu's GCC defaults to
// -fstack-protector-strong (__stack_chk_fail) and -D_FORTIFY_SOURCE=2 (eprintf's fprintf becomes
// __fprintf_chk); GCC names the GOT symbol in PIC code; and the two compilers pick different helper
// libcalls for the same operation (signed vs unsigned 128-bit division inside the overflow checks of
// muloti4/mulvti3; which __float128 comparison and conversion helpers divtc3/multc3 use). Every
// helper named on either side is itself defined in libyolort; fprintf/__fprintf_chk are libc's.
const oracle = new Oracle({
  oursOnlyUndef: new Set(["__udivti3", "__lttf2", "fprintf"]),
  theirsOnlyUndef: new Set(["_GLOBAL_OFFSET_TABLE_", "__stack_chk_fail", "__fprintf_chk", "__divti3", "__gttf2", "__letf2", "__floatsitf"]),
  // No oursOnlyDefined: zilc builds compiler-rt with `_Float16` off, as the release was (W-10's
  // departure is zailc's), so every member must define exactly the release's symbols.
  why: "W-8",
  sourceForm: (p) => existsSync(p.startsWith("/") ? p : `${builtins}/${p}`),
});
const UNDEF_BUDGET = 14; // objects whose undefined symbols differ (13 members + crtbegin.o; zailc, 0.686)
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
oracle.ratchet("UNDEFINED", oracle.undefDiffering, UNDEF_BUDGET);
oracle.ratchet("DEPARTED-DEFINED", oracle.departedDefined, DEPARTED_BUDGET);
console.log(`departures: ${oracle.departedDefined} symbols defined only by ours (budget ${DEPARTED_BUDGET}: zilc is faithful)`);
oracle.ratchet("EMPTY-TU", oracle.emptyTu, 0);
console.log(oracle.failures ? `FAILED: ${oracle.failures}` : "OK: libyolort.a and crtbegin.o / crtend.o define exactly upstream's symbols, in upstream's member order");
process.exit(oracle.failures ? 1 : 0);
