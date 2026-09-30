# Design Decisions & Invariants

## Decisions made

| Date | Decision | Why |
| --- | --- | --- |
| 2026-09-18 | Project layout and `cmem/` policy mirror wazmrt | Owner request; proven structure |
| 2026-09-18 | License `Apache-2.0 WITH LLVM-exception OR MIT` | Compatible with all three upstreams; see `licensing.md` |
| ~~2026-09-18~~ | ~~Target Zig **0.16.0**~~. **Superseded the same day**, see the full-compatibility row below | Was: installed toolchain; matched wazmrt |
| 2026-09-18 | Upstream = Fil-C `deluge` branch; not fetched into this repo yet | The Fil-C tree is a full llvm-project fork (multi-GB). How to consume it is an open question below |
| 2026-09-18 | **First milestone (owner-agreed):** a Zig program plus a C library, compiled through Fil-C's *existing* pass and runtime, panics correctly on OOB/UAF | Tests the premise (Zig IR survives GIMSO) before any zilc code. The Zig runtime rewrite and C++ come later |
| ~~2026-09-18~~ | ~~No WSL on the Windows dev machine~~ | **Superseded 2026-09-23: WSL2 Ubuntu 26.04 is installed and is where Fil-C runs** (KI-1) |
| ~~2026-09-23 (morning)~~ | ~~Integration route: build Zig against Fil-C's LLVM fork; wrapper-driver ruled out~~ | **REVERSED the same day** — the ruling-out rested on Debug-mode runs only |
| **2026-09-23 (P2)** | ✅ **Integration route: a WRAPPER DRIVER.** Stock Zig emits IR → rewrite the two `target datalayout` lines → Fil-C's clang. **No Zig fork, no LLVM build** | Works today for ReleaseSafe/Small/Fast, proven by the milestone test (`roadmap.md` P2). The heavy route stays in reserve for Debug mode / startup, if those cannot be solved otherwise |
| ~~2026-09-23~~ | ~~zilc's first shipping shape: Zig exports C-ABI functions; C owns `main`~~ | **Superseded the same day**: whole Zig programs work via a generated entry shim, and the stated cause (an aux-vector walk) was wrong — it is `@ptrFromInt` (KI-5) |
| 2026-09-23 | **The driver GENERATES a C-ABI entry (`zilc_entry.zig`) for whole Zig programs**, making it the root module and the user's file a module named `user` | Keeps `start.zig` out of the build entirely, which is the only way past `@ptrFromInt(getauxval(…))`. `--entry auto\|zig\|c` overrides |
| 2026-09-23 | **`-O Debug` is supported with two automatic concessions** (`filc -O0`, `-fno-stack-check`) rather than refused | Debug is where Zig's safety checks live. The 108× size cost is announced, not hidden. The `-O1` crash is upstream's (KI-4) |
| 2026-09-23 | **`zig build gate` SKIPS (exit 0) where Fil-C is absent** instead of failing | A build that never had a chance to pass is an absence, not a failure. ⚠️ The cost: a green gate on Windows means nothing, so it prints `SKIPPED` first (`testing.md`) |
| 2026-09-23 | **Version `0.3.0`** — minor per roadmap phase, P1 + P2 shipped | The cadence recorded in `releasing.md` before either phase ran |
| **2026-09-30** | **The Zig-native runtime is built on LINUX FIRST, checked against Fil-C** (owner). Fil-C's pass and its checked musl stay fixed; only the runtime is swapped, one layer at a time, and every gate case must behave identically under both runtimes | Fil-C runs on Linux, so it can serve as the reference for the port. The measured runtime contract makes a piece-by-piece swap possible: `architecture.md` "The runtime contract" |
| **2026-09-30** | **`zilc build --runtime filc\|zig`** — one switch between Fil-C's runtime and zilc's. `filc` is the default. **`zig` is RESERVED: parsed, then refused** with an explanation until the Zig runtime is ready for testing (owner: "build in the flag now and just don't use the zig one until it is actually ready") | Refused rather than silently linking Fil-C's, so no build can claim the Zig runtime while linking Fil-C's. Enabling it = deleting the refusal in `driver.build`; the CLI side is final. A unit test pins the refusal |
| **2026-09-30** | 🎯 **GOAL (owner): once the initial work is complete, zilc must move to the LATEST Zig with the least rework of the source file layout.** The current 0.15.2 pin is a starting condition, not a permanent state | Owner. How to design for it: invariant 4 below |
| **2026-09-30** | ✅ **Versioning: `<Zig line>-<zilc release>`** (the Zig the line is built with; corrected from "compatible Zig" the same day). APPLIED: the version is `0.15.2-3`** (was `0.3.0`), replacing minor-per-phase (owner: "0.15.2-? it is then"). Spelled that way everywhere. `0.15.2.3` is rejected by `build.zig.zon`, and `0.15.2_3` is silently read as `0.15.23`. **No 1.0, ever** (owner: "We will just have a -? progression"). Only `N` advances, so the number signals neither breaking changes nor maturity. **`N` restarts at 1 for every new Zig version, patch releases included** (owner: Zig patch releases break things too), e.g. `0.16.1-1` and `0.16.2-1` | Our minor-per-phase numbers would eventually collide with Zig's `0.15.x`. Detail and open questions: `releasing.md` |
| **2026-09-30** | **Every latest-line release names its BASIS** (owner): the reference release it was ported from, e.g. `0.16.2-1` basis `0.15.2-100`, recorded in the release notes. A new Zig line is ported **from the latest reference release**, using the previous line's **port notes** (`ports/<version>.md`) | If Fil-C stays on an old LLVM, the reference line keeps moving and stays the fixed point every latest-line release is checked against. The notes make each port faster than the last. Detail: `releasing.md` "Two kinds of line" |
| **2026-09-30** | 🔒 **STAY ON ZIG 0.15.2 UNTIL THERE IS A STABLE BASE** (owner: "We have to stay with 0.15.2 until we have a stable base to work from"). No latest-Zig line is started until then. A trial port to 0.16.0 was begun and **stopped on the owner's word**; its facts are kept in `ports/README.md` "Scouting" | The upgrade procedure needs a solid reference line to compare against. P3, the Zig runtime, is built on 0.15.2 first |
| **2026-09-30** | **One git branch per Zig line** (owner): `0.15.1-N`, `0.15.2-N`, `0.16.1-N`, `0.16.2-N` each on their own branch. A new line's branch starts at its basis release, and releases are tagged on their line's branch. **Settled the same day:** branches are named **`v<zig>`** (`v0.15.2`); **`main` is the base, the reference line**, and moves on with it; **`cmem/` is authoritative on `main` only**, with port notes in `cmem/ports/<version>.md`. First tag `v0.15.2-3` and branch `v0.15.2` created 2026-09-30 | "For compatibility with the upstream zig version": each line stays buildable with its own Zig indefinitely. Detail: `releasing.md` "Two kinds of line" |
| **2026-09-30** | **Upgrades run in three stages (owner):** **A**, follow Fil-C to the Zig whose LLVM major matches (the *reference*); **B**, port that to the latest Zig if different, checked against A; **C**, benchmark comparison between versions | A gives a known-good base, so every difference in B is visible as a regression. C gives zilc its own performance numbers. Procedure: `upstream.md` "Upgrade procedure" |
| 2026-09-30 | **The pass is NOT ported to Zig.** It stays in Fil-C's LLVM and zilc keeps calling it externally | FilPizlonator is at least 16k lines of C++ and works on IR, so it is largely OS-independent already. Porting it gains nothing for other platforms, and calling it externally fits Zig's move away from linking LLVM |
| 2026-09-18 | **The WHOLE repo is on Zig 0.15.2**, not just the experiments ("for full compatibility", owner). `minimum_zig_version = "0.15.2"`, and `main.zig` was ported off the 0.16 APIs | 0.15.2 bundles **clang 20.1.2** (checked with `zig cc --version`), the same major as Fil-C 20.1.8. One Zig for everything: nothing in the repo can drift onto an LLVM the pass cannot read |
| 2026-09-18 | **Follow Fil-C's LLVM version; never port the pass ahead of upstream.** zilc stays on Zig 0.15.2 until Fil-C moves to LLVM 21, then the whole repo converts to 0.16.0 | Owner. Porting 17k lines of FilPizlonator to a newer LLVM ourselves would fork us from upstream. **Switch condition:** Fil-C's `cmake/Modules/LLVMVersion.cmake` reports major 21 (checked at every upstream sync, `upstream.md`) |

