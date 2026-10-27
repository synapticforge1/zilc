# zilc release notes

Each release states what its version number does not: the Zig your code is compiled with, the
Fil-C release it is built on, and, for a release on a newer Zig line, the release it was ported
from (its basis). `zilc --version` prints the same facts and checks them against your machine.

How versions read: `<Zig line>-<Fil-C release>.<zilc release>`. `0.15.2-0.687.1` is zilc release 1
for Zig 0.15.2 and Fil-C 0.687. The last number restarts at 1 for every new Zig release and every
new Fil-C release. There is no 1.0: breaking changes are announced here, not in the number.

---

## 0.15.2-0.687.1

| | |
| --- | --- |
| **Line** | reference (built with Zig 0.15.2 and checked directly against Fil-C) |
| **Your Zig code is compiled with** | Zig 0.15.2 |
| **Built on** | Fil-C 0.687 (compiler pass, runtime and its checked musl libc), released 2026-10-23 |
| **Basis** | none: this is the reference line |
| **Platform** | Linux x86_64 only, by design (on Windows, inside WSL) |

zilc moves to Fil-C 0.687. Fil-C stays on LLVM 20.1.8, so your code is still compiled with Zig
0.15.2.

### What changed

- **Fil-C 0.687's fixes** now apply to zilc programs. Among them: arguments passed by value are
  checked over their whole size (tail padding included); the compiler's model of where the
  garbage collector may run is corrected for stack allocations and memory copies; and `setjmp`
  inside loops is handled soundly.
- **Fil-C 0.687 defines what was undefined**: an oversized shift amount is taken modulo the width,
  an out-of-range vector lane index is brought into range, and division or remainder by zero
  (and the most negative number divided by −1) gives a defined result instead of undefined
  behaviour. Zig's ReleaseSafe still reports these as Zig safety panics before they happen; in
  ReleaseFast and ReleaseSmall you get Fil-C's defined result.
- **Rebuild everything.** Fil-C 0.687 changes its runtime ABI (`setjmp`), so objects built for
  0.686 must not be linked with 0.687's runtime. zilc's object cache keys on the compiler, so it
  rebuilds by itself.
- **`--runtime zig` is gone.** It was reserved and always refused; `--runtime filc` (the default,
  and the only value) still works.

### Checked for this release

Fil-C's own test suite gives the same result with the stock and zilc's patched clang on all 7,269
tests. zilc's safety gate passes 8 of 8, its 156-program corpus runs as designed in all four
optimize modes, and its output matches plain Zig's with no unexplained difference.

### Requirements

- Fil-C 0.687's clang (`--filc` or `ZILC_FILC`) and Zig 0.15.2 (`--zig` or `ZILC_ZIG`), on Linux
  x86_64 (on Windows, inside WSL). First-time setup: `tools/README.md`.
- Recommended, as before: zilc's patched build of Fil-C's clang (`tools/filc/build-patched-clang.ts`);
  stock 0.687 still crashes on Zig's Debug code, as 0.686 did.

---

## 0.15.2-0.686.1

| | |
| --- | --- |
| **Line** | reference (built with Zig 0.15.2 and checked directly against Fil-C) |
| **Your Zig code is compiled with** | Zig 0.15.2 |
| **Built on** | Fil-C 0.686 (compiler pass, runtime and its checked musl libc), released 2026-10-04 |
| **Basis** | none: this is the reference line |
| **Platform** | Linux x86_64, the platform Fil-C supports (on Windows, through WSL2) |

The first published release. zilc compiles Zig, C and C++ into one memory-safe program through
Fil-C: out-of-bounds accesses, use-after-free and pointers forged from integers stop the program
with a report naming the source line, instead of corrupting memory.

### What works

- **Whole Zig programs** (`pub fn main`), with `std.os.argv` and `std.os.environ` set.
- **Mixed programs**: a C `main` calling Zig exports (with the same std support as a whole Zig
  program), and Zig calling C. C++ sources are passed to Fil-C's compiler but are not tested yet.
- **All four optimize modes**: Debug, ReleaseSafe, ReleaseFast, ReleaseSmall.
- **Zig's std under Fil-C**: files, directories, processes, threads, sockets, HTTP and TLS,
  JSON, time, random numbers, 128-bit floats. A 156-program test corpus (78 C, 78 Zig) runs as
  designed in every mode, and prints the same as plain Zig except where a program prints
  addresses, timing or thread order.
- **Panics** are reported by Fil-C, with its stack trace, and stop the program.
- **Guaranteed tail calls** (`@call(.always_tail, …)`) no longer grow the stack: Fil-C 0.686
  added `musttail` support. On Fil-C 0.685, a deep tail-call loop overflowed the stack.

### Build speed

- Big modules generate their machine code in parallel parts after Fil-C's pass has run on the
  whole module, so the code is the same as a single run. `-j <n>` or `ZILC_JOBS` (default: cores,
  at most 16; `-j 1` turns it off).
- Unchanged modules are reused from a cache. `--no-cache` or `ZILC_CACHE=0` turns it off;
  `zilc --clean-cache` empties it.
- Example: a TLS client (`std.http.Client`) builds in about 38 seconds (plain Zig: 17) and
  rebuilds unchanged in about 2.

### Requirements

- Fil-C 0.686's clang (`--filc` or `ZILC_FILC`) and Zig 0.15.2 (`--zig` or `ZILC_ZIG`).
- **Recommended: zilc's patched build of Fil-C's clang** (`tools/filc/build-patched-clang.ts`).
  It fixes a crash on Zig's Debug code and a compile-time slowdown on large functions, without
  changing the code it emits for anything else, and adds the parallel code generation. With the
  stock Fil-C 0.686 clang, the Release modes work; Debug does not.
- Target musl (`x86_64-linux-musl`, the default): Fil-C's libc is musl.

### Things to know

- **`std_options.crypto_always_getrandom` is always on.** Zig's other random-number path probes
  the kernel with a deliberately invalid `madvise` call, which Fil-C stops. With the option on,
  every random byte comes from the kernel's `getrandom()`: as secure, fork-safe, one system call
  per request. `zilc build` prints a note if your code sets it to anything but `true`.
- Your own `panic`, `std_options` and `os` declarations in the root file are honoured.
- Fil-C's output is not bit-for-bit reproducible between runs of its compiler; the programs it
  produces behave the same.

### Licences

zilc is `Apache-2.0 WITH LLVM-exception OR MIT`. Programs built with it link Fil-C's runtime
(BSD-2-Clause) and musl (MIT); see `third_party/LICENSES.md`.
