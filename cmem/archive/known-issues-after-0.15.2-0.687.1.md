# Known issues closed after release 0.15.2-0.687.1 (review round 1, 2026-11-15/19) — archived 2026-11-23 from known-issues.md

## ✅ KI-24 — The release guard accepted any entry that mentioned both reviews (review round 1, D1; 2026-11-15, FIXED)

**Class:** a guard that passes on text, not on fact (round 1, class 1; `open-work.md` § Review).
**Measured** (reviewer D, run; the session re-read the code): `bump.ts` and `release.ts` tested
`/security review/i` and `/hardening review/i` on the entry, so `security review: not run.
hardening review: skipped.` made the bump commit. **Fix** (`tools/release/guards.ts`): a review is
a RECORD in one fixed form, one line per kind (`REVIEW_FORM`; `release.md` § "Review records"),
exactly one of each, a real date, at least one round; and the record is checked against the
history: its range starts at the previous release's tag, names a commit in the history being
released, and after that commit only `cmem/` and `RELEASE-NOTES.md` changed. **Test:**
`guards.test.ts` (a throwaway repository: negation, placeholders, a heading, one kind, zero rounds,
a bad date, a duplicate, the wrong base, a commit off the history, code after the review). The
reviewer's reproducer now refuses (`bump.ts release` exit 1, both records named).

## ✅ KI-25 — CI released any push of an untagged version, without reading the reviews (D2; 2026-11-15, FIXED)

**Same class.** `release.yml`'s decide step set `release=true` for any `main` commit whose version
had no tag, and `checks` never read the reviews: a plain `git push` bypassed `release.ts`, and a
memory commit pushed after the bump commit could race it for the tag. **Fix:** a commit is a
release only when its subject is `bump to v<version>`; on a release, `checks` runs
`tools/release/check-reviews.ts "$GITHUB_SHA"` (the same check `release.ts` runs before it pushes):
the bump commit changes only `README.md`, `build.zig.zon`, `src/root.zig`, and the entry's records
cover the history (KI-24). **Test:** `guards.test.ts` (the CLI on a non-bump commit and on a git
failure, exit 1 and 2); the decide step run on a scratch bump commit (`release=true`) and its child
(`release=false`), 2026-11-15. Still CI's half: the first real release runs it on GitHub.

## ✅ KI-26 — `bump --check` passed a version place on a substring (D5; 2026-11-15, FIXED)

**Same class.** Each place was an `includes`: the version test pinning `0.687.0` with `0.687.1` in
a trailing comment passed (run, session); so did a State row naming the version as "previous", and
any line naming a longer version (`…687.10` for `…687.1`). **Fix:** each place is the one line that
carries it, matched whole and anchored, and exactly one such line (`guards.ts` `disagreements`);
build.zig.zon must hold exactly one `.version` line. The State row must BEGIN with the version.

## ✅ KI-27 — A release entry was found by `startsWith` and ran to the end of the file (D6; 2026-11-15, FIXED)

