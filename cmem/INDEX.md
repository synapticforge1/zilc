# cmem — Portable Project Memory for zilc

This folder is the **authoritative, portable project memory** for `zilc`. It lives inside the
project tree, so it travels with the project (USB drive, clones) and is **committed to git**, unlike
a machine-local `CLAUDE.md`.

**Format:** plain Markdown. One focused topic file per domain, so any single concern can be reviewed
and revised without wading through one giant file. Keep files small and single-topic.

Modeled on the `cmem/` of the sibling project `wazmrt`
(`../wazmrt/cmem`), which is the template
for structure and policy.

---

## ▶️ 2026-10-02 (later) — BUILD SPEED DONE: levers (a), (b), (c). START HERE

- ✅ **(b) dense interference graph** in the patched pass (`patch-pass.ts`): the pass on `69`
  11.2 → 4.3 s; the same graph, verified on the whole corpus in all four modes with
  `ZILC_VERIFY_INTERFERENCE=1` + `ZILC_VERIFY_COLOURING=1` (no difference).
- ✅ **(c) object cache** (`cacheLookup`/`objectKey` in `src/driver.zig`; on by default,
  `--no-cache`/`ZILC_CACHE=0`; key = IR + zilc commands + plan + clang/llvm-split binary
  identity): an unchanged `69` rebuilds in **2.3 s**. Limit: misses for a new output path.
  ✅ **Default-on confirmed by the owner**, who asked for **`zilc --clean-cache`** (done: deletes
  `<cache>/objects`, keeps the std overlay; tests 26/26).
- **`69` ReleaseSafe alone: 55.9 s (2026-10-01) → 35.9 s cold** (native Zig 16.9 s). The rest
  is mostly LLVM's own `-O1` on instrumented code. Corpus 78/78 as designed in all four modes,
  gate 4/4, tests 25/25; toolchain re-archived; upstream: every edit still applies.
- ✅ **Output comparison** (pre-publish item) done the same day: **0 unexplained differences**
  between zilc and native over the whole corpus, C and Zig, all four modes (`testing.md`).
- ✅ **Library mode** (pre-publish item) done the same day: C-owns-`main` builds get a
  generated library root with the same std hooks (panic, `page_allocator`, getrandom), and both
  roots now honour a user file's own `panic`/`os`/`std_options` (getrandom stays forced).
  `examples/library/`; gate 8/8 (new expectations: "runs", "zig panic").
- ✅ **KI-5** (pre-publish item) done the same day: `std.os.environ` set (was silently empty);
  the stack-size expansion and the segfault handler measured/argued unnecessary. Gate 8/8.
- ✅ **Owner confirmed:** `crypto_always_getrandom` stays forced even over a user's explicit
  `false`, AND the user is told: `zilc build` prints a `zilc: note:` with the reason
  (`workarounds.md` KI-20; tests 27/27).
- ✅ **2026-10-05: `zilc --version` + `RELEASE-NOTES.md`** (pre-publish item; `releasing.md`).
- ✅ **2026-10-05: Fil-C's own 7,003 tests** run against zilc's patched clang: identical to stock;
  found and fixed a broken kernel-header link on this machine (`testing.md`).
- ✅ **2026-10-05: every tool is Deno** (owner: cross-platform; all but `tools/p1/setup-wsl.sh`).
  `deno run -A tools/<group>/<tool>.ts` works from Windows and Linux; Linux-only tools bridge into
  WSL by themselves (`tools/lib/tool.ts`, `tools/README.md`). Each of the 31 conversions was checked
  against its shell original; the end-to-end re-run: corpus 78/78 in four modes, output comparison
  0 unexplained (505 identical), gate 8/8, toolchain build/archive/restore OK.
- 📌 **Record (owner): `tiny-ni2.ll`**, the one phase-experiment input with no committed source,
  and the two P1 IR files it comes from: their exact Zig commands were recovered and verified;
  `testing.md` "Experiment inputs that live outside the repo", `tools/p1/README.md`,
  `tools/p2/README.md`.
