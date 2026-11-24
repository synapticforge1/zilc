# review-process.md — zilc's slots in the review standard

The standard is `../workspace/cmem/review-process.md` (🔒 owner, 2026-11-17, "Review standard —
final", letter H37); this file fills only what differs for zilc (its § 12). Last verified
2026-11-19. Briefs are the standard's item lists word for word plus the scope; they are not copied
here. It replaced zilc's slots for the 2026-11-12 standard (letter H35: "review", "security
review", "hardening review" and two record lines per release entry).

## The owner's words (beside "commit" / "push" / "release", `working-rules.md` § Owner commands)

- **"review"** — all five required classes, in order: basic, hardening, licensing, security, privacy.
- **"basic review"**, **"hardening review"**, **"licensing review"**, **"security review"**,
  **"privacy review"** — that class alone, by the same loop.
- **"efficiency review"** — optional; when asked, it runs first.

None of them commits, pushes or releases.

## The loop, as zilc runs it

- The standard's § 9: one agent per class over the full scope since the last release
  (`git diff v<last>..HEAD` and the code those changes reach); triage; all fixes of one class, then
  the next, with targeted tests; a NEW agent per class re-reviews the fixes only; the first empty
  re-review ends it; then the full suite once on every supported platform ([platforms.md](platforms.md)).
- Fixes go on a local branch `review/<version>`, merged to `main` when the review completes.
- Issues: `cmem/review-issues.md` — **gitignored**; `release.ts`'s privacy gate refuses it if
  tracked. One item per issue: ID (`<class letter><n>`: B, H, L, S, P, E), the platform ID where it
  is one, the finding, the state (rejections with their reason), the fix commit.
- When the re-review is empty and the full suite passed, § Last review records ONE line
  `- Review complete: <commit>` (the reviewed commit, replacing the previous one) in a memory-only
  commit. `tools/release/review-gate.ts`, the FIRST step of `release.ts`, refuses a release unless
  that commit is in the released history and only `cmem/` and `RELEASE-NOTES.md` changed since.
- **Reviewer briefs say:** work only in the folder you are given — under the main session's
  scratchpad, or `~/zilc-work/review-<n>/` in WSL (WSL's `/tmp` was seen emptied, 2026-11-12);
  the main session deletes it (clones, mutants, planted inputs) at triage (`working-rules.md`
  § Scratch space); 🛑 never execute anything built by Fil-C, cosmo or zilc on the Windows host —
  every run is in WSL or Linux (`workarounds.md`); never commit, push or release.
- **Also in every brief (lessons of review 1, 2026-11-23/24):**
  - a fresh `ZIG_LOCAL_CACHE_DIR` in your folder: a shared cache served a stale compile after
    edits from Windows (`toolchain-quirks-build-systems.md` Z-b-9);
  - never write to shared outputs under `~/zilc-work` (`outcmp/`, `equiv/`, the toolchain trees):
    one reviewer overwrote them; copy what you need into your folder;
  - every git command in a checkout under `~/zilc-work/filc-src` runs as `timeout 60 git
    --no-optional-locks …`: it is a partial clone (`blob:none`), so `git status` fetches missing
    blobs from GitHub. One such fetch hung for 15 hours and held `.git/index.lock`, until the main
    session killed it on 2026-11-24.

## Last review

- Review complete: 4f377a5

Review 1 under this standard, 2026-11-23/24 (owner: "review"), from `a38387a` on branch
`review/0.15.2-0.687.2`: 28 findings at the floor fixed, six re-reviews (the sixth empty), then
the full suite once on linux-x64, all passing (`testing.md`; record in `review-issues.md`).
Licence L1 closed by the owner on 2026-11-24 (`design-decisions.md`). Round 1 (H35), stopped on
2026-11-19: its 24 carried findings are still to be triaged (`review-issues.md`).

## Slots

- **Private-data paths:** `cmem/local/` (machine facts), `cmem/review-issues.md`, `.claude/`, the
  root `CLAUDE.md` — all gitignored; anything outside the clone but the read-only siblings a
  reviewer is pointed at.
- **Reference results** (basic: "reference results hold"; each a dated count in `testing.md`,
  re-derived before quoting; any change is a finding until explained):
  - the safety gate, `bun tools/run-gate.ts` (Fil-C in WSL): **10/10** (2026-11-23), each case trapping at its
    file:line;
  - `zig build test --summary all`: **56/56** (2026-11-23);
  - `bun test tools/release/ tools/lib/`: **132 pass, 1 skip** (the live GitHub render, opt-in; 2026-11-23);
  - the corpus (`testing.md` "corpus"): **78/78 as designed in all four modes**;
  - the output comparison (`testing.md`): **0 unexplained**;
  - Fil-C's own suite, stock vs zilc's clang (`tools/filc/run-filc-tests.ts`): **0 differences on
    7,269**;
  - the pure-Zig chain (`tools/filc/compare-chains.ts`): **14/14**;
  - the sarcasm port (`bun tools/sarcasm/check-stages.ts`): **every stage 0 differ**.
- **Support matrix and platform notes:** [platforms.md](platforms.md).
- **Licence inventory and notices:** `third_party/LICENSES.md` — the Component Ledger (every
  adopted or ported component with its SPDX licence read from the source, the Adoption Checklist)
  — and `licensing.md` (the why, the runtime-linking rule, the copyleft exclusion). zilc's own
  licence is `Apache-2.0 WITH LLVM-exception OR MIT` (`LICENSE-APACHE`, `LICENSE-MIT`, `NOTICE`,
  the SPDX header of each `.ts` / `.zig` file). A release is the tag's SOURCE archive; no Fil-C
  distributable is ever committed (`toolchain/` is gitignored), and Fil-C's sources are fetched by
  `zig build` from GitHub, pinned by hash. **Missing:** a licence inventory checked by a script
  against an allowlist (the ledger is kept by hand).
- **Outputs that can carry user facts:**
  - the programs zilc compiles: Zig and Fil-C debug info holds the absolute source paths of the
    user's files; a Fil-C trap or `zilc` panic prints the source file:line at run time;
  - the caches and outputs: `.zig-cache/`, `zig-out/`, `~/.cache/zilc*`, `~/zilc-work/`
    (`working-rules.md` § Scratch space);
  - error messages, which print the user's paths;
  - network, all requested by the user's own command: `zig build` fetches Fil-C's source archive
    (and, with `-Dfetch-build-tools`, cmake and ninja); `check-upstream.ts` fetches upstream git;
    the release scripts call GitHub's REST API. No telemetry.
- **Gate scripts** (all local, run by `tools/release/release.ts`; CI only publishes, H37 (e)):
  `review-gate.ts` (first); `bump.ts --check`; the privacy gate (no private file tracked, then the
  path scan — `working-rules.md` § Privacy); `zig fmt --check`; Biome's Markdown check
  (`tools/md/biome.ts ci`); `zig build test`; `bun test tools/release/`; `bun tools/run-gate.ts`.
  The reference suites above run by the per-release checklist (`releasing.md`). **Missing:** a
  credential scan (the path scan finds paths, not tokens), a vulnerability check, a licence
  allowlist check, an API surface check.

## Items that do not apply, and why

- **Sandbox boundary (runtimes)** (security): zilc is a compiler; it runs no guest. Memory safety
  of the compiled program is Fil-C's, checked by the safety gate and the reference results.
- **Native library loading (loaders)** (security): zilc loads no native library at run time.

## Where the reviews look first

- **The worst silent case:** a memory-unsafe program that zilc compiles and that runs without
  trapping — an out-of-bounds, use-after-free or type-confused access Fil-C would have stopped, let
  through by zilc's driver, its pass patches or a pure-Zig piece. Next: a pure-Zig piece whose
  output differs from Fil-C's (a sarcasm stage, a runtime module, the link) while every test
  passes. Both rank above any crash.
- **Untrusted input:** the user's Zig / C / C++ source and build files, Fil-C's source archive
  (pinned by hash in `build.zig.zon`), upstream's sarcasm inputs. Building a program runs its own
  `build.zig` by design (Zig's model); nothing else of the input runs.
- **The release path:** `release.md` — only CI tags and makes the page; no registry; no `uses:`;
  Bun pinned by sha256; `contents: write` only in the two write jobs, which check out nothing; no
  `gh`.
