# working-rules.md — the checklist for every increment in zilc

zilc sits in a workspace of sibling repos whose common floor is `../cmem/working-rules.md` (since
2026-10-26, workspace letter H26). This file records that floor as it applies here, plus zilc's own
rules. **zilc's own rules govern inside zilc**; where they differ from the floor, the difference is
named below. Method lessons are in [best-practices.md](best-practices.md), not here.

## Before starting work

- Read `../cmem/workspace-correspondence.md` for every open row addressed to zilc, or touching what
  you will change (owner, 2026-10-26, binding on every repo), and `../cmem/handoffs.md` for the
  letters' full text. zilc answers in its own memory, then writes the commit into its row of the
  ledger; the creator of a row verifies and closes it.
- **Never write into a sibling repo** (zailc, wazmrt, …) from a zilc session, unless the owner
  directs that specific write; draft the note here and hand it over. zailc reads zilc as its
  oracle; zilc changes nothing for it.

## Git

- Commit messages go through a file: `git commit -F <file>`, the file written with the file tools.
  Never a heredoc, never a double-quoted `-m`.
- **Nothing is pushed, tagged or published unless the owner says so.**
- Branches: one branch per Zig line, `main` the base (`releasing.md`); work branches such as
  `bun-port` (merged and deleted 2026-10-27) are merged by the owner's call.
- Docs and memory land in the same commit as the code they describe.
- Line endings are LF, pinned in `.gitattributes` wildcard-first (`* text=auto eol=lf`). Never
  "fix" a line-ending complaint with `git config`; check with `git check-attr`.
- The exFAT `.git` recipe is KI-23's (`known-issues.md`); the workspace standard differs —
  `open-work.md` owner call 4.

## The gate

- A change to `src/` (or to a tool a gate runs) triggers the full gate, run on the committed tree
  after the last edit, reading every exit code and diffing OUTPUT, not exit codes: `testing.md`.
  zilc has no CI workflow, so `testing.md` is the gate's definition. `zig build gate` prints
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
- After any scripted edit, read back the changed lines; an edit script asserts each match exactly
  once and writes atomically.
- When the exit code IS the measurement, do not pipe: redirect to a file, then read the code.
- Never run a formatter on `cmem/` or on `tests/basics/`.

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

- A written number is a claim with a date; re-derive it before quoting or acting on it.
- Owner calls stay owner calls: where a record says 🗓️, gather the evidence and stop.
- Retired siblings: wabt-ts and binaryen-ts (2026-10-26) are cited only as history, never as a
  location; their memory is binaryang's `cmem/wabt-ts.md` and `cmem/binaryen-ts.md`.
