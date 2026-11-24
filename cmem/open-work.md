# open-work.md — the state of zilc and what is outstanding

Where the project stands now is [STATE.md](STATE.md) (memory guide, letter H38, 2026-11-19); the
State table below is the dated record behind it. Only open items live here; each points at its
record. Closed items and the dated session logs moved on 2026-11-23 to
`archive/open-work-to-2026-11-19.md` (letter H38 step 4). Counts are not copied here:
`testing.md` holds them, with their dates. Last verified 2026-11-24.

## State (2026-11-24)

| what      | value                                                                                            |
| --------- | ------------------------------------------------------------------------------------------------ |
| version   | **`0.15.2-0.687.1`** — published 2026-10-27, tag `v0.15.2-0.687.1` on `be51808` (`releasing.md`) |
| toolchain | Zig **0.15.2**, Fil-C **0.687** with zilc's patched clang, compiled by Zig since 2026-10-30      |
| pushed    | 2026-11-24: `main` = `origin/main`, the merge of `review/0.15.2-0.687.2` (review 1, H37)         |
| gates     | full suite 2026-11-23 on linux-x64 (review 1), gate 10/10; counts in `testing.md`                |
| remote    | `origin` = `github.com/synapticforge1/zilc`; purged history pushed 2026-10-27                    |
| branches  | `main`, `v0.15.2`, `work-2026-11-15`; `review/0.15.2-0.687.2` (review 1, pushed 2026-11-24)      |
| sibling   | **zailc** (`../zailc`) translates Fil-C into Zig; zilc is its reference and test oracle          |

The full rows as they stood on 2026-11-19 (every push, the purge, the branch history):
`archive/open-work-to-2026-11-19.md` § State.

## ⏹️ Review round 1 STOPPED 2026-11-19 — superseded by the final review standard (letter H37)

🔒 **Owner, 2026-11-19 ("yes", to stopping round 1 rather than finishing KI-39):** round 1 ran
under the 11-12 standard (letter H35). Its class 1 hardened `tools/release/check-reviews.ts` and
CI's review step — the check that a release entry carries the Security and Hardening record
paragraphs and that GitHub shows them. The final standard (H37, 2026-11-17) REMOVES both: (d) the
release script runs the review set as its first step instead of checking record paragraphs; (e)
the tests leave CI, which only verifies the version, tags and makes the page. Finishing class 1
would harden code that H37 deletes.

- **Where it stopped:** KI-24–KI-38 committed (`2e557d5`, `be52302`, `0a43dc4`); KI-39's code
  committed in `cdbb031` (owner, 2026-11-19), all on `work-2026-11-15`, merged into `main` as
  `de07d93` and pushed (owner: "push", 2026-11-19). KI-39's mutant run was NOT re-run; its row records it as superseded.
- **What carries over:** the lessons (KI-31, KI-38: a guard never forbids valid Markdown; GitHub's
  renderer decides what is shown) and Biome for `.md`, which stays (`working-rules.md` § Git).
- **Done since:** H38 steps 4–7 (2026-11-23); review 1 under H37's five classes, complete at
  `4f377a5`, then `5ed1df1` with R3L1's NOTICE paragraph (2026-11-24; `review-process.md` § Last
  review; L1, the sarcasm licence, closed by the owner the same day).
- **Next:** (pushed 2026-11-24) the triage of round 1's 24
  carried findings under H37's classes (`review-issues.md`).
- **The sarcasm port** went on first (owner's work order, 2026-11-24): checkpoints 3–5 done.

## 🔎 Review, round 1 — 2026-11-15 (owner: "review") — STOPPED 2026-11-19 (above)

Scope `v0.15.2-0.687.1..HEAD`, four reviewers (A sarcasm, B the `.ts` harnesses, C the pure-Zig
build chain, D the release tooling): 30 findings. **Class 1** (a guard that passes on text, not on
fact) was fixed through ten retests: KI-24–KI-38 (`known-issues.md`), then superseded with KI-39.
Class 7 (C8) was measured and is not a defect (`toolchain-quirks.md` Z-cc-17). Retest 3 item 5 —
a Fil-C or Zig move cannot pass the review gate's exact-bump check — is decided (owner,
2026-11-15: "c", at the next Fil-C move) and carried in `upstream.md`'s Fil-C update checklist.