- ✅ **2026-10-05: zilc MOVED TO FIL-C 0.686** (owner: "move the release to the Fil-C 0.686
  version just released"). Same LLVM (20.1.8); the LLVM fork is now `pizlonator/fil-c.git`, tag
  `v0.686` = `163fae5`. One place names the release: `tools/lib/tool.ts` (`FILC_VERSION`,
  `FILC_SHA`, `FILC_SOURCE_URL`); the p1–p3 tools stay on 0.685 (`FILC_0685_PREBUILT_TREE`): they
  are records of what 0.685 did. zilc's 8 edits apply unchanged (the saved patch moved only its
  line offsets). Upstream review of the 10 `FilPizlonator.cpp` commits: `upstream.md` "Review of
  Fil-C 0.686". Gains: **`musttail`** (Zig `@call(.always_tail)` no longer overflows the stack) and
  the stack-aux GC fix (`097f7b7`, not reproduced on 0.685 but relevant to Zig's IR). **KI-4 and
  KI-18 still crash stock 0.686**, so the patched clang stays recommended.
  Verified on 0.686: corpus **78/78 as designed in all four modes** (71 clean + the 7 intentional),
  0 verification differences; output comparison **0 unexplained** (503 identical); gate 8/8;
  `69` ReleaseSafe **38.0 s** cold; Fil-C's own 7,205 tests: **0 differences** stock vs patched, every runnable test passes except `inlineasm_rdpkru` (CPU feature WSL lacks; `sarcasm-mb-pl-sink-att` needed an OpenSSL file in the test checkout, `testing.md`). Toolchain re-archived as `filc-0.686-zilc`
  (the 0.685 archive kept in `toolchain/filc-0.685/`).
- ✅ **2026-10-05: VERSION SCHEME (owner): `<Zig>-<Fil-C>.<zilc release>`**, this release
  **`0.15.2-0.686.1`**; the last number restarts at 1 for every new Zig or Fil-C release
  (`releasing.md`, `design-decisions.md`). ⚠️ The never-pushed local tag `v0.15.2-3` SORTS ABOVE
  it and must be deleted at publish.
- ✅ **2026-10-05: PLATFORMS SCOPE PASS** (`platforms.md`, `tools/p6/os-surface.ts`). All 78
  corpus programs compile for 9 targets. OS functions (corpus): Linux 75, macOS 79 (22 differ),
  Windows 86 (78 differ); whole std: kernel32 90 + ntdll 49 + ws2_32 83. **Linux aarch64: the
  pass already runs; 4 gaps** (patched clang built X86-only, unlike upstream; data layout must
  come from Fil-C's clang; KI-7 rewrite is x86-only; aarch64 tree + qemu). **Upstream Fil-C
  now has a COSMO mode** whose binaries run on macOS and x86_64 Windows, with Linux x86_64's C
  ABI: evaluate before any per-OS runtime.
- 🚀 **2026-10-05: PUBLISHED `v0.15.2-0.686.1`** (owner: "publish"). Pushed to
  `github.com/jrmarcum/zilc`: `main` and branch `v0.15.2` at `19e7172`, annotated tag
  `v0.15.2-0.686.1`. Local tag `v0.15.2-3` deleted (never pushed). Checked first: version in all
  five places, `zilc --version` ok/ok on this machine, `capi-smoke` OK, nothing from `toolchain/`
  but its README tracked, fast-forward push (43 commits). No GitHub Release page was made (no `gh`
  here); the tag and `RELEASE-NOTES.md` carry the release.
- ▶️ **Next (owner, 2026-10-05): evaluate Fil-C's COSMO mode, starting by building Fil-C from
  source** (`platforms.md` Finding 1 and its open questions).

## ✅ 2026-10-02 — BUILD SPEED, lever (a)

- ✅ **Lever (a), parallel code generation** (owner chose the route: *no bloat, same code*):
  big modules (≥ 4 MB of Fil-C-dialect IR) run Fil-C's pass and `-O1` optimizer WHOLE, then
  zilc's mode of `llvm-split` (`tools/filc/patch-split.ts`, built and installed next to clang by
  `build-patched-clang.ts`, archived in `toolchain/`) cuts the bitcode, and clang generates the
  parts' code in parallel; `ld -r` + objcopy rejoin them (`filcCompile` in `src/driver.zig`;
  `-j`/`ZILC_JOBS`, 1 = off). **2,840/2,840 functions of `69` identical** to the unsplit compile
  of the same bitcode; `69` alone **60.6 → 43.9 s**; corpus **78/78 as designed in all four
  modes**, gate 4/4, tests 24/24. Splitting BEFORE the pass (~24 s) was rejected: +37% binary.
  🔑 Learned: **use-list order changes x86 code generation**, so the splitter deletes bodies
  instead of cloning (`workarounds.md` KI-22 "Lever (a)", with every why).
- Then: levers (b) and (c), done the same day (section above).

## ⏸️ 2026-10-01 (end of day)

- **Next task then: the three BUILD-SPEED options** (approved by the owner; (a) done 2026-10-02,
  above). Baseline then: `69` ReleaseSafe 55.9 s alone vs native Zig 16.9 s.
- **Done 2026-10-01:** **KI-18** fixed (3-byte globals wrapped in a struct; `i21` and `<3 x i8>`),
  **KI-20** fixed (`crypto_always_getrandom`), **KI-21** fixed (std's stack-trace code no longer
  compiled: `62` 40 s → 8 s; Debug route too). New: `workarounds.md` (the why of every workaround,
  owner rule) and `UPSTREAM-ISSUES.md` (documentation only; reporting not planned).
- **Owner decisions today** (`design-decisions.md`): "clean-room" meant **licence compliance**, not
  a ban on reading Fil-C's source; compliance is **documentation only**; **KI-22: option 2, then
  research option 3.**
- ✅ **KI-22 option 2 done:** a **patched Fil-C clang** (`~/zilc-work/tools/filc-0.685-zilc/`, built
  by `tools/filc/build-patched-clang.ts` from the prebuilt's own commit `bb0d0a64`) is now the
  **default** in zilc's scripts; the prebuilt stays for comparison (`tools/filc/compare-clangs.ts`).
  Two fixes in it: the cubic frame-slot colouring (KI-22, verified equal to the original on the whole
  corpus) and Fil-C's `indirectbr` lowering (**KI-4**). KI-4's fix lets **Debug compile at `-O1`**,
  which **fixed KI-19**. **The corpus is 78/78 as designed in ALL FOUR MODES**, gate 4/4, tests 24/24.
- 🔑 **Found:** Fil-C's output is **not reproducible under ASLR** (bears on the fidelity goal;
  `roadmap.md` P3, `workarounds.md` KI-22).
- ✅ **Option 3 researched and REJECTED:** Fil-C erases escaping allocas' lifetime markers before
  its liveness runs, so zilc-inserted markers could not help (`workarounds.md` KI-22). Debug's slow
  builds were a third KI-21 route (`unexpectedErrno` → stack-trace dump), now guarded (overlay v5):
  **Debug median 19 s → 4 s, same as ReleaseSafe; 78/78 in all modes.** Remaining: `69`-class
  programs (55.9 s vs native 16.9 s), inherent to instrumented code; the three levers were
  **approved by the owner at end of day** (next task, above).
