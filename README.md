# zilc

**A Fil-C-style memory-safe compilation target for the Zig toolchain**, covering Zig, C and C++ with
one compiler binary.

> **Status: working prototype (v0.15.2-3: zilc release 3, for Zig 0.15.2), Linux x86_64 only.** `zilc build` compiles Zig and C into
> one binary where out-of-bounds access and use-after-free trap at a named source line — using
> Fil-C's existing pass and runtime, with no Zig fork and no LLVM build. See [Limits](#limits).

## What it is

[Fil-C](https://github.com/pizlonator/fil-c) makes C and C++ memory-safe at runtime. It gives every
pointer an invisible *capability* (InvisiCap) holding its allocation bounds, and replaces `free()`
with an accurate, non-moving garbage collector (FUGC). Out-of-bounds accesses and use-after-free
become deterministic panics instead of memory corruption.

zilc brings that model to Zig. Today it does so by **rewriting Zig's LLVM IR into Fil-C's dialect**
and handing it to Fil-C's compiler — no Zig fork, no LLVM build. Two lines of `target datalayout` are
the whole difference.

The cost is runtime speed, which is the same trade Fil-C makes (roughly 1.5×–4× slower, depending on
the workload).

## It works: C allocates, Zig overflows, Fil-C traps

```sh
zilc build examples/interop/c_caller.c examples/interop/bounds.zig -o interop
./interop
```

```
in bounds ok, sum=6
filc safety error: cannot write pointer with ptr >= upper.
    expected 4 writable bytes.
semantic origin:
    (interop) bounds.zig:13:6: zig_add        <-- the fault is named in the ZIG source
check scheduled at:
    (interop) bounds.zig:13:6: zig_add
    (interop) c_caller.c:26:5: main
[502] filc panic: thwarted a futile attempt to violate memory safety.
```

The memory was allocated in C and overflowed in Zig, and the capability survived the call. Exit
code 133, no corruption.

## Or a whole Zig program, with no C at all

```sh
zilc build examples/whole_program/hello.zig -o hello
./hello
```

```
hello from a whole Zig program
filc safety error: cannot read pointer with ptr >= upper.
semantic origin:
    (hello) hello.zig:25:6: hello.main
```

### Using it

```sh
export ZILC_ZIG=/path/to/zig-0.15.2/zig          # stock Zig
export ZILC_FILC=/path/to/filc/build/bin/clang   # Fil-C's clang (see below)
zilc build [-O ReleaseSafe] [--target x86_64-linux-musl] [--entry auto|zig|c] [--runtime filc] [-o out] <inputs...>
```

**Which Fil-C clang.** zilc works best with **Fil-C 0.685's clang rebuilt with two fixes** to its
compiler pass (`tools/filc/build-patched-clang.sh`, about an hour; the diff is in
`third_party/filc-patches/`). The fixes don't change what the compiler emits for code it already
handled:

- a crash on code with several computed jumps in one function, which Zig's Debug builds contain.
  **Debug builds need the patched clang.**
- a slow step that grew with the cube of a function's size. Large programs build several times
  faster.

The same build adds `llvm-split` with a zilc mode, which lets zilc generate a large module's
machine code in parallel parts after Fil-C's pass has run on the whole module, so the code is
the same as a single run. `-j <n>` (or `ZILC_JOBS`) sets the number of parts; the default is
the number of cores, at most 16, and `-j 1` turns it off.

The stock Fil-C 0.685 prebuilt still works for the Release modes, without the parallel step.

zilc also keeps the objects Fil-C's clang produces, so rebuilding an unchanged program skips that
step: a TLS client rebuilds in about 2 seconds instead of 36. The cache lives in
`$ZILC_CACHE_DIR`, else `$XDG_CACHE_HOME/zilc`, else `~/.cache/zilc`; `--no-cache` (or
`ZILC_CACHE=0`) turns it off, and deleting the folder clears it.

`.zig` inputs go through Zig and the Fil-C pass; `.c`, `.cpp`, `.o` and `.a` go straight to Fil-C.
`-v` prints every command it runs. `--runtime zig` is reserved for zilc's own runtime and is refused
until that runtime is ready for testing; `filc` (the default) links Fil-C's.

### Limits

Each has a reason recorded in [cmem/known-issues.md](cmem/known-issues.md):

- **Linux x86_64 only** — that is what Fil-C supports.
- **`-O Debug` needs the patched Fil-C clang** (above). With the stock prebuilt, Fil-C's pass
  crashes on Zig's Debug code. ReleaseSafe keeps Zig's own safety checks on and is the better
  default anyway.
- **Large programs build slower than with plain Zig.** Fil-C's checks make the code it compiles
  several times larger. Typical programs build in seconds; a TLS client (`std.http.Client`) takes
  about 36 seconds against Zig's 17 (2 seconds to rebuild unchanged).
- **Target musl** — Fil-C's libc is musl; a gnu target fails to link.
- **Zig's own start code cannot run** — it builds a pointer out of an integer address
  (`@ptrFromInt(getauxval(AT_PHDR))`), which is precisely what the capability model forbids. zilc
  works around it by generating a C-ABI entry that calls your `main` directly, so whole Zig programs
  work; your program just gets no `std.os.environ` and no Zig stack-size expansion.

### Where it is going

- An LLVM pass usable from `zig cc`/`zig build-exe` directly, rather than through an IR rewrite.
- A runtime written in Zig (`zilc_runtime`), replacing Fil-C's C runtime.
- Whole Zig programs, then C++.

## Building

Requires **Zig 0.15.2**, and newer versions will not build it. zilc pins the Zig release whose
bundled LLVM matches Fil-C's: 0.15.2 ships LLVM 20, and Fil-C is on LLVM 20.1.8. zilc will move to
a newer Zig when Fil-C moves to a newer LLVM.

```sh
zig build                # CLI (zig-out/bin/zilc) + static runtime (zig-out/lib) + zilc.h
zig build gate           # build every example with zilc, assert each one traps (needs Fil-C)
zig build test           # unit tests (includes the IR-rewrite tests)
zig build capi-smoke     # C client linked against the runtime through zilc.h
zig build baseline       # bug examples built with PLAIN zig cc (unsafe, for comparison)
zig build run -- --help

# the driver runs on Linux, where Fil-C is; cross-compile it from anywhere:
zig build -Dtarget=x86_64-linux-musl -Doptimize=ReleaseSafe
```

**On an exFAT drive, put the Zig cache on an NTFS path.** A `.zig-cache` on exFAT works for one
build and fails with `error: Unexpected` on every build after that:

```powershell
$env:ZIG_LOCAL_CACHE_DIR = 'C:\zig-cache\zilc'
```

## Layout

```text
src/          Zig sources: driver, IR rewrites, std patches, runtime library, CLI
include/      zilc.h, the runtime's C ABI
tests/        C smoke test, and tests/basics: 156 C and Zig programs that must run correctly
examples/     canonical memory-safety bugs (OOB write, use-after-free)
tools/        developer tooling: corpus runs, the patched Fil-C build (filc/), upstream monitoring
third_party/  upstream license texts, Fil-C patches, and the compliance ledger (LICENSES.md)
cmem/         project memory: design, decisions, roadmap, workarounds
toolchain/    local archive of the patched Fil-C clang (not in git)
upstream/     read-only reference clone of Fil-C (not in git)
```

## License

zilc's own code is licensed under either of

- the Apache License, Version 2.0 with LLVM Exceptions ([LICENSE-APACHE](LICENSE-APACHE)), or
- the MIT license ([LICENSE-MIT](LICENSE-MIT)),

at your option. `SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT`

Code derived from Fil-C, LLVM or Zig keeps its original license (Apache-2.0 WITH LLVM-exception,
BSD-2-Clause, or MIT). See [NOTICE](NOTICE) and [third_party/LICENSES.md](third_party/LICENSES.md).

**zilc bundles none of those toolchains** — it invokes the Zig and Fil-C you point it at. Note,
though, that a binary *produced* by `zilc build` contains Fil-C's runtime (BSD-2-Clause) and musl
(MIT), because Fil-C links them. If you distribute programs built with zilc, their notices travel
with those programs.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in
this work, as defined in the Apache-2.0 license, is dual-licensed as above, without any additional
terms or conditions.
