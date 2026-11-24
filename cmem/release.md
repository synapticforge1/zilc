# release.md — how a zilc release runs, and every release made

🔒 **One place for release records (owner, 2026-11-10, workspace `release-process.md` § 5 U11,
letter H33): § "Release History" below, newest first,** one entry per version with a summary of
what changed, the run, the read-backs and what was checked. The version scheme, its five places and
the upgrade checklist stay in [releasing.md](releasing.md); the process is the workspace's
`../workspace/cmem/release-process.md` §§ 5–8, mapped onto zilc here.

## How a release runs (the owner's word "release" — `working-rules.md` § Owner commands)

zilc publishes to **no registry** (release-process.md § 6, "no registry"): a release is a tag
`v<Zig>-<Fil-C>.<N>` and its GitHub Release page, both made by CI. 🔒 **Every gate and test runs
locally; CI only publishes** (owner, 2026-11-17, letter H37 (e): "We want the CI to verify the
version, then tag, create the release page and publish, and skip any version already published").
The slots (§ 5):

- **U1 the go and the level.** The owner's "release". The "level" is the KIND, an argument:
  `release` (N + 1). A Fil-C or Zig move is the upgrade procedure (`releasing.md` "Per-release
  checklist", `upstream.md`), which resets N to 1. 🔒 **Before it: the five required reviews**
  (basic, hardening, licensing, security, privacy — the workspace review standard, letter H37),
  ended by an empty re-review and the full suite, and recorded as ONE line
  `- Review complete: <commit>` in `review-process.md` § Last review.
- **U2 merge first.** `RELEASE-NOTES.md`'s `## <version>` section, the State row in `open-work.md`
  and this file's entry are merged into `main`; then the bump is its own commit,
  `bump to v<version>`, made by the tool.
- **U3 the bump tool.** `bun tools/release/bump.ts release`: refuses a dirty tree (untracked files
  count), places that disagree, a missing notes section / State row / entry, or no completed
  review covering HEAD; writes `build.zig.zon`, `src/root.zig` (`release` and its test literals)
  and the README status line; runs `zig build test`; puts every file back on failure; commits.
  **No surface floor and no previous-release tests:** the version deliberately encodes no
  compatibility (`releasing.md` "No 1.0"; release-process.md § 7's zilc card), and the previous
  release's tests pin the previous version string by design. `bump.ts --check` verifies the five
  places.
- **U4 the release script.** `bun tools/release/release.ts` (`--dry-run`: everything but the
  push). **First, the review gate** (`review-gate.ts HEAD`, H37 (d)); then: clean tree, on `main`,
  `origin/main` an ancestor of `main`, the tag absent locally and on origin, the `v*` tags here
  equal origin's (fetched; KI-30), `bump.ts --check`, the privacy gate (no private file tracked,
  then the path scan), and the gates — `zig fmt --check`, Biome, `zig build test`, the release
  scripts' tests, **the Fil-C gate** (`bun tools/run-gate.ts`, 10/10); then `git push origin main`
  and a read-back with `ls-remote`. **It makes and pushes no tag.** Never `git tag -f`, never a
  forced tag push.
- **U5 `checks`.** `.github/workflows/release.yml` on the pushed `main` commit, `contents: read`, a
  token-less clone. "Is this a release?" = build.zig.zon's version has no tag yet **and the commit
  is `bump to v<version>`** (KI-25: a plain push of an untagged version, or a commit after the
  bump, is ordinary work); a version tagged elsewhere was released before and is skipped. On a
  release only: Bun, then `bump.ts --check` (the version verified). No build, no test, no gate
  (until 2026-11-19 it ran zig fmt, `zig build test`, the release scripts' tests, Biome, the
  privacy scan and the review check).
- **U6 `tag`.** CI creates the annotated tag on `github.sha` (`tools/release/github-tag.ts`, REST
  API, `contents: write` only) and reads it back (peels to the commit). Already there on this
  commit = done; anywhere else = refuse.
- **U7 `release`.** CI makes the Release page FROM the tag (`tools/release/github-release.ts`,
  H32's order: the tag peels to `github.sha`; an existing page is done; `POST` with
  `generate_release_notes`; read back; peel again). The line on top links `RELEASE-NOTES.md` at
  the tag (no registry to name). 30 s limit on every request.
- **U8 `publish`.** **None** — no registry; the tag and its page are the release.
- **U9 pins.** No `uses:` steps; Bun 1.4.4 by version AND sha256 (measured 2026-11-12 at the
  source); a `concurrency` group per commit, never cancelled.
- **U10 read back as a user.** **None** — nothing to install from a registry; the user's path is a
  clone (`README.md`, `tools/README.md` "First-time setup"), the same tree the gate ran on.
- **U11 record.** § "Release History" below, newest first. Each entry carries one
  `Tested on: <OS and version> (<platform ID>)` line per platform actually run, and "other
  platforms: not yet tested" (owner, 2026-11-19; [platforms.md](platforms.md)).
- **U12 failure.** "Re-run failed jobs": each job skips what is done. Never a new tag for the same
  code, never a moved tag.

### What runs where

- **The owner's machine (`release.ts`):** every gate and test — the review gate, the version
  places, the privacy gate, format, `zig build test`, the release scripts' tests, the Fil-C safety
  gate (`run-gate.ts`, 10/10). Fil-C's own suite, the corpus and the output comparison are the
  per-release checklist in `releasing.md`, run before the notes are written.
- **CI:** "is this a release?", the version check, the tag, the page. Nothing else.
- **History:** CI ran the no-Fil-C half (format, unit and release-script tests, version places,
  privacy scan) from 2026-11-12 (first run 43295657634 on `bba102f`, `checks` green; `tag` and
  `release` skipped as designed) to 2026-11-19. The 2026-11-19 change was rehearsed before it
  landed (best-practices 7.22): the decide step run as written in `release.yml` against a scratch
  history (`guards.test.ts`), `bump.ts --check` with no Zig on `PATH`, and `release.ts --dry-run`
  refusing at its first step; `bun test tools/release/` 124 pass, 1 skip; 5 of 5 mutants caught.
  Still unproven on GitHub: `tag` and `release` — the first release proves them.

## The review record (since 2026-11-19, letter H37 (d))

`review-process.md` § Last review holds exactly ONE line, `- Review complete: <commit>`, written
when a review's re-review came back empty and the full suite passed. `tools/release/guards.ts`
checks it, in `bump.ts release` (on HEAD before the bump) and `review-gate.ts` (on the bump commit,
`release.ts`'s first step): `<commit>` is in the released history; after it only `cmem/` and
`RELEASE-NOTES.md` changed (so the record and the notes can be written after the review, the code
cannot; a move is seen from both sides); and the bump commit is exactly `bumpEdits` of its parent —
`README.md`, `build.zig.zon` and `src/root.zig`, byte for byte (KI-28), compared as git objects:
the exact bytes, mode `100644` on both sides (KI-29). Text that only mentions a review is not a
record. (2026-11-15 to 2026-11-19 the record was two lines in the release entry, a security and a
hardening review — letter H35, KI-24.)

**Any valid Markdown; a place that is not rendered is an error** (owner, 2026-11-15; KI-38).
`review-gate.ts` and `bump.ts release` render the counted files with **GitHub's own renderer**
(`POST /markdown`, `gfm`; the REST API, never `gh`) and require, as visible text, the `v<version>`
entry heading, the notes' `## <version>` heading, the README's status version in its quote, and
the State row as a table row. A render that fails is a refusal; without `GITHUB_TOKEN` GitHub can
refuse it for its rate limit (seen 2026-11-19; `review-issues.md` H1). The four files are LF only.
**Formatting is Biome's** (`bun tools/md/biome.ts ci .`, `biome.jsonc`; `release.ts` runs it).

## Release History (newest first)

### v0.15.2-0.687.1 — 2026-10-27

**Summary:** zilc moves to Fil-C 0.687 (LLVM still 20.1.8, so user code stays on Zig 0.15.2);
yolo musl's shared half (`libyoloc.so`, the loader) joins the pure-Zig track.
**Made by hand, before the CI process existed:** owner "release", after the checklist run the
same day. Pushed to `https://github.com/synapticforge1/zilc`: `main` and branch `v0.15.2` at
`be51808`, annotated tag `v0.15.2-0.687.1` (tag object `303b597`) on the same commit; all three
fast-forwards / new, read back with `ls-remote`. Checked first: every per-release checklist item
on the committed tree (`testing.md`, `upstream.md` "Review of Fil-C 0.687"), the five version
places, the 3 pushed commits scanned (no personal path, none in a message). No CI, no GitHub
Release page (no backfill — owner, 2026-11-09: "only new tags will get release pages").
Reviews: none were required then (the requirement dates from 2026-11-12).

### v0.15.2-0.686.1 — 2026-10-05

**Summary:** the first published release — zilc on Fil-C 0.686, the version scheme
`<Zig>-<Fil-C>.<N>`, `zilc --version`'s machine check.
Pushed to `https://github.com/jrmarcum/zilc` (the repo has since moved to
`https://github.com/synapticforge1/zilc`, where `origin` points since 2026-10-27; it serves the
same commit): `main` + branch `v0.15.2` at `19e7172`, annotated tag `v0.15.2-0.686.1`. Since the
2026-10-27 history purge that commit is **`13ce96a`** and the tag object `7dbddf8` (was
`fda2d43`); map: `history-map-2026-10-27.md`. The local `v0.15.2-3` tag was deleted, never pushed.
No GitHub Release page (no backfill, as above).