- 📦 **The patched clang is also archived IN THE PROJECT** (owner, end of day): `toolchain/` (gitignored,
  never push) holds the tree (83 MB) and its debug info (966 MB), verified by a restore into a
  scratch directory: same objects, gate 4/4. A fresh machine restores it with
  `tools/filc/restore-patched-clang.ts` in a minute instead of a ~1 h rebuild. After any change to
  the patch, re-run `tools/filc/archive-patched-clang.ts`.
- 📚 **Upstream reference (owner, end of day; settles open question 6):** `upstream/fil-c/`
  (gitignored, read-only, never built) as in binaryen-ts. `tools/upstream/check-upstream.ts`
  monitors it (memory-update step 5). As of 2026-10-02: 105 commits past v0.685, 9 to
  `FilPizlonator.cpp`, none to `llvm-split`; all zilc edits (pass and `llvm-split`) still apply. ⚠️ **Not yet reviewed**: read those 9 commits
  (above all `097f7b7`, stack auxes, next to our colouring fix) and then run `--mark-reviewed`.
- 📏 **LF everywhere (owner):** `.gitattributes` is `* text=auto eol=lf`; reference clones use
  `core.autocrlf=false`; and since 2026-10-01 (owner) **global** `core.autocrlf=input`,
  `core.eol=lf` (overriding Git for Windows' system default `true`) across all projects.
- 🧹 **KI-23 (git maintenance errors after commits) closed:** repo-local config uses `gc` instead of
  the geometric task, which Windows and exFAT file semantics break. **Projects stay on D: for
  portability (owner)**, so this mitigation is final, and it travels with the repo.
- 🏷️ **Stale labels corrected:** KI-10 (fixed 2026-09-30 by KI-17), KI-6 (handled), the KI-11
  line, and the upstream-report loose end. README synced: Debug needs the patched clang; build
  times; layout.
- **State:** everything committed on `main`, **nothing pushed**. WSL has
  `build-essential` + `cmake` (owner installed; `ninja` 1.12.1 and gdb in `~/zilc-work/tools/`, no
  sudo needed). ⚠️ Build LLVM with `JOBS` ≤ 12 (32 crashed the WSL VM).
- **How to run things:** `tools/run-gate.ts` (gate); `tools/basics/zilc-check.ts` (`MODE=…`) and
  `all-modes.ts` (corpus); Windows-side builds need `C:\zig\0.15.2\zig.exe` and
  `ZIG_LOCAL_CACHE_DIR=C:\zig-cache\zilc`. Pass shell text to WSL as a **file** (KI-1).

## 🆕 2026-09-30 — the Zig runtime and other platforms now have a plan (no version bump)

- **Decided (owner):** the Zig-native runtime (P3) is built **on Linux first, checked against
  Fil-C**. Fil-C's pass and checked musl stay fixed; the runtime is swapped one layer at a time, and
  every gate case must match under both runtimes. The pass is **not** ported (`design-decisions.md`).
- **Shipped:** `zilc build --runtime filc|zig`. `filc` is the default; **`zig` is reserved and
  refused** until the Zig runtime is ready for testing. Tests **10/10**, gate **4/4** re-run.
- **Measured:** Fil-C's runtime contract. `libpizlo` exports 294 `filc_*` (pass → runtime), 1,032
  allocator/GC, and 335 `zsys_*` (the OS boundary). Details: `architecture.md` "The runtime contract".
- **Proposed, not adopted:** **P6 — other platforms**. Safe Zig on the major 64-bit OSes, safe C on
  Linux first. Zig's portability covers the runtime, but not the per-OS checked wrappers or a safe
  libc (`roadmap.md` P6, `design-decisions.md` open question #4).
- ▶️ **NEXT, the owner picks:** the **`zsys_write` spike** (`roadmap.md` P3: learns Fil-C's
  internal calling convention and the linking question) or **P4**. ⚠️ Before any runtime code:
  settle open question #3, port vs. clean-room rewrite.
- 🎯 **Goal (owner):** after the initial work, move to the **latest Zig with the least rework of
  the file layout**. Design for it now (`design-decisions.md` invariant 4): keep version-sensitive
  std calls few (about 31 sites today), and remember there are **two Zigs**, the one that builds
  zilc and the one that compiles user code, and only the second is pinned by Fil-C's LLVM.
- 🔄 **Upgrade procedure (owner):** **A** follow Fil-C to the Zig with the matching LLVM (the
  reference) → **B** port to the latest Zig if different, and require identical gate results →
  **C** benchmark comparison between versions. `upstream.md` "Upgrade procedure". The benchmark
  suite doesn't exist yet (`testing.md`).
- 🔖 ~~**Versioning (owner), APPLIED: the version is now `0.15.2-3`**~~ → **superseded 2026-10-05 by
  `<Zig>-<Fil-C>.<zilc release>` = `0.15.2-0.686.1`** (`releasing.md`). Was:, `<Zig line>-<zilc
  release>` (was `0.3.0`). Spelling verified with Zig's parser (`0.15.2_3` rejected: Zig reads it as
  `0.15.23`). **No 1.0, ever**: only `-N` advances, and **`N` restarts at 1 for every new Zig
  version, patch releases included** (e.g. `0.16.1-1`, `0.16.2-1`). Scheme fully settled
  (`releasing.md`).
- 🧭 **Lines and basis (owner):** the Zig part names the Zig a line is **built with**, not the Zig
  user code needs (corrected the same day; `root.zig`'s constant is now `zig_line`). The
  **reference line** tracks Fil-C's LLVM. Each **latest line** is ported from the newest reference
  release and names it as its **basis** (`0.16.2-1`, basis `0.15.2-100`). Port notes go in
  `cmem/ports/`. ⚠️ There's no release-notes file yet, and `zilc --version` should show the
  user-code Zig and the Fil-C release.
- 🎯 **FIDELITY FIRST, THEN STREAMLINE (owner):** the Fil-C → Zig port first reproduces upstream
  exactly (user-program binaries byte-identical, runtime results identical), and only then optimises
  beyond it, e.g. smaller binaries. At that point byte-identity no longer matters, but identical
  safety-guarantee results always do (`roadmap.md` P3, `design-decisions.md`). ✅ **Scope confirmed
  by the owner: byte-identity means the end user's COMPILED BINARIES**, not the libraries used to
  build them.
- 🧪 **`tests/basics`: 156 correct programs (owner's C + Zig lessons), 2026-09-30 → `testing.md`.**
  **C: 78/78 build and 77/78 run identically under zilc** (the one difference is `abort()` exiting
  133). **Zig 0.15.2: all 78 build and run with plain Zig, but only 24/78 run under zilc**, all
  because of std: **KI-7** raw `syscall` asm (even `std.debug.print`), **KI-8** `__zig_probe_stack`
  in ReleaseSafe (an easy driver fix), **KI-9** f128 helpers, **KI-10** `pthread_join`. Sizes: C
  zilc is 0.86× Zig ReleaseSmall stripped. Zig zilc is 1.26× ReleaseSafe and 4.36× ReleaseSmall,
  stripped. Every zilc program also needs a ~20 MB shared runtime. Licence: CC BY 3.0 via Go by
  Example, test-only, first ledger entry.
- 🔭 **P3 SCOPING STARTED (2026-09-30), on 0.15.2 → `filc-abi.md`.** Fil-C's runtime ABI was
  decoded from post-pass IR, headers and binaries, **not runtime source**. `pizlonated_X` is a
  *getter* returning a **function object**; calls use a fast or generic entry through the thread's
  cc buffers; the header word at `lower−8` holds the aux pointer and object kind. **This reorders P3:
  the shared ABI core is step 0**, before any `zsys_*`. Overriding by linking looks workable (not
  yet run). It's also evidence that a **clean-room** runtime is feasible (open question #3).
  ✅ **Design docs read** (`invisicap.txt`, `gimso_semantics.md`, `Manifesto.md`), closing most
  gaps: the header is `{size, aux}`, aux holds lowers or atomic boxes, `inttoptr` loses capabilities
  across loads and calls, and the **FUGC protocol requires exiting before any blocking call**. So
  KI-7's raw syscalls would also stall the GC. ✅ **Probed:** the pollcheck flag is a byte at
  thread + 8 (mask `0x0E`) → `filc_pollcheck_slow`, and blocking calls are `filc_exit` → syscall →
  `filc_enter`. **The ABI is observed enough to start step 0**, once open question #3 is settled.
  Probes: `tools/p3/`.
- 🛠️ **Fixed 2026-09-30:** **KI-8** (`-fno-stack-check` in every mode: Zig builds under zilc
  50 → 77/78) and most of **KI-7** (raw `syscall` asm → the checked `zilc_syscall` helper: Zig runs
  correctly 26 → **45/78**). Rule recorded: **nothing unsafe is left to chance**
  (`design-decisions.md` invariant 5). Then the **panic handler** (Fil-C `zerror`, no `getcontext`) and
  **KI-9** (f128 helpers through the pass): Zig as designed **50/78**. **Next for the corpus:** 26 × "pointer with null
  object", the new top failure.
- ✅ **OWNER DECISIONS, 2026-09-30** (`design-decisions.md`): **(1) ~~clean-room runtime: never read
  Fil-C's runtime source~~ → CORRECTED 2026-10-01 (owner): the intent is LICENCE COMPLIANCE.**
  Fil-C's source (pass and runtime) may be read; the Zig runtime is new Zig code; every adaptation
  is ledgered and its notice carried (`licensing.md`). **(2) upstream defects are noted for the
  record, not filed** (refined 2026-10-01: a short email pointing to `UPSTREAM-ISSUES.md`).
  **(3) publish as `v0.15.2-3`** (now `v0.15.2-0.686.1`) after the open items and the platforms scope, before the port
  (move the local tag and branch, `releasing.md`). **(4) platforms: Linux, macOS, Windows on every
  prevalent processor, then iOS, Android later** (`roadmap.md` P6; ✅ x86_64 + aarch64 confirmed;
  riscv64 out of scope for now, low interest).
- 📋 **PRE-PUBLISH CHECKLIST (all must close before `v0.15.2-0.686.1` is pushed; was `v0.15.2-3`):**
  - [x] **KI-18**: Fil-C assertion on 2 programs (every mode). ✅ 2026-10-01, `ir.wrapThreeByteGlobals`
  - [x] **KI-20**: `madvise` probe in `std.crypto.random`. ✅ 2026-10-01, `crypto_always_getrandom`
  - [x] **KI-21**: dead stack-trace code compiled into every program. ✅ 2026-10-01, std-overlay guards
  - [x] **KI-22**: build time on big functions and Debug. ✅ Option 2 done (patched clang, default);
    option 3 researched and rejected; Debug builds now as fast as Release
  - [x] **Build-speed options (a) parallel parts, (b) faster interference, (c) object cache** for
    `69`-class programs. ✅ 2026-10-02: `69` 55.9 → 35.9 s cold, 2.3 s unchanged; `--clean-cache`
  - [x] **KI-19**: Debug syscall pointer arguments (12 programs). ✅ 2026-10-01, Debug at `-O1` via the
    KI-4 patch
  - [x] **KI-4** (Debug `-O1` crash), the root of KI-19. ✅ 2026-10-01, patched `indirectbr` lowering
  - [x] **Output comparison**: corpus output vs native, not just exit codes. ✅ 2026-10-02: 0
    unexplained differences in 624 comparisons (C + Zig, 4 modes); `tools/basics/compare-output.ts`,
    `testing.md` "Output comparison"
  - [x] **Library mode** (C owns `main`): panic handler, page-allocator hook and (KI-20)
    `crypto_always_getrandom` not applied. ✅ 2026-10-02: a generated LIBRARY root module
    (`library_shim`, sharing `shim_hooks` with the entry shim); gate cases 6–8 (gate 8/8 with KI-5's case 5)
  - [x] **KI-5**: `std.os.environ` unset by the entry shim. ✅ 2026-10-02: set from libc's
    `environ` (gate case 5); stack expansion measured NOT needed (zilc recurses ~4× deeper than
    native); segfault handler n/a; library mode matches native
  - [x] `zilc --version` shows the user-code Zig and Fil-C release; create a **release-notes file**.
    ✅ 2026-10-05: `--version` also checks the machine's Zig and Fil-C clang (ok/MISMATCH, patched
    build or stock); `zilc build` warns on the wrong Zig; `RELEASE-NOTES.md` (`releasing.md`)
  - [x] **Fil-C's own test suite against zilc's patched clang** (owner, 2026-10-05). ✅ Same day:
    **0 differences** between stock and patched on all 7,003 tests (0.685); 5,778/5,779 runnable
    pass with both (the 1 needs a CPU feature WSL lacks). No Ruby needed: `tools/filc/run-filc-tests.ts`
    (Deno port). It also found a MACHINE problem: a dangling `os-include/asm` link broke every
    program using kernel headers; fixed (`fix-os-include.ts`). `testing.md`, `workarounds.md`
  - [x] **Upstream review + move to Fil-C 0.686** (owner, 2026-10-05). ✅ Same day: the 10
    `FilPizlonator.cpp` commits reviewed (`upstream.md`), zilc rebuilt on 0.686 and re-verified
    (corpus, output comparison, gate, Fil-C suite); version `0.15.2-0.686.1`
  - [x] **Platforms scope pass** (P6): per platform, the processors, the std OS-function count, the
    libc story, KI-5-family code, and the host toolchain. ✅ 2026-10-05: `platforms.md`
  - [x] Then: tag `v0.15.2-0.686.1`, DELETE the local tag `v0.15.2-3` (it sorts above the new
    one), move branch `v0.15.2` to the final commit, and push. ✅ 2026-10-05, published
  - Deferred past publish (with the port): `-Druntime=both`, the byte-identity check, the
    benchmark suite (stage C), and the 0.16.0 examples under zilc
- 🔑 **Pipeline change (2026-09-30): zilc now takes Zig's UNOPTIMIZED IR (KI-17).** Zig's `-femit-llvm-ir` is
  post-optimisation under an integral layout, which turned pointer loads into integers. With it:
  **ReleaseSafe, ReleaseFast and ReleaseSmall each 76/78 as designed** (identical); Debug 63/78.
  Open: **KI-18** (a Fil-C assertion, 2 programs, every mode) and **KI-19** (Debug-only syscall
  pointer arguments, 13). KI-15 is fixed by owner-chosen option 1 (`sys_can_stack_trace = false`).
- 🧭 **The 2 bounds violations (2026-09-30):** **69** (the `mmap` hint) is **fixed** through std's
  `root.os.heap.page_allocator` hook (KI-12). **67** (`indexOfSentinel` over-read) is std's own
  SIMD scan, **already fixed upstream in 0.16.0**, and documented for a possible Zig report
  (`zig-upstream-notes.md` Z-1). ✅ **KI-11 decided and done 2026-09-30 (owner): the 0.16.0
  backport**, through a version-keyed **std overlay** (`src/stdpatch.zig`, each patch verifying its
  original). Both bounds violations are cleared.
- 🔒 **STAY ON ZIG 0.15.2 UNTIL THERE IS A STABLE BASE (owner).** A 0.16.0 trial port was
  stopped. Its facts are in `ports/README.md` "Scouting": Fil-C head is still LLVM 20.1.8, latest
  Zig is 0.16.0 (clang 21), and Fil-C ships ARM64 builds.
- 🌿 **One git branch per Zig line (owner), named `v<zig>`:** `main` is the base (the reference
  line), and **`cmem/` is authoritative on `main` only**, with port notes in `cmem/ports/`. The
  first release tag is **`v0.15.2-3`**, and branch **`v0.15.2`** was cut from the same commit
  (local, not pushed). ⚠️ Never create a tag named just `v0.15.2`; it would clash with the branch
  (`releasing.md`).
  Tests **11/11**, gate 4/4 after the change.
- **Loose ends:** ~~`std.os.environ` (KI-5, on the pre-publish checklist)~~ ✅ 2026-10-02. ~~The upstream Debug report
  (owner files it)~~ superseded 2026-10-01: upstream reporting is optional and not planned, and the
  Debug crash (KI-4) is fixed in zilc's patched clang.

## 🏁 STATE AT PAUSE — 2026-09-23. ✅ **P1 AND P2 ARE COMPLETE (`0.3.0`). zilc WORKS.**

**Read this first; it is the shortest true summary of where the project stands.**

🎯 **One command compiles Zig and C into a binary where memory-safety violations trap at a named
source line** — and it needs **no Zig fork and no LLVM build**:

```
$ zilc build examples/interop/c_caller.c examples/interop/bounds.zig -o interop && ./interop
in bounds ok, sum=6
filc safety error: cannot write pointer with ptr >= upper.
semantic origin:  bounds.zig:13:6: zig_add   ←  c_caller.c:26:5: main      exit 133
```

C allocated the memory, **Zig** overflowed it, and the capability survived the language boundary.

| gate | value | note |
| --- | --- | --- |
| version | **`0.15.2-0.686.1`** | zilc release 1 for Zig 0.15.2 and Fil-C 0.686 (was `0.3.0`, then `0.15.2-3`; scheme changed 2026-09-30 and 2026-10-05, `releasing.md`) |
| **`zig build gate`** | **4/4** | 🎯 **the safety gate** — every example traps at the right file:line. **Inversion-tested.** ⚠️ SKIPS (exit 0) without Fil-C |
| `zig build test` | 11/11 | incl. the IR-rewrite unit tests, which caught two real bugs, the `--runtime zig` refusal, and the version round-trip (2026-09-30) |
| `zig build` | green | CLI `zilc` + static `zilc_runtime` + `zilc.h` |
| `zig build capi-smoke` | green | C client links the runtime via `zilc.h` |
| `zig build baseline` | green | the same bugs under plain `zig cc`: **exit 0, undetected** — the contrast the project exists for |
| third-party code | **none incorporated** | zilc *invokes* Fil-C and Zig; it ships neither. Ledger EMPTY |

### How it works, in three lines

1. Stock **Zig** emits LLVM IR (`zig build-obj -femit-llvm-ir`).
2. zilc rewrites **two `target datalayout` lines** into Fil-C's dialect (`src/ir.zig`).
3. **Fil-C's clang** runs the GIMSO pass and links. C/C++ inputs go straight to it.

### What was learned that the code does not say

- 🔑 **Fil-C's IR is a two-line dialect, not a different IR.** `ni:0` on address space 0 (which stock
  LLVM refuses on purpose) plus `datalayout_after_filc`. Everything else is ordinary LLVM IR — KI-4.
- 🔑 **Zig's `start.zig` cannot run under Fil-C**: `@ptrFromInt(getauxval(AT_PHDR))` forges a pointer
  from an integer, which InvisiCap forbids outright. zilc generates a C-ABI entry instead — KI-5.
  ⚠️ **`@ptrFromInt` is ordinary Zig used across `std`; every use is a potential trap site.** That is
  P4's problem, and the most likely source of future surprises.
- ⚠️ **A Debug-mode crash in Fil-C's pass is upstream's bug**, reduced from 1,110 functions to 8 and
  written up in `tools/p2/repro/`. **The owner will file it** (owner, 2026-09-23).
- 🎓 **Two wrong conclusions were published in this very file during the day and later overturned**
  ("the cheap route is dead"; "Zig walks off the end of envp"). Both are kept with their corrections,
  in `roadmap.md` P1 step 3 and KI-5. *The failure mode was the same twice: reasoning from one
  unvaried default, and from a function's name instead of its body.*

**Toolchain: Zig 0.15.2, for the whole repo** (owner, 2026-09-18). It bundles clang **20.1.2**,
the same major as Fil-C's LLVM **20.1.8**. ⚠️ **It is at `C:\zig\0.15.2\zig.exe`, not on PATH.**
Bare `zig` is scoop's **0.16.0** (kept for wazmrt), and it fails to build zilc. zilc moves to 0.16
only when Fil-C reaches LLVM 21. See `known-issues.md` KI-3.

```powershell
$env:ZIG_LOCAL_CACHE_DIR = 'C:\zig-cache\zilc'
& C:\zig\0.15.2\zig.exe build test
```

### 🎯 NEXT — **P4: Zig language fidelity** (nothing is blocked; this is a fresh start)

P1 and P2 are closed. The next work is making Zig's *language* safe under the target rather than
just its output: how slices, optionals, `allowzero`, `@ptrCast` and above all **`@ptrFromInt`** map
onto capabilities, and what breaks when real `std` code runs. See `roadmap.md` P4.

**Two loose ends, neither blocking:** the owner files the upstream report when ready, and the entry
shim leaves `std.os.environ` unset (nothing tested needs it yet — KI-5). *(Both closed later: the
report is not planned, 2026-10-01; `std.os.environ` is set, 2026-10-02.)*

**Where to start next session:** `zig build gate` must be 4/4 before anything is believed. Run
`tools/run-gate.ts`, and read the first line — it prints `SKIPPED` rather than failing when the
Fil-C toolchain is missing.

### 🔒 Three things to know before touching anything

1. **Fil-C work happens in WSL2** (Ubuntu 26.04), under `~/zilc-work/`. ⚠️ **`sudo` needs an
   interactive password**, so install prebuilt binaries into `$HOME` rather than using `apt`. ⚠️
   **Pass shell text to WSL as a FILE** (`wsl.exe -e sh <file>`); PowerShell mangles it inline.
   (zilc's own tools no longer need this: since 2026-10-05 they are Deno and bridge into WSL with an
   argument list, `tools/README.md`. The rule stays for ad-hoc commands.)
   See `known-issues.md` KI-1.
2. **D: is exFAT. Set `ZIG_LOCAL_CACHE_DIR=C:\zig-cache\zilc` before any `zig build`.** A
   `.zig-cache` on exFAT works for exactly one build, then fails with `error: Unexpected` until it
   is deleted. This was learned the hard way in wazmrt and reconfirmed here 2026-09-18. See
   `known-issues.md` KI-2.

---

## Policy (durable — adopted from wazmrt 2026-09-18)

- **`cmem/` is the single home for ALL project memory.** When the owner says "**update the project
  memory**", fold the latest decisions, found bugs, design changes and current state into the
  matching `cmem/` topic file(s), then refresh its one-line pointer in the Files table below.
  Convert relative dates to absolute. Update existing entries rather than duplicating them.
- **`README.md` is NOT project memory.** It is the public, user-facing document. Keep internal
  decision logs and post-mortems out of it.
- **`third_party/LICENSES.md` is the compliance source of truth.** `licensing.md` records the *why*;
  the ledger of actually-reused code lives in `third_party/LICENSES.md`. Keep them consistent.

### The "update the project memory" trigger (binding on every agent)

When the owner says **"update the project memory"** (or "update memory", "record this", "remember
this for the project"), do all of the following:

1. **Revise all relevant `cmem/` files.** Fold in the change, refresh the Files-table pointer,
   convert dates to absolute, and update entries instead of duplicating them.
2. **Sync `README.md` only where the change is user-relevant** (build, usage, status).
3. **If the work produced a transferable METHOD lesson, add it to
   [`best-practices.md`](best-practices.md)** as one bold rule plus a citation to the incident.
4. **Keep the patched Fil-C clang archived in the project (owner, 2026-10-01).** Run
   `deno run -A tools/filc/check-toolchain.ts`. If it reports STALE (a new patch
   or workaround in Fil-C's source in WSL, a rebuilt compiler, or an archive from an older patch),
   do what it says before finishing. In order:
   1. Every change to Fil-C's source goes into an edit script, the source of truth:
      `tools/filc/patch-pass.ts` (the pass) or `tools/filc/patch-split.ts` (`llvm-split`).
   2. Rebuild with `build-patched-clang.ts`. Then run Fil-C's own test suite with the stock and
      the patched clang and compare (`tools/filc/run-filc-tests.ts`, `testing.md`): the result
      must stay **0 differences** (2026-10-05).
   3. Save the diff to `third_party/filc-patches/zilc-filc-pass.patch`.
   4. Re-archive with `archive-patched-clang.ts`.
   5. Update the ledger entry `filc-pass-fixes` and `workarounds.md`.

   `toolchain/` is gitignored, so the archive itself is never committed, but the patch, the
   scripts and the checksum line in the ledger are.
5. **Check Fil-C upstream for changes (owner, 2026-10-01):** `deno run -A tools/upstream/check-upstream.ts`
   (any OS). Record in `upstream.md` anything that touches a watched file, above all whether
   zilc's pass patch still applies. After reviewing, `--mark-reviewed`, and commit
   `tools/upstream/REVIEWED`. The reference clone is `upstream/fil-c/` (gitignored, never built).

### The "workaround" rule (binding on every agent; owner, 2026-10-01)

**Every workaround gets copious WHY notes in [`workarounds.md`](workarounds.md) when it is made**,
whether the cause is an upstream defect or a system limitation: the exact symptom, the class, the
root cause (measured vs. surmised, kept apart), why the fix is correct, what was ruled out, how it
was found, how to recognise a relative, and the cost and exit condition. Owner: *"so that when we
run into similar issues we can quickly identify those past problems and their resolutions, and
investigate and surmise potential similar resolutions."* **A new failure is looked up in
`workarounds.md`'s symptom index and families first.**

### The "adopt upstream code" trigger (binding on every agent)

Before incorporating or adapting code from Fil-C, LLVM or Zig (see `reference-projects.md`,
`upstream.md`), complete the **Adoption Checklist** in `third_party/LICENSES.md`, add a Component
Ledger entry, and update `reference-projects.md`. *Looking at* upstream code is free. *Copying or
porting* it always requires the ledger entry, and code that ends up in the **runtime** also needs
the runtime-linking rule checked.

---

## Files

| File | What it holds |
| --- | --- |
| [overview.md](overview.md) | What zilc is, repo layout, key files, build steps. |
| [vision.md](vision.md) | The goal: one `zig` binary that compiles Zig, C and C++ to a single memory-safe target. Owner's framing (via a Gemini discussion, 2026-09-18), with the claims that still need verifying marked. |
| [architecture.md](architecture.md) | Target pipeline (frontend → LLVM IR → zilc pass → `zilc_runtime`), the InvisiCap and FUGC components, what exists today, and 🔑 **the runtime contract measured 2026-09-30** (`libpizlo`'s four layers, by symbol count). |
| [design-decisions.md](design-decisions.md) | Invariants, decisions made so far, and the **open questions** that must be settled with the owner. **2026-09-30: Linux-first Zig runtime checked against Fil-C, `--runtime filc\|zig`, the pass not ported; #4 platform analysis; #3 now blocks runtime code.** Zig 0.15.2 API + Windows build notes (0.15.2 is at `C:\zig\0.15.2`, not on PATH). |
| [upstream.md](upstream.md) | 🆕 2026-10-05: **"Review of Fil-C 0.686"** (the 10 pass commits; what zilc gains; KI-4/KI-18 still upstream). 2026-10-01: **the `upstream/fil-c/` reference clone and its monitor** (`tools/upstream/`, first-run results), and reporting marked not planned. How zilc relates to Fil-C upstream: what to track, which files matter, pinned commit, and 🔄 **the three-stage upgrade procedure (2026-09-30)**: Fil-C + compatible Zig → latest Zig → benchmarks. |
| [licensing.md](licensing.md) | **License = `Apache-2.0 WITH LLVM-exception OR MIT`** (2026-09-18). Why, the runtime-linking rule, the copyleft exclusion. |
| [reference-projects.md](reference-projects.md) | Fil-C, LLVM, Zig: verified licenses, what to mine each for, adoption status. |
| [platforms.md](platforms.md) | 🆕 2026-10-05: **the P6 scope pass**: per platform the processors, OS-function counts (corpus and whole std), int-to-pointer sites, libc and host story. Linux aarch64 measured (4 gaps); Fil-C's new **cosmo mode** (APE binaries for macOS/x86_64 Windows, Linux-x86_64 C ABI) |
| [roadmap.md](roadmap.md) | P0 ✅ → P1 ✅ → P2 ✅ (`0.3.0`) → **P3 Zig runtime (plan 2026-09-30: Linux first, checked against Fil-C, `zsys_*` first; next step the `zsys_write` spike)** → P4 Zig-language fidelity → P5 C++ → **P6 other platforms (proposed 2026-09-30)**. |
| [security-model.md](security-model.md) | The safety guarantees being targeted (spatial, temporal, thread-safe capability updates), and what is explicitly out of scope. |
| [testing.md](testing.md) | Current gates (gate 8/8, tests 29/29 on 2026-10-05, re-verified on Fil-C 0.686, with the exact commands), 🆕 the OUTPUT COMPARISON vs native (0 unexplained differences, 2026-10-02), corpus results per mode and (2026-10-01) build times, the recorded expected panics, and the planned gates: `-Druntime=both`, the between-versions comparison, and the benchmark suite. |
| [known-issues.md](known-issues.md) | 🆕 2026-10-01: **KI-4, KI-10, KI-18, KI-19, KI-20, KI-21 fixed; KI-22 (build time) DONE** (patched Fil-C clang; option 3 rejected; levers (a) parallel code generation, (b) dense interference graph, (c) object cache, all 2026-10-02: `69` 55.9 → 35.9 s cold, 2.3 s unchanged). Partly open: KI-7 (`getcontext`), KI-5. KI-23 (git maintenance on exFAT) closed with a final mitigation. 🔑 **KI-4 (2026-09-23): Fil-C's IR is a PATCHED-LLVM DIALECT** (`ni:0` + `datalayout_after_filc`), so stock IR cannot enter the pass — this decided the integration route. KI-1 ✅ resolved (WSL2 installed; `sudo` needs a password); KI-2 exFAT zig-cache; KI-3 LLVM 20 vs 21 skew. |
| [workarounds.md](workarounds.md) | 🆕 2026-10-01 (2026-10-02: KI-22 levers (a), (b), (c), with the why of each piece: use-list order, unused TLS declarations, objcopy and Zig names, the dense graph's equal-graph details, the cache key). **The WHY of every workaround** (owner rule): symptom index, five failure families (F1 pass rejects valid IR, F2 capability lost through an integer, F3 inline asm, F4 code outside the pass, F5 std out of bounds), the entry template, KI-18 in full, and short forms of KI-4…KI-17. **Look up new failures here first.** |
| [releasing.md](releasing.md) | 🔖 **Version `0.15.2-0.686.1`** (2026-10-05): `<Zig>-<Fil-C>.<zilc release>`, the publish plan (delete local tag `v0.15.2-3`). Earlier: `<Zig line>-<release>`, the **basis** each latest-line release names, how to bump it, why `.` and `_` were rejected, no 1.0, `-N` restarts at 1 per Zig version, the four places the number lives. The old minor-per-phase cadence is retired. |
| [filc-abi.md](filc-abi.md) | 🆕 2026-09-30. **Fil-C 0.685's runtime ABI as OBSERVED** (post-pass IR, headers, binaries; no runtime source): flight pointers, the object-header word, function objects and getters, the fast and generic calling convention, the thread layout, linking and overriding. What P3 must match, and its scoping consequences. |
| [zig-upstream-notes.md](zig-upstream-notes.md) | 🆕 2026-09-30. **Zig behaviours we may need to report** (owner asked): Z-1 `indexOfSentinel` over-read (fixed in 0.16.0; report draft and repro in `tools/zig-reports/`), Z-2 the `mmap` hint, Z-3 raw syscalls, Z-4 `getcontext`, Z-5 `DebugAllocator` integer arithmetic. Each with whether it is really a Zig bug. |
| [ports/](ports/README.md) | 🆕 2026-09-30. **Port notes: one file per new Zig line, named by its first release** (`ports/0.16.2-1.md`): its basis, each API change and fix, the sites touched. `ports/README.md` holds the guide, the template, and, seeded with the 2026-09-18 0.16 → 0.15.2 move, whose API list is the 0.15.2 → 0.16 port in reverse. |
| [best-practices.md](best-practices.md) | Method rules. Seeded from wazmrt, plus zilc's own: verify toolchain versions in the build files **and** the binary; a minimum-version field is not a pin; no heredocs; Deno/Bun for scripts; (2026-09-30) measure the contract before planning a port; reserve a switch by refusing, never by falling back. |

## Related files outside cmem

- `README.md`: the public, user-facing doc. NOT project memory.
- `third_party/LICENSES.md`: the compliance ledger, adoption checklist and verified inventory.
- `LICENSE-APACHE` / `LICENSE-MIT` / `NOTICE`: the dual license texts and attribution notice.
