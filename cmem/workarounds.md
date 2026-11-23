# Workarounds — what we work around, and WHY

This file: the rule, the families and the symptom index. The entries, split by subject on
2026-11-23 (letter H38 step 5): [workarounds-filc-pass.md](workarounds-filc-pass.md) (KI-18, KI-20,
KI-4), [workarounds-build-time.md](workarounds-build-time.md) (KI-21, KI-22),
[workarounds-machine.md](workarounds-machine.md) (machine setup, the Windows-host rule) and
[workarounds-pure-zig.md](workarounds-pure-zig.md) (the short-form entries, W-1 … W-14).

**Owner rule (2026-10-01):** _"When we create a work around for something, take copious notes for
the why part so we can refer back to it in the future. Whether it is an upstream defect or a system
limitation we need to know the why of these issues so that when we run into similar issues we can
quickly identify those past problems and their resolutions, and investigate and surmise potential
similar resolutions."_

So this file is the **lookup table for new failures**. A new symptom goes here first: find its row
in the symptom index, read the family, and try that family's resolution before starting from zero.
`known-issues.md` keeps the full investigation history of each KI. This file keeps the
**reasoning**: why it fails, why the fix is correct, and how to recognise a relative.

---

## How to write an entry (binding on every agent)

Every workaround gets an entry **when it is made**, not later. Use these headings:

| heading                           | what goes in it                                                                                                                                             |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Symptom**                       | The exact text a user or the corpus sees (assertion, trap message, linker error), so a text search finds it                                                 |
| **Class**                         | Upstream defect (Fil-C / Zig / LLVM) · system limitation (by design, will not change) · std behaviour (legal natively, unsafe under Fil-C) · zilc's own gap |
| **Root cause (the why)**          | The mechanism, as far as it is **known**. Mark what is **measured** and what is **surmised**, separately                                                    |
| **Why the workaround is correct** | Which invariant it preserves (same bytes, same value, same checks), and why it cannot hide a real safety error                                              |
| **Ruled out**                     | Hypotheses that were tested and failed, with the test. These save the most time later                                                                       |
| **How it was found**              | The method and tools (reducer, probes), so the next one is quicker                                                                                          |
| **Recognising a relative**        | What a similar problem would look like, and the first thing to try                                                                                          |
| **Cost and exit**                 | What it costs (speed, size, lost diagnostics), and the condition for removing it (e.g. "Fil-C fixes X")                                                     |
| **Where**                         | Code (function, driver step), tests, repro files, KI number                                                                                                 |

---

## Families: the patterns seen so far

- **F1. Fil-C's pass rejects a valid IR shape** — An assertion or crash inside `FilPizlonatorPass` on IR that stock LLVM accepts
  - members: KI-4 (Debug `-O1` segfault), **KI-18** (3-byte globals)
  - first thing to try: Reduce with `tools/p2/llreduce.ts` (functions **and** globals), then probe
    the minimal shape's neighbours (sizes, wrappers, positions) by hand. Rewrite the IR into an
    equivalent shape the pass accepts
- **F2. A capability lost through an integer** — `cannot read/write pointer with null object`
  - members: KI-5, KI-13, KI-17, KI-19, KI-10
  - first thing to try: Find where the pointer became an integer (`ptrtoint`, a call result,
    `extractvalue`, a parameter, a stack slot). Fil-C recovers a capability only through plain
    same-function integer arithmetic
- **F3. Inline asm** — `cannot handle inline asm …`
  - members: KI-7 (syscall), KI-14 (Valgrind), KI-15/Z-4 (frame walks)
  - first thing to try: Route through checked libc (`zilc_syscall`), or turn the feature off with a Zig flag (`-fno-valgrind`)
- **F4. Code that never goes through the pass** — `undefined reference to pizlonated_…`
  - members: KI-6 (glibc names), KI-8 (stack probe), KI-9 (f128 helpers)
  - first thing to try: Either stop emitting the call (a flag) or compile the provider through the pass
- **F6. Build time far above native Zig** — a zilc build several times slower than `zig build-exe`
  - members: KI-21 (dead std code compiled), KI-22 (cubic frame-slot colouring in the pass)
  - first thing to try: Time each stage (Zig IR, Fil-C `-ftime-report`, link) against native and
    stock-clang baselines; list IR lines by namespace; for time inside the pass, scale a synthetic
    test and sample with gdb, then read the pass
