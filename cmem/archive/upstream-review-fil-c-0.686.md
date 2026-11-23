# Review of Fil-C 0.686 — archived 2026-11-23 from upstream.md

### 📋 Review of Fil-C 0.686 (2026-10-05; owner: "do the upstream review and include it in the release")

`v0.686` = `163fae5` (2026-10-04) = upstream's head that day. **Same LLVM: 20.1.8** (the version
file is unchanged; only 17 files under `llvm/` and `clang/` changed: Fil-C's pass, and 16 in Clang's
C/C++ front end and driver, which Zig's IR does not pass through, except `BackendUtil.cpp`, which
now runs LLVM's coroutine lowering before Fil-C's pass, a no-op on IR without coroutines). Fil-C's
LLVM fork is now the `fil-c` repo (was `llvm-project-deluge`; same history).

The 10 commits to `FilPizlonator.cpp`, oldest first:

- `1bb4c53`, `57c71fa` — stack checks under the large code model (+PIC)
  - for zilc: not used (Zig, zilc: small model)
- `886e4bd` (#312) — GC fences: ARM64 weak loads; a store-store fence after inline allocation (`dmb ishst` on ARM64, an empty compiler barrier on x86)
  - for zilc: relevant, small: stops the COMPILER moving a new object's initialising stores past its publication
- `47a39b2` (#325) — ARM `hint` intrinsic allowed
  - for zilc: not x86
- `097f7b7` — always-live explicit stack auxes (locals without lifetime markers) get their own GC slots; before, they shared ONE and the collector saw only one
  - for zilc: **relevant**: Zig's IR has NO lifetime markers. A Zig port of upstream's reproducer
    did not fail on 0.685 (`bad = 0`, all modes, GC stress), but the shape is Zig's. It inserts
    edges just before zilc's stack-aux colouring edit, which still applies
- `26a97be` — C++20 coroutines; `musttail` honoured when the caller roots every pointer argument
  - for zilc: **relevant, MEASURED**: Zig's `@call(.always_tail, …)` emits `musttail`. 10 million tail calls: **0.685 → `filc safety error: stack overflow`; 0.686 → completes**, Debug and ReleaseSafe
- `006ab97` + `81c1c3f` — misaligned constant pointers, then reverted
  - for zilc: no net change
- `635e0b7` — `setjmp` recognised by name (`-fno-builtin`); C common symbols → weak
  - for zilc: C inputs with unusual flags only
- `45adc76` — `zunsafe_call` only with `-yolo-assembler`
  - for zilc: a safety tightening; Zig does not use it

Other watched files: `configure_llvm.sh` (cosmo aarch64, not our configuration), `libpas/common.sh`
(cross builds added and reverted: no net change), `filc/include/stdfil.h` (versioning, a doc change),
`filc/run-tests` (cosmo support, an asm gate, glibc fenv; zilc's Deno port already follows 0.686's).

**Still in stock 0.686** (zilc's fixes stay): KI-4 (the `indirectbr` crash on Debug IR) and KI-18 (the
assertion on 3-byte globals); both repros fail on the 0.686 prebuilt exactly as on 0.685.

**Decision (owner): move the release to 0.686.** Done the same day: prebuilt installed (sha256
`60bfbe8e…`), source moved to `163fae5`, the patched clang rebuilt with zilc's 8 edits unchanged
(its version string equals the prebuilt's), and zilc re-verified (`testing.md`). Marked reviewed.
