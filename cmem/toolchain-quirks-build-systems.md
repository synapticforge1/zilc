# toolchain-quirks-build-systems.md — Zig's build system, CMake, LLVM, GCC and musl as build systems (split from toolchain-quirks.md 2026-11-23)

## Zig's build system and package manager

- Z-b-1 — A lazy dependency downloads for every `zig build` command
  - Cause: `b.lazyDependency()` marks it needed whenever `build()` calls it; `build()` cannot see which steps were named
  - Fix: Read the build runner's argv (bare args are step names, stop at `--`) and request only then
  - Where: `build/filc_source.zig` `named()`
- Z-b-2 — A run step does not rerun when an input DIRECTORY's files change
  - Cause: Run steps are cached by their arguments; a path argument is only a string
  - Fix: Declare every file read as a file input
  - Where: `musl-headers` (W-5)
- Z-b-3 — Executable bits in a fetched package differ from the archive's
  - Cause: Zig's fetcher IGNORES archive modes and marks a file executable iff it starts with `#!`, ELF or Mach-O (ziglang/zig#17463); its hash records no executable bit
  - Fix: Check packages against that rule
  - Where: `verify-filc-package.ts`; `best-practices.md` § 5
- Z-b-4 — Zig cannot fetch `.tar.bz2`
  - Cause: No bzip2 decompressor in Zig 0.15.2
  - Fix: Use the `.tar.xz` / `.tar.gz` of the same release
  - Where: GCC prerequisites in `build.zig.zon`
- Z-b-5 — A fetched tree's files have arbitrary mtimes, so make tries to rerun autoconf/automake/makeinfo
  - Cause: Files are written in archive order
  - Fix: Stage a copy and give every file one timestamp
  - Where: `tools/gcc-reference.zig`
- Z-b-6 — A cached shim's path changes whenever its source file changes, which reconfigures (and fully rebuilds) any CMake build that recorded it
  - Cause: Zig caches by content
  - Fix: Keep shims that other builds record in files that do not change; add new behaviour in a separate shim
  - Where: `tools/gcc-host-shim.zig` vs `tools/zig-shim.zig`
- Z-b-7 — `.zig-cache` on exFAT fails on the second build
  - Cause: exFAT (no atomic rename)
  - Fix: `ZIG_LOCAL_CACHE_DIR` in the Linux home
  - Where: KI-2
- Z-b-8 — A static library from `b.addLibrary(.static)` names its members by the objects' FULL cache
  paths (`/home/<user>/.cache/…/o/<hash>/aio.o`); upstream's `ar` uses its own names (`aio.lo`,
  `absvdi2.c.o`, `pas-pizlo-release-x.o`)
  - Cause: Zig's archiver stores the object path it was given
  - Fix: No link effect, but not reproducible across machines and it bakes a home path into the
    archive. ✅ FIXED 2026-11-04: `tools/archive-rename.zig` rewrites each archive with upstream's
    names AND order (`zig ar q`, so repeated names survive; `zig ranlib`); all four now list exactly
    as the release's
  - Where: `testing.md` "Parity inventory" (libyoloc.a 1,343, libpizlo.a 183, libyolort.a 167, libyolounwind.a 1)
