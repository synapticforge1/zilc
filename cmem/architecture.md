# Architecture

## What exists today (2026-09-23, `0.3.0`) — **the pipeline is real**

```
  user.zig ──► zig build-obj -femit-llvm-ir ──► plain LLVM IR
                                                     │  src/ir.zig rewrites TWO lines
                                                     ▼
                                          Fil-C-dialect IR (ni:0 + datalayout_after_filc)
                                                     │  filc clang: FilPizlonatorPass
  user.c ─────────────────────────────────────────►  ▼
                                              safe object ──► link ──► a binary that traps
```

| piece | file | state |
| --- | --- | --- |
| The IR rewrite | `src/ir.zig` | ✅ done, unit-tested (idempotent; `ni:0` after the `m:` component) |
| The pipeline | `src/driver.zig` | ✅ done — Zig→IR→rewrite→`filc clang`, C straight through, one link |
| The CLI | `src/main.zig` | ✅ `zilc build`, with KI-4/5/6 encoded as behavior, not just documented. `--runtime filc\|zig` (2026-09-30; `zig` reserved and refused) |
| Entry shim for whole Zig programs | generated `zilc_entry.zig` | ✅ done (KI-5) |
| The safety gate | `tools/gate.zig` | ✅ 4/4, inversion-tested |
| `zilc_runtime` (the Zig runtime) | `src/root.zig`, `src/capi.zig` | ◻️ **still a stub** — binaries link **Fil-C's** C runtime. That is P3 |

⚠️ **So zilc today is a DRIVER, not a runtime.** The safety comes entirely from Fil-C; zilc's
contribution is making Zig's output acceptable to it, and making that one command.

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

## 🔑 The runtime contract (measured 2026-09-30, Fil-C 0.685, `nm` in WSL)

Fil-C's runtime is **not built into the compiler**. It is a separate library linked against a fixed
set of named symbols, which is what makes swapping it one layer at a time possible (P3). The
prebuilt release's `pizfix/lib/` holds:

| file | role |
| --- | --- |
| `libpizlo.so` / `.a` (9.1 / 14 MB) | **the runtime**: capabilities, checks, allocator, GC, OS boundary |
| `libc.so` / `.a` | **checked musl**, compiled *with* the pass |
| `libyoloc.a`/`.so`, `libyolort.a`, `libyolounwind.a` | the **trusted** libc/runtime/unwinder beneath `libpizlo` |
| `lib_gcverify/`, `lib_test/`, `lib_test_gcverify/` | alternative `libpizlo.so` builds, e.g. with GC verification. Useful as references for the GC port |
| `stdfil-include/*.h` (1,850 lines) | the declared API: `stdfil.h`, `pizlonated_syscalls.h` (419 lines), `pizlonated_runtime.h`, … |

`libpizlo.so` exports **2,496** symbols in four layers:

| layer | size | what it is |
| --- | --- | --- |
| **pass → runtime** | **294** `filc_*` (excluding `filc_native_*`) | allocation, access-check failures, call checks (`filc_cc_args_check_failure`), global init. A small malloc/memcpy/printf C program calls only **11** |
| **allocator + GC** | **1,032** `pas_*` / `bmalloc_*` / `verse_*` | libpas (WebKit's allocator) + `verse_heap` (FUGC). Largest, and it holds **global state**: two GCs cannot share one heap, so this layer can only be swapped all at once |
| **OS boundary** | **335** `pizlonated_zsys_*`; checked musl uses **224** of them (of 283 external needs) | `long zsys_read(int fd, void* buf, size_t size)` etc. Implemented by 455 `filc_native_*`. **Fil-C has already drawn the narrow OS boundary a cross-platform port needs**, though it is shaped like Linux (`ioctl`, `readv`, …) |
| **beneath** | `libpizlo.so` imports **337** symbols | from the trusted libc — where the runtime actually reaches the kernel |

⚠️ **Code compiled by the pass calls `pizlonated_*` with Fil-C's own internal calling convention**,
not the normal C one. ✅ **Decoded 2026-09-30 → `filc-abi.md`:** `pizlonated_X` is a getter
returning a function object, and calls use a fast or generic entry through the thread's cc buffers.

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