## Invariants (proposed. Confirm with the owner.)

1. **Semantics come from Fil-C.** Where zilc and Fil-C disagree on what a program may do, Fil-C's
   documented GIMSO semantics win unless a deviation is recorded here with its reason.
2. **Every bug example must panic.** Anything in `examples/` that is UB under `zig build baseline`
   must be a deterministic trap under the safe build. A new unsafe pattern gets an example first.
3. **Our own files carry `SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT`.**
   Adapted files carry the upstream's SPDX (`third_party/LICENSES.md`).
4. **Written to be upgraded (owner goal, 2026-09-30).** Moving to the latest Zig must mean editing a
   few known places, not reorganising files. The rules:
   - **The file layout stays stable** (`src/`, `include/`, `tools/`, `examples/`). Zig API churn is
     absorbed inside files, never by moving or splitting them.
   - **Keep std calls that change between Zig versions in few places.** Baseline 2026-09-30: about
     **31 sites** (`std.fs` 10, `std.process` 13, `ArrayListUnmanaged` 8) across `driver.zig`,
     `main.zig`, `ir.zig` and `tools/gate.zig`, plus **36** build API calls in `build.zig`. New code,
     above all the P3 runtime, should not grow this freely. When a second file needs the same
     version-sensitive call, route both through one small helper instead of duplicating it. Prefer
     plain slices and explicit allocators, which change least between releases.
   - 🔑 **There are TWO Zigs, and only one is pinned by Fil-C.** The Zig that *builds zilc* (host
     toolchain, and the P3 runtime, which is linked as an ordinary object) is limited only by our
     own code. The Zig that *compiles user code* (`ZILC_ZIG`) must emit IR that Fil-C's LLVM reads,
     so it follows Fil-C's LLVM major (KI-3). Today both are 0.15.2 by owner decision (2026-09-18).
     Separating them is what lets zilc itself reach the latest Zig **before** Fil-C moves.
     ◐ **Implied by the upgrade procedure's stage B (2026-09-30)**, which moves only the Zig
     that builds zilc. The 2026-09-18 "one Zig for everything" decision therefore holds only up
     to stage A. ⚠️ Confirm with the owner that this is intended.
   - **Zig source that zilc generates or ships is compiled by the USER-CODE Zig**: the entry shim
     in `driver.zig` and `examples/**/*.zig`. It tracks `ZILC_ZIG`'s version, not the host's, so
     keep it minimal (it is ~30 lines today).
   - **Every upgrade** follows the three-stage procedure in `upstream.md`. Porting code between Zig
     versions is the same checklist in stages A and B: bump `minimum_zig_version`, fix the counted
     sites, run `zig build test` + `gate`, then refresh the Zig API notes below.

