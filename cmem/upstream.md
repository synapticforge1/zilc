# Upstream — tracking Fil-C

**Upstream:** https://github.com/pizlonator/fil-c, default branch **`deluge`**.
**Pinned at project start (2026-09-18):** `cd830ff67170486aaa74c253ae6ba665a2a601b5`.
**Site/docs:** https://fil-c.org/

The Fil-C repo is a **full llvm-project fork** (llvm, clang, lld, lldb, mlir, flang, libcxx…) plus
Fil-C's own directories. GitHub's license detector reports it as `NOASSERTION` because the tree is
multi-licensed (see `licensing.md`).

## Files that matter to zilc

| Upstream path | What it is | License |
| --- | --- | --- |
| `llvm/lib/Transforms/Instrumentation/FilPizlonator.cpp` | **The pass.** "Apply GIMSO semantics to LLVM IR" | Apache-2.0 WITH LLVM-exception |
| `clang/` (Fil-C diffs vs clang 20.1.8) | Frontend changes; size TBD | Apache-2.0 WITH LLVM-exception |
| `libpas/src/libpas/filc_runtime.c`, `filc_*.c/h` | **The runtime** | BSD-2-Clause |
| `libpas/` (rest) | Allocator substrate, incl. FUGC | BSD-2-Clause |
| `filc/include/stdfil.h` | Public Fil-C API header for programs | BSD-2-Clause |
| `filc/tests`, `filc/run-tests` | **Test corpus**, a candidate conformance suite for zilc | BSD-2-Clause (verify per file) |
| `projects/usermusl`, `projects/yolomusl` | The two-level libc | MIT |
| `yolounwind/` | Unwinder | verify |
| `invisicap.txt`, `invisicaps_by_example.md`, `gimso_semantics.md`, `Manifesto.md` | **Design docs**, read first | n/a (docs) |
| `README.md` | Build and license overview | n/a |

Excluded: `projects/*` other than the musl pair, `pizlix/`, and the glibc variant (see
`third_party/LICENSES.md` → Copyleft exclusion).

## 🔄 Upgrade procedure: Fil-C first, then the latest Zig (owner, 2026-09-30)

Every upgrade runs in **three stages**. Stage A produces a known-good **reference**, stage B is
checked against it, and stage C benchmarks all of them. Nothing moves to the latest Zig without
first passing on the Zig that matches Fil-C.

### Stage A: follow Fil-C to the COMPATIBLE Zig (the reference)

1. Record the new upstream SHA **and the prebuilt release version** (0.685 today) here, with the date.
2. **Check Fil-C's LLVM version** (`cmake/Modules/LLVMVersion.cmake`; 20.1.8 at the pinned SHA).
   Find the Zig release whose bundled LLVM has **the same major**. That is the *compatible Zig*
   (0.15.2 ↔ LLVM 20 today; verify in Zig's build files **and** with `zig cc --version`, per
   `best-practices.md`).
3. Diff only the files in the table above between the old and new SHA. Port the changes to anything
   zilc has adapted (see the ledger) and update each ledger entry's pinned commit. Re-measure the
   runtime contract (`architecture.md`), since a changed object layout breaks the P3 runtime.
4. Move the repo to the compatible Zig, if it changed. Re-run `zig build test` and `zig build gate`
   until they pass.
5. **Freeze the reference:** record the gate output, test count and stage-C numbers for this
   pair (Fil-C version + compatible Zig).

### Stage B: port to the LATEST Zig, if it is a different release

1. On **the new line's own branch, created from the latest reference release's tag** (the
   **basis**; one branch per Zig line, `releasing.md`), port zilc to the latest Zig, so the conversion is as small as possible. Start from the previous line's entry in
   `ports/<version>.md`, and follow `design-decisions.md` invariant 4 (fix the counted
   version-sensitive sites, keep the layout). The result is a new line, `<latest Zig>-1`, whose
   release notes name the basis (`releasing.md`).
2. ⚠️ **Only the Zig that builds zilc moves.** The Zig that compiles user code (`ZILC_ZIG`) stays on
   the compatible release, because Fil-C's LLVM has to read its IR. This procedure is what puts the
   two-Zig split into practice (invariant 4).
