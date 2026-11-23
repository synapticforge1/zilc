# toolchain-quirks.md — C, C++, Zig, linker and build-system peculiarities, for future reference

Owner, 2026-11-04: _"we need to document the C, C++, zig ideosyncronicities for future reference for
these kinds of issues encountered."_ One entry per peculiarity: **symptom** (what you see),
**cause** (measured unless marked _surmised_), **fix**, and **where** zilc applies it. The long
forms stay where they were first written (`workarounds.md` W-n and KI-n, `best-practices.md`);
this file is the index by TOOL, so the next person who swaps a compiler or a linker looks here
first. Zig 0.15.2 (clang/LLD 20.1.2) throughout unless stated. Zig's build system, CMake, LLVM,
GCC and musl as build systems: [toolchain-quirks-build-systems.md](toolchain-quirks-build-systems.md)
(split 2026-11-23, letter H38 step 5).

## `zig cc` / `zig c++` as a drop-in C or C++ compiler

- Z-cc-1 — `fatal error: 'curl/curl.h' file not found` (any system library header)
  - Cause: With an explicit `-target`, Zig uses only its bundled libc headers: `/usr/include` is not searched
  - Fix: Leave `-target` off (the host is native), pin the CPU with `-mcpu=baseline`
  - Where: projeny in `build-filc-from-source.ts` (W-13)
- Z-cc-2 — `-march=native`-tuned output on a build meant to be portable
  - Cause: Without `-target`/`-mcpu`, `zig cc` compiles for the host CPU
  - Fix: `-mcpu=baseline` (or `-target x86_64-linux-gnu -mcpu=baseline`)
  - Where: `tools/zig-shim.zig`, `gcc-host-shim.zig`
