# zilc

**A Fil-C-style memory-safe compilation target for the Zig toolchain**, covering Zig, C and C++ with
one compiler binary.

> ⚠️ **Status: scaffold (v0.1.0).** The build, C ABI and test harness exist. No memory-safety
> instrumentation is implemented yet.

## What it is

[Fil-C](https://github.com/pizlonator/fil-c) makes C and C++ memory-safe at runtime. It gives every
pointer an invisible *capability* (InvisiCap) holding its allocation bounds, and replaces `free()`
with an accurate, non-moving garbage collector (FUGC). Out-of-bounds accesses and use-after-free
become deterministic panics instead of memory corruption.

zilc aims to bring that model into the Zig toolchain:

- **An LLVM IR pass** (derived from Fil-C's `FilPizlonator`) run by `zig cc`, `zig c++` and
  `zig build-exe`, so all three languages compile to the same safe target.
- **A runtime written in Zig** (`zilc_runtime`): the collector, the capability metadata and the
  syscall shims.
- **Safety across the FFI boundary.** A Zig slice passed to C keeps its bounds, so an overflow inside
  a legacy C library panics instead of corrupting Zig memory.

The cost is runtime speed, which is the same trade Fil-C makes (roughly 1.5×–4× slower, depending on
the workload).

## Building

Requires **Zig 0.15.2**, and newer versions will not build it. zilc pins the Zig release whose
bundled LLVM matches Fil-C's: 0.15.2 ships LLVM 20, and Fil-C is on LLVM 20.1.8. zilc will move to
a newer Zig when Fil-C moves to a newer LLVM.

```sh
zig build                # CLI (zig-out/bin/zilc) + static runtime (zig-out/lib) + zilc.h
zig build test           # unit tests
zig build capi-smoke     # C client linked against the runtime through zilc.h
zig build baseline       # bug examples built with PLAIN zig cc (unsafe, for comparison)
zig build run -- --help
```

**On an exFAT drive, put the Zig cache on an NTFS path.** A `.zig-cache` on exFAT works for one
build and fails with `error: Unexpected` on every build after that:

```powershell
$env:ZIG_LOCAL_CACHE_DIR = 'C:\zig-cache\zilc'
```

## Layout

```text
src/          Zig sources: runtime library (root.zig), C ABI (capi.zig), CLI (main.zig)
include/      zilc.h, the runtime's C ABI
tests/        C smoke test
examples/     canonical memory-safety bugs (OOB write, use-after-free)
tools/        developer tooling (future)
third_party/  upstream license texts + the compliance ledger (LICENSES.md)
cmem/         project memory: design, decisions, roadmap
```

## License

zilc's own code is licensed under either of

- the Apache License, Version 2.0 with LLVM Exceptions ([LICENSE-APACHE](LICENSE-APACHE)), or
- the MIT license ([LICENSE-MIT](LICENSE-MIT)),

at your option. `SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT`

Code derived from Fil-C, LLVM or Zig keeps its original license (Apache-2.0 WITH LLVM-exception,
BSD-2-Clause, or MIT). See [NOTICE](NOTICE) and [third_party/LICENSES.md](third_party/LICENSES.md).

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in
this work, as defined in the Apache-2.0 license, is dual-licensed as above, without any additional
terms or conditions.
