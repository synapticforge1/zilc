# working-rules.md — the checklist for every increment in zilc

zilc sits in a workspace of sibling repos whose common floor is `../workspace/cmem/working-rules.md`
(since 2026-10-26, workspace letter H26; the workspace memory is the `workspace` repo since
2026-11-19, letter H42; its Tooling rules are in `../workspace/cmem/tooling-rules.md`). This file records that floor as it applies here, plus zilc's own
rules. **zilc's own rules govern inside zilc**; where they differ from the floor, the difference is
named below. Method lessons are in [best-practices.md](best-practices.md), not here.

## Before starting work

- Read `../workspace/cmem/workspace-correspondence.md` (one line per open item) for every item
  addressed to zilc, or touching what you will change (owner, 2026-10-26, binding on every repo),
  then only those items' files in `../workspace/cmem/letters/<ID>.md` (letter H41). zilc answers in
  its own memory, then appends ONE bullet under `## Answers` in the item's file —
  `- **zilc, <date>:** <what was done, the commit, the check>`, lines under 200 characters — and
  changes neither the index line nor the status; the creator verifies and closes. That bullet is
  the one write zilc makes outside its own repo (the workspace session commits it), and the
  workspace repo is PUBLIC: no machine paths, credentials or personal facts in it (letter H42).
  An old pointer to `handoffs.md H<n>` or a ledger row resolves by searching
  `../workspace/cmem/archive/` for the ID.
- **Never write into a sibling repo** (zailc, wazmrt, …) from a zilc session, unless the owner
  directs that specific write; draft the note here and hand it over. zailc reads zilc as its
  oracle; zilc changes nothing for it.

## Session routine (🔒 owner, 2026-11-17; the memory guide, letter H38)

The guide is `../workspace/cmem/memory-guide.md`. The root `CLAUDE.md` (gitignored) names
`cmem/STATE.md` and `cmem/INDEX.md` and nothing else.

- **Start:** read [STATE.md](STATE.md), then [INDEX.md](INDEX.md), then the workspace rows
  addressed to zilc (§ Before starting work); open only the files STATE's "Read next" or the task
  names in the index.
- **End:** rewrite `STATE.md` (never append; counts only, no issue content, no machine facts);
  move what closed to `cmem/archive/`; record decisions in `design-decisions.md` and rules here;
  run the size check, `bun scripts/check-cmem.ts` (the workspace's script, verbatim; `--summary`
  for counts), and fix what it reports.
- **Limits:** `INDEX.md` 3 KB, a router with one line per file under 120 characters; `STATE.md`
  60 lines; any other live note 25 KB; any line outside a code block 200 characters; `archive/`
  and `local/` unlimited.
- **Sub-agents:** a reviewer gets its brief and `STATE.md` and does not browse `cmem/`; any other
  sub-agent gets the task and the exact files the main session picked from the index.

## 🔒 What bites in the first five minutes (moved from `INDEX.md`, 2026-11-19)

0. 🔒 **zilc is Fil-C on Linux x86_64 only, worked in WSL or Linux — always** (owner,
   2026-10-27). zailc uses zilc as its base and develops the cross-platform part; no aarch64,
   macOS, Windows, mobile or cosmo work happens here (`design-decisions.md`). 🔒 **zilc's whole
   role** (owner, 2026-10-27): track Fil-C releases, follow the Zig whose LLVM matches Fil-C's,
   keep Zig and C correct under Fil-C on x86_64 Linux, be zailc's reference — and keep the
   **pure-Zig track**: zailc's build up to a pure-Zig Fil-C running in Linux (the runtime by
   `zig build`, then the pass in Zig), checked by `zig build gate-zig-modules`; zilc is the corpus
   of truth (owner, later the same day; `roadmap.md`). zailc keeps its modifications.
