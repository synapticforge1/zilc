# design-decisions-early.md — the decisions of 2026-09-18 to 2026-10-05

Split from `design-decisions.md` on 2026-11-23 (letter H38 step 5), verbatim and in the original
order. Some are superseded (struck through, or marked by a later row there); the rest still hold.

## Decisions made (2026-09-18 to 2026-10-05)

- 2026-10-05 (evening) — 🌱 **NEW PROJECT: Zaig** (owner; renamed **zailc** = Zig + AI + Fil-C on
  2026-10-08, since "zaig" is taken on GitHub). A separate project built on Zig + Fil-C that takes
  the best parts of both: "a complete departure from Zig in that I will use AI in the development
  and we will zag where they zig. We will fix what they did not and cleanup what they left a mess
  of." **zilc stays the stable reference**: faithful to Zig + Fil-C releases, its version cadence
  unchanged (`<Zig>-<Fil-C>.<release>`), and it is Zaig's proven base and test oracle. **Zaig stays
  on Zig 0.15.2** until it is proven to produce the same as zilc. **Start:** once the cosmo
  evaluation is complete and the scope is written up (`archive/platforms-p6-cosmo-2026-10-08.md`,
  `zig-filc-scope.md`, the starting brief)
  - Why: Owner: keeps zilc maintainable and provable against the latest Zig, LLVM and Fil-C releases
    without criss-crossing intents, while the new platform grows from what zilc proved.
    Consequences: the all-Zig goal, the three steps and the "only Zig" question move to Zaig; the
    two rows marked UNDER REVIEW below are RESOLVED as still right FOR ZILC
- 2026-10-05 (later) — 🔀 **Owner: do the Fil-C TRANSLATION (Fil-C's pass and runtime into Zig, the
  all-Zig steps) on Zig 0.15.2 FIRST, then move to 0.16.0.** "After our discussion on 0.16.0, I
  think I want to perform the Fil-C translation part in 0.15.2 instead, then make the change to
  0.16.0"
  - Why: Removes the LLVM blocker: on 0.15.2 Zig and Fil-C 0.686 share LLVM 20, so each translated
    piece can be checked against upstream's own build (FIDELITY FIRST) on the line that works today.
    Once the pass runs as Zig and Zig's own LLVM compiles its output, the move to 0.16.0 (LLVM 21)
    no longer needs a Fil-C on LLVM 21. Refines the row below: same goal and order, done on 0.15.2
    before the line change
- 2026-10-05 — ↪️ _Refined the same evening by the Zaig row above: the only-Zig goal and the three
  steps move to Zaig (on 0.15.2 until proven); zilc keeps its cadence, so zilc's 0.16-or-later line
  comes when Fil-C reaches that Zig's LLVM (whether zilc then skips 0.16 for 0.18, as said here, is
  to confirm when it happens)._ 🧭 **Owner direction: the next line is Zig 0.16.0, and the goal is a
  zilc whose user installs ONLY Zig and runs `zig build`, with no third-party tools to download.**
  Zig 0.17.0 is out, but zilc stays on 0.16.0 until 0.18.0 is released, "so that we are not having
  to work around ongoing issues". Planned version `0.16.0-0.686.1` (0.16.0 is installed on Windows
  via scoop). **Approach (owner): start with the same dependencies as Fil-C, then convert them to an
  all-Zig base step by step, the way binaryang started on wabt + binaryen.** Assessed order: (1)
  0.16 line on Fil-C as today; (2) Fil-C runtime + libc built from source by `zig build` (needs
  libpas's two Ruby scripts ported TO ZIG, not Deno, since a user's `zig build` can rely on Zig
  alone: `find_clang_include_dir.rb`, 54 lines, and `generate_pizlonated_forwarders.rb`, 852 lines,
  which writes `filc_native.h` + `filc_native_forwarders.c` at every build; the Zig port must
  produce byte-identical files, checked against Ruby's output. Owner 2026-10-05: Ruby installed for
  the cosmo evaluation meanwhile); (3) the pass as a Zig IR-to-IR step, compiled by Zig's own LLVM,
  after which only Zig is needed
  - Why: ⚠️ **Blocker for step 1, told to the owner:** Zig 0.16.0 emits LLVM 21 IR; Fil-C 0.686 is
    LLVM 20.1.8 and cannot read it. Needs Fil-C on LLVM 21, our own port of Fil-C's LLVM changes, or
    step 3 first. ⚠️ **Supersedes, pending the owner's confirmation, the two rows below marked
    "under review".** Open: whether pinned, hash-checked source packages fetched by `zig build`
    count as "third-party downloads"
