# Zig in zilc: the base Zig, and Zig's part in reaching pure-Zig parity

[Fil-C.md](Fil-C.md) records how zilc gets from base (Fil-C's stock release) to pure-Zig parity,
which means every piece of Fil-C built by Zig from Fil-C's sources and shown equal to the release.
zailc builds on that record. This file is Zig's side of it, in two parts:

- **the base**: which Zig, how zilc runs it on user code, and every change zilc makes so Zig code
  runs correctly under Fil-C's rules;
- **the route**: how Zig, as compiler and build system, replaces upstream's GCC, make, CMake and
  Ruby for each piece, and what each replacement needed (the last two sections before the
  licences).
Zig behaviours that may be worth reporting upstream are in `cmem/zig-upstream-notes.md` and, once
confirmed, in [UPSTREAM-ISSUES.md](UPSTREAM-ISSUES.md) (none open today). The full reasoning behind
each workaround is in `cmem/workarounds.md` (by KI number); the defect log is
`cmem/known-issues.md`.

## The Zig zilc uses

| | |
| --- | --- |
| **Zig release** | **0.15.2**, for zilc itself AND for the user code it compiles |
| **Why this one** | Zig 0.15.2 emits LLVM 20 IR (its clang is 20.1.2), the same major as Fil-C 0.687's LLVM 20.1.8, so Fil-C can read it. Zig 0.16 emits LLVM 21 IR, which Fil-C cannot read (KI-3). zilc moves Zig only when Fil-C moves LLVM |
| **Download** | `zig-x86_64-linux-0.15.2.tar.xz` from ziglang.org, SHA-256 `02aa270f183da276e5b5920b1dac44a63f1a49e55050ebde3aecc9eb82f93239` |
| **Installed at** | `~/zilc-work/tools/zig-0.15.2/zig` by `tools/p1/setup-wsl.ts` ([tools/README.md](tools/README.md) "First-time setup") |
| **How zilc finds it** | `--zig <path>` or `ZILC_ZIG`; `zilc --version` checks it and says `ok` or `MISMATCH` |
| **Platform** | Linux x86_64 (on Windows, inside WSL) |

There are **two Zigs** in principle. One builds zilc, and is limited only by zilc's own code. The
other compiles user code, and must match Fil-C's LLVM. Today both are 0.15.2. A newer Zig for
zilc itself would be a separate "latest" line (`cmem/releasing.md`, `cmem/upstream.md` stage B).
`build.zig.zon`'s `minimum_zig_version` is not a pin: a newer Zig fails to build zilc with errors
that look like code bugs.

## How zilc runs Zig

For each `.zig` input, the driver (`src/driver.zig`) runs `zig build-obj` and takes the IR:

| flag | why | record |
| --- | --- | --- |
| `--verbose-llvm-ir=<file>` (the **unoptimized** IR), not `-femit-llvm-ir` | `-femit-llvm-ir` is post-optimisation under an integral data layout, which had already turned pointer loads into integers, so capabilities were lost | KI-17 |
| `-fllvm` | Debug otherwise uses Zig's own x86_64 backend, which emits no LLVM module | KI-17 |
| `-target x86_64-linux-musl` (the default) | Fil-C's libc is musl | KI-6 |
| `-lc` | without it, std reaches the kernel through raw `syscall` asm in many more places | KI-7 |
| `-fno-stack-check` | `__zig_probe_stack` is undefined under Fil-C, and Fil-C checks the stack itself | KI-8 |
| `-fno-valgrind` | Valgrind client requests are inline asm, which Fil-C refuses | KI-14 |
| `--zig-lib-dir <overlay>` | std with zilc's patches (below) | KI-11 |
| `-O <mode>` | all four modes are supported and checked separately | KI-16 |

## The generated root: Zig's start code and std's hooks

zilc does not let Zig's `start.zig` run: it forges a pointer from an integer
(`@ptrFromInt(getauxval(AT_PHDR))`), which Fil-C forbids (KI-5). Instead it generates a C-ABI
`main` around your `pub fn main` (or, when C owns `main`, a library root). The root sets what std
reads from it:

| hook | why | record |
| --- | --- | --- |
| `std.os.argv` and `std.os.environ` from C's `argc`/`argv`/`environ` | the entry shim replaces Zig's start code, which normally sets them | KI-5 |
| `os.heap.page_allocator` = `std.heap.c_allocator` | std's page allocator passes an `mmap` address hint built from an integer, which Fil-C rejects | KI-12 |
| `std_options.crypto_always_getrandom = true` (forced; `zilc build` prints a note if your code sets otherwise) | std's other random path probes the kernel with a deliberately invalid `madvise`, which Fil-C stops | KI-20 |
| a panic handler that reports through Fil-C (`zerror`) | Zig's default handler uses `getcontext` (inline asm, which Fil-C refuses) and native stack walking; Fil-C reports the panic with its own trace | KI-7, KI-15 |

Your own `panic`, `std_options` and `os` declarations in the root file are honoured, except the
forced `crypto_always_getrandom`.

## The std overlay (`src/stdpatch.zig`)

zilc ships no Zig files. At build time it copies the installed Zig's `std/` into a cache
(`~/.cache/zilc/std-overlay/<version>-v<n>`), applies the patches for that exact Zig version, and
compiles user code against it. Each patch checks the original text it replaces, so a different
Zig fails loudly instead of being mis-patched.

| patch (Zig 0.15.2) | why | record |
| --- | --- | --- |
| `std.mem.indexOfSentinel`: Zig 0.16.0's scalar loop | 0.15.2's SIMD scan reads past the end of the object (up to a page boundary); under Fil-C that is an out-of-bounds read. Fixed upstream in 0.16.0 | KI-11, Z-1 |
| `DebugAllocator`: no pointer rebuilt from an integer | its bucket arithmetic loses capabilities | KI-13, Z-5 |
| no native stack walking, decided at compile time | stack walking reads raw frame pointers and can never carry capabilities; compiling it in also cost ~56k lines per Debug program | KI-15, KI-21 |

## Rewrites zilc applies to Zig's IR

- **Raw `syscall` inline asm becomes a call to the checked helper `zilc_syscall`** (KI-7). This
  covers even `std.debug.print`. What remains is `getcontext`, at std level.
- **The data layout lines become Fil-C's dialect** (KI-4, [Fil-C.md](Fil-C.md)).
- **3-byte globals are wrapped** (KI-18). One trigger is Zig's `std.unicode.replacement_character: u21`.
- **128-bit float helpers are compiled through the pass** when a module uses `fp128` (KI-9).

## The route: Zig in place of upstream's build tools

On the pure-Zig track (`cmem/roadmap.md` Z1, table in [Fil-C.md](Fil-C.md) § 3), the same Zig
0.15.2 builds Fil-C's runtime pieces. `build/pure_zig.zig` holds the steps (`zig build libpas |
yolomusl | compiler-rt | pure-zig -Dfilc-src=<tree>`), and `zig build gate-zig-modules` checks the
result.

| upstream used | zilc uses | what it took | record |
| --- | --- | --- | --- |
| Ruby (`generate_pizlonated_forwarders.rb`) | `zilc-gen`, a Zig program (`src/gen/`) | a port proved byte-identical, banner included | W-1 |
| `make install-headers` | `zilc-gen` | each header declared as a build input, so an edited header reruns the step | W-5 |
| make + clang 20.1.8 (libpas, crt objects, unwinder) | `addLibrary` / `addObject` from the imported `PASSRCS` | `-nostdinc` also drops Zig's bundled clang headers, so `-isystem <zig lib>/include` is added back; `-ffile-prefix-map` so `__FILE__` names upstream's relative paths | W-3, W-6 |
| musl's make + GCC 12.3 (yolo musl) | `addLibrary` / `addObject` from the imported Makefile and configure flags | clang and GCC choose different libcalls and helpers; allowed by name | W-8 |
| CMake + GCC 11.4 (compiler-rt) | CMake run **once** under `zig cc -target x86_64-linux-gnu`, its `build.ninja` read into a table, then `addLibrary` | the `_Float16` probe's variable is per architecture (`COMPILER_RT_HAS_x86_64_FLOAT16=OFF`), to stay faithful to the release | W-8, W-10 |
| GCC's driver linking `libyoloc.so` | `zig ld.lld -shared -e _dlstart` with configure's `LDFLAGS_AUTO` | `zig cc` refuses `--exclude-libs` and `--dynamic-list` ("unsupported linker arg"); and because yolo musl goes in as an archive, `--exclude-libs=ALL` becomes `--exclude-libs=libyolort.a`; LLD's `PHDR` segment allowed by name | W-11 |

Two rules hold throughout:
- **A Zig cache never goes on the exFAT checkout.** It works for one build and then fails with
  `error: Unexpected`, so the caches live in the Linux home (KI-2, W-2).
- **Zig's clang is 20.1.2, Fil-C's is 20.1.8.** Where the oracle was built by Fil-C's clang, a
  remaining difference may be the patch version (W-4). zilc does not move Zig to close it, because
  Zig is pinned by the IR it emits, not by its clang.

## Known Zig behaviours

`cmem/zig-upstream-notes.md` lists what was found and whether each is really a Zig bug:
- **Z-1:** the `indexOfSentinel` over-read, fixed in 0.16.0;
- **Z-2:** the `mmap` hint;
- **Z-3:** raw syscalls;
- **Z-4:** `getcontext`;
- **Z-5:** `DebugAllocator`'s integer arithmetic.

Under ordinary Zig most of these are fine; they matter only under a capability checker. Nothing is
filed upstream.

## Licences

Zig is MIT. zilc's binaries contain Zig's std, as every Zig program does; `src/stdpatch.zig` holds
std text and is MIT as a whole. Details: [third_party/LICENSES.md](third_party/LICENSES.md),
[NOTICE](NOTICE).
