# Roadmap

> **Updated 2026-09-18 after the first goals discussion.** P1's milestone is owner-agreed. The later
> phases are still a sketch. **P1 is ON HOLD until a Linux machine is available** (no WSL on the
> Windows dev box; see KI-1).

## ✅ P0 — Scaffold (`0.1.0`, 2026-09-18)

Repo layout, dual license + staged upstream licenses, compliance ledger, `cmem/`, build graph with
`test` / `capi-smoke` / `baseline`, two bug examples.

## ⏸️ P1 — The feasibility milestone (owner-agreed 2026-09-18). Needs a Linux x86_64 machine.

> **Milestone:** a Zig program plus a C library, compiled through Fil-C's *existing* pass and
> runtime, panics correctly on out-of-bounds and use-after-free.

No zilc code is involved. Only Deno scripts in `tools/` and notes in `cmem/`. Steps:

1. **Environment.** On the Linux machine, unpack the prebuilt `filc-<ver>-linux-x86_64.tar.xz`
   (no LLVM build) and install **Zig 0.15.2** (LLVM 20, matching Fil-C; see KI-3).
2. **Reference behavior.** Build `examples/oob_write.c` and `examples/use_after_free.c` with
   `filcc`. Save the exact panic output. That becomes the expected result for the bug-example gate
   (`testing.md`).
3. **The spike: does Zig IR survive GIMSO?** A tiny Zig program (slice, heap allocation, OOB write
   through a pointer, call into a C function) → Zig 0.15.2 emits LLVM IR for
   `x86_64-linux` **with libc linked** → Fil-C's clang runs the pass → link against Fil-C's
   runtime + musl. Record the result either way: correct panics, or a list of exactly what breaks.
4. **Decide the integration route** (open question 1) from what step 3 shows.

**Expected first breakages (from reading upstream, 2026-09-18). Check these first:**
- **Inline-asm syscalls.** Zig's std on Linux issues syscalls through inline asm unless libc is
  linked. Fil-C cannot allow raw asm. → link libc (`-lc`), and it must be **Fil-C's musl**.
- **Symbol mangling.** The pass renames every symbol to `pizlonated_<name>`
  (`FilPizlonator.cpp:1904`). Every object in the link must go through the pass. Uninstrumented
  Zig `std` objects or compiler-rt will not link or will not be safe.
- **Zig's start-up code and its allocators** (`page_allocator` → direct `mmap`), and Zig
  compiler-rt intrinsics.

## P2 — Integrate the pass with Zig

Take the route chosen in P1 (patched Zig, LLVM plugin, or `zilc` wrapper driver; see open
question 1). The Zig version follows Fil-C's LLVM: 0.15.2 now, and 0.16.0 once Fil-C reaches
LLVM 21. We do not port the pass ourselves (owner, 2026-09-18). **Exit criterion:**
the P1 milestone reproduces through zilc's own tooling instead of hand-run commands.

## P3 — `zilc_runtime` in Zig

Replace the C runtime with Zig, piece by piece, behind the same ABI the pass emits calls to.
**Exit criterion:** P2's gate still passes with no Fil-C C code linked.

## P4 — Zig language fidelity

P1 tests whether Zig IR survives the pass at all. P4 makes it *right*. Define how Zig's pointer
kinds (slices, many-pointers, optionals, `allowzero`, `@ptrCast`, `@intFromPtr`/`@ptrFromInt`) map
onto capabilities, and how Zig's own safety checks interact with GIMSO. **Exit criterion:** a
Zig ⇄ C program where C overflows a Zig-owned slice and panics, across the full Zig test corpus.

## P5 — C++ and polish

libc++/libc++abi under the target, exceptions/unwinding, threads with atomic capability updates,
performance measurement against Fil-C.
