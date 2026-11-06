# tests/bench — the benchmark suite's own programs

Run by `tools/bench/bench.ts` (`bun tools/bench/bench.ts`; method, first baseline and how to read it
in `cmem/testing.md` "Benchmark suite"). Each program here is built twice, with plain Zig
(`zig build-exe`) and through zilc (`zilc build`), in ReleaseSafe and ReleaseFast, and both builds
must print the same result. Upstream Fil-C's own `filc/benchmarks` run beside these, read from the
fetched Fil-C package: nothing of Fil-C's is copied here.

| file | what it measures | argument (suite's) |
| --- | --- | --- |
| `zig/nbody.zig` | upstream's n-body, in Zig: floating point in a tight loop | steps (5,000,000) |
| `zig/spectralnorm.zig` | upstream's spectral-norm, in Zig (scalar; upstream's C uses AVX) | N (2000) |
| `zig/fannkuch.zig` | upstream's fannkuch-redux, in Zig, single-threaded: small arrays | N (10) |
| `zig/binarytrees.zig` | upstream's binary-trees, in Zig, freeing every node: the C allocator | depth (16) |
| `zig/hashmap_churn.zig` | `std.AutoHashMap` / `std.ArrayList` growth, removal, lookup on the C allocator | rounds (120) |
| `zig/sort_format.zig` | `std.fmt` formatting and parsing, small heap strings, `std.mem.sort` | count (600,000) |
| `zig/dispatch.zig` | tagged-union `switch`, a vtable of function pointers, error unions on the hot path | iterations (100,000,000) |
| `zig/slices.zig` | a sieve over `[]bool` and a matrix multiply over `[][]f64` | limit, size (100,000,000, 400) |
| `interop/interop.zig` + `interop/kernel.c` | Zig ⇄ C both ways: libc `qsort` calling a Zig comparator, Zig calling a C kernel (needs `zilc build --entry zig`: with a `.c` input, `--entry auto` takes C's `main`) | elements (1,000,000) |
| `compat/stdfil.h` | not a benchmark: lets the PLAIN build of upstream's richards.c compile (`zprintf` → `printf`, `zgc_alloc` → `calloc`) | — |

All of it is zilc's own code (the ports implement the Benchmarks Game's public algorithms, written
afresh in Zig). Each program takes its size as its first argument and has a default, so it can be
run by hand: `zilc build -O ReleaseFast -o /tmp/nbody tests/bench/zig/nbody.zig && /tmp/nbody 1000`.
