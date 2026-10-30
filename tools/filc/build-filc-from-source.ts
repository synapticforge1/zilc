// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Does Fil-C compile with zilc's Zig-built clang? (owner, 2026-10-30: "verify that Fil-C compiles
// with the zig-built clang".) Runs UPSTREAM's own build — build_base.sh's steps after the LLVM
// build, unchanged — on the Fil-C sources `zig build` fetched, with `build/` holding nothing but
// the clang `zig build patched-clang` made (and its resource headers). So every piece upstream
// compiles with its clang (libpas's Fil-C half, the user musl, libc++/libc++abi, minilute,
// sarcasm) is compiled by the Zig-built one; the stock pieces (projeny, compiler-rt, yolounwind,
// yolo musl) by the host's cc, as upstream does. Then pizfix/lib is compared with the release's.
// Next, Fil-C's suite against the result (printed at the end) shows whether it WORKS.
//
//   bun tools/filc/build-filc-from-source.ts      env: CLANG_BUILD (default: patched-clang's
//                                                   build-zig dir), OUT (default
//                                                   ~/zilc-work/filc-from-source-<release>)
//
// Needs what upstream's build needs besides LLVM: cc/c++, make, cmake, ninja, ruby, perl,
// python3, patchelf, the kernel headers. Copies (not links) the sources: the scripts write into
// the tree, and the fetched package in Zig's cache must stay as fetched.

import { readdir } from "node:fs/promises";
import { env, exists, FILC_PREBUILT_TREE, FILC_VERSION, filcPackageDir, mkdirp, must, rmrf, run, WORK } from "../lib/tool.ts";

const pkg = await filcPackageDir();
const clangBuild = env("CLANG_BUILD", `${WORK}/patched-clang/filc-${FILC_VERSION}/build-zig`);
const out = env("OUT", `${WORK}/filc-from-source-${FILC_VERSION}`);
for (const p of [pkg, `${clangBuild}/bin/clang-20`, `${clangBuild}/lib/clang`]) {
  if (!(await exists(p))) throw new Error(`missing ${p} (run \`zig build patched-clang\` first)`);
}

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

// 3. Upstream's steps, as build_base.sh orders them, minus configure_llvm.sh / build_clang.sh.
const steps = ["build_projeny_yolo.sh", "build_compiler_rt.sh", "build_yolounwind.sh", "build_os_include.sh",
  "build_yolomusl.sh", "build_runtime.sh", "build_usermusl.sh", "build_cxx.sh", "build_minilute.sh", "build_sarcasm.sh"];
await mkdirp(`${out}/zilc-logs`);
for (const s of steps) {
  const t0 = Date.now();
  const r = await run(["sh", "-c", `./${s} > zilc-logs/${s}.log 2>&1`], { cwd: out });
  console.log(`${r.code === 0 ? "ok  " : "FAIL"} ${s} (${((Date.now() - t0) / 1000).toFixed(0)} s)`);
  if (r.code !== 0) {
    console.log((await must(["tail", "-25", `${out}/zilc-logs/${s}.log`])).trimEnd());
    process.exit(1);
  }
}

// 4. pizfix/lib against the release's: the same files (names), and for each the same kind.
const list = async (d: string) => (await readdir(d, { withFileTypes: true })).map((e) => `${e.name}${e.isSymbolicLink() ? " (link)" : ""}`).sort();
const ours = await list(`${out}/pizfix/lib`), theirs = await list(`${FILC_PREBUILT_TREE}/pizfix/lib`);
const onlyOurs = ours.filter((n) => !theirs.includes(n)), onlyTheirs = theirs.filter((n) => !ours.includes(n));
console.log(`pizfix/lib: ${ours.length} entries, release ${theirs.length}; only ours: ${onlyOurs.join(", ") || "none"}; only the release's: ${onlyTheirs.join(", ") || "none"}`);
console.log(`\nbuilt: ${out}\nnext, Fil-C's suite against it (from ~/zilc-work/filc-tests-${FILC_VERSION}):\n  bun <zilc>/tools/filc/run-filc-tests.ts run --pizfix ${out}/pizfix --label from-source --jobs 24\n  bun <zilc>/tools/filc/run-filc-tests.ts compare results-stock.json results-from-source.json`);
process.exit(onlyOurs.length || onlyTheirs.length ? 1 : 0);
