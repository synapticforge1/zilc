// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Fil-C's toolchain built from source with zilc's Zig-built clang, in one of two chains (owner,
// 2026-10-30: "verify that Fil-C compiles with the zig-built clang"; then "make sure that the
// entire compilation no longer needs gcc at all", after making sure "the resulting compilations
// are functionally the same from gcc or the zig only compilation chain"):
//
//   MODE=zig (default)  NO GCC, no host clang. Every piece upstream builds with the host's
//                       compilers comes from `zig build pure-zig` (compiler-rt, yolo musl static and
//                       shared, yolounwind, libpas whole: its stock half by Zig's clang, its Fil-C
//                       half by the Zig-built Fil-C clang, libpizlo.so/.a linked by Zig's LLD) and
//                       projeny is compiled by `zig cc`/`zig c++`; upstream's own scripts run only
//                       the steps that use Fil-C's clang (user musl, libc++/libc++abi, minilute,
//                       sarcasm).
//   MODE=upstream       build_base.sh's steps after the LLVM build, unchanged: the stock pieces by
//                       the host's GCC and clang, as upstream does. The baseline the zig chain is
//                       compared with (cmem/testing.md).
//
// In both, `build/` holds nothing but the clang `zig build patched-clang` made (and its resource
// headers), and pizfix/lib is compared with the release's at the end. Then Fil-C's suite against
// the result (printed) shows whether it WORKS.
//
//   bun tools/filc/build-filc-from-source.ts    env: MODE (zig | upstream), CLANG_BUILD (default:
//                                                 patched-clang's build-zig dir), OUT (default
//                                                 ~/zilc-work/filc-from-source-<release>[-upstream])
//
// Host tools still used: make, cmake + ninja (libc++), python3 (libc++'s CMake), perl and sh
// (musl's configure), GNU ld (binutils: the linker Fil-C's clang calls), ar/ranlib, patchelf
// (fix_clang.sh), libcurl headers (projeny), the kernel headers. MODE=upstream also needs cc/c++
// (GCC), clang and ruby. Copies (not links) the sources: the scripts write into the tree, and the
// fetched package in Zig's cache must stay as fetched.

import { readdir } from "node:fs/promises";
import { env, exists, FILC_PREBUILT_TREE, FILC_VERSION, filcPackageDir, mkdirp, must, REPO, rmrf, run, WORK, ZIG, zigCacheArgs } from "../lib/tool.ts";

const mode = env("MODE", "zig");
if (mode !== "zig" && mode !== "upstream") throw new Error(`MODE must be zig or upstream, not ${mode}`);
const pkg = await filcPackageDir();
const clangBuild = env("CLANG_BUILD", `${WORK}/patched-clang/filc-${FILC_VERSION}/build-zig`);
const out = env("OUT", `${WORK}/filc-from-source-${FILC_VERSION}${mode === "upstream" ? "-upstream" : ""}`);
for (const p of [pkg, `${clangBuild}/bin/clang-20`, `${clangBuild}/lib/clang`]) {
  if (!(await exists(p))) throw new Error(`missing ${p} (run \`zig build patched-clang\` first)`);
}
console.log(`mode: ${mode}`);

// 1. The tree: upstream's top-level scripts, and the directories the steps below read.
// (`libc`: libc++'s charconv includes LLVM libc's shared/fp_bits.h; `projects/lute-1.0.0`: minilute
// builds the Luau in its extern/luau.)
const dirs = ["libpas", "filc", "yolounwind", "compiler-rt", "libcxx", "libcxxabi", "libc", "runtimes", "cmake", "third-party", "llvm",
  "projects/projeny", "projects/yolomusl", "projects/usermusl", "projects/minilute", "projects/sarcasm", "projects/lute-1.0.0"];
await rmrf(out);
await mkdirp(`${out}/projects`);
for (const e of await readdir(pkg, { withFileTypes: true })) if (!e.isDirectory()) await must(["cp", "-a", `${pkg}/${e.name}`, out]);
for (const d of dirs) await must(["cp", "-a", `${pkg}/${d}`, `${out}/${d}`]);
await rmrf(`${out}/llvm/test`); // 0.6 GB nobody here reads

// 2. build/: ONLY the Zig-built clang (the driver finds pizfix as ../../pizfix from it).
const clangVer = (await readdir(`${clangBuild}/lib/clang`))[0];
await mkdirp(`${out}/build/bin`);
await mkdirp(`${out}/build/lib/clang`);
await mkdirp(`${out}/build/include`); // an LLVM build dir has it; install-cxx-linux.sh copies into it
await must(["cp", `${clangBuild}/bin/clang-20`, `${out}/build/bin/clang-20`]);
for (const l of ["clang", "clang++"]) await must(["ln", "-s", "clang-20", `${out}/build/bin/${l}`]);
await must(["cp", "-a", `${clangBuild}/lib/clang/${clangVer}`, `${out}/build/lib/clang/${clangVer}`]);
const builtBy = (await must(["readelf", "-p", ".comment", `${out}/build/bin/clang-20`])).split("\n").map((l) => l.match(/\]\s+(.*)$/)?.[1]).find(Boolean);
console.log(`clang: ${(await must([`${out}/build/bin/clang`, "--version"])).split("\n")[0]}\n  compiled by: ${builtBy}`);