- Z-cc-3 — Link fails: `undefined reference to __ubsan_handle_*`
  - Cause: `zig cc` enables UBSan when no `-O` is given (Zig's Debug default)
  - Fix: `-fno-sanitize=all`, or set `-O`; in build.zig `.sanitize_c = .off`
  - Where: compiler-rt's `crtbegin.o` (no `-O` in its CMake rule); `build/pure_zig.zig` everywhere (W-13)
- Z-cc-4 — `unknown CPU: 'x86'`
  - Cause: `-march=x86-64-v2` is parsed with Zig's `-mcpu` syntax: CPU `x86` with features `64`, `v2` REMOVED
  - Fix: Spell it `-mcpu=x86_64_v2` (in build.zig: `.cpu_model = .{ .explicit = &…x86_64_v2 }`)
  - Where: libpas's stock half (W-13)
- Z-cc-5 — `unknown type name 'bool'` compiling a C++ project's `*.c` files with `$(CXX)`
  - Cause: `g++`/`clang++` treat a `.c` input as C++; `zig c++` picks the language from the extension
  - Fix: Wrap each `.c` input: `-x c++ file.c -x none` (`-x` holds for following inputs; `-x none` restores detection)
  - Where: GCC 11's `libcpp` (`tools/gcc-host-shim.zig`)
- Z-cc-6 — `error: unsupported linker arg: --dependency-file=…`
  - Cause: CMake ≥ 3.27/4.x asks the linker for a depfile (`-Wl,--dependency-file`); `zig cc` rejects unknown linker args
  - Fix: `-DCMAKE_LINK_DEPENDS_USE_LINKER=OFF`, or drop the arg in a wrapper
  - Where: `tools/patched-clang.zig` (zig mode); the alias probe (W-13)
- Z-cc-7 — `unsupported linker arg: --exclude-libs` / `--dynamic-list` / `-retain-symbols-file`
  - Cause: Same: `zig cc` accepts only the linker args it knows (libtool's `-export-symbols` becomes `-retain-symbols-file`)
  - Fix: Call `zig ld.lld` directly with the full link rule; or leave out what needs it (`--disable-libcc1`, GDB's plugin, in GCC)
  - Where: `libyoloc.so` (W-11); `tools/gcc-reference.zig`
- Z-cc-8 — A configure-based build "works" but the library binds differently
  - Cause: A build system that tests flags (musl's `tryldflag`) silently DROPS the ones `zig cc` refuses
  - Fix: Diff the configure RESULT (`config.mak`), not just the exit code; don't route such builds through `zig cc`
  - Where: The alias probe: `libyoloc.so` 503 vs 21 self-binding relocations (W-13)
- Z-cc-9 — `-nostdinc` builds miss `stddef.h`, `stdarg.h`
  - Cause: `-nostdinc` drops Zig's bundled clang resource headers too
  - Fix: Add `-isystem <zig lib>/include` (what upstream gets from `find_clang_include_dir.rb`)
  - Where: libpas (W-3)
- Z-cc-10 — `__FILE__` (assert and panic messages) differs from upstream's
  - Cause: Zig passes ABSOLUTE source paths; upstream's make passes relative ones
  - Fix: `-ffile-prefix-map=<dir>/=` (or `=../`) to reproduce upstream's spelling
  - Where: libpas, crt objects, yolounwind (W-6)
- Z-cc-11 — glibc headers behave as one version whatever `x86_64-linux-gnu.2.NN` says
  - Cause: Zig ships ONE set of glibc headers; the version only selects the symbols linked against
  - Fix: Do not expect a header-level fix from the target's glibc version
  - Where: The MPFR case below (2026-11-04)
- Z-cc-12 — `zig objcopy --strip-debug` → `error: unimplemented`
  - Cause: Zig 0.15.2's objcopy does not implement it for (at least) a large LLVM ELF
  - Fix: Build and use `llvm-objcopy` in the same ninja run (binutils' `strip` works too)
  - Where: `tools/patched-clang.zig`
- Z-cc-13 — CMake's `CMAKE_C_COMPILER` cannot take `zig cc` (two words)
  - Cause: CMake wants one executable per tool
  - Fix: A tiny executable per subcommand (`zig-cc`, `zig-c++`, `zig-ar`, `zig-ranlib`)
  - Where: `tools/zig-shim.zig`, `tools/gcc-host-shim.zig`
- Z-cc-14 — Inside **libc++**'s `<__locale>`: `too many arguments provided to function-like macro invocation`, `'__abi_tag__' attribute only applies to …`
  - Cause: `zig c++` always uses libc++ (Zig ships no libstdc++). A project that defines
    function-like macros named like `isalpha`/`isspace` BEFORE including C++ headers (GCC's
    `safe-ctype.h` poisons them) breaks when a libc++ header reaches `<locale>`: libc++'s `<map>`
    does (via `<functional>`, `<vector>`), libstdc++'s does not
  - Fix: Include the C++ standard headers before such macros. GCC FIXED this upstream: PR
    middle-end/111632 (master `9970b576`, Dimitry Andric; backported to releases/gcc-12 `a995fded`
    and gcc-11 `5a419c22`, first in 12.4.0 / 11.5.0); zilc applies those backports verbatim to
    11.4.0 / 12.3.0 (`third_party/gcc-patches/`)
  - Where: GCC 11.4 / 12.3 in `tools/gcc-reference.zig`
- Z-cc-16 — With `-target x86_64-linux-gnu` and upstream's OWN libc headers (`-nostdinc -isystem
  yolo-include`, musl): `call to undeclared library function 'strlcpy'` (libpas
  `filc_setproctitle.c`); a plain clang compiles it
  - Cause: For a glibc target Zig predefines `__GLIBC_MINOR__`, which leads musl's `features.h` path
    to define `_POSIX_C_SOURCE`/`_XOPEN_SOURCE`/`_DEFAULT_SOURCE`, so `strlcpy` (BSD) is hidden; the
    same target also predefines `__SSP_STRONG__` (stack protector on by default), which a plain
    clang does not
  - Fix: `-target x86_64-linux-none` when the code brings its own libc headers (as `build/pure_zig.zig` runtimeModule `.abi = .none`); then the predefined macros equal Ubuntu clang's but for Z-cc-17
  - Where: `tools/host-clang-shim.zig` (2026-11-05)
- Z-cc-17 — `zig cc -O3` predefines `NDEBUG`; a plain clang never does
  - Cause: `zig cc` maps `-O2`/`-O3` to a release mode, whose C defines include `NDEBUG`
  - Fix: Matters only to code using `assert.h`/`NDEBUG`: libpas, yolounwind and `filc/main` use
    neither (grep, 2026-11-05), so no workaround; add `-UNDEBUG` where it matters. **The Zig-built
    patched clang keeps LLVM's and the pass's assertions** (review round 1, C8, measured
    2026-11-15): `clang --version` says `Build config: +assertions`, and the KI-18 repro
    `tools/p2/repro/filc-0.685-i21-global.ll` fails `Assertion '!(CSize % WordSize)'` (exit 1) in
    the stock 0.687 clang, the GCC-built and the Zig-built `filc-0.687-zilc` alike
  - Where: `tools/host-clang-shim.zig`
- Z-cc-15 — `zig: error: unsupported option '-print-multi-os-directory'`
  - Cause: GCC-driver-only queries (`-print-multi-os-directory`, `-print-multi-lib` …) are not in `zig cc`
  - Fix: Harmless where only an install subdirectory is computed from it (GCC's host libiberty); answer it in a wrapper if a build depends on it
  - Where: GCC 11.4 host build (seen, not fatal)

## Clang (Zig's 20.1.2) versus GCC, as the compiler of the same C

- C-1 — Undefined-symbol differences between clang- and GCC-built objects: `_GLOBAL_OFFSET_TABLE_`
  (GCC), `memcpy`/`memset` calls (clang) where GCC inlines, `__stack_chk_fail` / `__fprintf_chk`
  (Ubuntu GCC's default hardening), helper libcalls (`__divti3` vs `__udivti3`, `__gttf2` …)
  - Cause / note: Compiler choices; defined symbols stay equal
  - Where recorded: W-8
- C-2 — GCC gives an empty translation unit a compile unit; clang does not
  - Cause / note: —
  - Where recorded: W-8 (`src/linux/cache.c`)
- C-3 — compiler-rt built by GCC 15 has 5 more half-float/bfloat16 builtins than the release's (GCC 11.4)
  - Cause / note: CMake probes compiler support for `_Float16` / bf16 and enables members accordingly
  - Where recorded: `testing.md` (GCC chain's `libyolort.a`); W-10 is the same probe family. Gone since the GCC chain uses the pinned GCC 11.4.0 (2026-11-05: 188 = 188 definitions)
- C-4 — Clang lacks `_Float128` on x86 (C), but has `__float128`; MPFR 4.1.0 then `#define _Float128
  __float128`, and glibc's `bits/floatn.h` (`typedef __float128 _Float128;`) becomes a self-typedef:
  `cannot combine with previous '__float128' declaration specifier`, surfacing as MPFR's
  `GMP_NUMB_BITS and sizeof(mp_limb_t) are not consistent`
  - Cause / note: MPFR's float128 fallback + glibc's header assuming GCC
  - Where recorded: `--disable-float128` (reaches the in-tree MPFR through GCC's configure); `tools/gcc-reference.zig`
- C-5 — GCC's objects carry `.note.gnu.property` (x86 ISA notes); clang's do not, so GNU ld makes a `GNU_PROPERTY` segment only for the former
  - Cause / note: —
  - Where recorded: W-11 part 3
- C-6 — `crtbegin.o` built by Zig's clang at `-O0` and by GCC 11.4 have IDENTICAL relocations (`PLT32` + `REX_GOTPCRELX` per weak function)
  - Cause / note: A difference seen later in a `.so` was the LINKER's, not this (L-3)
  - Where recorded: W-14
- C-7 — The release's GCC-built pieces start indirect-branch targets with `endbr64` (crt1.o 1, crtbegin.o 2, libyoloc.so 1,695, libyolort.a 170); Zig's clang builds: 0
  - Cause / note: **Ubuntu's GCC defaults to `-fcf-protection`** (Intel CET), plus
    `-fstack-clash-protection` and `-D_FORTIFY_SOURCE=2` at `-O` — distribution patches, so a
    VANILLA GCC does not apply them either. No-ops unless CET is enforced, and the release's
    `libyoloc.so` is not CET-marked anyway (its property note lacks IBT/SHSTK)
  - Where recorded: ✅ FIXED 2026-11-04: `build/pure_zig.zig` passes `-fcf-protection` to yolo musl,
    compiler-rt and their crt objects (`ubuntu_gcc_cet`); `endbr64` now equals the release's per
    archive member (libyoloc.a 1,715, libyolort.a 170, crt objects) and the IBT/SHSTK notes are
    there. A pinned VANILLA GCC still needs Ubuntu's defaults passed explicitly
  - `testing.md` "Parity inventory"
- C-7b — The release's compiler-rt calls `__stack_chk_fail` (9 calls, 18 `%fs:0x28` guard loads in 8
  members) and `__fprintf_chk`; its yolo musl has 15 stack-clash probes (`orq $0x0,(%rsp)`); the zig
  chain has none
  - Cause / note: The REST of Ubuntu GCC's defaults: `-fstack-protector-strong`,
    `-D_FORTIFY_SOURCE=2` (only when optimizing), `-fstack-clash-protection` — first misfiled under
    W-8 as "compiler differences" (2026-11-04), corrected 2026-11-05 by counting them
  - Where recorded: ✅ FIXED 2026-11-05, as far as two compilers allow: the flags in
    `build/pure_zig.zig` (compiler-rt builtins all three; crtbegin/crtend SSP + clash, no fortify at
    `-O0`; yolo musl clash). Fortify: 1 = 1. Stack-clash page probes: 15 = 15 (in `libyoloc.a` /
    `.so`; which function holds them differs by inlining, C-8). Stack protector: every member the
    release guards is guarded, plus 8 more — clang's `-fstack-protector-strong` rule guards x87
    long-double conversions and `eprintf` that GCC's does not (C-10)
  - `testing.md` "Parity inventory"
- C-10 — `-fstack-protector-strong` guards different function SETS under clang and GCC (compiler-rt: GCC 11.4 8 members, clang 16 — a superset)
  - Cause / note: Each compiler's own heuristic for "strong"
  - Where recorded: Not equal-able with clang; ours is stronger, never weaker: `verify-compiler-rt.ts` checks both directions with the 8 extras named
  - 2026-11-05
- C-11 — glibc's `fprintf` under `_FORTIFY_SOURCE=2` is `__vfprintf_chk` with clang, `__fprintf_chk` with GCC
  - Cause / note: glibc's headers fortify variadic calls differently for clang (no `__builtin_va_arg_pack`)
  - Where recorded: The same check through another glibc entry; allowed by name in `verify-compiler-rt.ts`
  - 2026-11-05
- C-12 — Counting stack-clash probes: GCC writes `orq $0x0,(%rsp)`, clang `movq $0x0,(%rsp)`, each right after `sub $0x1000,%rsp`; `movq $0x0,(%rsp)` alone is ordinary code too
  - Cause / note: Different probe instructions
  - Where recorded: Count only a probe that follows a one-page `sub`
  - 2026-11-05
- C-13 — One build, two spellings: make's `./src/aio/aio.c` (srcdir = .) reaches `__FILE__` and
  DWARF as `src/aio/aio.c`, while a header found through `-I./src/internal` stays
  `./src/internal/atomic.h`
  - Cause / note: Clang drops a leading `./` from the file it is given, not from an include directory's
  - Where recorded: To reproduce from absolute paths: `-ffile-prefix-map=<tree>/=` and the `-I`
    directories written `<tree>/./…` (not path-joined, which folds `/./`); a plain map to `./` gets
    the main file wrong, a plain map to nothing the headers (`build/pure_zig.zig` `buildUserMusl`,
    2026-11-06; caught by `verify-usermusl.ts` comparing with the release). **yolomusl, checked
    2026-11-06:** it has NO `__FILE__` string on either side (0 of 1,343 members), so the difference
    lived only in DWARF line tables (`src/internal` vs the release's `./src/internal`); fixed the
    same way in `buildYoloMusl`, now equal. Left, debug info only: the two GENERATED include dirs
    sit in Zig's cache (`…/o/<hash>/obj-include/bits` vs the release's `obj/include/bits`)
  - 2026-11-06
- C-8 — `libyoloc.so`: 1,694 `endbr64` vs the release's 1,695 although every archive member matches
  - Cause / note: Zig's clang INLINES the hidden `__ftello_unlocked` into `ftello` (141 bytes vs 70 + 92); `--gc-sections` then drops the unused out-of-line copy and its `endbr64`
  - Where recorded: An inlining difference (W-8 family), not CET; same behaviour
  - 2026-11-04
- C-9 — The release's GCC-built objects carry an "x86 ISA used / feature used" property note (and, after linking, `libyoloc.so` a `GNU_PROPERTY` segment from it); Zig's never do
  - Cause / note: Written by GNU `as` (Ubuntu's binutils default `-mx86-used-note=yes`), not by the compiler; clang's integrated assembler has no equivalent
  - Where recorded: Not fixable with Zig's toolchain (it would mean assembling with GNU as); allowed by name in `verify-yolomusl.ts` (W-11 part 3)
  - 2026-11-04

## Fil-C's own clang (and the release's install step)

- F-1 — The same compile command run twice gives objects differing by 6–8 bytes (code and section
  names identical); 79 of `libc.a`'s 1,332 members, 22 of `libc++.a`'s 54, 5 of `libc++abi.a`'s 18
  differ between two builds
  - Cause: Fil-C's clang is not run-to-run reproducible (already the reason zilc's object cache keys on its own hash, KI-22 lever c)
  - Note: Not a chain difference: compare such pieces by symbols and behaviour, never by bytes (2026-11-04)
- F-2 — `clang -shared … -nodefaultlibs` (user musl's `libc.so` rule) still links Fil-C's runtime
  - Cause: Fil-C's driver adds, whatever `-nodefaultlibs` says: `crti.o crtbegin.o -L<pizfix>/lib
    -rpath <pizfix>/lib` before the inputs and `-lpizlo -lyolort -lyoloc -lyolom -lyolort
    -lyolounwind crtend.o crtn.o` after (`clang -###`, 0.687)
  - Note: Reproduce the driver's whole line when linking without it (`build/pure_zig.zig`
    `buildUserMusl`, 2026-11-06). For C++ (`clang++ -shared`) it adds `-lc -lm` as well, so libc++'s
    links bind the USER libc; `import-libcxx-sources.ts` records the driver's line (`-###`) rather
    than rebuilding it
- F-3 — Scanning a Fil-C object's `.rodata` for `__FILE__` strings finds FRAGMENTS (`rocess/fork.c`, `fil-include/stdfil.h`), and which ones depends on the machine
  - Cause: Fil-C lays a constant string out in pieces at offsets set by what precedes it; a member
    that embeds the compiler tree's ABSOLUTE `stdfil.h` path (its inline checks' `__FILE__`) shifts
    the rest by that path's length
  - Note: Compare the found strings as sets with upstream's (after mapping the compiler-tree
    prefix), and count instead of compare the members that embed `stdfil.h` (11 of user musl's
    1,333: `verify-usermusl.ts`, ratcheted; `objects.ts` `sourceUncomparable`)
- F-4 — zilc's PATCHED Fil-C clang gives user musl's `putc_unlocked` and `putchar` one more undefined symbol, `filc_object_ensure_aux_ptr_outline`, than the release's stock clang
  - Cause: A difference of the patched compiler, not of the build: upstream's own `make` with the
    same patched clang shows it too (2026-11-06); which of the pass patches (`workarounds.md` KI-4,
    KI-22) is not yet pinned down
  - Note: Allowed by name in `verify-usermusl.ts`, exactly 2 members (ratcheted); re-check when the patches move

## Linkers: LLD (Zig's) versus GNU ld (binutils)

- L-1 — `--exclude-libs=ALL` hid all of libc (8 exports instead of 1,653)
  - Cause: It hides every ARCHIVE's symbols; upstream links loose `.lo` objects, zilc an archive
  - Fix / note: Name the one archive upstream's flag reaches: `--exclude-libs=libyolort.a`
  - Where: W-11
- L-2 — `PHDR` segment in an LLD shared object, none from GNU ld
  - Cause: Linker layout choice
  - Fix / note: Allowed by name
  - Where: W-11
- L-3 — 5 more `JUMP_SLOT`s from LLD than GNU ld on identical objects
  - Cause: GNU ld gives a function referenced through BOTH the PLT and the GOT one `.plt.got` stub over its GOT slot (`GLOB_DAT` only); LLD has no `.plt.got`
  - Fix / note: Functionally the same; for parity link with GNU ld (scope in `open-work.md`)
  - Where: W-14
- L-4 — `-dynamic-linker` on a SHARED object gives an `INTERP` segment with LLD; GNU ld omits it
  - Cause: —
  - Fix / note: Leave `-dynamic-linker` off for shared objects
  - Where: W-12
- L-5 — What a release's driver added implicitly must be spelled out to LLD
  - Cause: `gcc`/`clang` drivers add `--build-id`, `--eh-frame-hdr`, `-z relro`, `--hash-style=gnu`
  - Fix / note: Read the release's binary (`readelf -n/-S/-l`) and pass the same
  - Where: W-11, W-12
- L-6 — Fil-C's clang links every program with `/usr/bin/ld` (GNU ld); its driver prints `Selected GCC installation` but takes nothing from it
  - Cause: Driver probing vs use
  - Fix / note: Judge a dependency by `-###`, not by `-v`
  - Where: `testing.md` "THE ZIG-ONLY CHAIN"
- L-7 — GNU ld lists `__environ` as an undefined dynamic symbol in `libpizlo.so` with no relocation using it; LLD does not
  - Cause: GNU ld behaviour, whichever chain's objects (measured both ways)
  - Fix / note: Harmless; disappears or appears with the linker (W-14 family)
  - Where: `testing.md` "Parity inventory"
- L-8 — `.relro_padding` section (LLD) vs `.plt.got` (GNU ld)
  - Cause: Linker layout
  - Fix / note: W-14 family
  - Where: same
- L-9 — The release's `libc.so`, `libc++.so.1.0`, `libc++abi.so.1.0` have one more `LOAD` segment than either chain's
  - Cause: Linker VERSION: the release's binutils (Ubuntu 22.04, 2.38) vs this machine's (2.45); Fil-C's clang links them with the host's `ld` in both chains
  - Fix / note: Not a Zig matter; follows the host binutils
  - Where: same

## git, archives, line endings

- G-1 — A GitHub archive's file differs from the commit's blob
  - Cause: `git archive` writes text files as a checkout does: upstream's `eol=crlf` files arrive CRLF
  - Fix: Compare against the checkout form, attributes read with `check-attr`
  - Where: `verify-filc-package.ts`
- G-2 — `git check-attr --source` silently ignores some `.gitattributes`
  - Cause: In a partial, sparse clone, unfetched attribute blobs count as absent
  - Fix: Fetch every attributes blob first; refuse if one is missing
  - Where: `verify-filc-package.ts`
- G-3 — `git fetch origin <blob id>` fails its connectivity check
  - Cause: Blobs are not fetchable that way
  - Fix: Let lazy fetch do it: `git -c url.https://github.com/.insteadOf=git@github.com: cat-file -t <id>`
  - Where: `verify-filc-package.ts`
- G-4 — `git diff`'s `index` lines changed length with no content change
  - Cause: Short blob ids grow with the object count
  - Fix: `git diff --full-index` for anything compared byte for byte
  - Where: `check-toolchain.ts`
- G-5 — `git hash-object` in zilc's repo gave a "wrong" blob id for foreign bytes
  - Cause: It applies the repo's `* text=auto eol=lf` to its input
  - Fix: Compute SHA-1 of `blob <len>\0` + bytes yourself
  - Where: `best-practices.md`

## Zig 0.15.2 API notes (this project targets 0.15.2)

- `pub fn main() !void`; args via `std.process.argsAlloc(arena)`.
- stdout (post-"Writergate" I/O): `var w = std.fs.File.stdout().writer(&buf); const out = &w.interface;`
  and **flush before returning**.
- `build.zig`: `addExecutable`/`addLibrary(.{ .linkage = … })`/`addTest` all take `.root_module`.
  That is the same shape as 0.16, so `build.zig` needed no change in the port.
- `build.zig.zon` requires a `.fingerprint`. Zig prints a suggested value if it is missing.
- ⚠️ **Don't copy code from wazmrt without checking.** wazmrt is on **0.16** (`std.process.Init`,
  `std.Io`), and its `main`/I/O code does not compile here.
- ⚠️ `minimum_zig_version` only rejects _older_ Zigs. **Zig 0.16 is not rejected up front; it fails
  with a compile error in `main.zig`.** Those errors mean the wrong Zig, not a code bug.
