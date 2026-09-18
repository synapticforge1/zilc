# Vision

## The primary goal (owner, 2026-09-18)

> Create a **Zig-based Fil-C runtime and target that unifies Zig, C and C++ under a single
> memory-safe target.**

Zig already compiles C and C++ through its embedded clang (`zig cc` / `zig c++`). A Fil-C-style
target inside the Zig toolchain would therefore cover all three languages from **one binary**,
instead of Fil-C's separate, heavyweight clang fork (`filcc` / `fil++`).

The owner's framing came from a design discussion with Gemini. Its content is recorded below,
separated into what that discussion *proposed* and what has since been *checked against upstream*.

## The proposed pipeline

```
Zig / C / C++ source
        │   zig build-exe / zig cc / zig c++
        ▼
Clang / Zig LLVM frontend  →  standard LLVM IR
        ▼
Zig-FilPass (LLVM IR pass)     injects InvisiCap bounds checks, moves escaping stack
        │                      allocas to the GC heap, instruments syscalls
        ▼
zig_fil_runtime (static lib)   FUGC collector + capability runtime, written in Zig
        ▼
memory-safe machine code
```

## Claimed advantages (from the discussion, to be validated)

1. **Native polyglot compilation.** One `zig` binary builds safe Zig, safe C and safe C++.
2. **Runtime in idiomatic Zig.** The GC, the shadow/capability lookup and the syscall traps are
   written in Zig, using explicit allocators and `comptime` layout.
3. **FFI safety across Zig ⇄ C ⇄ C++.** A `[]u8` or `*T` passed to C keeps its capability, so an
   out-of-bounds write in a legacy C library panics instead of corrupting Zig memory.

## Acknowledged costs (from the discussion)

1. **Stack-to-heap conversion.** Escaping stack frames are GC-allocated, costing memory and time.
   The discussion put the slowdown at roughly 1.5×–4×, depending on workload.
2. **LLVM optimizer interop.** Optimizations can reorder or strip pointer arithmetic in ways that
   break capability tracking, so the pass has to control where it runs in the pipeline.
3. **Atomic capability updates.** Under data races, a pointer and its capability must never tear.
   Otherwise a pointer can be paired with the wrong bounds.

## ⚠️ Claims NOT yet verified, which must be checked before being relied on

- *"Community proposals within the Zig ecosystem have explored a safe, Fil-C-like target."*
  No source was given. Find the issue/proposal (Codeberg `ziglang/zig`, since Zig moved off GitHub)
  or drop the claim.
- *"100% exploit-proof memory safety."* Fil-C's own claim is narrower and precise: GIMSO
  semantics (see upstream `gimso_semantics.md`, `invisicap.txt`). Use Fil-C's wording, not the
  marketing summary.
- *"A single binary (`zig`)"*. This implies **patching the Zig compiler**. Two other options are a
  pass plugin loaded into an unmodified Zig, or a wrapper driver. That is the biggest open
  question; see `design-decisions.md`.
- *"Passing a Zig slice into a C function preserves its capability."* ◐ **Checked against upstream
  2026-09-18: true only if BOTH sides are compiled with the pass.** FilPizlonator renames every
  symbol to `pizlonated_<name>` (`FilPizlonator.cpp:1904`), so instrumented code cannot call
  uninstrumented C directly. The goal still holds (one safe world for Zig, C and C++), but it does
  not extend to calling ordinary, uninstrumented C libraries.
- ✅ *"The pass can apply to Zig."* **Supported by upstream's own framing** (2026-09-18): Fil-C's
  pass is "garbage in, memory safety out" (GIMSO), with memory-safe semantics for *any* LLVM
  module, including adversarial ones (`gimso_semantics.md`). Nothing in principle is C-specific.
  The P1 spike tests this in practice.
- Zig-language support is **not** equivalent to C support. Zig has slices, optionals, error unions,
  `@ptrCast`, `allowzero`, packed structs and its own `Allocator` interface. How each maps onto
  capabilities is unexplored. Fil-C itself has never targeted Zig.

## Guiding decisions (so far)

- **Track Fil-C, don't fork blindly.** Upstream is actively developed. Take its *pass* and its
  *semantics*; reconsider its runtime (see `upstream.md`).
- **Safety over speed.** The target exists to trade throughput for absolute runtime resilience.
- **Permissive, upstream-compatible licensing** (`licensing.md`).
