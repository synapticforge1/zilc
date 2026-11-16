# release.md — how a zilc release runs, and every release made

🔒 **One place for release records (owner, 2026-11-10, workspace `release-process.md` § 5 U11,
letter H33): § "Release History" below, newest first,** one entry per version with a summary of
what changed, the run, the read-backs and what was checked. The version scheme, its five places and
the upgrade checklist stay in [releasing.md](releasing.md); the process is the workspace's
`../cmem/release-process.md` §§ 5–8, mapped onto zilc here.

## How a release runs (the owner's word "release" — `working-rules.md` § Owner commands)

zilc publishes to **no registry** (release-process.md § 6, "no registry"): a release is a tag
`v<Zig>-<Fil-C>.<N>` and its GitHub Release page, both made by CI. The slots (§ 5):

| slot | zilc |
| --- | --- |
| **U1** the go and the level | The owner's "release". The "level" is the KIND, an argument: `release` (N + 1). A Fil-C or Zig move is the upgrade procedure (`releasing.md` "Per-release checklist", `upstream.md`), which resets N to 1. 🔒 **Before it: a security review and a hardening review, each run to its empty round on everything since the last release and recorded in this release's entry below** (owner, 2026-11-12; `review-process.md` § 0, letter H35) as the two lines of § "Review records" — `bump.ts`, `release.ts` and CI's `checks` refuse without them (since 2026-11-15 checked against the history, KI-24). |
| **U2** merge first | `RELEASE-NOTES.md`'s `## <version>` section, the State row in `open-work.md` and this file's entry (with both reviews) are merged into `main`; then the bump is its own commit, `bump to v<version>`, made by the tool. |
| **U3** the bump tool | `bun tools/release/bump.ts release`: refuses a dirty tree (untracked files count), places that disagree, missing notes / State row / reviews; writes `build.zig.zon`, `src/root.zig` (`release` and its test literals) and the README status line; runs `zig build test`; puts every file back on failure; commits. **No surface floor and no previous-release tests:** the version deliberately encodes no compatibility (`releasing.md` "No 1.0"; release-process.md § 7's zilc card), and the previous release's tests pin the previous version string by design. `bump.ts --check` verifies the five places (CI runs it on every push). |
| **U4** the release script | `bun tools/release/release.ts` (`--dry-run`: everything but the push): clean tree, on `main`, HEAD is the bump commit, `origin/main` an ancestor of `main`, the tag absent locally and on origin, the `v*` tags here equal origin's (fetched; KI-30), `bump.ts --check`, `check-reviews.ts HEAD` (both review records, covering the history), the privacy scan, the cold gate — `zig fmt --check`, `zig build test`, the release scripts' tests, **the Fil-C gate** (`bun tools/run-gate.ts`, 8/8); then `git push origin main` and a read-back with `ls-remote`. **It makes and pushes no tag.** Never `git tag -f`, never a forced tag push. |
| **U5** `checks` | `.github/workflows/release.yml` on the pushed `main` commit, `contents: read`, a token-less clone: zig fmt, `zig build test`, the release scripts' tests (mock GitHub API), `bump.ts --check`, the privacy scan; "is this a release?" = build.zig.zon's version has no tag yet **and the commit is `bump to v<version>`** (since 2026-11-15, KI-25: a plain push of an untagged version, or a commit after the bump, is ordinary work); on a release, `check-reviews.ts "$GITHUB_SHA"` before the tag. |
| **U6** `tag` | CI creates the annotated tag on `github.sha` (`tools/release/github-tag.ts`, REST API, `contents: write` only) and reads it back (peels to the commit). Already there on this commit = done; anywhere else = refuse. |
| **U7** `release` | CI makes the Release page FROM the tag (`tools/release/github-release.ts`, H32's order: the tag peels to `github.sha`; an existing page is done; `POST` with `generate_release_notes`; read back; peel again). The line on top links `RELEASE-NOTES.md` at the tag (no registry to name). 30 s limit on every request. |
| **U8** `publish` | **None** — no registry; the tag and its page are the release. |
| **U9** pins | No `uses:` steps; Zig 0.15.2 and Bun 1.4.4 by version AND sha256 (measured 2026-11-12 at the source); a `concurrency` group per commit, never cancelled. |
| **U10** read back as a user | **None** — nothing to install from a registry; the user's path is a clone (`README.md`, `tools/README.md` "First-time setup"), the same tree the gate ran on. |
| **U11** record | § "Release History" below, newest first. |
| **U12** failure | "Re-run failed jobs": each job skips what is done. Never a new tag for the same code, never a moved tag. |

### What runs where

- **CI (`checks`):** what needs no Fil-C — format, unit tests, the release scripts' tests, the
  version places, the privacy scan. Rehearsed 2026-11-12 on a fresh clone with empty Zig caches
  and no `ZILC_*`: `zig build test` 40/40 in 4 s, nothing fetched; a planted failing test fails it.
- **The owner's machine (`release.ts`):** the Fil-C safety gate (`run-gate.ts`, 8/8) — a GitHub
  runner has no Fil-C toolchain (zilc builds it from source in hours, or installs the release's
  prebuilt). Fil-C's own suite, the corpus and the output comparison are the per-release checklist
  in `releasing.md`, run before the notes are written.
- **First real CI run: 2026-11-12, run 43295657634 on `bba102f`** — `checks` green, every step;
  `tag` and `release` skipped (`v0.15.2-0.687.1` already tagged elsewhere, so "not a release"), as
  designed. Before it, rehearsed (best-practices 7.22): the scripts against a mock API (27 cases,
  3 mutants), `checks` on a fresh clone. Since 2026-11-15: `guards.test.ts` (141 cases, 64 mutants
  caught; review round 1, KI-24–KI-36) — `bun test tools/release/` is 168 tests. Still unproven on GitHub: `tag` and `release` — the first
  release proves them.

## Review records (the two lines a release entry must hold — since 2026-11-15, KI-24)

A release's entry below holds exactly one line of each kind, in this form (more text may follow on
the line):

```
- **Security review:** <n> rounds, empty round <YYYY-MM-DD>, reviewed `<previous release's tag>..<commit>`
- **Hardening review:** <n> rounds, empty round <YYYY-MM-DD>, reviewed `<previous release's tag>..<commit>`
```

`<commit>` is the commit the round that found nothing reviewed. `tools/release/guards.ts` checks,
in `bump.ts release`, `release.ts` and CI (`check-reviews.ts`): the tag is the previous release
(the nearest `v*` tag below the code being released); `<commit>` is in that history; after it,
only `cmem/` and `RELEASE-NOTES.md` changed (so the records and the notes can be written after the
review, the code cannot; a move is seen from both sides); and the bump commit is exactly
`bumpEdits` of its parent — `README.md`, `build.zig.zon` and `src/root.zig`, byte for byte
(KI-28), compared as git objects: the exact bytes, mode `100644` on both sides (KI-29). Prose about a review ("security review: not run") is not a record. **The section is plain text (KI-31):** this file, `RELEASE-NOTES.md`, `README.md`
and `open-work.md` are LF only, with no HTML comment, declaration, details or summary tag, or HTML block (checked on the raw line, KI-33)
and fences; a fence starts at column 0 (one inside a list, a quote or an indent is refused, KI-32);
the Release History section holds no fence; an entry ends at its next heading-like line. The
README status line follows a blank line and has only plain characters before its version; the
State row is a row of a table with a header and a delimiter row of the same width, at least 2 cells, no front matter (KI-34, KI-35). Anything else is refused by name — the guard does not guess how GitHub would render it. **Limit:** CI runs the
guard code of the commit it judges, so a commit that edits `tools/release/` or `release.yml`
judges itself; such a change is reviewed like any code, and the record's range covers it.

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