## ❓ Open questions — to settle with the owner

These shape everything else. Listed roughly in order of how much they constrain the rest.

1. **How does the pass get into Zig?** ✅ **SETTLED BY EXPERIMENT 2026-09-23 — (c) wins.**
   - ✅ **(c) Wrapper driver.** Stock `zig` emits IR; the driver rewrites `target datalayout` to
     Fil-C's `ni:0` form and adds `target datalayout_after_filc`; Fil-C's clang runs the pass and
     links. **Verified end to end**, Zig ⇄ C, panic located in the Zig source (`roadmap.md` P2).
     ⚠️ Limits today: Release modes only (KI-4 reversal), C-ABI `main` only (KI-5), musl only (KI-6).
   - 🔒 (a) **Build Zig against Fil-C's LLVM fork.** Held in reserve. It is what Debug-mode support
     or a real `zilc` Zig *target* may eventually require — but it is no longer the entry price.
   - ❌ (b) **LLVM pass plugin in a stock LLVM.** Still impossible: stock LLVM rejects `ni:0` and
     does not know `datalayout_after_filc` (KI-4).
2. **LLVM version skew.** ✅ *Settled 2026-09-18 (owner).* zilc follows Fil-C's LLVM version and
   does not port the pass itself. Zig 0.15.2 (LLVM 20) is used until Fil-C moves to a clang that
   Zig 0.16.0 covers (LLVM 21), and the conversion happens then. See the decision table above.