- Z-b-9 — After an edit made from Windows to a file on the exFAT drive, `zig build` in WSL
  installed a `zilc` built from the OLD source: the new behaviour was missing, while `grep` in WSL
  showed the new text (2026-11-23, review 1 re-review 3, `src/driver.zig`)
  - Cause: _surmised_ — Zig's cache manifest trusted the file's stat (drvfs / 9p on exFAT) and
    reused the earlier compile; a brand-new `ZIG_LOCAL_CACHE_DIR` built the new code at once
  - Fix: before a result is believed after editing from Windows, build with a fresh local cache
    (or empty `~/.cache/zilc-zig`, zilc's own) and check the new behaviour is there; the review's
    final runs were made on an emptied cache (`zig build test` 56/56, gate 10/10)
  - Where: every local build of the repo from WSL (`run-gate.ts`, `zig build test`)

## CMake, LLVM, GCC, musl as build systems

- B-1 — `clang --version` of a clang built from a tarball lacks the repository and commit
  - Cause: LLVM reads them from `.git`
  - Fix: `-DLLVM_FORCE_VC_REPOSITORY=… -DLLVM_FORCE_VC_REVISION=…`
  - Where: `tools/patched-clang.zig`
- B-2 — LLVM's configure needs Python 3
  - Cause: `find_package(Python3)` in LLVM's CMake
  - Fix: Listed as a build tool
  - Where: README
- B-3 — A changed configure option did not reach an existing build dir
  - Cause: Configure ran only when `build.ninja` was missing
  - Fix: Stamp the whole configure command (and the compilers passed by environment) and reconfigure on change
  - Where: `tools/patched-clang.zig`, `tools/gcc-reference.zig`
- B-4 — GCC's top-level `configure` options reach the in-tree GMP/MPFR/MPC
  - Cause: GCC passes its arguments down
  - Fix: Use it to configure a prerequisite (`--disable-float128`)
  - Where: `tools/gcc-reference.zig`
- B-5 — libc++'s build reads LLVM `libc/` (`shared/fp_bits.h`); minilute builds the Luau in `projects/lute-1.0.0`; `install-cxx-linux.sh` expects `build/include`
  - Cause: Fil-C's tree dependencies
  - Fix: Copy them; create `build/include`
  - Where: `build-filc-from-source.ts`
- B-6 — GCC 11's libsanitizer: `invalid application of 'sizeof' to incomplete type '__sanitizer::termio'`
  - Cause: An OLD GCC's target libraries are compiled against the HOST's glibc headers; glibc 2.42 removed `struct termio`
  - Fix: `--disable-libsanitizer` (nothing here uses `-fsanitize`)
  - Where: `tools/gcc-reference.zig`
- B-11 — libc++'s CMake configured from zilc's `FILC_SRC` gives a different build: the link gets
  `-lllvm-libc-common-utilities`, the compiles lose `LIBC_NAMESPACE` (0 vs upstream's 108), and a
  compile then misses `shared/fp_bits.h`
  - Cause: `FILC_SRC` is a SPARSE checkout without `libc/`;
    `runtimes/cmake/Modules/FindLibcCommonUtils.cmake` makes the `llvm-libc-common-utilities` target
    only when `../../../libc` exists (and libc++'s charconv includes `libc/shared/…`)
  - Fix: A tool that runs upstream's build system, or builds libc++, uses the FETCHED package
    (`filcPackageDir()`), the tree `zig build` compiles: `import-libcxx-sources.ts`,
    `verify-libcxx.ts` (2026-11-06)
  - Where: `tools/runtime/`
- B-10 — libpas's `HOST_CLANG_EXTRA_FLAGS = -isystem \`./find_clang_include_dir.rb\``finds nothing under`zig cc`
  - Cause: The Ruby helper keeps only the `clang -###` line containing `bin/clang`; Zig's command line never has it (its include dir, `<zig>/lib/include`, is there)
  - Fix: Set the variable through `MAKEFLAGS` (a variable there counts as set on make's command line, overriding the Makefile's `=`), to `-isystem<zig>/lib/include`
  - Where: `build-filc-from-source.ts` MODE=upstream (2026-11-05)
- B-7 — With a `specs` file holding only `+` additions in GCC's library directory, `g++` links fail:
  `undefined reference to symbol '_Unwind_Resume@@GCC_3.0'`, `libgcc_s.so.1: DSO missing from
  command line`
  - Cause: The driver reads that file INSTEAD of calling `init_spec()` (gcc.c: `if (specs_file)
    read_specs(...) else init_spec()`), and `init_spec()` is what turns `*libgcc` into the
    shared-libgcc form and prepends `--eh-frame-hdr` / `--build-id` to `*link`; the link got the
    static `-lgcc` alone
  - Fix: The file carries `*libgcc` and `*link` as `-dumpspecs` prints them, then the additions; proven by B-9's check
  - Where: `tools/gcc-reference.zig` (2026-11-05)
- B-8 — `gcc -dumpspecs > specs` is not a usable specs file: "specs file malformed after N characters"
  - Cause: The reader takes the next line after `*name:` as its value even when it is blank, so an
    empty spec (`*self_spec:`) swallows the next name and parsing loses its place; `*link_command`'s
    value also spans two lines
  - Fix: Write only the entries needed (B-7)
  - Where: `tools/gcc-reference.zig` (2026-11-05)
- B-9 — `-dumpspecs` looks the same with and without a specs file that drops `init_spec()`'s work
  - Cause: `-dumpspecs` calls `init_spec()` itself before printing, so it cannot show what a real compile uses
  - Fix: Compare the driver's real commands (`-###`, temp names normalized) with and without the
    file: only the cc1 line may differ, only by the added flags (5 variants: exe, `-shared`,
    `-static`, C and C++)
  - Where: `tools/gcc-reference.zig` (2026-11-05)
