# Workarounds — what we work around, and WHY

**Owner rule (2026-10-01):** *"When we create a work around for something, take copious notes for
the why part so we can refer back to it in the future. Whether it is an upstream defect or a system
limitation we need to know the why of these issues so that when we run into similar issues we can
quickly identify those past problems and their resolutions, and investigate and surmise potential
similar resolutions."*

So this file is the **lookup table for new failures**. A new symptom goes here first: find its row
in the symptom index, read the family, and try that family's resolution before starting from zero.
`known-issues.md` keeps the full investigation history of each KI. This file keeps the
**reasoning**: why it fails, why the fix is correct, and how to recognise a relative.

---

## How to write an entry (binding on every agent)

Every workaround gets an entry **when it is made**, not later. Use these headings:

| heading | what goes in it |
| --- | --- |
| **Symptom** | The exact text a user or the corpus sees (assertion, trap message, linker error), so a text search finds it |
| **Class** | Upstream defect (Fil-C / Zig / LLVM) · system limitation (by design, will not change) · std behaviour (legal natively, unsafe under Fil-C) · zilc's own gap |
| **Root cause (the why)** | The mechanism, as far as it is **known**. Mark what is **measured** and what is **surmised**, separately |
| **Why the workaround is correct** | Which invariant it preserves (same bytes, same value, same checks), and why it cannot hide a real safety error |
| **Ruled out** | Hypotheses that were tested and failed, with the test. These save the most time later |
| **How it was found** | The method and tools (reducer, probes), so the next one is quicker |
| **Recognising a relative** | What a similar problem would look like, and the first thing to try |
| **Cost and exit** | What it costs (speed, size, lost diagnostics), and the condition for removing it (e.g. "Fil-C fixes X") |
| **Where** | Code (function, driver step), tests, repro files, KI number |

---

## Families: the patterns seen so far

| family | the shape | members | first thing to try |
| --- | --- | --- | --- |
| **F1. Fil-C's pass rejects a valid IR shape** | An assertion or crash inside `FilPizlonatorPass` on IR that stock LLVM accepts | KI-4 (Debug `-O1` segfault), **KI-18** (3-byte globals) | Reduce with `tools/p2/llreduce.ts` (functions **and** globals), then probe the minimal shape's neighbours (sizes, wrappers, positions) by hand. Rewrite the IR into an equivalent shape the pass accepts |
| **F2. A capability lost through an integer** | `cannot read/write pointer with null object` | KI-5, KI-13, KI-17, KI-19, KI-10 | Find where the pointer became an integer (`ptrtoint`, a call result, `extractvalue`, a parameter, a stack slot). Fil-C recovers a capability only through plain same-function integer arithmetic |
| **F3. Inline asm** | `cannot handle inline asm …` | KI-7 (syscall), KI-14 (Valgrind), KI-15/Z-4 (frame walks) | Route through checked libc (`zilc_syscall`), or turn the feature off with a Zig flag (`-fno-valgrind`) |
| **F4. Code that never goes through the pass** | `undefined reference to pizlonated_…` | KI-6 (glibc names), KI-8 (stack probe), KI-9 (f128 helpers) | Either stop emitting the call (a flag) or compile the provider through the pass |
| **F6. Build time far above native Zig** | a zilc build several times slower than `zig build-exe` | KI-21 (dead std code compiled), KI-22 (cubic frame-slot colouring in the pass) | Time each stage (Zig IR, Fil-C `-ftime-report`, link) against native and stock-clang baselines; list IR lines by namespace; for time inside the pass, scale a synthetic test and sample with gdb, then read the pass |
| **F5. std code that is legal natively but stopped by Fil-C** | `cannot read N bytes when upper - ptr = M`, `ptr >= upper`, `unrecognized … advice` | KI-11 (sentinel over-read), KI-12 (`mmap` hint), KI-20 (`madvise` probe) | std hook if one exists (`root.os.heap.page_allocator`); otherwise the std overlay (`src/stdpatch.zig`), backporting upstream first |

---

## Symptom index