**Same class, latent** (no `.10` yet). `### v0.15.2-0.687.10` answered a lookup for `…687.1`, an
entry without the `v` counted, and the last entry swallowed every later section. **Fix:**
`guards.ts` `findEntry`: the exact `### v<version>` heading (a space or the line's end after it),
ending at the next heading of any level; two entries for one version is an error.

**Inversion for KI-24–KI-27, 2026-11-15:** 16 mutants, each putting one part back to the first
version's behaviour (substring places, first match only, `startsWith`, to end of file, two entries,
the form not enforced, zero rounds, no date check, no base check, off-history allowed, later code
allowed, bump extras allowed, the CLI's subject check, a git failure as a pass): **16 of 16 caught**
by `guards.test.ts`. One check written first (a reviewed commit from before the previous release)
was seen by no test of its own — the later-changes check always fires first — and was removed.

## ✅ KI-28 — The review check read file NAMES, not content (class 1 retest 1; 2026-11-15, FIXED)

**Same class, found by the class's first retest (a fresh reviewer, all three RUN):** (1) the diff
after the review used git's rename detection, so `git mv src/x cmem/x` listed only the `cmem/`
side and a deletion of reviewed code passed; (2) the bump commit was checked for WHICH files it
touched, not what it put in them — a hand-made `bump to v…` commit adding a line to `src/root.zig`
or `build.zig.zon` passed; (3) git quoted a non-ASCII `cmem/` name (`"cmem/caf\303\251.md"`), so a
correct release was refused. **Fix** (`guards.ts`): every diff is `--no-renames -z` (`changedPaths`:
both sides of a move, names never quoted); the bump's edits are one function, `bumpEdits`, which
bump.ts writes through and the check recomputes from the bump commit's parent, requiring the three
files byte for byte. **Test:** `guards.test.ts` (a smuggled line in each of the three files, a move
into `cmem/`, a `cmem/café.md`, and `bumpEdits` on the real repository); 3 more mutants (rename
detection back, quoted names, content unchecked), **19 of 19 caught**; `bun test tools/release/`
61/61; the end-to-end scratch release still bumps and passes `check-reviews.ts` (2026-11-15).
**Limit, not fixed (inherent):** CI runs the guard code of the commit it judges, so a pushed
commit that edits `tools/release/` or `release.yml` judges itself (`release.md` § "Review records").

## ✅ KI-29 — The review check compared decoded text, file names without modes, and records nobody sees (class 1 retest 2; 2026-11-15, FIXED)

**Same class, found by the class's second retest (fresh reviewer; 1–4 RUN, 5 by grep):** (1) the
bump commit was compared as text decoded from UTF-8, so changing an invalid byte or adding a BOM
in the bump commit passed; (2) a mode change (`chmod +x`) of a bump file passed; (3) a gitlink moved
after the review was invisible when `.gitmodules` said `ignore = all`; (4) a record inside an HTML
comment or a code fence counted; (5) `Fil-C.md` named the current version, a sixth place no guard
checked or bumped. **Found by the session while fixing:** `bump.ts` itself read and wrote the three
files as UTF-8, so a bump of a file holding an invalid byte would have rewritten it as U+FFFD.
**Fix** (`guards.ts`, `bump.ts`, `Fil-C.md`): git output kept as bytes (`Git` → `raw`); the bump
compared blob for blob (`git cat-file blob`, `Buffer.equals`), edited one character per byte
(latin1) in both the check and `bump.ts`; each bump file must be mode `100644` on both sides
(`git ls-tree`; a symlink, gitlink or executable is refused by the mode); every diff
`--ignore-submodules=none --no-textconv`; every git call `--no-replace-objects`; records count only
outside HTML comments (an unclosed one runs to the end) and fences; `Fil-C.md` now names
`0.15.2-0.687.<N>` and points at the five places. **Test:** `guards.test.ts` (an invalid byte changed,
an exact bump of a file with one, a BOM, a chmod, a symlink, a submodule with `ignore = all`, a
replace ref showing a clean bump, records in comments and fences, and a sweep that the current
version is named only in its known places); 8 more mutants. **Inversion 2026-11-15: 26 of 26 caught,
the unmutated copy passing first** (the mutant run now refuses to start otherwise — the first run of
this round was void: the sweep failed in every copy on a doc comment naming the real version, which
the working tree hid because `guards.ts` was untracked; the example is a placeholder now). A type
check added first was seen by no test (the mode check always refuses first) and was removed.
`bun test tools/release/` 73/73.

## ✅ KI-30 — Stale version mentions, entries hidden from the page, and tags the owner's machine had not fetched (class 1 retest 3; 2026-11-15, FIXED)

**Same class, found by the class's third retest (fresh reviewer; no way for unreviewed code
through; 1–4 RUN):** (1) the version-places sweep exempted whole bump files, so a second mention of
the version in `README.md` or `src/root.zig` passed every guard and would go stale at the bump
(`src/root.zig` itself named it 4 times: two doc examples and an ordering-test literal); (2) a
`### v<version>` heading inside a fence or an HTML comment counted as the entry; (3) the fence
parser closed on any fence line (a shorter one, one with text after it, the other character), and
records inside `<script>` / `<style>` / `<pre>` / `<textarea>` blocks counted; (4) `bump.ts` never
fetched, so after CI tagged a release the owner's clone named an older "previous release" than CI
would — `bump.ts` accepted what CI then refused, and a refused bump commit can never be released
(the decide step releases only `bump to v…`), so the version would be skipped. **Fix:** every bump
file must name the current version exactly once (`guards.ts` `mentions`, in `disagreements`, so
`bump --check` and CI see it); `src/root.zig`'s examples use `0.15.2-0.680.4` / `0.700.1`; one
`visibleLines` for the entry lookup and the records (CommonMark closers; the four hiding HTML blocks);
`bump.ts` and `release.ts` fetch origin's tags and refuse when the `v*` tags here and on origin
differ in either direction (`tagsDifferFrom`). **Test:** `guards.test.ts`: second mentions in each
bump file, `…1` in `…10`, entry headings in a fence / comment / `<pre>`, the fence and HTML cases,
records after a properly closed fence, `bump.ts`'s pre-bump path (`bumped = false`, which had no
test), the tag comparison against a bare-clone origin each way and with origin gone, and **the
workflow's decide step run as written in `release.yml`** (bump commit, child, re-run, released
before). 7 more mutants: **33 of 33 caught** on a passing baseline; `bun test tools/release/`
90/90; the scratch end-to-end release bumps (its `zig build test` on the edited `src/root.zig`
passing) and passes `check-reviews.ts` (2026-11-15). **Not fixed — owner, 2026-11-15: "c", decided at the next Fil-C move (item 5
of the retest; `upstream.md` Stage A step 9):** a Fil-C or Zig move cannot pass `check-reviews.ts`, which requires the bump commit
to be exactly `bumpEdits` (N + 1, three files), while the upgrade procedure moves every pin and
resets N to 1 (`open-work.md` § Review).

