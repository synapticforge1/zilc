# Issues found in upstream projects

zilc compiles Zig and C programs with Fil-C's memory-safety pass. While doing so we came across the
issues below in projects we depend on. Each has a small, self-contained reproduction in this
repository. They are listed for the maintainers' information; none of them blocks zilc, which works
around each one.

---

## Fil-C

Version: **Fil-C 0.685** prebuilt release, `clang version 20.1.8 (Fil-C 0.685
git@github.com:pizlonator/llvm-project-deluge.git bb0d0a64eed297ab8e171002033208fb08ad9941)`,
`Build config: +assertions`. Linux x86_64 (Ubuntu 26.04 under WSL2, glibc 2.43).

The input files are LLVM IR produced by Zig 0.15.2 for `x86_64-linux-musl`, with the data layout
rewritten to Fil-C's form (`ni:0` added, plus a `target datalayout_after_filc` line). Nothing else
in them is changed. The second reproduction is 16 lines and hand-written.

### 1. Assertion `!(CSize % WordSize)` on a global with a 3-byte value type

Reproduction: [`tools/p2/repro/filc-0.685-i21-global.ll`](tools/p2/repro/filc-0.685-i21-global.ll)

```sh
clang -c -o /dev/null filc-0.685-i21-global.ll
```

```
clang: /fil-c/llvm/lib/Transforms/Instrumentation/FilPizlonator.cpp:16714:
void {anonymous}::Pizlonator::run(): Assertion `!(CSize % WordSize)' failed.
```

The whole module is one global and one function:

```llvm
@g = internal unnamed_addr constant i21 65533, align 4

define ptr @use() {
  ret ptr @g
}
```

- It happens at `-O0`, `-O1` and `-O2`, for constant and mutable globals alike.
- **It fails** for any global whose value type has a 3-byte store size: `i17`, `i21`, `i24`,
  `<3 x i8>`, `<24 x i1>`, `<17 x i1>`, `<2 x i12>`.
- **It works** for every other size we tried: `i2`, `i8`, `i9`, `i12`, `i16`, `i25`, `i31`,
  `i32`, `i33`, `i39`, `i40`, `i41`, `i48`, `i49`, `i56`, `i57`, `i63`, `i64`, `i65`, `i100`,
  `i120`, `<3 x i1>`, `<5 x i8>`, `<6 x i8>`, `<7 x i8>`, `<9 x i8>`, `<11 x i8>`, `<12 x i8>`,
  `<3 x i16>`, `<3 x i32>`, `<3 x float>`. It also works for the same
  values wrapped in an aggregate (`{ i21 }`, `{ i21, i8 }`, `[2 x i21]`, `{ <3 x i8> }`) and for
  `i21` in allocas, loads and stores.
- Found through Zig's `std.unicode.replacement_character: u21`.
- Workaround: we wrap such a global's value in a one-field struct (`{ i21 } { i21 65533 }`), which
  has the same size, alignment and bytes.

### 2. Segmentation fault in `FilPizlonatorPass` at `-O1` and `-O2` (fine at `-O0`)

Reproduction: [`tools/p2/repro/filc-0.685-O1-crash.ll`](tools/p2/repro/filc-0.685-O1-crash.ll)
(9,773 lines, 8 functions). Notes: [`tools/p2/repro/README.md`](tools/p2/repro/README.md).

```sh
clang -O1 -c -o /dev/null filc-0.685-O1-crash.ll   # segfault while running FilPizlonatorPass
clang -O0 -c -o /dev/null filc-0.685-O1-crash.ll   # succeeds
```

- The 8 functions are Zig's `std.compress.flate` Huffman decoder, compiled unoptimized (Zig's Debug
  mode). The same code compiled in Zig's ReleaseSafe mode passes.
- Debug metadata is stripped from the file; inline asm is not involved.
- It could not be reduced further at function granularity: all 8 functions are needed.
- Workaround: we compile such modules at `-O0`.

---

## Zig

Nothing open. The one Zig issue we found (`std.mem.indexOfSentinel` reading past the end of its
object, in 0.15.2) is already fixed in 0.16.0.
