# zilc release notes

Each release states what its version number does not: the Zig your code is compiled with, the
Fil-C release it is built on, and, for a release on a newer Zig line, the release it was ported
from (its basis). `zilc --version` prints the same facts and checks them against your machine.

How versions read: `<Zig line>-<release>`. `0.15.2-3` is zilc release 3 on the Zig 0.15.2 line.
The number restarts at 1 for every new Zig release. There is no 1.0: breaking changes are
announced here, not in the number.

---

## 0.15.2-3

| | |
| --- | --- |
| **Line** | reference (built with Zig 0.15.2 and checked directly against Fil-C) |
| **Your Zig code is compiled with** | Zig 0.15.2 |
| **Built on** | Fil-C 0.685 (compiler pass, runtime and its checked musl libc) |
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

### Build speed

- Big modules generate their machine code in parallel parts after Fil-C's pass has run on the
  whole module, so the code is the same as a single run. `-j <n>` or `ZILC_JOBS` (default: cores,
  at most 16; `-j 1` turns it off).
- Unchanged modules are reused from a cache. `--no-cache` or `ZILC_CACHE=0` turns it off;
  `zilc --clean-cache` empties it.
- Example: a TLS client (`std.http.Client`) builds in about 36 seconds (plain Zig: 17) and
  rebuilds unchanged in about 2.

### Requirements

- Fil-C 0.685's clang (`--filc` or `ZILC_FILC`) and Zig 0.15.2 (`--zig` or `ZILC_ZIG`).
- **Recommended: zilc's patched build of Fil-C's clang** (`tools/filc/build-patched-clang.sh`).
  It fixes a crash on Zig's Debug code and a compile-time slowdown on large functions, without
  changing the code it emits for anything else, and adds the parallel code generation. With the
  stock Fil-C 0.685 clang, the Release modes work; Debug does not.
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