- 2026-09-18 — Project layout and `cmem/` policy mirror wazmrt
  - Why: Owner request; proven structure
- 2026-09-18 — License `Apache-2.0 WITH LLVM-exception OR MIT`
  - Why: Compatible with all three upstreams; see `licensing.md`
- ~~2026-09-18~~ — ~~Target Zig **0.16.0**~~. **Superseded the same day**, see the full-compatibility row below
  - Why: Was: installed toolchain; matched wazmrt
- 2026-09-18 — Upstream = Fil-C `deluge` branch; not fetched into this repo yet
  - Why: The Fil-C tree is a full llvm-project fork (multi-GB). How to consume it is an open question below
- 2026-09-18 — **First milestone (owner-agreed):** a Zig program plus a C library, compiled through Fil-C's _existing_ pass and runtime, panics correctly on OOB/UAF
  - Why: Tests the premise (Zig IR survives GIMSO) before any zilc code. The Zig runtime rewrite and C++ come later
- ~~2026-09-18~~ — ~~No WSL on the Windows dev machine~~
  - Why: **Superseded 2026-09-23: WSL2 Ubuntu 26.04 is installed and is where Fil-C runs** (KI-1)
- ~~2026-09-23 (morning)~~ — ~~Integration route: build Zig against Fil-C's LLVM fork; wrapper-driver ruled out~~
  - Why: **REVERSED the same day** — the ruling-out rested on Debug-mode runs only
- **2026-09-23 (P2)** — ✅ **Integration route: a WRAPPER DRIVER.** Stock Zig emits IR → rewrite the two `target datalayout` lines → Fil-C's clang. **No Zig fork, no LLVM build**
  - Why: Works today for ReleaseSafe/Small/Fast, proven by the milestone test (`roadmap.md` P2). The heavy route stays in reserve for Debug mode / startup, if those cannot be solved otherwise
- ~~2026-09-23~~ — ~~zilc's first shipping shape: Zig exports C-ABI functions; C owns `main`~~
  - Why: **Superseded the same day**: whole Zig programs work via a generated entry shim, and the stated cause (an aux-vector walk) was wrong — it is `@ptrFromInt` (KI-5)
- 2026-09-23 — **The driver GENERATES a C-ABI entry (`zilc_entry.zig`) for whole Zig programs**, making it the root module and the user's file a module named `user`
  - Why: Keeps `start.zig` out of the build entirely, which is the only way past `@ptrFromInt(getauxval(…))`. `--entry auto\|zig\|c` overrides
- 2026-09-23 — **`-O Debug` is supported with two automatic concessions** (`filc -O0`, `-fno-stack-check`) rather than refused
  - Why: Debug is where Zig's safety checks live. The 108× size cost is announced, not hidden. The `-O1` crash is upstream's (KI-4)
- 2026-09-23 — **`zig build gate` SKIPS (exit 0) where Fil-C is absent** instead of failing
  - Why: A build that never had a chance to pass is an absence, not a failure. ⚠️ The cost: a green gate on Windows means nothing, so it prints `SKIPPED` first (`testing.md`)
- 2026-09-23 — **Version `0.3.0`** — minor per roadmap phase, P1 + P2 shipped
  - Why: The cadence recorded in `releasing.md` before either phase ran
- **2026-09-30** — **The Zig-native runtime is built on LINUX FIRST, checked against Fil-C**
  (owner). Fil-C's pass and its checked musl stay fixed; only the runtime is swapped, one layer at a
  time, and every gate case must behave identically under both runtimes
  - Why: Fil-C runs on Linux, so it can serve as the reference for the port. The measured runtime contract makes a piece-by-piece swap possible: `architecture.md` "The runtime contract"