## ✅ KI-31 — The guard emulated GitHub's Markdown, and each retest found another corner; now it refuses what it cannot read (class 1 retest 4; 2026-11-15, FIXED)

**Same class, found by the class's fourth retest (fresh reviewer; no way for unreviewed code
through; 1–5 RUN):** (1) comments were stripped before fences were read, so `<!-- -->` + ` ``` ` on
one line closed a fence for the guard that stays open on GitHub, and `<!--` inside inline code ate
text to the next `-->`; (2) `<?…?>` and `<![CDATA[…]]>` were read as visible, and an entry did not
end at a setext heading, an indented `##`, a bare `###` or `#<tab>`; (3) the five-places check read
RELEASE-NOTES.md and the State row RAW, so a notes heading in a comment or a fence passed; (4) no
time limit on `ls-remote` or on `release.ts`'s git calls (a hung remote waited forever); (5) a CR
byte broke the entry lookup. **The class's lesson:** four retests found four more ways an emulation
of a renderer can be made to disagree with the renderer. **Fix — refuse, do not emulate**
(`guards.ts`): `unreadable` refuses, by name, a CR byte (LF only — owner, 2026-10-01 and again
2026-11-15: "we should be using LF as the standard not CRLF") and any HTML comment, declaration,
processing instruction, CDATA or HTML block outside inline code and fences; the three Markdown
places are read only from files it passes, outside fences; `findEntry` reads only inside the one
`## Release History` section, which may hold no fence at all, and an entry ends at any heading-like
line; an entry holding a fence or a heading-like line is refused; one fence reader (`fenceLines`)
serves both `unreadable` and `visibleLines`, so they cannot disagree about what is code; every git
call has a time limit that returns when it fires (killing git does not close pipes a remote helper
still holds — found by this round's own test). Measured first: none of the real files holds a CR, a
comment, a PI or an HTML block; the one fence in `cmem/release.md` is above the section. **Test:**
`guards.test.ts` (each refused form; the notes and State-row hiding cases; inline code naming markup
allowed; a comment inside a fence allowed; a shorter fence line not closing a longer fence; the
branches no test reached — an empty bump commit, a record naming a non-commit, a parent without a
version, a parent `bumpEdits` cannot bump, bump files executable on both sides, injected git
failures in `describe` and `merge-base`, a remote helper that never answers). **Inversion,
2026-11-15: 45 of 45 mutants caught on a passing baseline** (two missed at first — no test showed a
comment inside a fence allowed, or a shorter fence line not closing — tests added).
`bun test tools/release/` 120/120.

## ✅ KI-32 — A fence inside a list item: the guard's one remaining reading of Markdown structure (class 1 retest 5; 2026-11-15, FIXED)

**Same class, found by the class's fifth retest (fresh reviewer; RUN end to end):** the fence reader
took an INDENTED fence (` ```` under`- item`) as a fence running to its matching closer, but on
GitHub a fence in a list item ends with the item, so a column-0 `<!--`after it is a live comment
that can hide the whole Release History section — while the guard skipped that`<!--` as "inside a
fence" and passed (`check-reviews.ts`exit 0,`bump --check` exit 0). The same trick split the
README status line in two readings. Smaller, same round: a one-dash setext underline (`-`) was not
heading-like; `outsideCode`paired an escaped backtick and backtick runs of different lengths
(CommonMark § 6.1 pairs only equal runs); the shared`run()`in`tools/lib/tool.ts`(release.ts's
git helper, bump.ts's fetch) waited for the pipes after a timeout kill — the hang`gitIn` had just
been fixed for. **Fix:** fences only at column 0 (`fenceLines`), and any fence-like line after
indentation, a list marker or `>` is refused by name (`containerFence`) — the guard no longer reads
container structure at all, it refuses it; `headingLike`takes`-+`; `outsideCode`removes escaped
backticks first and pairs only equal runs;`run()` stops waiting 2 s after its timeout kill
(`tools/lib/tool.ts`, all tools: behaviour changes only where a timeout fires and something still
holds the pipes, which used to hang). Measured first: none of the four Markdown files holds an
indented or prefixed fence, a lone `-`line, or an escaped backtick. **Test:** the reviewer's trap
above the section and in the README; fences indented, quoted, nested-quoted, after`-`/`1.`/ a
tab; an indented CLOSER of a column-0 fence still closing (allowed); the one-dash underline; both
backtick cases;`run()`against the never-answering remote helper (exit 124 within the limit).
**Inversion 2026-11-15: 51 of 51 mutants caught** on a passing baseline;`bun test tools/release/`
133/133; the scratch end-to-end release passes.

## ✅ KI-33 — The comment check subtracted code spans first, which is the renderer's call (class 1 retest 6; 2026-11-15, FIXED)

**Same class, found by the class's sixth retest (fresh reviewer; RUN at unit level; spec-reasoned):**
`unreadable` removed what it took for inline code spans before looking for `<!--`, but which
backticks pair is decided by CommonMark's precedence: a backtick inside a tag's attribute
(`<b title="`">`) is no span opener, and a backslash inside a span does not escape (§ 6.1, § 6.6) —
so a live comment passed, and the README status line could pass while a reader saw no version.
Smaller: inline `<details>`/`<summary>` (which collapse what follows on GitHub, everything after an
unclosed one) passed anywhere but a line start; the status line's version could sit in a tag
attribute, a code span or strikethrough. The records, entry headings, notes heading and State row
were NOT reachable (fixed column-0 text, which an inline construct cannot swallow — the reviewer's
analysis). **Fix:** the checks run on the RAW line — no code span is ever subtracted (`<!--`even in
backticks is refused; zilc's files hold none, measured);`<details>`/`<summary>`refused anywhere
outside column-0 fences; the text before the status line's version may hold no`<`, backtick,
backslash or `~`. Placeholders such as `<n>` or `` `<Zig>` `` mid-line stay allowed (they hide
nothing a guard counts). A `(?!~)`written for strikethrough after the version was seen by no test
(GFM strikethrough needs`~~`on both sides, and the prefix rule already refuses the opening one)
and was removed. **Test:** the reviewer's two inputs,`<details>`mid-line / indented / quoted / in a
list,`</summary>`, the status version in an attribute / struck through / in a code span, and
placeholders allowed. **Inversion 2026-11-15: 51 of 51 mutants caught** on a passing baseline;
`bun test tools/release/`144/144 (with a test that the real`cmem/release.md` stays readable — this
ledger's own first wording of the rule put a literal tag there); the scratch end-to-end release
passes.

## ✅ KI-34 — The two free-text places could be hidden by their surroundings (class 1 retest 7; 2026-11-15, FIXED)

**Same class, found by the class's seventh retest (fresh reviewer; rendered with Bun 1.4.4's
`Bun.markdown` — md4c, not GitHub's renderer; the CommonMark rules cited are documented, GitHub's
sanitizer behaviour inferred):** the records, entry heading and end, and the notes heading HELD
(block starts, which no inline construct crosses). The two places with free text around them did
not: (1) the README status version could be an image's alt text (`![logo (v…)](logo.svg)` — the
prefix allowed `!`, `[`, `]`); (2) a line BEFORE the status line in the same quote paragraph could
open a tag attribute (`> see <span title="`) that runs over it (an inline tag's quoted attribute
may span lines, § 6.6); (3) the State row was counted even when it was not in a table, so a
paragraph line before it could swallow it the same way. **Fix** (`guards.ts` `disagreements`):
before the status version only `[A-Za-z0-9 ,.:;/+-]`; the status line must follow a blank line (it
opens its own paragraph); the State row must be a row of a real table (a header and a delimiter
row above it, all lines `|`-led) — a cell cannot be reached by an attribute opened outside it.
Measured first: the real README and `open-work.md` already have that shape. **Test:** the alt-text
form, each of `[ ] ! $ * _` before the version, the quote-paragraph continuation, a State row
outside a table and one under a header with no delimiter row. **Inversion 2026-11-15: 54 of 54
mutants caught** on a passing baseline; `bun test tools/release/` 154/154; the scratch end-to-end
release passes.

## ✅ KI-35 — The State-row table check did not count cells (class 1 retest 8; 2026-11-15, FIXED)

**Same class, found by the class's eighth retest (fresh reviewer; RUN end to end — `bump --check`
exit 0 on the edited real file; GFM's rules documented, cmark-gfm not run, md4c agrees):** the
State row was required to sit under a header and a delimiter row, but GFM makes those a table ONLY
when both have the same number of cells, and drops a row's cells past that number. So (A) a header
of 2 cells over a delimiter of 3, its header cell opening `<a title="`, was no table at all — one
paragraph, the State row inside an attribute; (B) a one-column table rendered the State row without
its version cell. Smaller: the status message hid the real cause when an em dash or an apostrophe
came before the version (both harmless, now allowed); YAML front matter (`---` at line 1, rendered
by GitHub as a table) was not refused; `run()`'s raced promise could reject unhandled after its
give-up. Nothing in the non-Markdown core was broken. **Fix:** `cells()` splits a row on every
unescaped `|` (in code spans too, as GFM does); the header and the delimiter row must have the same
count, at least 2, and the State row the same; the header may hold no `<`; front matter refused;
the status message names the expected form and the allowed characters; `run()` catches the
raced promise. Measured first: the real State table is 2 cells in every row; every file starts
with `#`. **Test:** shapes A and B, a wider State row, the cell split (code span, `\|`, no outer
pipes), front matter, an em dash and an apostrophe allowed. **Inversion 2026-11-15: 60 of 60
mutants caught** on a passing baseline; `bun test tools/release/` 160/160; the scratch end-to-end
release passes.

## ✅ KI-36 — A fence that splits the State table, symlinked counted files, entries past their section (class 1 retest 9; 2026-11-15, FIXED)

**Same class, found by the class's ninth retest (fresh reviewer; 1–2 RUN end to end, `bump --check`
exit 0):** (1) the State table's rows were walked on VISIBLE lines, which had the fence lines
removed — a column-0 fence between the table and the State row (or between header, delimiter and
rows) ends the table on GitHub, and the row renders as a paragraph; (2) `RELEASE-NOTES.md` or
`cmem/open-work.md` as a symlink passed — the guard read through the link, while GitHub shows the
link at that path (the Release page links `blob/<tag>/RELEASE-NOTES.md`); (3) a `### v<version>`
entry under a LATER `##` / `#` section still counted; (4) a `$$` math block was not refused
(unverified on GitHub; refused by name, cheap); (5) no test tied `release.yml`'s review step and its
`if:` to the guard. The non-Markdown core held again. **Fix:** the State table is checked on the raw
lines (a fence line breaks it; the row is the first one outside a fence); the four counted Markdown
files must be mode `100644` at the commit (`MD_PLACES`, in `reviewsCoverRelease`, so CI and both
tools), and `bump.ts` refuses a symlink in the working tree; the Release History section ends at
the next level-1 or level-2 heading; `$$` refused; a test asserts the review step, its `if:`, its
command, and `tag` needing `checks`. Measured first: no `$$` line, all four files `100644`, nothing
after Release History at level 2. **Test:** fences splitting the table (two places), `$$`, an entry
under a later section (two forms), the section's last entry ending at the next section, each of the
two files as a symlink at the commit, the workflow's review step. **Inversion 2026-11-15: 64 of 64
mutants caught** on a passing baseline; `bun test tools/release/` 168/168; the scratch end-to-end
release passes.