await mkdirp(`${out}/zilc-logs`);
async function step(name: string, argv: string[], extraEnv: Record<string, string> = {}) {
  const t0 = Date.now();
  const r = await run(["sh", "-c", `"$@" > zilc-logs/${name}.log 2>&1`, "sh", ...argv], { cwd: out, env: extraEnv });
  console.log(`${r.code === 0 ? "ok  " : "FAIL"} ${name} (${((Date.now() - t0) / 1000).toFixed(0)} s)`);
  if (r.code !== 0) {
    console.log((await must(["tail", "-25", `${out}/zilc-logs/${name}.log`])).trimEnd());
    process.exit(1);
  }
}

// 3. The steps, as build_base.sh orders them, minus configure_llvm.sh / build_clang.sh.
const filcSteps = ["build_usermusl.sh", "build_cxx.sh", "build_minilute.sh", "build_sarcasm.sh"];
if (mode === "upstream") {
  for (const s of ["build_projeny_yolo.sh", "build_compiler_rt.sh", "build_yolounwind.sh", "build_os_include.sh",
    "build_yolomusl.sh", "build_runtime.sh", ...filcSteps]) await step(s, [`./${s}`]);
} else {
  // projeny (a host program: Fil-C's package tool) by Zig, for the host as native target, so the
  // system's headers and libraries (libcurl) are found as GCC finds them; baseline CPU; no UBSan,
  // which `zig cc` turns on when no -O is given. Its Makefile takes CC/CXX from the environment.
  const zcc = `${ZIG} cc -mcpu=baseline -fno-sanitize=all`, zcxx = `${ZIG} c++ -mcpu=baseline -fno-sanitize=all`;
  await step("build_projeny_yolo.sh", ["./build_projeny_yolo.sh"], { CC: zcc, CXX: zcxx });
  // libpas/build.sh's directories and Makefile-setup's stdfil-include (a copy of filc/include),
  // then upstream's os-include links: Fil-C's clang reads both from its pizfix/.
  for (const d of ["include", "stdfil-include", "musl-include", "bin", "sbin", "libexec", "share", "lib", "lib_gcverify", "lib_test", "lib_test_gcverify", "man/man1"]) await mkdirp(`${out}/pizfix/${d}`);
  for (const h of await readdir(`${out}/filc/include`)) if (h.endsWith(".h")) await must(["cp", `${out}/filc/include/${h}`, `${out}/pizfix/stdfil-include/${h}`]);
  await step("build_os_include.sh", ["./build_os_include.sh"]);
  // Every stock piece and libpas whole, from zilc's build, into this tree's pizfix/.
  await step("zig-build-pure-zig", [ZIG, "build", "pure-zig", `-Dfilc-src=${out}`, `-Dfilc-clang=${out}/build/bin/clang`,
    `-Dpizfix=${out}/pizfix`, "--prefix", `${out}/pizfix`, "--build-file", `${REPO}/build.zig`, ...zigCacheArgs()]);
  await rmrf(`${out}/pizfix/lib/libpizlo-stock.a`); // zilc's verification archive, not part of Fil-C's tree
  await must(["ln", "-fs", "libyoloc.so", `${out}/pizfix/lib/ld-fil1-x86_64.so`]); // build_yolomusl.sh's link
  for (const s of filcSteps) await step(s, [`./${s}`]);
}

// 4. pizfix/lib against the release's: the same files (names), and for each the same kind.
const list = async (d: string) => (await readdir(d, { withFileTypes: true })).map((e) => `${e.name}${e.isSymbolicLink() ? " (link)" : ""}`).sort();
const ours = await list(`${out}/pizfix/lib`), theirs = await list(`${FILC_PREBUILT_TREE}/pizfix/lib`);
const onlyOurs = ours.filter((n) => !theirs.includes(n)), onlyTheirs = theirs.filter((n) => !ours.includes(n));
console.log(`pizfix/lib: ${ours.length} entries, release ${theirs.length}; only ours: ${onlyOurs.join(", ") || "none"}; only the release's: ${onlyTheirs.join(", ") || "none"}`);
const label = mode === "zig" ? "from-source-zig" : "from-source-upstream";
console.log(`\nbuilt: ${out}\nnext, Fil-C's suite against it (from ~/zilc-work/filc-tests-${FILC_VERSION}):\n  bun <zilc>/tools/filc/run-filc-tests.ts run --pizfix ${out}/pizfix --label ${label} --jobs 24\n  bun <zilc>/tools/filc/run-filc-tests.ts compare results-stock.json results-${label}.json`);
process.exit(onlyOurs.length || onlyTheirs.length ? 1 : 0);