- **2026-09-30** — **`zilc build --runtime filc\|zig`** — one switch between Fil-C's runtime and
  zilc's. `filc` is the default. **`zig` is RESERVED: parsed, then refused** with an explanation
  until the Zig runtime is ready for testing (owner: "build in the flag now and just don't use the
  zig one until it is actually ready")
  - Why: Refused rather than silently linking Fil-C's, so no build can claim the Zig runtime while
    linking Fil-C's. Enabling it = deleting the refusal in `driver.build`; the CLI side is final. A
    unit test pins the refusal
- **2026-09-30** — 🎯 **GOAL (owner): once the initial work is complete, zilc must move to the
  LATEST Zig with the least rework of the source file layout.** The current 0.15.2 pin is a starting
  condition, not a permanent state
  - Why: Owner. How to design for it: invariant 4 below
- **2026-09-30** — ✅ **Versioning: `<Zig line>-<zilc release>`** (the Zig the line is built with;
  corrected from "compatible Zig" the same day). APPLIED: the version is `0.15.2-3`** (was `0.3.0`),
  replacing minor-per-phase (owner: "0.15.2-? it is then"). Spelled that way everywhere. `0.15.2.3`
  is rejected by `build.zig.zon`, and `0.15.2_3` is silently read as `0.15.23`. **No 1.0, ever**
  (owner: "We will just have a -? progression"). Only `N` advances, so the number signals neither
  breaking changes nor maturity. **`N` restarts at 1 for every new Zig version, patch releases
  included** (owner: Zig patch releases break things too), e.g. `0.15.2-0.686.1`, then
  `0.16.0-0.686.1` (examples updated 2026-10-05 to the current scheme and the real next line)
  - Why: Our minor-per-phase numbers would eventually collide with Zig's `0.15.x`. Detail and open questions: `releasing.md`
- **2026-09-30** — **Every latest-line release names its BASIS** (owner): the reference release it
  was ported from, e.g. `0.16.2-1` basis `0.15.2-100`, recorded in the release notes. A new Zig line
  is ported **from the latest reference release**, using the previous line's **port notes**
  (`ports/<version>.md`)
  - Why: If Fil-C stays on an old LLVM, the reference line keeps moving and stays the fixed point
    every latest-line release is checked against. The notes make each port faster than the last.
    Detail: `releasing.md` "Two kinds of line"
- **2026-09-30** — 🔒 **The Zig runtime is a CLEAN-ROOM implementation** (owner: "definitely clean-room"). Settles open question #3
  - Why: **Binding from now on:** nobody working on zilc reads Fil-C's **runtime source**
    (`libpas/`, `filc_runtime.c`, `filc_*.c`, or Fil-C's musl/yolo-libc sources). Allowed: the
    pass's _output_ (IR), compiled binaries (`nm`/`objdump`), the public headers in
    `pizfix/stdfil-include/`, and the published design docs (`invisicap.txt`, `gimso_semantics.md`,
    `Manifesto.md`), which is exactly how `filc-abi.md` was built. The compiler pass
    (`FilPizlonator.cpp`) is not part of the runtime and is not ported. Keeps zilc's runtime free of
    BSD-2-Clause obligations in user binaries (`licensing.md`)
- **2026-09-30** — **Upstream defects are NOTED FOR THE RECORD, not filed** (owner: "We will not file, we will only note for the record"), for the KI-4 Fil-C crash report
  - Why: The draft stays in `tools/p2/repro/` as a record. 🔸 Applied by default to KI-18 and the Zig notes too, unless the owner asks to file
- **2026-10-05** — 🔖 **VERSION = `<Zig>-<Fil-C>.<zilc release>`: this release is `0.15.2-0.686.1`**
  (owner: _"make our release version … indicate the zig release version, the Fil-C release version
  and the zilc release version"_; spelling chosen by the owner: Fil-C's full version,
  `0.15.2-0.686.N`; **N restarts at 1 per Fil-C release**, as per Zig release)
  - Why: `0.15.2.686-N` is impossible (Zig rejects four numbers). The chosen form is valid in
    `build.zig.zon` and orders correctly across zilc, Fil-C (incl. a future 1.0) and Zig releases
    (verified with Zig 0.15.2's parser; `releasing.md`). The never-published local tag `v0.15.2-3`
    must be deleted, not moved: it sorts above `0.15.2-0.686.1`
- **2026-10-05** — ⬆️ **THE RELEASE MOVES TO FIL-C 0.686** (owner: _"move the release to the Fil-C
  0.686 version just released"_), after the upstream review of the 10 pass commits (owner: _"do the
  upstream review and include it in the release"_)
  - Why: Same LLVM (20.1.8), so Zig 0.15.2 still pairs with it. zilc's 8 edits applied unchanged;
    the patched clang is rebuilt from fil-c.git `163fae5` (the LLVM fork's new name). Gained for
    Zig: `@call(.always_tail, …)` now keeps its guarantee (0.685 dropped it: 10M-deep tail recursion
    overflowed the stack), and the stack-aux GC-root fix for locals without lifetime markers (Zig's
    IR has none). KI-4 and KI-18 still occur on stock 0.686, so zilc's fixes stay. Details:
    `upstream.md` "Review of 0.686"
- **2026-10-05** — 🦕 **ALL TOOL SCRIPTS ARE DENO** (owner: _"Can we make the bash scripts deno
  scripts so that are cross platform?"_; scope chosen by the owner: **everything except
  `tools/p1/setup-wsl.sh`**, which bootstraps Ubuntu before Deno exists there). 31 shell scripts
  became `.ts` beside a shared helper, `tools/lib/tool.ts`
  - Why: A tool is written once, for the platform its work needs: `linuxOnly()` re-runs a Linux tool
    inside WSL when started on Windows (replacing `wsl.exe -e sh /mnt/d/…` and KI-1's quoting
    workaround); tools that need only git or Windows' Zig run natively anywhere. Each conversion was
    checked against its shell original (same output, same files). Conventions: `tools/README.md`
- **2026-10-02** — 📚 **LIBRARY MODE: a generated LIBRARY root module** (owner: "proceed",
  pre-publish item). A Zig file in a C-owns-`main` build is compiled as module `user` under
  `library_shim`, which carries the same std hooks as the entry shim (`shim_hooks`) and references
  `user` so its exports are compiled. **Both roots now honour a user file's own `panic`, `os` and
  `std_options`** (this agent's choice: before, the entry shim silently ignored them, since the
  user's file was no longer the root); `crypto_always_getrandom` stays forced, as without it the
  program stops at its first random number (KI-20). ✅ **Owner confirmed the same day:** *"I agree
  with your recommendation, with an added stipulation that if the user modifies the
  'crypto_always_getrandom' for zig that we notify the user why this can't be set to false for
  zilc."* → `zilc build` prints a `zilc: note:` explaining the override whenever the root Zig file
  sets the field to anything but `true`
  - Why: Measured before: in library mode `page_allocator` trapped (KI-12), `crypto.random` trapped (KI-20), `@panic` overflowed the stack. After: all three behave, Release and Debug; gate cases 6–8
- **2026-10-02** — ⚡ **LEVERS (b) AND (c) DONE** (owner: "Then you can start the (b) and (c) work").
  (b): the pass's interference graph over dense ids, the same graph by construction and checked
  (`ZILC_VERIFY_INTERFERENCE=1` on the whole corpus). (c): an object cache, **on by default** with
  `--no-cache` / `ZILC_CACHE=0` to opt out. ✅ **Confirmed by the owner the same day:** _"Leave the
  cache on by default, as that make the future compile faster in zig. Although, it would be good to
  have a '-clean-cache' cli option that cleans up the cache."_ → **`zilc --clean-cache`** (alone, or
  as a `build` option that cleans first) deletes `<cache>/objects` and reports what it freed; the
  std overlay beside it stays
  - Why: Faithful by construction: the key covers the IR, zilc's commands, the plan and the
    clang/llvm-split binaries' identity, and Fil-C itself is not run-to-run reproducible. `69`: 43.9
    → 35.9 s (b); unchanged rebuild 2.3 s (c). Detail: `workarounds.md` KI-22
- **2026-10-02** — ⚡ **BUILD-SPEED LEVER (a) = SPLIT CODE GENERATION ONLY, after the whole-module
  pass and optimizer; then (b), then (c)** (owner: "yes"). The faster route, splitting BEFORE the
  pass (`69` clang stage 55 → ~24 s), was **rejected for bloat**: +37% stripped binary, because the
  optimizer cannot inline across parts (owner: _"What is another option that doesn't bloat the
  resulting binary, is reasonably speedy and maintains fidelity?"_)
  - Why: Every decision about the code stays on the whole module, so the parts give the same code:
    **2,840/2,840 functions identical** to the unsplit compile of the same bitcode on `69`, same
    symbols, same stripped size. `69` 60.6 → 43.9 s through the driver. On by default for
    Fil-C-dialect IR ≥ 4 MB, `-j`/`ZILC_JOBS` (1 = off). Detail and the why of each piece:
    `workarounds.md` KI-22 "Lever (a) carried out"
- **2026-10-01** — 🔓 **CLARIFIED (owner): "clean-room" meant BUILDING NEW ZIG EQUIVALENTS, not a
  ban on reading Fil-C's source** (owner: "I thought we were just creating new zig equivalents. Not
  totally not reviewing how Fil-C source actually functions."). Narrows the 2026-09-30 row below,
  whose "nobody reads runtime source" wording was this agent's strict-legal interpretation, not the
  owner's words
  - Why: **Reading Fil-C's source is allowed, pass and runtime.** ✅ **Settled the same day (owner):
    the intent is COMPLIANCE, not avoidance**: "The intent has always been to comply with the Fil-C
    licensing parts. That is why we have been keeping track of the workarounds and issues that we
    are finding. So we can be in compliance." Runtime code that adapts Fil-C follows the Adoption
    Checklist and the runtime-linking rule (BSD-2-Clause notice with user binaries); see open
    question #3
- **2026-10-01** — 💾 **PROJECTS STAY ON THE D: DRIVE (exFAT) FOR PORTABILITY** (owner: "The reason it is on the D: drive is for portability. We won't be placing project on the NTFS drive")
  - Why: Nothing of the project moves to NTFS, git's `.git` included. exFAT limits are handled in
    place: the Zig cache goes to `C:\zig-cache\zilc` (a cache, so local by nature; KI-2), and git
    maintenance uses `gc` instead of geometric repack (repo-local config, KI-23). Anything that must
    persist stays on D:
- **2026-10-01** — ⚡ **BUILD-SPEED OPTIONS APPROVED (owner: "I agree with the speed up options")**
  for `69`-class programs, after KI-22 option 2 and the option 3 research: **(a)** split each module
  and run Fil-C's clang on the parts in parallel; **(b)** an output-identical faster interference
  build in the patched pass; **(c)** an object cache keyed by IR hash for unchanged rebuilds. Not
  started
  - Why: Goal: zilc must not make Zig's build time a detriment (owner). Each one keeps output
    identical or provably equivalent. (b) is another `filc-pass-fixes` edit with a `ZILC_VERIFY_…`
    check, like the colouring fix. (a) must keep Fil-C's per-module globals and getters correct
    across parts, as C translation units do. Details: `workarounds.md` KI-22 "Levers that remain"
- **2026-10-01** — 📄 **COMPLIANCE = DOCUMENTATION; upstream reporting is optional and NOT planned**
  (owner: "lets just perform the documentation part"). None of Fil-C's licences (Apache-2.0 + LLVM
  exception for the compiler, BSD-2-Clause runtime, MIT musl) require reporting or contributing
  back; their conditions apply on redistribution. **KI-22: option 2 chosen** (build a PATCHED Fil-C
  clang locally with an output-identical colouring fix), **then fully research option 3**
  (zilc-inserted lifetime markers) to check whether it is still needed
  - Why: `UPSTREAM-ISSUES.md` stays as documentation; the email is not planned. The patched clang is
    **local use only**: no distribution, so no Apache-2.0 §4 duties arise. If it is ever
    distributed: include the licence and NOTICE, and mark the modified file. Ledger entry
    `filc-pass-fixes` in `third_party/LICENSES.md`. Supersedes the email part of the next row
- **2026-10-01** — ✉️ **Upstream issues are REPORTED BY A SHORT EMAIL pointing to ONE FILE,
  `UPSTREAM-ISSUES.md`** (owner), refining the row above. No issue reports and no long write-ups:
  some upstream projects are anti-AI, and the owner does not want to deal with that, so the email
  only says an issue was found and links the file
  - Why: `UPSTREAM-ISSUES.md` (repo root) is public-facing: plain facts, versions, a one-line repro
    command, the workaround. **No internal jargon (KI numbers, `cmem/`), no mention of how it was
    produced.** Email template and procedure: `upstream.md` "Reporting upstream". The link works
    only once `main` is pushed
- **2026-09-30** — 📦 **Publish as `v0.15.2-3`** once the remaining open-items list is done, **after** the platforms-plan scope and **before** the port effort (owner)
  - Why: The tag `v0.15.2-3` and branch `v0.15.2` exist only **locally** (on `277cc80`, was
    `5464a17` before the 2026-10-27 purge, `history-map-2026-10-27.md`). Never pushed, so they are
    **moved to the final commit at publish time**. The version stays `0.15.2-3`
- **2026-09-30** — 🔁 **SUPERSEDED 2026-10-27 for zilc** (Linux only; cross-platform is zailc's —
  row at the top). Was: 🌍 **PLATFORMS (owner): Linux, macOS and Windows, on every currently
  prevalent processor; then iOS; Android later.** Adopts P6 as a goal (`roadmap.md`)
  - Why: Fil-C supports only Linux (x86_64, aarch64), so every other OS depends on the clean-room Zig runtime and a checked OS layer per platform
- **2026-09-30** — 🎯 **FIDELITY FIRST, THEN STREAMLINE** (owner). Porting Fil-C to Zig starts with
  **fidelity**: produce the **same binaries and the same results** as upstream. **Only once that is
  proven** may zilc optimise beyond upstream, e.g. **smaller binaries**. From then on, not being
  byte-identical to Fil-C doesn't matter, **as long as the safety-guarantee results are the same**;
  smaller binaries with identical guarantees are a plus on the Zig side
  - Why: Owner: "As long as we are producing the same safety guarantee results and make binaries
    smaller, the fact that we are not byte identical at that point is irrelevant from the Fil-C side
    and a plus from the zig side." ✅ **Confirmed by the owner (2026-09-30): "I was talking about the
    compiled binaries, not the libraries that are used for the end user's compilation."** The _user
    program_ binary (produced by Fil-C's unchanged pass) is held byte-identical. The _runtime_
    library cannot be, being new code in a new language, so it is held to identical observable
    results by the `-Druntime=both` gate. Detail: `roadmap.md` P3 "Two phases"
- **2026-09-30** — 🔒 **STAY ON ZIG 0.15.2 UNTIL THERE IS A STABLE BASE** (owner: "We have to stay
  with 0.15.2 until we have a stable base to work from"). No latest-Zig line is started until then.
  A trial port to 0.16.0 was begun and **stopped on the owner's word**; its facts are kept in
  `ports/README.md` "Scouting"
  - Why: The upgrade procedure needs a solid reference line to compare against. P3, the Zig runtime, is built on 0.15.2 first
- **2026-09-30** — **One git branch per Zig line** (owner): one branch per Zig release (`v0.15.2`
  today, `v0.16.0` next). A new line's branch starts at its basis release, and releases are tagged
  on their line's branch. **Settled the same day:** branches are named **`v<zig>`** (`v0.15.2`);
  **`main` is the base, the reference line**, and moves on with it; **`cmem/` is authoritative on
  `main` only**, with port notes in `cmem/ports/<version>.md`. First tag `v0.15.2-3` and branch
  `v0.15.2` created 2026-09-30
  - Why: "For compatibility with the upstream zig version": each line stays buildable with its own Zig indefinitely. Detail: `releasing.md` "Two kinds of line"
- **2026-09-30** — **Upgrades run in three stages (owner):** **A**, follow Fil-C to the Zig whose
  LLVM major matches (the _reference_); **B**, port that to the latest Zig if different, checked
  against A; **C**, benchmark comparison between versions
  - Why: A gives a known-good base, so every difference in B is visible as a regression. C gives zilc its own performance numbers. Procedure: `upstream.md` "Upgrade procedure"
- 2026-09-30 — ✅ RESOLVED 2026-10-05 (evening): still right for zilc; porting the pass to Zig is
  Zaig's work. **The pass is NOT ported to Zig.** It stays in Fil-C's LLVM and zilc keeps calling it
  externally
  - Why: FilPizlonator is at least 16k lines of C++ and works on IR, so it is largely OS-independent
    already. Porting it gains nothing for other platforms, and calling it externally fits Zig's move
    away from linking LLVM
- 2026-09-18 — **The WHOLE repo is on Zig 0.15.2**, not just the experiments ("for full compatibility", owner). `minimum_zig_version = "0.15.2"`, and `main.zig` was ported off the 0.16 APIs
  - Why: 0.15.2 bundles **clang 20.1.2** (checked with `zig cc --version`), the same major as Fil-C 20.1.8. One Zig for everything: nothing in the repo can drift onto an LLVM the pass cannot read
- 2026-09-18 — ✅ RESOLVED 2026-10-05 (evening): still right for zilc (its cadence is unchanged);
  Zaig stays on 0.15.2 until proven. **Follow Fil-C's LLVM version; never port the pass ahead of
  upstream.** zilc stays on Zig 0.15.2 until Fil-C moves to LLVM 21, then the whole repo converts to
  0.16.0
  - Why: Owner. Porting 17k lines of FilPizlonator to a newer LLVM ourselves would fork us from
    upstream. **Switch condition:** Fil-C's `cmake/Modules/LLVMVersion.cmake` reports major 21
    (checked at every upstream sync, `upstream.md`)
