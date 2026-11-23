# workarounds-filc-pass.md — workarounds for Fil-C's pass and std under it (split from workarounds.md 2026-11-23)

## KI-18 — globals with a 3-byte value type

**Symptom.** Fil-C's clang aborts (exit 134, the driver reports `clang frontend command failed with
exit code 134`):
`FilPizlonator.cpp:16714: void {anonymous}::Pizlonator::run(): Assertion '!(CSize % WordSize)' failed.`
Seen on `22_strings-and-runes` and `69_http-client`, in **every** mode, only on the unoptimized IR
route (KI-17).

**Still needed on Fil-C 0.686 (checked 2026-10-05).** Stock 0.686 still fails the same assertion
on the saved repro (`tools/p2/repro/filc-0.685-i21-global.ll`), so this workaround stays
(`upstream.md` "Review of Fil-C 0.686").

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
  The Zig comment says so: _"Check if this is the case by passing bogus parameters, we expect
  EINVAL as result."_
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

**Still needed on Fil-C 0.686 (checked 2026-10-05).** Stock 0.686 still crashes on the saved repro
(`tools/p2/repro/filc-0.685-O1-crash.ll`: `Stack dump`, exit 1), so the patched `indirectbr` lowering
stays. Its edit applied to 0.686 unchanged (only the line offsets moved).

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