1. 🛑 **Nothing built by Fil-C, cosmo or zilc is ever EXECUTED on the Windows host** (owner,
   2026-10-08; the machine's EDR, `workarounds.md`). Everything runs in WSL.
2. **Work happens in WSL2** (Ubuntu), under `~/zilc-work/`; `sudo` needs a password, so install
   into `$HOME` (`tools/README.md` "First-time setup"). 🔒 **Bun runs inside Linux only** (owner,
   2026-10-27): `~/.bun/bin/bun` from a WSL shell; the tools refuse Windows' Bun. Ad-hoc commands
   from Windows: **pass shell text to WSL as a FILE** (KI-1).
3. **Toolchain: Zig 0.15.2** (owner, 2026-09-18). 🔒 **zilc stays on the Zig whose LLVM matches
   Fil-C's, always** (owner, 2026-10-27): no newer-Zig line here, only recommendations for one
   (`upstream.md`). WSL's at `~/zilc-work/tools/zig-0.15.2/zig`
   (`tools/p1/setup-wsl.ts`); bare `zig` may be a newer Zig that fails to build zilc (KI-3). The
   repo is on exFAT, so **keep the Zig cache in the Linux home** (KI-2), as `run-gate.ts` does:

   ```sh
   ZIG_LOCAL_CACHE_DIR=~/.cache/zilc-zig ~/zilc-work/tools/zig-0.15.2/zig build test
   ```

4. **`zig build gate` must be green before anything is believed**, and it prints `SKIPPED` (exit
   0) when the Fil-C toolchain is missing — read its first line. `~/.bun/bin/bun tools/run-gate.ts`;
   everything else in `testing.md`.
5. 🔒 **Clone zilc, install the build tools, `zig build` either side** (owner, 2026-10-27; done
   2026-10-30): the first step that needs Fil-C's sources fetches them, GitHub's archive at the
   build commit as-is, pinned by `build.zig.zon`'s hash — **no Fil-C distributable in zilc, ever**
   (owner, 2026-10-30). Every reference to the Fil-C release moves together: `zig build check-pins`
   (`design-decisions.md` top row; `releasing.md` checklist).
6. **LF everywhere** (owner): `.gitattributes` is `* text=auto eol=lf`; reference clones use
   `core.autocrlf=false`.

## Git

- Commit messages go through a file: `git commit -F <file>`, the file written with the file tools.
  Never a heredoc, never a double-quoted `-m`.
- **Nothing is pushed, tagged or published unless the owner says so.**
- Branches: one branch per Zig line, `main` the base (`releasing.md`); work branches such as
  `bun-port` (merged and deleted 2026-10-27) are merged by the owner's call.
- Docs and memory land in the same commit as the code they describe.
- **Every `.zig` file is formatted with the project's Zig (0.15.2 today), and `zig fmt --check
  build.zig build tools tests src` is clean before a commit** — the `tests/basics` copies of the
  owner's programs included, both the `zig-0.15.2` and `zig-0.16.0` folders (owner, 2026-11-06:
  _"if we need to fix formatting, lets fix that first then commit and push"_; then _"they need to
  be formatted for the version we are currently using in this project"_). Confirm the diff is
  layout only and rebuild what the file feeds.
- **Every `.md` file is formatted by Biome, and `bun tools/md/biome.ts ci .` is clean before a
  commit** (owner, 2026-11-15: "biome. I know it works correctly"; the tool the other projects
  chose). `bun tools/md/biome.ts format --write .` formats; one pass may leave a file for a second.
  Biome 2.6.4, pinned by version and sha256 in the tool; `biome.jsonc` holds the settings. Any
  valid Markdown is allowed — nothing is forbidden for a guard's sake (owner, 2026-11-15).
- Line endings are LF, pinned in `.gitattributes` wildcard-first (`* text=auto eol=lf`). Never
  "fix" a line-ending complaint with `git config`; check with `git check-attr`.
- The exFAT `.git` recipe is KI-23's (`known-issues.md`); the workspace standard differs —
  `open-work.md` owner call 4.

## The gate

- A change to `src/` (or to a tool a gate runs) triggers the full gate, run on the committed tree
  after the last edit, reading every exit code and diffing OUTPUT, not exit codes: `testing.md`.
  `testing.md` is the gate's definition. 🔒 **Every gate and test runs locally; CI only publishes**
  (owner, 2026-11-17, letter H37 (e)): `.github/workflows/release.yml` decides whether a push is a
  release, verifies the version (`bump.ts --check`), tags and makes the page; `release.ts` runs
  every gate before it pushes (`release.md` § "What runs where"). `zig build gate` prints
  `SKIPPED` and exits 0 without Fil-C — read its first line.
- 🛑 Nothing built by Fil-C, cosmo or zilc is ever executed on the Windows host
  (`workarounds.md`).

## Platform (🔒 owner, 2026-10-27)

- **zilc is Fil-C on Linux x86_64 only, worked in WSL or Linux — always.** Every Fil-C step,
  user-program build, test and run of output is on Linux x86_64, natively or in WSL. No
  cross-platform work lands here: aarch64 (Linux included), macOS, Windows, iOS, Android and
  cosmo/APE belong to zailc, which uses zilc as its base.
  A change that adds a non-Linux target to zilc is out of scope, not a feature
  (`design-decisions.md`, top row).
- **The tools run in Linux too**: from a WSL shell on this machine, from a Linux shell elsewhere,
  with that environment's Bun (§ Tooling).

## Tooling (owner, 2026-10-22; workspace rule 1)

- **A committed script that stays for repeated use is TypeScript run by Bun** (Zig's `zig run`
  builds an executable, so it does not count as a scripting mechanism). 🔒 **Bun runs inside
  Linux only** (owner, 2026-10-27): WSL's Bun (`~/.bun/bin/bun`) on a Windows host, the machine's
  own Bun on a Linux machine. Never start a zilc tool with Windows' Bun. Node APIs + `Bun.*`, never
  `Deno.*` or `jsr:`. `build.zig` and the Zig sources it builds and runs are the build, not
  scripts. **No committed shell scripts** — none since 2026-10-27, when `tools/p1/setup-wsl.sh` became
  the documented Bun step (`tools/README.md` "First-time setup") plus `tools/p1/setup-wsl.ts`. A one-time probe deleted after use may be
  any language, still written with the file tools.
- **No heredocs, ever**, in any language (`bun -e`, `@'…'@`, `-F -` included). No host Python.
- 🔒 **No `gh`, in CI too** (owner, 2026-11-08; workspace Tooling rule 9, letter H30): check the
  repo instead — `git ls-remote` and the repo's own files; in a workflow, GitHub's REST API from a
  Bun step with `GITHUB_TOKEN` (`tools/release/github-*.ts`); a GitHub web-UI task is an owner item.
  `git grep` finds no `gh` invocation in zilc (2026-11-12).
- 🔒 **Bun versions: every notation is the latest installed Bun** (owner, 2026-11-09; workspace
  Tooling rule 10, letter H31) — the pin in `tools/README.md`, `roadmap.md`'s toolchain row and the
  workflow's `BUN_VERSION` move together; 1.4.4 since 2026-11-07.
- After any scripted edit, read back the changed lines; an edit script asserts each match exactly
  once and writes atomically.
- When the exit code IS the measurement, do not pipe: redirect to a file, then read the code.

## Scratch space (🔒 owner, 2026-11-19; workspace Tooling rule 15, letter H43)

The rule is the workspace's (`../workspace/cmem/tooling-rules.md` rule 15); as it applies here:

- **Every scratch and cache location counts:** the session scratchpad, the system temp folder,
  WSL's home and `/tmp`, `~/zilc-work/`, and any folder a tool or session makes for throwaway work.
- **Throwaway files go in this session's own scratchpad folder only**, never another session's;
  its path is a machine fact and is never written into a tracked file.
- **Project data lives in the project:** notes, decisions, results and state go in `cmem/`
  (private ones in `cmem/local/`), never only in scratch, a temp folder or the assistant's own
  per-project memory folder. A fact found outside is copied in and the outside copy removed.
- **Delete when the item is cleared:** a one-time script after its run; a reproducer, clone or
  build output when its finding is fixed and verified; a reviewer's folder (clones, mutants,
  planted inputs) when its round is triaged.
- **Budget: 200 MB per session scratchpad folder.** Anything larger is announced before it is
  made and removed when its step is done.
- 🗓️ **`~/zilc-work/` is zilc's named cache outside the repository**, not scratch: Fil-C and
  Zig work in WSL needs a Linux filesystem (WSL's `/tmp` was seen emptied, 2026-11-12), and
  it holds the toolchains the tools use (`~/zilc-work/tools/`, `patched-clang/`). Its folders,
  why each exists and the command that clears each are recorded in `cmem/local/zilc-work.md`.
  🔒 **No size limit; it is cleared as things stop being used** (owner, 2026-11-19: "I do not
  think a size limit is required as long as we are clearing things after they are not being
  utilized anymore"): **only the latest toolchain is kept** (owner, same day) — at a Fil-C or Zig
  move the old version's toolchain, archive, suite tree and build trees go once the new one passes
  the gate; a run's output goes once its result is recorded in `cmem/`; a probe goes after its
  run. Kept for the maintainer's GCC check: the two pinned GCCs, not their build tree.
- 🔒 **zilc cleans only zilc's items** (owner, 2026-11-19: "any items from a different project
  is that project's responsibility"). What another project left — in WSL's home (`~/zailc-work/`,
  a wazmrt folder, …), the system temp folder or anywhere else — is neither measured for removal
  nor touched from a zilc session; the owning project manages it.
- **Sub-agents** work in a folder under the main session's scratchpad; the main session removes
  it, and the brief says so.
- **Session end, and before the owner's "commit":** delete what this session wrote to scratch,
  then do the memory update; `open-work.md` never points at a scratch file.

## Privacy (🔒 owner, 2026-10-22, clarified 2026-10-23 and 2026-10-26)

Everything committed is public (zilc's GitHub repo is public), `cmem/` included. Never in a
committed file, a commit message, an issue or a release:

- **secrets** — tokens, keys, passwords, `.env` contents;
- **personal information** — email addresses, phone numbers, machine names, private account
  names, and **personal drive paths**.

**The path test is "is it machine-specific?", not "is it absolute?"** (owner, 2026-10-23, letter
H22). Not public: any path that records the owner's own machine layout — a user profile
(`C:\Users\<name>\…`), the project tree (`D:\Programs\…`), other drives, scoop or AppData installs,
scratchpad or session ids. Fine: repo- or sibling-relative paths (`../wazmrt/cmem`), environment
variables, placeholders (`<repo-root>`, `<scratchpad>`), WSL's `~/zilc-work`, and **convention
paths** that name nothing about one machine and work on any comparable host — `C:\zig-cache\zilc`
(the KI-2 cache) and `C:\zig\0.15.2\zig.exe` (the official zip unpacked by version; overridable by
`ZIG`). A scan hit is a candidate, judged by that test.

**The one exception — the maintainer address** (owner, 2026-10-23/26, letter H28): one contact
email in a registry manifest field (zilc publishes to no registry), as the git commit
author/committer address, and in ONE committed `cmem/` note that names the maintainer contact.
zilc carries it in no tracked file today (2026-10-27); it is not written into memory.

Private facts go in the gitignored `cmem/local/` (check `git check-ignore -v` before the first
write) or nowhere. Tool settings that record paths (`.claude/settings.local.json`) are never
tracked.

**Scan before committing**, text AND binaries (`-I` skips binaries; DWARF in committed objects has
carried paths in two siblings):

```
git grep -I -n -i -E '[A-Za-z]:[\\/]+(Programs|Users|scoop|tools)[\\/]|/[a-z]/(Programs|Users)/'
git grep -a -l -i -E '[A-Za-z]:[\\/]+(Programs|Users|scoop|tools)[\\/]|/[a-z]/(Programs|Users)/'
```

A secret that reached the remote is rotated, not just deleted. History is purged of personal
information (letter H19) — for zilc, done locally 2026-10-27 (`history-map-2026-10-27.md`); the
force-push is `open-work.md` owner call 1.

## Records

- 🔒 **Do not guess: test and verify** (owner, 2026-11-07: "please do not guess. just test and
  verify." — said after a guessed Zig path failed). Paths, commands, tool locations and whether a
  port matches upstream are looked up (`tools/lib/tool.ts`, `testing.md`, `which`) or run, never
  assumed. A "0 differ" is proven real: outputs non-empty, coverage counted, a planted fault caught.
  Say what was not tested.
- A written number is a claim with a date; re-derive it before quoting or acting on it.
- Owner calls stay owner calls: where a record says 🗓️, gather the evidence and stop.
- Retired siblings: wabt-ts and binaryen-ts (2026-10-26) are cited only as history, never as a
  location; their memory is binaryang's `cmem/wabt-ts.md` and `cmem/binaryen-ts.md`.
- 🔒 **zailc reads zilc's tests, examples and recorded results as its corpus** (ledger C28,
  2026-11-12): `tests/` (the `basics` copies, the corpus, `tests/sarcasm/`), `examples/`, the gate
  cases, and the dated results in `testing.md` / `sarcasm-port.md`. **A move, rename or removal of
  any of them is announced** — in that release's entry in `release.md`, or, between releases, as a
  letter to zailc in `../workspace/cmem/letters/` — before or with the commit. zilc still
  changes nothing FOR zailc; it only says what moved.

## Owner commands: "commit", "push", "release" (owner, 2026-11-10)

🔒 Written into every project by the workspace session on the owner's direction (2026-11-10:
"please write that into each project"; workspace `cmem/working-rules.md` Tooling rule 12, letter
H34). When the owner says:

- **"commit"** — first run "update the project memory files" (re-derive this repo's `cmem/` from
  its current state), then commit to the branch being worked on. Nothing is pushed.
- **"push"** — perform "commit", then merge the branch into `main`, then push `main` (and the
  working branch) to GitHub (`origin`) and read it back with `git ls-remote`.
- **"release"** — perform "push", then the release process: the workspace's
  `cmem/release-process.md` §§ 5–8 — CI checks first, then CI pushes the tag, then the GitHub
  Release page from the tag, then the publish to the registry — recorded in `cmem/release.md`
  § "Release History" (newest first, a summary of what changed). The level (patch / minor /
  major) is the owner's: ask if it was not given.

Each command includes the one before it, and none goes further than its own word (a "commit"
never pushes, a "push" never releases). This repo's own gate and merge rules apply at each step.
For zilc, "release" is [release.md](release.md): no registry, so CI's tag and page are the release,
and the KIND (`release`, N + 1) replaces the level.

## Owner commands: the seven review words (🔒 owner, 2026-11-17, letter H37)

The workspace review standard (`../workspace/cmem/review-process.md`); zilc's slots:
[review-process.md](review-process.md). **Five reviews are required before every release, in this
order: basic, hardening, licensing, security, privacy**; an efficiency review is optional and runs
first when asked.

- **"review"** — all five required classes, by the standard's loop (one agent per class, fixes per
  class, re-reviews of the fixes only, until one is empty; then the full suite once per platform).
- **"basic review"**, **"hardening review"**, **"licensing review"**, **"security review"**,
  **"privacy review"** — that one class, by the same loop.
- **"efficiency review"** — the optional class alone.

None of them commits, pushes or releases. A completed review is recorded as one line
`- Review complete: <commit>` in `review-process.md` § Last review; `release.ts` checks it first.
(Until 2026-11-19: "review", "security review", "hardening review" — letter H35.)

## Memory policy and triggers (moved from `INDEX.md`, 2026-11-19; adopted from wazmrt 2026-09-18)

- **`cmem/` is the single home for ALL project memory**; the status lives in `STATE.md`, once, and
  `INDEX.md` is a router (§ Session routine).
- **`README.md` is NOT project memory**: it is the public document; no decision logs in it.
- **`third_party/LICENSES.md` is the compliance source of truth**; `licensing.md` records the _why_.
- **Nothing private in a committed file**: the path test and the scan are in § Privacy; private
  facts go in the gitignored `cmem/local/`.
- **Outside `cmem/`:** `README.md` (public), `third_party/LICENSES.md` (the compliance ledger),
  `LICENSE-*` / `NOTICE`; `tools/README.md` (first-time setup, how the Bun tools run, inside Linux
  only); `Fil-C.md`, `Zig.md` (owner, 2026-10-27): **the notes on how zilc got from base (stock
  Fil-C and Zig) to pure-Zig parity, for zailc to build on** — the base and its workarounds (KI
  records), then the route piece by piece (recipe, Zig build, oracle, allowed differences,
  status); upstream defects stay in `UPSTREAM-ISSUES.md`. Update them with every Fil-C or Zig move
  and every track step.

### The "update the project memory" trigger (binding on every agent)

When the owner says **"update the project memory"** (or "update memory", "record this", "remember
this for the project"), do all of the following:

1. **Revise all relevant `cmem/` files.** Fold in the change, rewrite `STATE.md`, convert dates to
   absolute, and update entries instead of duplicating them. Then AUDIT: grep the old values
   across `cmem/`, `README.md` and `tools/README.md`; when two files disagree, measure.
2. **Sync `README.md` only where the change is user-relevant** (build, usage, status).
3. **If the work produced a transferable METHOD lesson, add it to
   [`best-practices.md`](best-practices.md)** as one bold rule plus a citation to the incident.
   Cross-repo lessons are reported to the workspace as well.
4. **Keep the patched Fil-C clang archived in the project (owner, 2026-10-01).** Run
   `bun tools/filc/check-toolchain.ts`. If it reports STALE (a new patch
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

5. **Check Fil-C upstream for changes (owner, 2026-10-01):** `bun tools/upstream/check-upstream.ts`
   (in WSL). Record in `upstream.md` anything that touches a watched file, above all whether
   zilc's pass patch still applies. After reviewing, `--mark-reviewed`, and commit
   `tools/upstream/REVIEWED`. The reference clone is `upstream/fil-c/` (gitignored, never built).
6. **Scan the diff for personal information before committing** (§ Privacy).

### The "workaround" rule (binding on every agent; owner, 2026-10-01)

**Every workaround gets copious WHY notes in [`workarounds.md`](workarounds.md) when it is made**,
whether the cause is an upstream defect or a system limitation: the exact symptom, the class, the
root cause (measured vs. surmised, kept apart), why the fix is correct, what was ruled out, how it
was found, how to recognise a relative, and the cost and exit condition. **A new failure is looked
up in `workarounds.md`'s symptom index and families first.**

### The "adopt upstream code" trigger (binding on every agent)

Before incorporating or adapting code from Fil-C, LLVM or Zig (see `reference-projects.md`,
`upstream.md`), complete the **Adoption Checklist** in `third_party/LICENSES.md`, add a Component
Ledger entry, and update `reference-projects.md`. _Looking at_ upstream code is free. _Copying or
porting_ it always requires the ledger entry, and code that ends up in the **runtime** also needs
the runtime-linking rule checked.

### Workspace triggers

"look for code issues", "coordinate", "divergence" and the regression gate were defined in the
workspace INDEX's § Triggers and bind here too. Since the workspace's own memory migration
(2026-11-19) that text is only in `../workspace/cmem/archive/INDEX-to-2026-11-19.md` § Triggers;
no live workspace file holds it (checked 2026-11-19).