**The other 25 moved on 2026-11-19 to the gitignored `cmem/review-issues.md`** (letter H37 (c)):
24 open, D9 fixed on the way; H1, found during the H37 work, is there too. The first review under
H37 re-runs each before it is fixed.

## Open work

- **The pure-Zig track — in progress on `main`** (2026-10-27): the generators
  (byte-identical to 0.687's) and the stock runtime pieces (libpas's stock half, yolo musl's static
  half, compiler-rt; every object = the 0.687 release's symbols) are in, and `gate-zig-modules`
  passes on 0.687 with 9 pure-Zig modules linked (`roadmap.md` Z1, `testing.md`). Merged into
  `main` (672968a). **Yolo musl's shared half** (`libyoloc.so`, the loader) is done on branch
  `pure-zig/yolomusl-shared` (W-11): 10 linked, gate 8/8, corpus 78/78 as designed, comparison 0
  unexplained; merged into `main` (676e04e, owner, 2026-10-27), pushed, branch deleted. Next: the Fil-C-compiled pieces (`filc/src`, the user
  libc, libc++). `Fil-C.md` and `Zig.md` record the route to parity for zailc. Plan as first
  written: bring zailc's step-2 build
  into zilc (`roadmap.md` Z1) — read from `../zailc` (`src/gen`, `src/runtime`, `tests/link`,
  `tools/gen`, `tools/runtime`, its `build.zig` steps `gen` / `libpas` / `yolomusl` /
  `compiler-rt`, its `oracle.md`), keep only what is faithful to Fil-C (zailc's departures W-n stay
  there), re-verify against 0.687, and run `zig build gate-zig-modules` on the result; then the
  rest of Z1, then Z2 (the pass in Zig). Licence: the ported pieces carry Fil-C's notices; ledger
  entries in `third_party/LICENSES.md` before the first file lands.
- 🔒 **zilc stays on the compatible Zig, always** (owner, 2026-10-27; `design-decisions.md` top
  row): no newer-Zig line, so the 0.16.0 examples under zilc and stage B are not zilc's;
  recommendations for a 0.17.0+ upgrade only (`upstream.md`). Still zilc's: the benchmark suite,
  for comparing one reference release with the next (stage C's first column). Abandoned with P3:
  `-Druntime=both`, the byte-identity check.
- **Partly open defects:** KI-7 (`getcontext`) — `known-issues.md`.
- **The sarcasm port** (owner, 2026-11-06): in progress; next is x86_64_frame checkpoint 6 — `sarcasm-port.md`.
- **5b. Fil-C's prebuilt becomes optional** (from clone-then-build, 2026-10-30): still needed for
  the Fil-C-compiled runtime pieces (Z1 item 3), as the tree the patched clang is installed into,
  and as the oracle. The record: `archive/open-work-to-2026-11-19.md` § Open work.
- **Owner call 1's follow-up:** GitHub Support's purge of the old commits (drafted in the gitignored
  `cmem/local/github-support-purge.md`; the owner submits it); re-check after: both old hashes
  must 404. The record: `archive/open-work-to-2026-11-19.md` § Owner calls.
- **At the next Fil-C move:** `build-patched-clang` and `build-cosmo` are run, rewritten or retired
  (owner, 2026-11-06; `upstream.md` Stage A step 7), and the upgrade's release path is decided
  (`upstream.md` Stage A step 9).

## Workspace letters (`../workspace/cmem/workspace-correspondence.md`; each item in `letters/<ID>.md`)

Open for zilc, 2026-11-19:

- **H41** (correspondence one file per item) — read; session start and the answer bullet in
  `working-rules.md` § Before starting work and § Session routine. Answer: one bullet, record-only.
- **H42** (workspace memory in the `workspace` repo) — every `../cmem/` pointer in `cmem/` now names
  `../workspace/cmem/` (`git grep '\.\./cmem/'` finds only this line).
- **H43** (scratch space) — rule in `working-rules.md` § Scratch space; reviewer brief in
  `review-process.md`; the four notes in the assistant's per-project memory folder checked against
  `cmem/` ("test, don't guess" was missing: now `working-rules.md` § Records) and removed; session
  scratchpad 0 bytes; WSL `/tmp` 0; `~/zilc-work/` 232 → **57 GB** (owner, 2026-11-19: only the
  latest toolchain is kept, what is still necessary stays): old suite outputs, the cosmo build, the
  0.685 / 0.686 toolchains and the GCC-built 0.687 rollback, run outputs recorded in `testing.md`.
  Kept: Fil-C 0.687's source and clang build tree, the toolchain, the pinned QC GCCs; gate 8/8 after.
  What stays and why: `cmem/local/zilc-work.md`. No size limit (owner): cleared as things stop
  being used (`working-rules.md` § Scratch space).
- **H38** (memory guide) — before: `check-cmem --summary` 470 problems (state-missing 1,
  index-size 1, line-length 459, file-size 9). **Steps 1–3 done 2026-11-19:** `STATE.md`; `INDEX.md`
  20 KB → 2.4 KB router (rules to `working-rules.md`, history to `design-decisions.md`); the root
  `CLAUDE.md` (gitignored) names the two. **Steps 4–7 done 2026-11-23:** (4) closed items to
  `archive/` (known issues by the release that closed them, roadmap P0–P6, the 0.686 review,
  open-work's closed sections and answered letters); (5) files over 25 KB split by subject
  (`testing-*`, `toolchain-quirks-build-systems`, `workarounds-*`, `design-decisions-early`,
  `open-questions`); (6) wide tables to lists, long lines wrapped — the State table kept as a
  table with short rows (the release guard reads it); (7) `scripts/check-cmem.ts`, identical to
  the workspace's. ★ copy → `best-practices-shared.md`, unchanged. Check: `check-cmem: all limits
  hold` (was 412 problems). Every word of the old notes found again, but for the edited lines
  (the router, six headings, five links now naming their file, open-work's intro).
- **H37** (final review standard) — **(a)–(g) done 2026-11-19**, superseding review round 1 (top
  of this file). (a) `review-process.md` rewritten: the seven words, the loop, § Last review, both
  new slots (licence inventory and notices; outputs that can carry user facts), the gaps named.
  (b) `cmem/review-issues.md` and `.claude/` gitignored; `release.ts`'s privacy gate refuses them,
  `cmem/local/` and `CLAUDE.md` if tracked (`guards.ts` `privateFilesTracked`, tested). (c) round
  1's 25 unclosed findings moved there. (d) `review-gate.ts` (was `check-reviews.ts`) is
  `release.ts`'s FIRST step: one `- Review complete: <commit>` line, the history and exact-bump
  checks kept; `bump.ts release` checks the same. (e) `release.yml` runs no build, test or gate:
  decide, then on a release `bump.ts --check`, tag, page. (f) the seven review words in
  `working-rules.md`. (g) a new `platforms.md` (matrix: linux-x64 tested on Ubuntu 26.04.1 LTS, the
  other five `none`, zailc's), the old P6 / cosmo record to `archive/`, the settings tagged
  `[linux-x64]`. Checked: `bun test tools/release/` 124 pass, 1 skip; 5 of 5 mutants caught;
  rehearsed (decide step on a scratch history, `bump.ts --check` without Zig, `release.ts
  --dry-run` refusing at the review gate first). Not done: the live render test (GitHub rate limit
  without a token, `review-issues.md` H1).

Answered earlier (closed or awaiting the workspace): `archive/open-work-to-2026-11-19.md` § Workspace letters.
