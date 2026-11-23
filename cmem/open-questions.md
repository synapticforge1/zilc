# open-questions.md — questions to settle with the owner (split from design-decisions.md 2026-11-23)

## ❓ Open questions — to settle with the owner

These shape everything else. Listed roughly in order of how much they constrain the rest.

1. **How does the pass get into Zig?** ✅ **SETTLED BY EXPERIMENT 2026-09-23 — (c) wins.**
   - ✅ **(c) Wrapper driver.** Stock `zig` emits IR; the driver rewrites `target datalayout` to
     Fil-C's `ni:0` form and adds `target datalayout_after_filc`; Fil-C's clang runs the pass and
     links. **Verified end to end**, Zig ⇄ C, panic located in the Zig source (`roadmap.md` P2).
     ⚠️ Limits today: Release modes only (KI-4 reversal), C-ABI `main` only (KI-5), musl only (KI-6).
   - 🔒 (a) **Build Zig against Fil-C's LLVM fork.** Held in reserve. It is what Debug-mode support
     or a real `zilc` Zig _target_ may eventually require — but it is no longer the entry price.
   - ❌ (b) **LLVM pass plugin in a stock LLVM.** Still impossible: stock LLVM rejects `ni:0` and
     does not know `datalayout_after_filc` (KI-4).
2. **LLVM version skew.** ✅ _Settled 2026-09-18 (owner)._ zilc follows Fil-C's LLVM version and
   does not port the pass itself. Zig 0.15.2 (LLVM 20) is used until Fil-C moves to a clang that
   Zig 0.16.0 covers (LLVM 21), and the conversion happens then. See the decision table above.
3. 🔁 **MOOT FOR zilc since 2026-10-27** (P3 moved to zailc; zilc writes no runtime — top row).
   Kept for zailc. Was: ✅ **SETTLED 2026-10-01: NEW ZIG CODE, LICENCE-COMPLIANT, READING ALLOWED** (owner: "The
   intent has always been to comply with the Fil-C licensing parts. That is why we have been
   keeping track of the workarounds and issues that we are finding."). The Zig runtime is written
   as new Zig code, Fil-C's source (pass AND runtime) may be read to understand it, and wherever
   Fil-C code or its design is adapted, the licence is complied with: an Adoption Checklist and
   ledger entry in `third_party/LICENSES.md`, and, for runtime code, the **runtime-linking rule**
   (BSD-2-Clause notices accompany user binaries, `licensing.md`). The 2026-09-30 "clean-room"
   reading below is **superseded**; it was this agent's strict interpretation. History follows.
   **Runtime: port or rewrite?** Porting `libpas`/`filc_runtime.c` to Zig is faster but carries
   BSD-2-Clause into every user binary (`licensing.md`). A clean-room Zig runtime avoids that but is
   far more work. 🔭 **Evidence for clean room (2026-09-30 scoping):** Fil-C's runtime ABI (calling
   convention, function objects, header word, thread layout, linking) was reconstructed **entirely
   from the pass's output, public headers and binaries**, without reading runtime source
   (`filc-abi.md`). The remaining gaps look answerable from upstream's design docs. So a clean-room
   runtime has a workable spec to build from. ⚠️ **Must be settled before the first line of runtime code** (2026-09-30), and
   that includes the `zsys_write` spike if it goes beyond calling Fil-C's own helpers. Either way
   the Zig runtime must match Fil-C 0.685's object and capability layout **exactly**, because the
   pass inlines fast-path checks that read it directly. That makes the layout a version-pinned
   ABI, to re-check at every upstream sync.
4. 🔁 **RE-SETTLED 2026-10-27 (owner): zilc is Linux x86_64 only, worked in WSL or Linux; the
   cross-platform part is zailc's** (decision table, top row). The analysis below is kept as the
   record zailc inherits; for zilc only Linux x86_64 applies (aarch64 Linux included in "not zilc's"). Was: ✅ **SETTLED 2026-09-30 (owner):
   Linux, macOS and Windows, on every currently prevalent processor; then iOS; Android later.** The scope work comes before publishing (`roadmap.md` P6).
   ✅ **Processors confirmed (owner, 2026-09-30): x86_64 and aarch64 (arm64)** on each OS, which covers
   Linux servers and desktops, Intel and Apple-silicon Macs, and Windows on x64 and ARM.
   **riscv64: out of scope for now** ("a low interest item"). It runs mainly on Linux (Android is in
   progress; no macOS, iOS or Windows), and Fil-C has no riscv64 build. Candidate for later, on the
   Linux row only, once the clean-room runtime exists.
   **Platform analysis** (Linux x86_64 is still the only working target, developed in WSL2, KI-1).
   How far other platforms can go, as analysed with the owner 2026-09-30:
   - **What Zig's portability covers:** the runtime (garbage collector, capabilities, safepoints). It
     needs threads, atomics, memory mapping, thread-local storage and a clock, all of which Zig's
     std provides on every major OS. FUGC finds pointers through safepoints and stack maps the pass
     inserts, not through OS signals, so it ports well.
   - **What it does not cover:** the checked wrappers at the OS boundary (Zig knows _how_ to call
     each OS but checks nothing), and a safe libc (musl is Linux-only; Windows' and macOS's C
     runtimes are closed or system-bound and cannot be compiled with the pass).
   - **No Zig fork is needed:** the pass renames every symbol `pizlonated_<name>`, so every OS
     entry point becomes a link-time hook. A Windows Zig program's `NtCreateFile` becomes
     `pizlonated_NtCreateFile`, which the runtime supplies. So the wrappers needed are exactly the
     OS functions Zig's std references for each target, a list that can be counted.
   - **Proposed scope:** _safe Zig on the major 64-bit OSes (LLVM backend), safe C on Linux first._
     Out of scope until examined: 32-bit, freestanding/embedded, wasm, Zig's non-LLVM backends.
   - **Expected trouble:** every OS layer in std that builds pointers from integers is a KI-5
     repeat. Windows std reads its thread environment block through inline asm and `@ptrFromInt`.
   - **Order:** Linux ARM64 (Fil-C supports it upstream) → P3 on Linux → count std's OS functions
     for Windows and macOS → the first non-Linux target, Zig code only (`roadmap.md` P6).
5. **Zig-language semantics.** ✅ _Settled 2026-09-18._ The first milestone includes Zig **as a
   source language** from the start, via the existing Fil-C pass (see the milestone decision
   above). It is not C-only. Since GIMSO accepts any LLVM IR, putting Zig first is how the premise
   gets tested.
6. ✅ **SETTLED 2026-10-01 (owner): a reference clone, as in binaryen-ts.** `upstream/fil-c/` is a
   plain, gitignored, read-only clone of the `deluge` branch, never built, kept up to date and
   monitored for changes (`tools/upstream/check-upstream.ts`). It's the reference for comparisons
   with zilc's modifications. Not a subtree, submodule, fork or vendored copy. zilc's own changes
   to Fil-C stay as the patch in `third_party/filc-patches/` and the edit script in `tools/filc/`.
   Details: `upstream.md` "The `upstream/` reference folder".