## ✅ KI-37 — A paragraph line above the State table, GFM's ASCII-only trim, and smaller (class 1 retest 10; 2026-11-15, FIXED)

**Same class, found by the class's tenth retest (fresh reviewer, on the committed `2e557d5`; 1–2
RUN, rendered with md4c; a 20,000-mutation fuzz found 2 independently):** (1) the State table was
not required to start a block: a quote or list line (`> <a title="`) just above the header takes it
as a lazy continuation, and the "table" is that paragraph, the version row inside an attribute;
(2) `cells()` used `trim()`, which strips Unicode whitespace (NBSP, BOM, U+3000 …) where GFM trims
only space, tab, VT and FF — a header ending in NBSP is 3 cells to GitHub, 2 to the guard. Smaller:
a leading BOM hid front matter from its check; `.github/README*` (which GitHub shows instead of
`README.md`) was not refused; `$$` was refused only at a line start; the `<` ban covered only the
header (and its delimiter half was dead code); an autolink at a line start and a one-dash delimiter
row (`|-|`, valid GFM) were refused. **Fix:** the State table follows a blank line or a heading; no
`<` from its header to the State row; `cells()` trims ASCII only; a BOM or non-ASCII whitespace
anywhere in a counted file is refused (`ODD_SPACE`, built from code points so the source holds no
invisible character); `$$` anywhere; `.github/README*` refused at the commit; autolinks and `-+`
delimiters allowed. Measured first: none of the four files holds a BOM, Unicode whitespace or `$$`
(the round record in `open-work.md` mentioned `$$` mid-line — reworded). **Test:** the lazy
continuation (four leads), four code points, the ASCII-only trim, a BOM before front matter, `<` in
a row above, a one-dash delimiter allowed, an autolink allowed and `<div>` refused, `$$` in four
positions, `.github/README.md`. **Inversion 2026-11-15: 72 of 72 mutants caught** on a passing
baseline; `bun test tools/release/` 182/182; the scratch end-to-end release passes.