| symptom text (search for it) | entry |
| --- | --- |
| `Assertion '!(CSize % WordSize)' failed` (`FilPizlonator.cpp:16714`) | [KI-18](#ki-18--globals-with-a-3-byte-value-type) |
| segfault in `FilPizlonatorPass` on Debug IR at `-O1` (`SplitKnownCriticalEdge`, `PHINode::setIncomingBlock`) | [KI-4](#ki-4--fil-cs-pass-segfaults-on-debug-ir-at--o1-and-why-debug-was-at--o0) |
| `cannot handle inline asm (unsupported mnemonic for safe inline asm: syscall)` | KI-7 |
| `literal register %rdi not covered` (Valgrind sequence) | KI-14 |
| `undefined reference to pizlonated___zig_probe_stack` | KI-8 |
| `undefined reference to pizlonated___multf3` / `roundq` | KI-9 |
| `undefined reference to pizlonated_getrlimit64` / `mmap64` | KI-6 |
| `cannot write pointer with null object` in `DebugAllocator` | KI-13 |
| `cannot read pointer with null object` after a syscall, Debug only | KI-19 (open) |
| `unsupported syscall: 310` | KI-15 |
| `cannot read 16 bytes when upper - ptr = 12` at `mem.zig` | KI-11 |
| `cannot write pointer with ptr >= upper` inside `zsys_mmap` | KI-12 |
| Zig `start.zig` trap reading the aux vector | KI-5 |
| a zilc build many times slower than native Zig; IR full of `debug.Dwarf` / `compress.flate` | [KI-21](#ki-21--stds-stack-trace-code-compiled-into-every-program-build-time) |
| build time dominated by `FilPizlonatorPass` on one huge function; Debug builds that never finish | [KI-22](#ki-22--fil-cs-frame-slot-colouring-is-cubic-on-big-zig-functions-build-time-open) |
| `attempting to use unrecognized madvise advice -1` (from `tlcsprng.zig`) | [KI-20](#ki-20--stdcryptorandom-probes-madvise-with-an-invalid-advice) |
| `Can't create a MachineFunction using a Module with a Target-incompatible DataLayout` (a module split before Fil-C's pass) | KI-22, lever (a): `datalayout_after_filc` lost |
| `TLS reference in … mismatches non-TLS reference in …` (joining split parts) | KI-22, lever (a): unused hidden declarations |
| `multiple definition of 'main'` … `filc_crt.o` / `filc_mincrt.o` after `clang -r` | KI-22, lever (a): Fil-C's driver adds its crt even to `-r -nostdlib` |
| `filc safety error: stack overflow` on a Zig `@panic`, or the KI-12 / KI-20 traps, in a program whose `main` is C | the Zig file was compiled without zilc's generated root, so std's hooks were missing: fixed 2026-10-02 by the library root (`library_shim`, KI-5 short form below; gate cases 6–8) |
| `fatal error: 'asm/types.h' file not found` (from `pizfix/os-include/linux/types.h`) | the Fil-C tree's `os-include/asm` link points at headers this machine lacks: `tools/filc/fix-os-include.ts <tree>` (see "Machine setup" below) |
| `patch-pass.ts` / `patch-split.ts`: `original found 0 times, expected 1` | an edit's original text no longer matches: upstream changed it (`check-upstream.ts`), or an editor trimmed a whitespace-only line in it (KI-22, lever (b)) |
| `zilc (KI-22): interference graph differs from the original` / `frame-slot colouring differs` | only with `ZILC_VERIFY_INTERFERENCE=1` / `ZILC_VERIFY_COLOURING=1`: the patched pass disagrees with the original; KI-22 levers (b) and the colouring fix |

---

## KI-18 — globals with a 3-byte value type

**Symptom.** Fil-C's clang aborts (exit 134, the driver reports `clang frontend command failed with
exit code 134`):
`FilPizlonator.cpp:16714: void {anonymous}::Pizlonator::run(): Assertion '!(CSize % WordSize)' failed.`
Seen on `22_strings-and-runes` and `69_http-client`, in **every** mode, only on the unoptimized IR
route (KI-17).

**Class.** Upstream defect in Fil-C 0.685's pass: an assertion on valid IR. Noted for the record,
not filed (owner decision 2026-09-30).

**Root cause, measured** (black-box probes, 2026-10-01; the pass source was not read):

- The trigger is a **global variable definition whose value type has a store size of exactly 3
  bytes**. Constant or mutable, internal or not, at `-O0`, `-O1` and `-O2`.
- ❌ asserts: `i17`, `i21`, `i24`; `<3 x i8>`, `<24 x i1>`, `<17 x i1>`, `<2 x i12>`.
- ✅ passes: `i2`, `i8`, `i9`, `i12`, `i16`, `i25`, `i31`, `i32`, `i33`, `i39`, `i40`, `i41`,
  `i48`, `i49`, `i56`, `i57`, `i63`, `i64`, `i65`, `i100`, `i120`; `<3 x i1>`, `<5 x i8>`,
  `<6 x i8>`, `<7 x i8>`, `<9 x i8>`, `<11 x i8>`, `<12 x i8>`, `<3 x i16>`, `<3 x i32>`,
  `<3 x float>`; `[3 x i8]`, `{ i21 }`, `{ i21, i8 }`, `{ <3 x i8> }`, `[2 x i21]`.
- ✅ passes: the same types **inside functions** (an `alloca i21`, a `load`/`store i21`, a
  `load i21` from an `i32` global).
- Where the two came from: Zig's `std.unicode.replacement_character: u21 = 0xFFFD`
  (`@unicode.replacement_character = internal unnamed_addr constant i21 65533`) in 22 and 69, and a
  `<3 x i8>` constant (`@__anon_9482 = … <3 x i8> <i8 48, i8 48, i8 48>`, three ASCII `'0'`s,
  likely a `@Vector(3, u8)` or a SIMD-ized std literal) in 69.
- Why only the unoptimized route: on the optimized route LLVM had already constant-folded these
  globals into their uses and deleted them, so the pass never saw them.

**Root cause, from the pass source** (read 2026-10-01 at the binary's commit `bb0d0a64`, once the
owner allowed reading the pass): for each global, `FilPizlonator.cpp:16710` builds
`paddedConstant(constantToRestConstantWithPtrPlaceholders(init))`, then asserts its store size is a
multiple of `WordSize = 8`. `paddedConstant` (line 6584) computes the padding from the **store**
size (3 for `i21`, so 5 bytes of padding) and appends it as a struct field. But a struct lays its
next field out after the **allocation** size (4 for `i21`), so `{ i21, [5 x i8] }` is 9 bytes, not
8, and the assertion fires. A wrapped `{ i21 }` is padded as an aggregate whose store size is 4, so
`{ { i21 }, [4 x i8] }` is 8. ❓ Not traced: why 5-to-7-byte scalars (`i40`, `<5 x i8>`) pass,
which by the same arithmetic would not. `constantToRestConstantWithPtrPlaceholders` probably
reshapes them first. The measured table above is authoritative.

**Why the workaround is correct.** `ir.wrapThreeByteGlobals` (driver step 2d, after the overflow
fold) rewrites `@g = … constant T V` to `@g = … constant { T } { T V }`:

- A one-field struct has **the same size, alignment and bytes** as its field (DataLayout), and the
  field is at offset 0, so **the global's address is the field's address**.
- With **opaque pointers**, no use of `@g` names its value type: `load i21, ptr @g` reads the same
  bytes as before. Nothing else in the module changes.
- So the program is identical in memory. Fil-C still checks every access to `@g` with the same
  bounds (one 4-byte object), so **no safety check is removed or weakened**.
- Declarations (`external global i24`, no initializer) are left alone; the assertion needs an
  initializer to lay out, and a declaration's type must match its definer's.
- Idempotent: a wrapped global's type starts with `{`, which the matcher ignores.

**Ruled out.**

- ❌ **"`i2` tag fields in Zig's error unions and optionals"** (the first suspicion, 2026-09-30). A
  hand-written global `{ { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] }` compiles.
  Odd widths **inside** aggregates are fine.
- ❌ The remaining function body after the first reduction (`os.linux.x86_64.syscall4`). It was kept
  only because the reducer could not remove globals yet.
- ❌ Debug metadata: the reduction kept all of it, and the minimal repro has none.

**How it was found.** `tools/p2/llreduce.ts` (ddmin) first reduced functions only: 21,523 → 7,710
lines with one innocent function left. Extended 2026-10-01 to reduce **globals** too (an excluded
global becomes `@g = external global T`, so references stay valid): 320 units → 1 in 11 runs
for 22. The same run on 69 found the `<3 x i8>` (→ 1 unit in 23 runs). Then hand-written
16-line probes swept widths, kinds and positions until the rule was exact. **Lesson:** when a
reducer leaves something "innocent", the reducer is missing a unit type, not the bug.

**Recognising a relative.**

- Any **other** `FilPizlonator.cpp` assertion about a size (`Size`, `WordSize`, alignment) on a
  module that stock clang compiles: suspect a **global's value type** first. Grep the module's
  `^@` lines for scalar or vector types and test each odd size with a 16-line probe.
- If a future type triggers it (e.g. some 3-byte `half`-based shape, or a 3-byte scalar inside a
  context other than a global), extend `threeByteGlobal`'s type test. The wrap applies to any type.
- If a 5-, 6- or 7-byte scalar ever triggers it, the surmise above is wrong and the rule is about
  something else. Re-probe.

**Cost and exit.** No run-time cost (same bytes); a linear text scan at build time. Remove it when a
Fil-C release compiles `tools/p2/repro/filc-0.685-i21-global.ll`. Re-test that file at every Fil-C
upgrade (`upstream.md` upgrade procedure, stage A).

**Where.** `src/ir.zig` `wrapThreeByteGlobals` / `threeByteGlobal` / `intTypeBits` and the test
"3-byte globals are wrapped in a one-field struct"; `src/driver.zig` step 2d (`--verbose` prints
the count); repro `tools/p2/repro/filc-0.685-i21-global.ll` with notes in
`tools/p2/repro/README.md`; `known-issues.md` KI-18.

---

## KI-20 — `std.crypto.random` probes `madvise` with an invalid advice

**Symptom.** At run time, the first use of `std.crypto.random` (here a TLS client handshake):
`filc safety error: attempting to use unrecognized madvise advice -1.` then
`filc panic: thwarted a futile attempt to violate memory safety.` (exit 133). Trace:
`zsys_madvise` ← musl `__madvise` ← `posix.zig:7052 posix.madvise` ←
`tlcsprng.zig:100 crypto.tlcsprng.tlsCsprngFill` ← `Random.bytes` ← `crypto.tls.Client.init`.
Seen on `69_http-client` once KI-18 no longer stopped its build (ReleaseSafe and ReleaseSmall,
2026-10-01).

**Class.** Std behaviour that is legal natively, meeting a deliberate Fil-C policy. **Not a bug on
either side**, so not for `UPSTREAM-ISSUES.md`.

**Root cause, measured** (read in Zig 0.15.2's `lib/std/crypto/tlcsprng.zig`):

- When the OS has `fork` and no `arc4random`, and `std.options.crypto_fork_safety` is on (the
  default), std keeps its CSPRNG state in a page it wants wiped on `fork`
  (`MADV_WIPEONFORK = 18`, Linux 4.14+).
- Before using it, std checks for **QEMU user-mode emulation**, which accepts any `madvise` hint:
  it calls `posix.madvise(ptr, 0, 0xffffffff)` **on purpose** and expects `EINVAL` (`:97`–`:102`).
  The Zig comment says so: *"Check if this is the case by passing bogus parameters, we expect
  EINVAL as result."*
- Fil-C's `zsys_madvise` does not pass an unknown advice through to the kernel to get `EINVAL`. It
  **stops the program**, which is its general rule for arguments it cannot vet.
- musl has no `arc4random`, so `os_has_arc4random` is false and this path is the default under zilc.

**Why the workaround is correct.** The entry shim declares std's official option
`pub const std_options: std.Options = .{ .crypto_always_getrandom = true };`. Then
`tlsCsprngFill` returns at its second line, through `std.options.cryptoRandomSeed`
(`tlcsprng.defaultRandomSeed` → `posix.getrandom`, which calls either `std.c.getrandom` or the raw
`linux.getrandom` syscall depending on `std.c.versionCheck`; the raw one is routed through
`zilc_syscall` by KI-7's rewrite, so **both reach the kernel through Fil-C's checked libc**):

- The bytes still come from the **kernel CSPRNG**; nothing becomes weaker. If anything stronger:
  there is no user-space state to leak.
- **Fork safety is kept by construction**: no state exists to duplicate into a child. That is
  better than the rejected alternative, `crypto_fork_safety = false`, which would let a forked
  child repeat its parent's random stream.
- The `madvise` probe and the WIPEONFORK page (an `mmap` of its own) are never reached.
- **Cost:** one `getrandom` call per fill instead of a ChaCha step. Random fills are rare (key
  generation, TLS nonces), so it is negligible.
- ~~A user program that declares its own `std_options` is not affected either way~~ (true until
  2026-10-02). Since then both generated roots FORWARD a user file's own `std_options`, and force
  only this one field to `true`. So a user who explicitly writes
  `crypto_always_getrandom = false` gets `true` anyway: with `false`, the program would stop at
  its first random number. ✅ **Owner confirmed 2026-10-02**, with a stipulation: tell the user.
  So `zilc build` prints a `zilc: note:` when the root Zig file sets the field to anything but
  `true`, explaining the override and its reason (`setsGetrandomOff` / `noteForcedGetrandom` in
  `src/driver.zig`, unit-tested). The check is textual because Zig's default is `false`: in the
  compiled code an explicit `false` cannot be told from an absent setting. It is sound because
  std reads `std_options` only from the root file, which is the file zilc is given.

**Ruled out.** Patching `maybe_have_wipe_on_fork` to false in the std overlay: that falls back to
`pthread_atfork` plus user-space state, which is more moving parts, and an overlay patch where an
official option exists. Not tried, because the option is strictly simpler.

**Recognising a relative.** Any `filc safety error: … unrecognized … <arg>` from a `zsys_*`
function means **std passed a value Fil-C will not vet**, usually a probe or a feature test that
expects an error code natively. Read the std caller around the trace line. Look first for a
`std.Options` field or a root-module hook that skips the path (`std_options`, `os.heap`,
`panic`), then the std overlay.

**Cost and exit.** Negligible run-time cost. No exit needed. If Fil-C ever returns `EINVAL` for
unknown advice, the option can stay anyway.

**Where.** `src/driver.zig`, entry shim (`std_options`), commented. Library mode (C owns `main`):
✅ covered since 2026-10-02 by the library root (`library_shim`), with the other hooks.

---

## KI-4 — Fil-C's pass segfaults on Debug IR at `-O1` (and why Debug was at `-O0`)

**Symptom.** `clang -O1` on Zig Debug IR: `clang frontend command failed with exit code 139`
(segfault) while running `FilPizlonatorPass`; the same IR compiles at `-O0`. From 2026-09-23 until
2026-10-01 zilc therefore compiled Debug at `filc -O0`, which caused KI-19 (12 Debug programs
trapping on syscall pointers) and much of KI-22's Debug build time.

**Class.** Upstream defect, **inherited by Fil-C from LLVM's own `IndirectBrExpandPass`**, which has
the same code. It lies in a path clang never exercises; Zig does.

**Root cause, measured** (patched clang built with debug info + gdb, then the pass source,
2026-10-01):

- Crash site: `prepare()` (`FilPizlonator.cpp` ~16004) → `SplitAllCriticalEdges` →
  `SplitKnownCriticalEdge` → `PHINode::setIncomingBlock(-1)`: a phi had no entry for one of its
  block's predecessors.
- The dumped block showed why: phis Fil-C added matched the predecessors (`switch_bb.Case1_crit_edge`,
  `Else7`, `Block8`, `Case11`), but the phi `%.1445` still named `Then`, `Then11`, `Then35`,
  `Then38`, which were no longer predecessors.
- `lowerIndirectBrForFunction` (a copy of `IndirectBrExpandPass`): with **two or more**
  `indirectbr`s in a function it creates one shared `switch_bb`, redirects every `indirectbr` to
  it, and **never updates the destination blocks' phis**.
- **Why clang never hits it:** clang compiles every computed `goto` in a function through ONE
  shared `indirectbr` block, so the merged path never runs. **Zig emits one `indirectbr` per
  `continue :label`** (labeled-switch dispatch; std's `compress.flate`, and std code present in
  every Debug program: 6 per program in the corpus, 8 in `69`).
- **Why only Debug:** Zig's Release IR (unoptimized route) has **no** `indirectbr`; Debug IR does.
- **Why only `-O1`:** at `-O1`, Fil-C promotes stack slots to SSA (its `filc-optimize` step) before
  this lowering, which creates the phis that go stale. At `-O0` the destinations have no phis.

**The fix, and a first attempt that was wrong.** Both are patches in `tools/filc/patch-pass.ts`.

- ❌ **First attempt (discarded):** keep the shared `switch_bb` and route each stale phi value
  through a new phi in it. It stopped the segfault but tripped the pass's liveness assertion
  (`Unexpected live: … getelementptr`, `isa<Argument>(V)`), because **merging changes
  dominance**: every destination becomes reachable from EVERY `indirectbr` site, so a value that
  dominated a destination before no longer does. No phi repair can fix that.
- ✅ **The fix:** with several `indirectbr`s, lower **each one in place into its own `switch`** over
  its own address-taken destinations, using the same global block numbering. Every CFG edge is
  preserved, so phis and dominance stay valid. Only edges to never-address-taken blocks and
  duplicate edges are dropped, together with their phi entries. **The single-`indirectbr` path is
  untouched, so no C output changes**, and at `-O0` (no phis) the result is equivalent.

**Result.** The KI-4 repro compiles at `-O1`. Debug at `-O1`: **all 13 failing Debug programs
behave as designed** (the 12 KI-19 traps are gone; `76_signals` waits as designed), and Debug `69`
compiles in 68 s and runs, where it used to time out at 30 min. The driver now compiles Debug at
`-O1` like every mode, and if Fil-C fails on a Debug build it says the patched clang is needed.

**Recognising a relative.** A Fil-C crash in `SplitCriticalEdge`/phi code, or a liveness
assertion about a value "live at entry": suspect a CFG rewrite that **merged edges**. Look for Zig
constructs clang never emits (`indirectbr` per `continue :label`). Debug-only failures: compare
the Debug IR with the Release IR first. Here Zig's Debug IR has `indirectbr` and the Release IR
has none.

**Cost and exit.** Needs the patched clang (`tools/filc/`). Remove when Fil-C (or LLVM's
`IndirectBrExpandPass`) handles several `indirectbr`s. Re-test the KI-4 repro at every Fil-C
upgrade.

**Where.** `tools/filc/patch-pass.ts` (edit "one switch per indirectbr"),
`third_party/filc-patches/zilc-filc-pass.patch`, `src/driver.zig` (`-O1` for every mode, and the
Debug hint), repro `tools/p2/repro/filc-0.685-O1-crash.ll`.

---

## KI-21 — std's stack-trace code compiled into every program (build time)

**Symptom.** Builds many times slower than native Zig: `62_directories` ReleaseSafe 40 s under
zilc vs 6.7 s natively, its IR 228k lines and 1,265 functions. Half of it is `debug.Dwarf`,
`debug.SelfInfo`, `compress.flate`, `sort.block` (sorting DWARF tables) and
`debug.FixedBufferReader`: std's DWARF unwinder and symbolizer.

**Class.** zilc's own gap, created by KI-17 (the unoptimized-IR route) together with KI-15.

**Root cause, measured** (IR caller analysis, 2026-10-01). KI-15 set `sys_can_stack_trace = false`,
but std tests it at RUN time. Two entry points keep the whole unwinder referenced:
`DebugAllocator` calls `debug.captureStackTrace` from `free`, `resize*` and `reportDoubleFree`
(with 0 frames), and `builtin.StackTrace.format` calls `getSelfDebugInfo` and `writeStackTrace`.
On the optimized route LLVM proved them dead and deleted them before Fil-C. On the unoptimized
route Fil-C instruments and compiles all of it, and Fil-C's code generation costs about 6× stock
LLVM's on the same IR (38.4 s vs 5.7 s for 62).

**Why the workaround is correct.** Two std-overlay patches (`src/stdpatch.zig`, overlay v4) put a
**comptime-known early return** at the top of both entry points:
`if (!sys_can_stack_trace) { stack_trace.index = 0; return; }` and
`if (!std.debug.sys_can_stack_trace) return writer.writeAll(…)`. Zig's semantic analysis stops at a
comptime-known `return`, so nothing after it is referenced or emitted. std uses this exact pattern
itself, in the same function (`if (builtin.os.tag == .freestanding) return;`, commented "avoid an
error … where it tries to call detectTTYConfig"). Behaviour is unchanged: the trace was already
empty, and a real walk would stop under Fil-C (KI-15).

**Result.** 62 ReleaseSafe 40 s → **8.0 s** (native 6.7 s); its IR 228k → 87k lines, 1,265 → 436
functions. It runs identically.

**Third route, Debug only (found 2026-10-01 evening).** `posix.unexpectedErrno` calls
`debug.dumpCurrentStackTrace` when std's "unexpected error tracing" is on, which is Debug. That
kept the whole unwinder, symbolizer and `compress.flate` in **every Debug program**: a trivial
program's Debug IR was 190,873 lines and 1,095 functions, 56k lines of them this code, plus 6
`indirectbr` (KI-4's trigger). Two more guards of the same kind (`dumpCurrentStackTraceToWriter`,
`dumpStackTrace`), overlay v5. **`04_constants` Debug: 9.9 s → 2.1 s** (IR 190k → 28k lines;
native Zig Debug with LLVM 1.1 s). Debug's "~5× Release" build time was this, not KI-22.

**Recognising a relative.** A zilc build much slower than native Zig: list the IR's lines by
namespace (`irstat.sh`-style awk over `^define`) and look for code that cannot run under zilc. Then
find who references it (callers of the namespace, from non-namespace functions). **Any std
behaviour we disable at run time must also be disabled at compile time**, or the unoptimized route
pays for it.

**Where.** `src/stdpatch.zig` (two patches, test "stack-trace entry points return before the
unwinder at compile time (KI-21)").

---

## KI-22 — Fil-C's frame-slot colouring is cubic on big Zig functions (build time, OPEN)

**Symptom.** `69_http-client` ReleaseSafe 132 s (native 20 s), 76% of it inside
`FilPizlonatorPass`. Debug (`filc -O0`) far worse: `crypto.tls.Client.init` alone ran 24 min
using 5.8 GB before it was stopped; the whole Debug build of 69 times out at 30 min.

**Class.** Upstream performance defect in Fil-C 0.685's pass, triggered by the shape of Zig's
unoptimized IR. Not fixed yet; options below.

**Root cause, measured** (time reports, synthetic scaling, gdb stack sampling and the pass source
at the binary's own commit `bb0d0a64`, 2026-10-01):

- Per function, the pass gives every pointer value the GC must see (escaping allocas and pointer
  SSA values) a frame slot (`FilPizlonator.cpp` ~2880–3076). It computes liveness (an iterative
  data flow copying an `unordered_set` per block), builds an **interference graph** (each
  definition × everything live), then **colours it greedily**: for each value, it tries
  `FrameIndex = 0, 1, 2, …` and **scans the whole adjacency set at each index**
  (lines 3054–3076).
- Zig's unoptimized IR puts **every local in an entry-block alloca, with no
  `llvm.lifetime.start/end`**. So every escaping alloca is live from function entry to its last
  use, they all interfere, and a function with N of them is a near-complete graph: the colouring
  costs about N³ hash lookups. `Client.init`: 100k lines, 912 allocas.
- gdb: **27 of 30 samples** at `-O1` were in that colouring loop (16 walking `Adjacency`, 11 in
  `FrameIndexMap` lookups). The same loop dominates at `-O0`.
- `-O0` is worse because Fil-C's own pre-pass clean-up (`filc-optimize`) only runs at `-O1`+ and
  cannot be forced on at `-O0`; without it there are more pointer values. For 62, the pass takes
  0.5 s at `-O1` and 3.6 s at `-O0`.
- Synthetic scaling at `-O1` (`scale2.ts`): N escaping allocas in one function: pass 0.08, 0.30,
  1.11, 4.67 s for N = 250…2000 (×4 per doubling). Calls alone: linear.

**Ruled out (each measured, so nobody re-tries them):** debug metadata (stripped: 116 s vs 117 s);
`llvm.assume` (120 s); Fil-C's DSE (`-filc-dse=false`: 108 s); check scheduling
(`-filc-optimize-checks`, `-filc-propagate-checks-backward`: 119–124 s, and slower builds overall);
the `-filc-inline-*` sub-passes (no effect at all: byte-identical objects); turning
`-filc-optimize` off (69: 172 s → **1,960 s**). **Splitting large basic blocks** (implemented and
measured, then removed): a synthetic single block of N stores IS quadratic at `-O0` (40k stores:
80 s vs 0.4 s in blocks of 16), but on 69 it changed nothing (131 s), because the real cost is the
colouring, and more blocks only make the liveness pass dearer.

**Specific to Fil-C, not to an LLVM version** (owner asked, 2026-10-01): the loop is in Fil-C's
own pass, which stock LLVM (and so Zig's bundled LLVM, any version) does not have. Plain Zig is
fast on the same code. **The trigger is Zig's IR shape, which does vary by Zig version:** measured
on one test module, Zig 0.16.0 still emits **no lifetime markers** and about **2× the allocas** of
0.15.2 (Debug 18,241 vs 9,202; ReleaseSafe 10,559 vs 4,755). So a 0.16 line would hit KI-22
harder. Re-check list: `ports/README.md`.

**Options (owner chose 2, then research 3; 2026-10-01):**

1. **Report upstream with a fix that changes no output.** Gather the neighbours' assigned indices
   once into a set or bitset, then take the lowest free index ≥ `NumSpecialFrameObjects`. The
   result is the same colouring (same order, same choice), so binaries stay byte-identical, at
   O(degree) per value instead of O(degree × colours). The same applies to the stack-aux colouring
   at lines 3146–3160.
2. **Build a patched Fil-C clang** with that fix. It works now and keeps output identical, but zilc
   has avoided building LLVM so far (hours; the owner's call).
3. ❌ **(Researched and rejected 2026-10-01: Fil-C erases escaping allocas' lifetime markers before
   liveness; see "Option 3 researched" below.)** **zilc inserts `llvm.lifetime.start` before each
   alloca's first use**, where that point dominates every use and lies in no loop. This shrinks the live ranges, so the graph is no longer
   a clique. It needs CFG, dominator and loop analysis in `src/ir.zig`, and a wrong marker
   miscompiles, so it carries the most risk.
4. **Accept it for now.** Typical programs are near native after KI-21; only functions with
   hundreds of escaping locals (TLS, big crypto) are slow, and Debug builds of them are impractical.

**Option 2, carried out (2026-10-01).** Fil-C's clang was built from the prebuilt's own commit with
the patch (`tools/filc/build-patched-clang.ts`; ~1 h; GCC 15.2 and CMake 4.2.3 from apt, Ninja
1.12.1 release binary). The version string matches the prebuilt exactly (the source remote must be
`git@github.com:…`, and the generated `VCSVersion.inc`/`VCSRevision.h` deleted to regenerate).
`69` at `-O1`: **112 s → 54 s** for Fil-C's clang alone.

**Option 3 researched and REJECTED (2026-10-01, owner asked to check its necessity after
option 2).**

- **Where the time is now** (`69` ReleaseSafe, patched clang, alone): zilc 55.9 s vs native Zig
  16.9 s. Fil-C's clang 55.4 s = pass **11.4 s** + LLVM's `-O1` optimizer ~18 s + code generation
  ~25 s. Stock clang on the same uninstrumented IR took ~15 s, so ~3× of the downstream work is
  the instrumentation's own size, inherent to Fil-C. Debug `69` is the same (54.5 s).
- **Inside the pass** (gdb with symbols, patched build): about 7 of 12 pass samples are in
  liveness and interference building (`FilPizlonator.cpp` 2970–2998), which is quadratic in
  simultaneously live pointers. That ~6–7 s (~12% of the build) is all that lifetime markers
  could ever have saved.
- **Why markers would not save even that:** `removeLifetimeIntrinsics()` **erases the lifetime
  markers of every ESCAPING alloca** before liveness runs, and keeps them only for non-escaping
  ones. The liveness and interference work tracks only escaping values (`LiveCast` returns null
  for anything else). So markers zilc inserted would be deleted before they could shorten any
  costly live range. **Option 3 cannot help build time.** It would also need CFG, dominator and
  loop analysis in `src/ir.zig`, with miscompile risk.
- **What did help instead:** the Debug-only std route above (KI-21, third route).
- **Levers that remain** (✅ **all three approved by the owner, 2026-10-01**; not started; next
  task):
  (a) split the module and run Fil-C's clang on the parts in parallel. Fil-C already compiles C
  one translation unit at a time, and 32 cores sit idle. (b) A faster interference build in the
  patched pass that produces the same graph. (c) Cache objects by IR hash for unchanged rebuilds.
  ✅ **(a) done 2026-10-02**, as the code-generation-only split below. ✅ **(b) and (c) done the
  same day** (sections after (a)).

**Lever (a) carried out (2026-10-02): split CODE GENERATION only, after the whole-module pass.**

- **What zilc does now** (`filcCompile` in `src/driver.zig`, for Fil-C-dialect IR ≥ 4 MB, `-j` /
  `ZILC_JOBS` jobs, default = cores up to 16, `-j 1` = off):
  1. Fil-C's clang runs the pass and the `-O1` optimizer on the WHOLE module and stops at bitcode:
     `-c -emit-llvm -Xclang -emit-llvm-uselists`.
  2. zilc's mode of `llvm-split` (`tools/filc/patch-split.ts`, installed next to clang) writes
     each part, one process per part, in parallel: `-j N --zilc-part=I --zilc-keep-global=FILE`.
  3. Fil-C's clang generates each part's code in parallel: `-Xclang -disable-llvm-passes -c -x ir`.
     This skips the IR pipeline (no pass, no optimizer) and keeps clang's own code-generation
     settings, so there is nothing to match by hand as there would be with `llc`.
  4. `ld -r` joins the parts; `objcopy --keep-global-symbols=FILE` makes local again every symbol
     the input did not define as global.
  - The splitter exits 2 on a module shape it does not handle (ifuncs, comdats, unnamed locals,
    a global named with whitespace, no globals at all); zilc then generates the code whole from
    the step-1 bitcode. No `llvm-split` next to clang = the old single clang run.
- **Result** (`69` ReleaseSafe, through the driver, alone): **60.6 s → 43.9 s**; `62`: 7.0 s →
  5.0 s. Step 1 is now most of it (~34 s of `69`): code generation went from ~22 s to ~7 s, bounded
  by `crypto.tls.Client.init` (100k IR lines, one function, cannot be split). Lever (b) attacks
  step 1.
- **Same code, checked like for like:** the parts' functions against the unsplit compile of the
  SAME step-1 bitcode: **2,840 of 2,840 functions identical** (normalized disassembly, alignment
  padding after each function excluded, since it depends on the next function's position), same
  global definitions (name, binding, visibility), same undefined references, same stripped size.
  Program output identical. Only the unstripped file grows (8.2 → 10.4 MB): each part carries
  its own DWARF copy of the types it uses. Script: this session's scratchpad `cgsplit2.sh` +
  `cmpfuncs.ts`.
- **Why "same as one clang run" cannot be the test for `62`/`69`:** the step-1 process lays out
  the pass's hash tables differently from a one-step run, so the PASS'S output differs (the
  ASLR finding above, extended). Proof: a plain one-step build of `62` with only `-ftime-report`
  added (timers, nothing else) already changes the object; the deterministic control
  (`allocas2000`) does not. On every input whose pass output IS deterministic (the gate's C
  examples, `zilc_syscall.c`, the KI-4 repro, the 2,000-alloca stress), one-step and two-step
  objects are **byte-identical**.

**Why each piece is the way it is (the workarounds inside lever (a)):**

- ❌ **Split BEFORE the pass (rejected by the owner, 2026-10-02: bloat).** Measured first: stock
  `llvm-split -j 16` on the Fil-C-dialect IR, then the full clang on each part: clang stage 55 s →
  ~24 s, but the stripped binary **+37%** (6.5 → 8.9 MB), because the optimizer can no longer
  inline across parts (each part is a separate C file, in effect). Owner: *"What is another option
  that doesn't bloat the resulting binary, is reasonably speedy and maintains fidelity?"*
- **`datalayout_after_filc` (seen only on the rejected route, kept for the record).** Stock
  llvm-split drops Fil-C's second data layout: `CloneModule` does not copy the Fil-C-only
  `Module` field, and bitcode has no record for it (the line exists only in Fil-C's text printer
  and parser). The parts crash Fil-C's clang with the "Target-incompatible DataLayout"
  assertion. After the pass the module no longer needs it, which is one reason to split there.
- 🔑 **Use-list order decides x86 code generation (measured).** Stock llvm-split CLONES each part;
  cloning rebuilds every value's use-list in a new order, and 80+ of `69`'s functions came out
  with different register allocation. Same IR, same linkage: the function's IR body was identical
  and changing `internal` → `hidden` on the whole module changed nothing; but the SAME module
  read from text instead of bitcode (text does not keep use-list order) changed 13 of 797
  functions. Hence: step 1 writes the use-lists (`-emit-llvm-uselists`), and zilc's splitter
  makes each part by DELETING the bodies it does not own (`deleteBody`), which keeps the
  surviving uses in their original order, and writes with use-list order preserved. Verified
  with `llvm-extract` on one function before writing the splitter.
- **Unused hidden declarations (`TLS reference … mismatches non-TLS reference`).** Every part
  declares every global. An unused declaration with HIDDEN visibility is still emitted as an
  undefined symbol, untyped (NOTYPE). Fil-C reads thread-locals directly
  (`@pizlonatedTP_Thread.LinuxThreadImpl.tls_thread_id = … thread_local …`), so GNU ld saw an
  untyped reference against the TLS definition in another part and refused. The splitter drops
  unused declarations; an unused declaration emits no code.
- **Locals used across parts.** Made `hidden` external with `dso_local` in every part (the
  plan is computed identically in every process: largest function first, to the least-loaded
  part, ties in module order; global variables in part 0). Linkage does not change code
  generation (measured above). After `ld -r`, `objcopy --keep-global-symbols` makes them local
  again, fed the input's OWN global definitions, not the list of exposed locals: (1) Zig names
  contain spaces (`crypto.sha2.Sha2x64(.{ 7640… })`), and objcopy's symbol files end a name at
  whitespace ("Ignoring rubbish found on this line"); the input's globals are few (49 in `69`)
  and plain, and the splitter refuses a module whose globals are not. (2) Not
  `--localize-hidden`: Fil-C's output has WEAK HIDDEN globals of its own (25 in `69`,
  `pizlonatedFI27932_write` etc.), which must stay global. (3) An EMPTY keep list means "no list"
  to objcopy, so the splitter refuses a module with no globals.
- **`ld -r` directly, not `clang -r`.** Fil-C's clang driver adds `filc_mincrt.o` even to
  `-r -nostdlib`, which put a second `main` into the joined object. zilc asks clang for its
  linker (`-print-prog-name=ld`) and runs it.
- **Memory.** Per process on `69`: splitter ~270 MB, code generation ≤ 740 MB, so 16 jobs stay
  under ~8 GB. The corpus script, which already runs 12 builds at once, sets `ZILC_JOBS=4`.

**Cost and exit.** Cost: an extra bitcode write and N parses of it (~2 s on `69`), larger
unstripped binaries (debug info). Below 4 MB of IR it is off (the processes cost more than they
save). Exit: none needed; it is how a parallel build works. If Fil-C's pass became deterministic,
one-step and two-step objects could be compared byte for byte on every input.

**Recognising a relative.** Any future "same IR, different machine code" puzzle: check use-list
order first (text vs bitcode, cloned vs original module). Any "TLS mismatches non-TLS": look for
an unused hidden declaration of a thread-local.

**Lever (b) carried out (2026-10-02): the pass's interference graph over dense ids.**

- **Where the pass's time was** (gdb samples of the whole-module step on `69`, after lever (a);
  the pass was 11.2 s of a 31 s step, the rest LLVM's own `-O1` passes): 17 of 44 pass samples
  in the interference build's hash-set inserts (`FilPizlonator.cpp` 2997–2998 at `bb0d0a64`),
  6 in the colouring's `FrameIndexMap` lookups per neighbour (3072–3073), 4 in `EraseIf`
  (1033–1035), 3 in liveness (2970).
- **The change** (`patch-pass.ts`, edit "interference graph over dense ids", plus the colouring
  edit): every value gets a number and one id per pointer slot; the live set during the
  interference walk is a dense set of value numbers (O(1) insert and erase); a neighbour list is
  a plain `std::vector<uint32_t>`; the colouring reads a dense "index held" array that mirrors
  `FrameIndexMap`. Duplicate neighbours are allowed: the colouring only asks which indices the
  neighbours hold, and its `Taken` vector, sized by the list length, still has a free slot in
  range. Liveness itself (the fixpoint) is unchanged.
- **Why it is the same graph, and the details that keep it so:**
  - The def × live loop counts a live value's slots with `countPtrsForValue(LV)`, but the
    argument loops count an argument's with `countPtrs(type)`. The two can differ for a byval
    argument, so each value's id range covers the larger, and each loop uses the count the
    original used.
  - `FrameIndexMap` already holds `Ignored` entries (index 0) when the colouring starts, and the
    original sees them as taken indices, so the dense array is filled from `FrameIndexMap`, not
    started empty.
  - `ZILC_VERIFY_INTERFERENCE=1` also runs the original construction, verbatim, and aborts unless
    every value's neighbour SET is equal (both directions: no value missing from either graph).
    With `ZILC_VERIFY_COLOURING=1` the original colouring search runs too, reading
    `FrameIndexMap` itself, which also checks the mirror array. **Both on, the whole corpus in
    all four modes: no difference** (the verified `69` builds took 154–431 s, proof the original
    code ran).
- **Result:** the pass on `69` **11.2 s → 4.3 s**; the whole-module step 31.2 → 24.7 s, peak
  ~1.0 GB. Through the driver: `69` ReleaseSafe **43.9 → 35.9 s** (split), `-j 1` 60.6 → 49.9 s.
  The 2,000-alloca stress test: unchanged (13.2 vs 13.1 s; its pass time is elsewhere). What is
  left in the pass has no hotspot (a re-profile spreads 18 samples over 14 places); the rest of
  the step is LLVM's own optimizer (SROA 4.2 s, InstCombine 3.0 s, …), which would change the
  output if touched.
- ⚠️ **Whitespace trap in the edit's original text:** `FilPizlonator.cpp` has a line of six spaces
  after `Live = LiveAtTail[BB];`. The file editor trimmed it from the edit, and the patch failed
  with "original found 0 times". Restored with `sed`, and marked in `patch-pass.ts`.
- `build-patched-clang.ts` now applies each edit script to a fresh copy of the PRISTINE file
  (`git show $SHA:path`) and replaces the tree's file only if the result differs: changing an
  edit's replacement text used to require resetting the file by hand, and rewriting an unchanged
  file made ninja rebuild clang.

**Lever (c) carried out (2026-10-02): the object cache.**

- **What:** before running Fil-C's clang on a module, zilc looks for
  `<cache>/objects/<key>.o` (cache = `$ZILC_CACHE_DIR`, else `$XDG_CACHE_HOME/zilc`, else
  `~/.cache/zilc`, the same root as the std overlay) and copies it on a hit; on a miss it compiles
  and stores the object (written through a temporary and renamed, so never half an object).
  `--no-cache` / `ZILC_CACHE=0` turn it off. `cacheLookup`, `objectKey` in `src/driver.zig`.
- **The key** (Blake3): the final Fil-C-dialect IR, zilc's version, a tag for zilc's clang
  command lines (`filc_commands_tag`: bump it when they change), the plan (parts count), and the
  IDENTITY of the clang and `llvm-split` binaries that would run: resolved path (PATH searched
  like the OS), size, mtime, inode. **Not `clang --version`:** the patched clang deliberately
  keeps the prebuilt's exact version string, so a rebuilt compiler would be invisible to it.
- **Why reuse is faithful:** Fil-C's own output is not reproducible run to run (pass ordered by
  heap addresses, above), so an earlier object for byte-identical input is as faithful as a
  fresh compile; the program it produces passed the same checks.
- **Result** (same source, same output path, built twice): `69` **36.0 → 2.3 s**, `62` 5.4 →
  0.5 s. Zig's IR is identical run to run (checked).
- **Limits:** (1) The key includes the OUTPUT path in effect: the entry shim lives in
  `<output>.zilc-tmp/`, and its path is in the IR's debug info, so the same program built to a
  different output path misses (seen in the first test, which used a new directory per run).
  (2) No automatic eviction: each entry is a full object (`69` ~11 MB). `zilc --clean-cache`
  (owner asked for it, 2026-10-02) deletes `<cache>/objects` and reports the files and MB freed;
  it keeps the std overlay, which every Zig build needs and would only recreate.
  (3) The corpus script sets `ZILC_CACHE=0` so its recorded build times stay real compiles.

**How the patch was proved output-identical, and why byte comparison could not do it:**

- 🔑 **Fil-C 0.685 is NOT reproducible run to run.** The SAME prebuilt clang compiling the SAME
  `62` IR twice gives different objects with ASLR on (Linux's default), and identical ones under
  `setarch -R`. The pass iterates hash tables keyed by pointer addresses, so heap addresses decide
  the emitted order. ⚠️ **This bears on the owner's FIDELITY FIRST goal** (user binaries
  byte-identical to upstream, `roadmap.md` P3): upstream itself is only reproducible with ASLR
  off, and probably only for one exact build of the compiler. Any byte-identity check must run
  with `setarch -R`, and between two DIFFERENT compiler binaries it can still differ on large
  inputs (heap layout differs).
- Under those rules (`tools/filc/compare-clangs.ts`), prebuilt vs patched is **identical** for the
  gate's C examples, `zilc_syscall.c`, the KI-18 repro (both assert) and the 2,000-alloca stress
  test at `-O0` and `-O1`, but **different** for `62` and `69`: two different binaries.
- So equivalence is checked **inside one run**: with `ZILC_VERIFY_COLOURING=1`, the patched pass
  also runs the original search for every frame slot and aborts on any difference. It passed on
  the stress test, `62` (`-O0`, `-O1`) and `69` (`-O1`, where it restored the original cost:
  108 s, proof it really ran), then on the whole corpus in all 4 modes (results in `testing.md`).

**Where.** Measurement scripts: this session's scratchpad (`scale.ts`, `scale2.ts`, `split.ts`,
`sample.sh` + `sampler.py`, gdb from `apt-get download` into `~/zilc-work/tools/gdb`, needs
`LD_LIBRARY_PATH`). Pass source: `~/zilc-work/filc-src/FilPizlonator.cpp` (reading the pass is
allowed, owner 2026-10-01).

---

## Machine setup — Fil-C's kernel-header links (`os-include`), 2026-10-05

**Symptom.** `fatal error: 'asm/types.h' file not found`, included from
`pizfix/os-include/linux/types.h`, for any C file that includes `<linux/futex.h>`,
`<linux/seccomp.h>` or another kernel header reaching `<asm/types.h>`.

**Class.** System setup (this machine), not a Fil-C or zilc defect.

**Root cause, measured.** Fil-C's prebuilt does not ship kernel headers. Its `setup.sh`, run once
after unpacking, links `pizfix/os-include/{linux,asm,asm-generic}` to the host's `/usr/include`,
choosing `asm` = `/usr/include/x86_64-linux-gnu/asm` **if it exists**, else `/usr/include/asm`.
Here setup.sh ran before `build-essential` (and with it `linux-libc-dev`) was installed, so `asm`
pointed at `/usr/include/asm`, which Ubuntu does not have: a dangling link. zilc's patched tree is a
copy of the prebuilt, so it inherited the link, and so does the archive in `toolchain/`.

**Why the fix is correct.** `tools/filc/fix-os-include.ts` re-applies setup.sh's own rule against
the machine as it is now; nothing else in the tree changes. `build-patched-clang.ts` and
`restore-patched-clang.ts` run it after installing, so a restored archive is repaired on the
machine it lands on; `check-toolchain.ts` reports a dangling link (`BROKEN`).

**How it was found.** Fil-C's own test suite (`tools/filc/run-filc-tests.ts`): 9 tests failed with
BOTH the stock and the patched clang, which pointed away from zilc's patches and at the setup. No
zilc test had hit it: the corpus and gate include no kernel headers.

**Recognising a relative.** A failure shared by the stock and the patched compiler is the
environment, not zilc's patches: look at links and paths outside the compiler first.

---

## Earlier workarounds (short form; expand to the full template when next touched)

- ~~**KI-4, Debug compiled at `filc -O0`.**~~ **Superseded 2026-10-01** by the KI-4 patch (full entry above); Debug is now at `-O1`. *Original why:* Fil-C's pass segfaults on Zig's Debug IR at
  `-O1`/`-O2` (reduced to 8 `std.compress.flate` functions, `tools/p2/repro/`). Upstream defect, F1.
  *Cost:* no inlining in Debug, which also exposes KI-13 #2 and KI-19. *Exit:* the repro compiles at
  `-O1`.
- **KI-4, the two-line data-layout rewrite** (`ir.toFilCDialect`). *Why:* Fil-C's LLVM is a dialect:
  `ni:0` on address space 0 plus `datalayout_after_filc`. Stock IR lacks both. System limitation.
- **KI-5, generated C-ABI entry shim.** *Why:* `start.zig` forges pointers from integers
  (`@ptrFromInt(getauxval(AT_PHDR))`), which InvisiCap forbids by design. F2. Also hosts the panic
  handler and the `page_allocator` hook. Since 2026-10-02 the hooks live in `shim_hooks`, shared with a LIBRARY root for C-owns-`main` builds, and a user file's own `panic`/`os`/`std_options` are honoured (only `crypto_always_getrandom` is forced).
- **KI-6, target `x86_64-linux-musl`.** *Why:* Fil-C's libc is musl; gnu-target Zig emits `*64`
  glibc names. F4.
- **KI-7, raw `syscall` asm → `zilc_syscall`** (`ir.rewriteSyscalls`). *Why:* std makes raw syscalls
  even with `-lc`; Fil-C refuses inline asm, and a raw blocking syscall would also stall the GC
  (FUGC needs an exit before blocking). The helper goes through Fil-C's checked `syscall()`. F3.
- **KI-8, `-fno-stack-check` in every mode.** *Why:* `__zig_probe_stack` lives in compiler-rt, which
  never goes through the pass. Safe because Fil-C checks the stack at every function entry. F4.
- **KI-9, f128 compiler-rt through the pass.** *Why:* the helpers are not in Fil-C's libc; they are
  compiled as checked code, with every other export internalized so they cannot replace Fil-C's
  libm. F4.
- **KI-11, std overlay backport of 0.16.0 `findSentinel`.** *Why:* 0.15.2's SIMD scan reads past the
  object (legal natively within a page). std has no hook for it. F5.
- **KI-12, `root.os.heap.page_allocator = c_allocator`.** *Why:* `PageAllocator`'s `mmap` hint is a
  pointer at an object's upper bound. F5.
- **KI-13, overflow fold + `fromPage` patch.** *Why:* Fil-C recovers capabilities only through plain
  integer instructions; `extractvalue` of `*.with.overflow` and integer parameters start at BOTTOM.
  Field 0 is the identical value, and the overflow branch is untouched. F2.
- **KI-14, `-fno-valgrind`.** *Why:* Valgrind client requests are inline asm; they are no-ops unless
  run under Valgrind. F3.
- **KI-15, `sys_can_stack_trace = false` in the overlay.** *Why:* native stack walking reads raw
  frame pointers and probes with `process_vm_readv`; it can never carry capabilities. Fil-C gives
  its own traces. F3/F2.
- **KI-17, Zig's unoptimized IR** (`--verbose-llvm-ir -fllvm`). *Why:* `-femit-llvm-ir` is
  post-optimisation under an integral layout, so LLVM had already turned pointer loads into
  integers. F2. Side effect: exposed KI-18 (globals no longer folded away).
