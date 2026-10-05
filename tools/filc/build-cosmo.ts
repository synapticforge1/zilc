// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Build Fil-C FROM SOURCE in COSMO mode (Cosmopolitan libc; upstream `cosmo.txt`), to evaluate it
// for zilc's other platforms (cmem/platforms.md Finding 1; owner 2026-10-05: "evaluate cosmo mode
// by first building Fil-C from source"). Upstream's own scripts do the work, unmodified:
// `build_base_cosmo.sh` (the normal Fil-C build with the cosmo yolo libc and the cosmo user libc in
// the two alternate slots). STOCK Fil-C: zilc's pass patches are not applied here, so the result
// is upstream's cosmo mode as shipped in v0.686. Linux; from Windows it runs inside WSL.
//
//   deno run -A tools/filc/build-cosmo.ts        env: JOBS (default 12)
//
// Tree: $WORK/filc-cosmo (a depth-1 clone of v0.686; the build writes `build/` and `pizfix/` into
// it). Log: $WORK/filc-cosmo/zilc-build.log. Tests are NOT run here (upstream's `build_all_fast_cosmo`
// runs Ruby's filc/run-tests); run tools/filc/run-filc-tests.ts against `pizfix/` afterwards.
import { exists, FILC_SHA, FILC_VERSION, env, linuxOnly, must, run, WORK } from "../lib/tool.ts";

await linuxOnly(import.meta);
const src = `${WORK}/filc-cosmo`;
const jobs = env("JOBS", "12");

// 1. Host tools. Upstream's list is Dockerfile-build-env (Ubuntu 25.04) plus cosmo.txt's aarch64
//    set. Differences on this machine's Ubuntu 26.04, chosen on 2026-10-05:
//    - libstdc++-15-dev-arm64-cross, not -13: cosmo.txt says to match the cross GCC's version,
//      and 26.04's gcc-aarch64-linux-gnu is GCC 15.
//    - libblake3-dev 1.8.2 from apt, not upstream's hand-built 1.8.7 in /usr/local: it is used by
//      Fil-C's BUILD tools only, never compiled into what Fil-C produces.
const need: [string, string][] = [
  ["clang", "clang"], ["ld.lld", "lld"], ["ninja", "ninja-build"], ["cmake", "cmake"], ["unzip", "unzip"],
  ["patchelf", "patchelf"], ["bison", "bison"], ["flex", "flex"], ["makeinfo", "texinfo"], ["autoconf", "autoconf"],
  ["libtoolize", "libtool"], ["pkg-config", "pkg-config"], ["automake", "automake"], ["msgfmt", "gettext"],
  ["aarch64-linux-gnu-gcc", "gcc-aarch64-linux-gnu"],
  ["aarch64-linux-gnu-ld", "binutils-aarch64-linux-gnu"], ["qemu-aarch64", "qemu-user"],
];
const missing: string[] = [];
for (const [cmd, pkg] of need) if ((await run(["sh", "-c", `command -v ${cmd}`])).code !== 0) missing.push(pkg);
for (const [file, pkg] of [["/usr/include/blake3.h", "libblake3-dev"], ["/usr/aarch64-linux-gnu/include/stdio.h", "libc6-dev-arm64-cross"],
  ["/usr/aarch64-linux-gnu/include/linux/types.h", "linux-libc-dev-arm64-cross"]]) {
  if (!(await exists(file)) && !(await exists(file.replace("/usr/include", "/usr/local/include")))) missing.push(pkg);
}
if ((await run(["sh", "-c", "ls -d /usr/aarch64-linux-gnu/include/c++/*"])).code !== 0) missing.push("libstdc++-15-dev-arm64-cross");
if (!(await exists("/usr/share/misc/config.guess"))) missing.push("autotools-dev");
// Not needed to BUILD; needed to RUN the Windows half of an APE here (upstream verified Windows
// under Wine only). Listed so one apt command prepares the whole evaluation.
if ((await run(["sh", "-c", "command -v wine"])).code !== 0) missing.push("wine64");
if (missing.length) {
  console.log("Missing host packages. Run this yourself in WSL (it needs your sudo password):\n");
  console.log(`  sudo apt-get update && sudo apt-get install -y ${[...new Set(missing)].join(" ")}\n`);
  Deno.exit(1);
}

// 2. Source: Fil-C at the release zilc is built on, checked by commit.
if (!(await exists(`${src}/.git`))) {
  await must(["git", "clone", "-c", "core.autocrlf=false", "--depth", "1", "--branch", `v${FILC_VERSION}`,
    "https://github.com/pizlonator/fil-c.git", src], { inherit: true });
}
const head = (await must(["git", "-C", src, "rev-parse", "HEAD"])).trim();
if (head !== FILC_SHA) throw new Error(`${src} is at ${head}, not v${FILC_VERSION} (${FILC_SHA})`);

// 3. Parallelism. ⚠️ Upstream uses every core: NCPU=`nproc` (libpas/common.sh) for make, and
//    ninja's default (cores + 2) for clang. 32 parallel RelWithDebInfo compiles of clang exhausted
//    this 31 GB WSL VM and crashed the WSL service twice (2026-10-01; build-patched-clang.ts).
//    Two upstream-supported knobs cap it without editing a script: GNU nproc honours
//    OMP_NUM_THREADS, and build_clang.sh / build_compiler_rt.sh source an optional
//    clang-build-overrides.sh for NINJAFLAGS. The job count changes build speed only.
await Deno.writeTextFile(`${src}/clang-build-overrides.sh`,
  `# Written by zilc's tools/filc/build-cosmo.ts: cap ninja's parallelism (see that file).\nNINJAFLAGS="-j ${jobs}"\n`);

// 4. Build. The first run downloads cosmo's toolchain (~1.2 GB, into projects/yolocosmo/.cosmocc).
const t0 = Date.now();
const r = await run(["sh", "-c", `./build_base_cosmo.sh > zilc-build.log 2>&1`],
  { cwd: src, env: { OMP_NUM_THREADS: jobs }, timeout: 6 * 3600 });
const mins = ((Date.now() - t0) / 60000).toFixed(1);
if (r.code !== 0) {
  console.log(`build_base_cosmo.sh FAILED (exit ${r.code}) after ${mins} min; the end of ${src}/zilc-build.log:`);
  console.log((await must(["tail", "-40", `${src}/zilc-build.log`])));
  Deno.exit(1);
}
console.log(`built in ${mins} min`);
for (const f of ["build/bin/clang", "pizfix/lib/libyolocosmo.a", "pizfix/lib-aarch64/libyolocosmo.a", "pizfix/libexec/apelink", "pizfix/libexec/pecheck"]) {
  console.log(`  ${(await exists(`${src}/${f}`)) ? "ok     " : "MISSING"} ${f}`);
}