## ✅ KI-38 — The guard stops reading Markdown for itself: GitHub's renderer decides what is shown, Biome formats (owner, 2026-11-15; FIXED)

**Why (owner, 2026-11-15):** retests 2–10 each found another way GitHub's rendering could differ
from the guard's own reading of Markdown, and KI-31–KI-37 answered by FORBIDDING valid Markdown.
The owner: "Characters that define valid markdown elements are not forbidden"; "a markdown record
that is not rendered is an error"; and, for formatting, "biome. I know it works correctly" (the
tool the other projects use). **Measured first:** GitHub's `POST /markdown` (`gfm`, unauthenticated,
8 calls) on the reviewers' hiding cases — a comment removed; an attribute's and an image's alt text
kept out of the text; `<details>` kept, collapsed; a list item's fence ending with the item; a
mismatched table not a table; a plain record a visible `<li>`. Biome 2.5.x ignores `.md` (2.5.14:
"These paths were provided but ignored"); 2.6.0 (2026-10-21) is the first with Markdown; 2.6.4
(2026-10-28, the newest at least two weeks old) parses, formats and fails `ci` on an unformatted
file; it refuses comments in `biome.json` (so `biome.jsonc`). **Fix:** (1) `renderedProblems`
(`guards.ts`) renders the counted files with GitHub's renderer (`githubRender`: the REST API, never
`gh`; CI's token; any failure throws) and requires, as TEXT nodes (an attribute is never text) not
inside a collapsed `<details>`: the `v<version>` heading with both records under it, the notes'
`## <version>` heading, the README status version in its quote, the State row as a table row —
in `check-reviews.ts` (CI, `release.ts`) and `bump.ts release`; (2) every forbidden-construct rule
of KI-31–KI-37 removed (only LF stays, owner's standard); the text side reads plain lines and ATX
headings — eight lines of fence and setext reading were then seen by no test (the rendered check
backs them) and were removed; (3) Biome: `biome.jsonc` (Markdown only, width 100, prose kept),
`tools/md/biome.ts` (Biome 2.6.4 fetched from npm's `@biomejs/cli-linux-x64`, sha256
`71d293b5…`, = the registry's sha512 integrity; a wrong hash installs nothing — RUN), a `checks`
step and `release.ts`'s cold gate; all 46 `.md` reformatted (43 files changed: table padding,
`_emphasis_`, list markers; one file needed a second pass). The reformat padded the State row
(`| version   |`), which the old exact pattern refused — the place is now matched with any padding.
**Test:** GitHub's own HTML for the eight cases (fixtures, verbatim); a stand-in renderer (Bun's
md4c, which keeps comments and `<details>`) for records in a comment / `<details>` / a fence / an
indented block, an entry heading in a fence, records under a later heading, two entry headings,
the status version in alt text and outside its quote, the notes heading in a comment, the State
row outside a table, the renderer's failures (non-200, no answer, a throwing renderer), the CLI
refusing a record GitHub would not show; and a live test against GitHub (`ZILC_LIVE_RENDER=1`,
off by default: 60 unauthenticated calls an hour) — PASSES. **Inversion 2026-11-15: 42 of 42
mutants caught** on a passing baseline; `bun test tools/release/` 117/117 (+1 live, skipped by
default). **Limit, recorded:** GitHub does not document that `/markdown` is the repository page's
exact pipeline; every case measured agrees (its output carries the page's `notranslate` classes and
`target="_blank"` links). `bump.ts`'s own render call and `tools/md/biome.ts` have no unit test
(both RUN by hand, 2026-11-15).
**Also:** Biome padded `Fil-C.md`'s table, and `zig build check-pins` (a Zig program that checks
text pins, run by `zig build test`) matched the old spacing exactly and failed. For `.md` pins it
now treats a run of spaces as one (`squeezeSpaces`, with its own unit test, wired into `zig build
test`: 41/41); inverted — a `Fil-C.md` naming another release still fails. `zig fmt` formats the
`.zig` files, Biome the `.md` files (owner, 2026-11-15: "zig fmt checks the zig format").