3. **Runtime: port or rewrite?** Porting `libpas`/`filc_runtime.c` to Zig is faster but carries
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
4. **Platform.** ◐ *Direction set 2026-09-30, not yet confirmed as a goal.* **Linux x86_64 is the
   first and only working target**, developed in WSL2 (KI-1). How far other platforms can go, as
   analysed with the owner 2026-09-30:
   - **What Zig's portability covers:** the runtime (garbage collector, capabilities, safepoints). It
     needs threads, atomics, memory mapping, thread-local storage and a clock, all of which Zig's
     std provides on every major OS. FUGC finds pointers through safepoints and stack maps the pass
     inserts, not through OS signals, so it ports well.
   - **What it does not cover:** the checked wrappers at the OS boundary (Zig knows *how* to call
     each OS but checks nothing), and a safe libc (musl is Linux-only; Windows' and macOS's C
     runtimes are closed or system-bound and cannot be compiled with the pass).
   - **No Zig fork is needed:** the pass renames every symbol `pizlonated_<name>`, so every OS
     entry point becomes a link-time hook. A Windows Zig program's `NtCreateFile` becomes
     `pizlonated_NtCreateFile`, which the runtime supplies. So the wrappers needed are exactly the
     OS functions Zig's std references for each target, a list that can be counted.
   - **Proposed scope:** *safe Zig on the major 64-bit OSes (LLVM backend), safe C on Linux first.*
     Out of scope until examined: 32-bit, freestanding/embedded, wasm, Zig's non-LLVM backends.
   - **Expected trouble:** every OS layer in std that builds pointers from integers is a KI-5
     repeat. Windows std reads its thread environment block through inline asm and `@ptrFromInt`.
   - **Order:** Linux ARM64 (Fil-C supports it upstream) → P3 on Linux → count std's OS functions
     for Windows and macOS → the first non-Linux target, Zig code only (`roadmap.md` P6).
5. **Zig-language semantics.** ✅ *Settled 2026-09-18.* The first milestone includes Zig **as a
   source language** from the start, via the existing Fil-C pass (see the milestone decision
   above). It is not C-only. Since GIMSO accepts any LLVM IR, putting Zig first is how the premise
   gets tested.
6. **Relationship to upstream in git.** Options: vendor Fil-C as a subtree, keep a separate fork and
   reference it, or copy only the pass + runtime files. See `upstream.md`.

## Zig 0.15.2 API notes (this project targets 0.15.2)

- `pub fn main() !void`; args via `std.process.argsAlloc(arena)`.
- stdout (post-"Writergate" I/O): `var w = std.fs.File.stdout().writer(&buf); const out = &w.interface;`
  and **flush before returning**.
- `build.zig`: `addExecutable`/`addLibrary(.{ .linkage = … })`/`addTest` all take `.root_module`.
  That is the same shape as 0.16, so `build.zig` needed no change in the port.
- `build.zig.zon` requires a `.fingerprint`. Zig prints a suggested value if it is missing.
- ⚠️ **Don't copy code from wazmrt without checking.** wazmrt is on **0.16** (`std.process.Init`,
  `std.Io`), and its `main`/I/O code does not compile here.
- ⚠️ `minimum_zig_version` only rejects *older* Zigs. **Zig 0.16 is not rejected up front; it fails
  with a compile error in `main.zig`.** Those errors mean the wrong Zig, not a code bug.

## Windows build gotchas (dev machine: win32, D: = exFAT)

- **Zig 0.15.2 lives at `C:\zig\0.15.2\zig.exe`** (official zip, SHA-256 verified against
  ziglang.org's `index.json`, installed 2026-09-18). It is **not on PATH**. Bare `zig` is the scoop
  shim, which is **0.16.0**, and wazmrt still needs that. So invoke by full path, or put
  `C:\zig\0.15.2` first on PATH for the session.
- `ZIG_LOCAL_CACHE_DIR=C:\zig-cache\zilc` is required (KI-2).
- The repo lives on exFAT, so git reports *dubious ownership*. ✅ **Fixed on this machine
  2026-09-18**: the owner added the repo path to the global `safe.directory`, so plain `git` works.
  On a new machine or clone location, run
  `git config --global --add safe.directory <path-to-zilc>` once.
- Writing Zig multiline strings (`\\`) through a bash heredoc can drop a backslash. Write Zig
  sources with the file tools instead.
