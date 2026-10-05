// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Build Fil-C's clang from source WITH zilc's local pass fixes, for local use only
// (cmem/workarounds.md KI-22; ledger `filc-pass-fixes` in third_party/LICENSES.md). Linux; from
// Windows it runs inside WSL.
//
//   deno run -A tools/filc/build-patched-clang.ts      env: JOBS (ninja jobs, default 12)
//
// Needs: build-essential + cmake (apt, `main`), Ninja in ~/zilc-work/tools/ninja (official release
// binary), Deno. The source is Fil-C's LLVM fork at the commit the 0.685 prebuilt names in
// `clang --version`, so the only difference from the prebuilt is the patch.
//
// Configuration mirrors Fil-C's own configure_llvm.sh at that commit, except LLVM_ENABLE_LLD (lld
// is not in Ubuntu's `main`); the linker changes build speed, not the compiler's output.
//
// Result: ~/zilc-work/tools/filc-0.685-zilc/ = a copy of the prebuilt tree with build/bin/clang-20
// replaced and build/bin/llvm-split added. Point zilc at it with
// ZILC_FILC=…/filc-0.685-zilc/build/bin/clang. Then (cmem/INDEX.md policy): run Fil-C's own test
// suite against it (run-filc-tests.ts) and re-archive (archive-patched-clang.ts).
import { fixOsInclude } from "./fix-os-include.ts";
import {
  env, exists, FILC_PATCHED_TREE, FILC_PREBUILT_TREE, linuxOnly, mkdirp, must, REPO, rmrf, run, show, WORK,
} from "../lib/tool.ts";

await linuxOnly(import.meta);
const sha = "bb0d0a64eed297ab8e171002033208fb08ad9941";
const src = `${WORK}/filc-src/repo`;
const path = `${WORK}/tools/ninja:${env("PATH")}`;
const withNinja = { env: { PATH: path } };

for (const t of ["cc", "c++", "cmake", "ninja"]) {
  if ((await run(["sh", "-c", 'command -v "$0" >/dev/null', t], withNinja)).code !== 0) throw new Error(`missing: ${t}`);
}
if ((await must(["git", "-C", src, "rev-parse", "HEAD"])).trim() !== sha) throw new Error(`source is not at ${sha}`);

// The patches (fail loudly if the original text differs): the pass fixes (KI-4, KI-22 colouring
// and lever b), and zilc's splitting mode of llvm-split (KI-22 lever a). Each is applied to a fresh
// copy of the PRISTINE file at $sha, so changing an edit's replacement text just works, and the
// tree's file is replaced only if the result differs (else ninja would rebuild clang for nothing).
async function patchFile(script: string, file: string) {
  const tmp = await Deno.makeTempFile();
  await Deno.writeTextFile(tmp, await must(["git", "-C", src, "show", `${sha}:${file}`]));
  await must([Deno.execPath(), "run", "--allow-read", "--allow-write", `${REPO}/tools/filc/${script}`, tmp], { inherit: true });
  const patched = await Deno.readTextFile(tmp);
  if (patched !== await Deno.readTextFile(`${src}/${file}`).catch(() => "")) await Deno.writeTextFile(`${src}/${file}`, patched);
  await Deno.remove(tmp);
}
await patchFile("patch-pass.ts", "llvm/lib/Transforms/Instrumentation/FilPizlonator.cpp");
await patchFile("patch-split.ts", "llvm/tools/llvm-split/llvm-split.cpp");

const build = `${src}/build`;
await mkdirp(build);
if (!(await exists(`${build}/build.ninja`))) {
  await must(["cmake", "-S", "../llvm", "-B", ".", "-G", "Ninja", "-DLLVM_ENABLE_PROJECTS=clang",
    "-DCMAKE_BUILD_TYPE=RelWithDebInfo", "-DLLVM_ENABLE_ASSERTIONS=ON",
    "-DLLVM_TARGETS_TO_BUILD=X86",
    "-DLLVM_ENABLE_LIBXML2=OFF", "-DLLVM_ENABLE_LIBEDIT=OFF",
    "-DLLVM_ENABLE_LIBPFM=OFF", "-DLLVM_ENABLE_ZLIB=OFF", "-DLLVM_ENABLE_ZSTD=OFF",
    "-DLLVM_ENABLE_CURL=OFF", "-DLLVM_ENABLE_HTTPLIB=OFF",
    "-DLLVM_STATIC_LINK_CXX_STDLIB=ON", "-DCMAKE_EXE_LINKER_FLAGS=-static-libgcc"], { cwd: build, inherit: true, ...withNinja });
}
// ⚠️ Not ninja's default (one job per core): 32 parallel RelWithDebInfo compiles of clang's largest
// files exhausted the 31 GB WSL VM and crashed the WSL service twice (2026-10-01,
// Wsl/Service/E_UNEXPECTED). The job count changes build speed only, never the result.
await must(["ninja", "-j", env("JOBS", "12"), "clang", "llvm-split"], { cwd: build, inherit: true, ...withNinja });

// Install: the prebuilt tree (headers, runtime, libc) with our clang binary in place, plus
// llvm-split beside it, where zilc finds it through clang's -print-prog-name. Stripped: it is
// ~1 GB of debug info otherwise, and debug info does not change what it writes.
await rmrf(FILC_PATCHED_TREE);
await must(["cp", "-a", FILC_PREBUILT_TREE, FILC_PATCHED_TREE]);
await must(["cp", `${build}/bin/clang-20`, `${FILC_PATCHED_TREE}/build/bin/clang-20`]);
await must(["strip", "--strip-debug", "-o", `${FILC_PATCHED_TREE}/build/bin/llvm-split`, `${build}/bin/llvm-split`]);
// The copied tree's kernel-header links may be stale (fix-os-include.ts says why).
await fixOsInclude(FILC_PATCHED_TREE);
await show(["sh", "-c", '"$0" --version | head -1', `${FILC_PATCHED_TREE}/build/bin/clang`]);
console.log(`installed: ${FILC_PATCHED_TREE}/build/bin/clang`);