- **F5. std code that is legal natively but stopped by Fil-C** — `cannot read N bytes when upper - ptr = M`, `ptr >= upper`, `unrecognized … advice`
  - members: KI-11 (sentinel over-read), KI-12 (`mmap` hint), KI-20 (`madvise` probe)
  - first thing to try: std hook if one exists (`root.os.heap.page_allocator`); otherwise the std overlay (`src/stdpatch.zig`), backporting upstream first

---

## Symptom index

- `Assertion '!(CSize % WordSize)' failed` (`FilPizlonator.cpp:16714`) — [KI-18](workarounds-filc-pass.md#ki-18--globals-with-a-3-byte-value-type)
- segfault in `FilPizlonatorPass` on Debug IR at `-O1` (`SplitKnownCriticalEdge`,
  `PHINode::setIncomingBlock`) —
  [KI-4](workarounds-filc-pass.md#ki-4--fil-cs-pass-segfaults-on-debug-ir-at--o1-and-why-debug-was-at--o0)
- `cannot handle inline asm (unsupported mnemonic for safe inline asm: syscall)` — KI-7
- `literal register %rdi not covered` (Valgrind sequence) — KI-14
- `undefined reference to pizlonated___zig_probe_stack` — KI-8
- `undefined reference to pizlonated___multf3` / `roundq` — KI-9
- `undefined reference to pizlonated_getrlimit64` / `mmap64` — KI-6
- `cannot write pointer with null object` in `DebugAllocator` — KI-13
- `cannot read pointer with null object` after a syscall, Debug only — KI-19 (open)
- `unsupported syscall: 310` — KI-15
- `cannot read 16 bytes when upper - ptr = 12` at `mem.zig` — KI-11
- `cannot write pointer with ptr >= upper` inside `zsys_mmap` — KI-12
- Zig `start.zig` trap reading the aux vector — KI-5
- a zilc build many times slower than native Zig; IR full of `debug.Dwarf` / `compress.flate` — [KI-21](workarounds-build-time.md#ki-21--stds-stack-trace-code-compiled-into-every-program-build-time)
- build time dominated by `FilPizlonatorPass` on one huge function; Debug builds that never finish —
  [KI-22](workarounds-build-time.md#ki-22--fil-cs-frame-slot-colouring-is-cubic-on-big-zig-functions-build-time-open)
- `attempting to use unrecognized madvise advice -1` (from `tlcsprng.zig`) — [KI-20](workarounds-filc-pass.md#ki-20--stdcryptorandom-probes-madvise-with-an-invalid-advice)
- `Can't create a MachineFunction using a Module with a Target-incompatible DataLayout` (a module split before Fil-C's pass) — KI-22, lever (a): `datalayout_after_filc` lost
- `TLS reference in … mismatches non-TLS reference in …` (joining split parts) — KI-22, lever (a): unused hidden declarations
- `multiple definition of 'main'` … `filc_crt.o` / `filc_mincrt.o` after `clang -r` — KI-22, lever (a): Fil-C's driver adds its crt even to `-r -nostdlib`
- `filc safety error: stack overflow` on a Zig `@panic`, or the KI-12 / KI-20 traps, in a program
  whose `main` is C — the Zig file was compiled without zilc's generated root, so std's hooks were
  missing: fixed 2026-10-02 by the library root (`library_shim`, KI-5 short form below; gate cases
  6–8)
- `fatal error: 'asm/types.h' file not found` (from `pizfix/os-include/linux/types.h`) — the Fil-C
  tree's `os-include/asm` link points at headers this machine lacks:
  `tools/filc/fix-os-include.ts <tree>` (see "Machine setup" below)
- `patch-pass.ts` / `patch-split.ts`: `original found 0 times, expected 1` — an edit's original text
  no longer matches: upstream changed it (`check-upstream.ts`), or an editor trimmed a
  whitespace-only line in it (KI-22, lever (b))
- `zilc (KI-22): interference graph differs from the original` / `frame-slot colouring differs` —
  only with `ZILC_VERIFY_INTERFERENCE=1` / `ZILC_VERIFY_COLOURING=1`: the patched pass disagrees
  with the original; KI-22 levers (b) and the colouring fix

---