## ⏹️ KI-39 — Render-design retest: hidden blocks GitHub does not show (class 1 retest 11; 2026-11-15; SUPERSEDED 2026-11-19)

**Found (retest 11, all RUN against GitHub's `/markdown`):** a `<details>` nested in a list item
or paragraph, a summary inside an outer collapsed `<details>`, struck-through records and status
version, and a visible code-block copy while the counted line is hidden — each let the guard count
a place the reader does not see. Accepted, not fixed: a decoy HTML table row showing the State
row's facts while the real row is not a table (the reader sees the right version). Loud refusals
noted: `/markdown`'s 400 KB limit (`open-work.md` is about 60 KB); 60 unauthenticated renders an
hour locally, about 11 per release cycle (CI uses its token).
**Fix, committed in `cdbb031` (owner, 2026-11-19):** `renderedBlocks` (`tools/release/guards.ts`)
keeps text inside a collapsed `<details>` at any depth, or inside `<del>` / `<s>` / `<strike>`, out
of its block; `<details open>` is shown; numeric and `&nbsp;` references are decoded; records must
be list items again; the redundant `seen` filter is gone. `bun test tools/release/` 128/128, Biome
clean, `bump --check` ok, the live render passes (2026-11-15). **Not done:** the mutant run (in
flight at the pause, its harness lost with the scratchpad) and the fresh class 1 retest.
**Superseded (owner, 2026-11-19):** letter H37 replaces the record-paragraph check this guards
with a run of the review set, and takes the tests out of CI; review round 1 stopped
(`open-work.md`, top). **Done 2026-11-19:** H37 (d) replaced `check-reviews.ts` and the two
record lines with `review-gate.ts` and one `- Review complete: <commit>` line (the exact-bump and
history checks kept); (e) took every test and gate out of CI (`release.md`).