3. **Compare against the reference:** same tests passing, and **identical gate results**: every
   case traps with the same fault kind at the same file:line. Any difference is a porting bug until
   shown otherwise.
4. **One recorded experiment:** try the latest Zig as `ZILC_ZIG` too. IR from a newer LLVM major is
   expected to be rejected by Fil-C's LLVM. If it isn't, that's worth knowing, but it is not relied
   on.
5. **Write the port notes** in `ports/<version>.md` while the port is fresh: every API change hit, the
   fix, and which sites it touched. **Later changes** to the reference line are carried to the
   latest line the same way, and each resulting release names its new basis.

### Stage C: benchmark comparison between versions

Compare **previous reference → new reference (A) → latest-Zig port (B)**, on the same machine:

| metric | why |
| --- | --- |
| run time of each benchmark program, zilc vs. plain `zig` (baseline) | **zilc's own slowdown figure**, which `vision.md` still lists as unmeasured |
| run time, version vs. version | did an upgrade make the checked code slower or faster |
| `zilc build` wall time per program | compile-time cost of the upgrade |
| binary size (ReleaseSafe and Debug) | Debug is already 108× (KI-4); watch it |

⚠️ Performance claims need **repeats and a stated noise floor** (`best-practices.md` §1). A benchmark
suite does not exist yet (`testing.md`, planned gates).

## ✉️ Reporting upstream (owner, 2026-10-01)

> **Status (owner, later 2026-10-01): NOT PLANNED.** Licence compliance needs only our own
> documentation (`design-decisions.md`); reporting is optional goodwill. `UPSTREAM-ISSUES.md` is
> kept as documentation, and the email template below is kept in case that changes.

**One public file, one short email.** Every upstream defect worth telling a project about goes into
[`UPSTREAM-ISSUES.md`](../UPSTREAM-ISSUES.md) at the repo root, under that project's heading. The
owner then sends a brief email that just says an issue was found and links the file. No GitHub
issue, no long report (some upstreams are anti-AI; the owner does not want to deal with that).

**Rules for `UPSTREAM-ISSUES.md`:** plain facts only: version string, a self-contained repro file
in the repo, the one-line command, what happens, what was tried, and the workaround. No KI numbers,
no `cmem/` links, no internal vocabulary, no mention of how it was produced. Only **real defects**
go in, not std design choices (`zig-upstream-notes.md` "Zig bug?" column) or things already fixed
upstream. Keep `cmem/workarounds.md` as the full internal why.

**Link** (works only after `main` is pushed):
`https://github.com/jrmarcum/zilc/blob/main/UPSTREAM-ISSUES.md`

**Email template** (fill in the project and the count):

> Subject: Fil-C 0.685: two compiler issues found (reproductions attached in a repo)
>
> Hello,
>
> While compiling Zig-generated LLVM IR with Fil-C 0.685, I found two issues in the
> FilPizlonator pass: an assertion failure on globals with a 3-byte value type, and a segfault at
> -O1. Each has a small reproduction file, and the details are here:
>
> https://github.com/jrmarcum/zilc/blob/main/UPSTREAM-ISSUES.md
>
> Neither is blocking me; I'm passing them on in case they're useful.
>
> Thanks for Fil-C,
> Jon Marcum

**Who:** Fil-C (`pizlonator/fil-c`): the owner picks the address. Zig: nothing open (Z-1 is fixed
in 0.16.0). The old GitHub-issue draft `tools/p2/repro/UPSTREAM-REPORT.md` is kept as a record
but superseded.

## 📚 The `upstream/` reference folder (owner, 2026-10-01; settles open question 6)

**Pattern taken from binaryen-ts** (`wasmExamples/binaryen-ts/upstream/`): a **plain git clone,
gitignored, never built, a read-only reference**, kept up to date with upstream's branch and
**monitored for changes**. It is used for comparisons with what zilc changed. Not a submodule:
binaryen-ts learned that a submodule leaves a wedged nested repo in the IDE ("submodule remnant",
its `publishing.md`).

