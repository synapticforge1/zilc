# Architecture

## What exists today (2026-09-18)

Only the scaffold: `src/root.zig` (the runtime module, holding just the version), `src/capi.zig`
(`zilc_version()`), `include/zilc.h`, and the `zilc` CLI placeholder. No instrumentation, no
allocator, no GC.

## Target pipeline

| Stage | Owner | Source of truth upstream |
| --- | --- | --- |
| Frontend: Zig → LLVM IR | Zig compiler (unmodified, or patched — open question) | n/a |
| Frontend: C/C++ → LLVM IR | clang embedded in Zig (`zig cc` / `zig c++`) | Fil-C also patches **clang** (`clang/`); size of those patches is TBD |
| **zilc pass** (LLVM IR → capability-checked IR) | zilc | `llvm/lib/Transforms/Instrumentation/FilPizlonator.cpp` ("apply GIMSO semantics to LLVM IR") |
| **zilc_runtime** | zilc (Zig) | `libpas/src/libpas/filc_*.c`, `filc/include/stdfil.h` |
| libc | ? | Fil-C ships a patched musl (`projects/usermusl`, `yolomusl`) and a glibc variant |
| C++ runtime | ? | Fil-C's `libcxx/`, `libcxxabi/` |

## 🔑 The Fil-C IR dialect (measured 2026-09-23 — this constrains every integration option)

The pass does not consume stock LLVM IR. A module entering it must declare **address space 0 as
non-integral** and carry a second, Fil-C-only layout directive:

```llvm
target datalayout = "e-m:e-ni:0-p270:32:32-…-S128"          ; "before": AS0 non-integral
target datalayout_after_filc = "e-m:e-p270:32:32-…-S128"     ; "after": plain
```

`ni:0` is inexpressible in stock LLVM (`address space 0 cannot be non-integral`), and
`datalayout_after_filc` is read through Fil-C's added `Module::getDataLayoutAfterFilC()`. This is why
capabilities cannot be forged: with AS 0 non-integral, LLVM's own optimizer is forbidden from
round-tripping pointers through integers behind the pass's back.

⚖️ **Measured scope of the divergence (2026-09-23):** Fil-C's *output* is ordinary LLVM IR once that
single extra line is removed — stock clang compiles it. `ni` itself is standard LLVM; only `ni:0` is
the extension. So this is a two-line dialect, not a different IR. Full evidence: `known-issues.md`
KI-4.

## The two core runtime components

1. **InvisiCap (capability bounds).** Every pointer carries hidden lower/upper bounds and type
   metadata. Loads and stores are checked against them. Upstream docs: `invisicap.txt`,
   `invisicaps_by_example.md`.
2. **FUGC (Fil's Unbelievable Garbage Collector).** An accurate, concurrent, non-moving collector.
   `free()` marks an object freed (later access traps), and memory is reclaimed only when
   unreachable, so use-after-free cannot reach reused memory. In Fil-C it lives inside `libpas`.

## Components zilc will need that are easy to forget

- **libc.** Instrumented code cannot call an uninstrumented libc directly. Fil-C solves this by
  compiling musl/glibc *with* Fil-C (the "user" libc) over a small trusted "yolo" libc. zilc must
  choose an equivalent. Zig's own bundled libcs (musl, mingw, wasi-libc) are candidates.
- **The unwinder / exceptions** for C++ (`yolounwind/` upstream).
- **The ABI boundary.** Instrumented and uninstrumented code have different pointer
  representations. Fil-C does not allow mixing them freely. Any "safe FFI" claim has to define what
  happens at that boundary.
- **Threads.** Capability updates must be atomic with the pointer store (see `security-model.md`).

## Build graph (`build.zig`)

`mod` (`src/root.zig`) is the runtime module. The `zilc` exe and the `zilc_runtime` static lib
(rooted at `src/capi.zig`) import it. `capi-smoke` builds a second copy of the lib for a gnu-ABI
target and links a C client against it. `baseline` compiles `examples/*.c` with no instrumentation.