- **Where:** `upstream/fil-c/` (gitignored as `/upstream/`), branch **`deluge`**. Note that
  `pizlonator/llvm-project-deluge`, the name in `clang --version`, redirects to `pizlonator/fil-c`.
- **Shape:** partial (`--filter=blob:none`), shallow (history from v0.684 on, so v0.685 and
  everything after), and sparse. The sparse set is Fil-C's pass and its headers
  (`llvm/lib/Transforms/Instrumentation`, `llvm/include/llvm/Transforms/Instrumentation`), LLVM's
  `CodeGen` (`IndirectBrExpandPass.cpp`, which KI-4's broken lowering was copied from), the runtime
  (`libpas`, and `filc` without its 15,603-file `tests/`), plus the top-level docs and build
  scripts. About 450 MB.
- **Create:** `sh tools/upstream/clone-upstream.sh` (Git Bash). It sets, **in the clone only**:
  - `core.autocrlf=false`: upstream's exact LF bytes; the global `true` broke exact-text matching;
  - `core.protectNTFS=false`: Fil-C bundles files whose names Windows forbids (`aux.h`, `:`, `\`),
    all outside the sparse set, which Git for Windows otherwise refuses even to index;
  - `core.longpaths=true`.

  Once per machine, because D: is exFAT (no file ownership):
  `git config --global --add safe.directory …/zilc/upstream/fil-c`. That's the same as every other
  project's `upstream/` in your global config.
- **Monitor:** `sh tools/upstream/check-upstream.sh`. It fetches, then reports, relative to the last
  reviewed commit in `tools/upstream/REVIEWED` (committed):
  - new commits and new release tags;
  - commits touching **watched files** (the pass zilc patches, `IndirectBrExpandPass.cpp`,
    `llvm-split.cpp` and `SplitModule.cpp` (since 2026-10-02, KI-22 lever a),
    `configure_llvm.sh`, `libpas/common.sh`, the runtime headers, the design docs, the versioning
    checklist);
  - **whether zilc's patches still apply** to upstream's newest `FilPizlonator.cpp`
    (`patch-pass.ts --check`) and `llvm-split.cpp` (`patch-split.ts --check`, since 2026-10-02);
    exit 1 if an edit's original text is gone. `llvm/tools/llvm-split` joined the sparse set for
    this (`clone-upstream.sh`; on the existing clone: `sparse-checkout add llvm/tools/llvm-split`).

  After reviewing, `--mark-reviewed` records the new head; commit `REVIEWED`.
- **First run (2026-10-01):** reviewed = v0.685 (`bb0d0a64`, our build). Upstream `deluge` is at
  `69522cf` (2026-09-30), **104 commits ahead, no new release tag**. Watched-file hits: **9 commits to
  `FilPizlonator.cpp`** (e.g. `097f7b7` "Give always-live explicit stack auxes their own frame
  slots", which is in the stack-aux colouring code we patch; `26a97be` C++20 coroutines and
  musttail; `635e0b7` setjmp by name), 1 to `configure_llvm.sh` (cosmo aarch64), 1 to `filc/include`
  ("Versioning"). **All four zilc edits still apply** textually. ⚠️ The stack-aux commit must be
  re-verified semantically (rebuild with `ZILC_VERIFY_COLOURING=1`) at the next Fil-C upgrade.
  **Not yet marked reviewed.**
- **Run of 2026-10-02:** upstream `deluge` at `9e72307` (2026-10-01), **105 commits ahead**, no
  new release tag. Watched-file hits unchanged (the same 9 to `FilPizlonator.cpp`, 1 to
  `configure_llvm.sh`, 1 to `filc/include`); **none to `llvm-split.cpp` or `SplitModule.cpp`**.
  **All pass edits (five, with KI-22 lever (b)'s, re-checked later the same day) and all three
  `llvm-split` edits still apply.** Still not marked reviewed:
  the 9 pass commits (above all `097f7b7`) have not been read yet.
- **When to run it:** at every "update the project memory" (`INDEX.md` policy, step 5), and before
  any Fil-C upgrade (stage A above).
