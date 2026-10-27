# cmem — Portable Project Memory for zilc

**At session start, read `../cmem/workspace-correspondence.md` (then `../cmem/handoffs.md`) for
items addressed to this repo** — the workspace pull line (letter H26). zilc has no `CLAUDE.md`, so
the line lives here.

This folder is the **authoritative, portable project memory** for `zilc`. It lives inside the
project tree, so it travels with the project (USB drive, clones) and is **committed to git**.
Plain Markdown, one focused topic file per domain. Modeled on the `cmem/` of the sibling project
wazmrt (`../wazmrt/cmem`), the template for structure and policy. Since 2026-10-26 zilc is under
the workspace floor (`../cmem/working-rules.md`); how it applies here: [working-rules.md](working-rules.md).

**The state of the project and everything outstanding: [open-work.md](open-work.md)** — the one
place for the status line. This file holds no status narrative (workspace `memory-conventions.md`;
the dated log it carried until 2026-10-27 is summarized there, full text
`git show c2841dd:cmem/INDEX.md`). Commit ids written before 2026-10-27 are pre-purge ids:
look them up in [history-map-2026-10-27.md](history-map-2026-10-27.md).

## 🔒 What bites in the first five minutes

1. 🛑 **Nothing built by Fil-C, cosmo or zilc is ever EXECUTED on the Windows host** (owner,
   2026-10-08): the machine's EDR quarantined cosmo programs run as `.exe` and cut Claude Code off.
   All Fil-C work runs in WSL; the Windows half of an APE only under `wine64` in WSL
   (`workarounds.md` "Nothing built by Fil-C or cosmo is ever EXECUTED on the Windows host").
2. **Fil-C work happens in WSL2** (Ubuntu), under `~/zilc-work/`. `sudo` needs an interactive
   password, so install into `$HOME`. zilc's tools are Bun and bridge into WSL with an argument list
   (`tools/README.md`); for ad-hoc commands, **pass shell text to WSL as a FILE** (KI-1).
3. **Toolchain: Zig 0.15.2** (owner, 2026-09-18), at `C:\zig\0.15.2\zig.exe`, not on PATH; bare
   `zig` may be a newer Zig that fails to build zilc (KI-3). **D: is exFAT: set
   `ZIG_LOCAL_CACHE_DIR=C:\zig-cache\zilc` before any `zig build`** (KI-2).

   ```powershell
   $env:ZIG_LOCAL_CACHE_DIR = 'C:\zig-cache\zilc'
   & C:\zig\0.15.2\zig.exe build test
   ```
4. **`zig build gate` must be green before anything is believed**, and it prints `SKIPPED` (exit
   0) when the Fil-C toolchain is missing — read its first line. `bun tools/run-gate.ts`;
   everything else in `testing.md`.
5. **LF everywhere** (owner): `.gitattributes` is `* text=auto eol=lf`; reference clones use
   `core.autocrlf=false`.

## Policy (durable — adopted from wazmrt 2026-09-18)

- **`cmem/` is the single home for ALL project memory.** When the owner says "**update the project
  memory**", fold the latest decisions, found bugs, design changes and current state into the
  matching `cmem/` topic file(s), then refresh its one-line pointer in the Files table below.
  Convert relative dates to absolute. Update existing entries rather than duplicating them.
- **This index stays one line per file**, and with the pointer under about 10 KB. State goes in
  `open-work.md`, once.
- **`README.md` is NOT project memory.** It is the public, user-facing document. Keep internal
  decision logs and post-mortems out of it.
- **`third_party/LICENSES.md` is the compliance source of truth.** `licensing.md` records the *why*;
  the ledger of actually-reused code lives in `third_party/LICENSES.md`. Keep them consistent.
- **Nothing private in a committed file**: the path test and the scan are in
  [working-rules.md](working-rules.md) § Privacy; private facts go in the gitignored `cmem/local/`.
- **Never run a formatter on `cmem/`.**

### The "update the project memory" trigger (binding on every agent)

When the owner says **"update the project memory"** (or "update memory", "record this", "remember
this for the project"), do all of the following:

1. **Revise all relevant `cmem/` files.** Fold in the change, refresh the Files-table pointer,
   convert dates to absolute, and update entries instead of duplicating them. Then AUDIT: grep the
   old values across `cmem/`, `README.md` and `tools/README.md`; when two files disagree, measure.
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
   (any OS). Record in `upstream.md` anything that touches a watched file, above all whether
   zilc's pass patch still applies. After reviewing, `--mark-reviewed`, and commit
   `tools/upstream/REVIEWED`. The reference clone is `upstream/fil-c/` (gitignored, never built).
6. **Scan the diff for personal information before committing** ([working-rules.md](working-rules.md)
   § Privacy).

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

### Workspace triggers

"look for code issues", "coordinate", "divergence" and the regression gate are defined in
`../cmem/INDEX.md` § Triggers and bind here too.

---

## Files

| File | What it holds |
| --- | --- |
| [open-work.md](open-work.md) | **The state (version, gates, branches) and everything outstanding**: owner calls, open work, workspace letters, the summarized dated log. |
| [working-rules.md](working-rules.md) | The checklist for every increment: the workspace floor as it applies here — git, gate, tooling (Bun), privacy and the path test. |
| [overview.md](overview.md) | What zilc is, repo layout, key files, build steps. |
| [vision.md](vision.md) | The goal: one `zig` binary compiling Zig, C and C++ to one memory-safe target; unverified claims marked. |
| [architecture.md](architecture.md) | The pipeline, InvisiCap and FUGC, and the runtime contract measured 2026-09-30 (`libpizlo`'s four layers). |
| [design-decisions.md](design-decisions.md) | Invariants, dated decisions with who decided, and the open questions for the owner. |
| [upstream.md](upstream.md) | How zilc tracks Fil-C: pinned release, watched files, the `upstream/fil-c/` monitor, the 0.686 review, the upgrade procedure. |
| [licensing.md](licensing.md) | `Apache-2.0 WITH LLVM-exception OR MIT`: why, the runtime-linking rule, the copyleft exclusion. |
| [reference-projects.md](reference-projects.md) | Fil-C, LLVM, Zig: verified licenses, what to mine each for, adoption status. |
| [zig-filc-scope.md](zig-filc-scope.md) | Scope of a Zig version of Fil-C on 0.15.2 (2026-10-05) — the brief zailc started from. |
| [platforms.md](platforms.md) | P6 scope pass per platform, and the cosmo evaluation (closed 2026-10-08). |
| [roadmap.md](roadmap.md) | P0–P2 done; P3 Zig runtime, P4 Zig-language fidelity, P5 C++, P6 other platforms. |
| [security-model.md](security-model.md) | The safety guarantees targeted, and what is out of scope. |
| [testing.md](testing.md) | Every gate with its command and dated count; the output comparison; corpus results per mode; planned gates. |
| [known-issues.md](known-issues.md) | The defect log, KI-1…KI-23: root cause, fix, status. |
| [workarounds.md](workarounds.md) | The WHY of every workaround (owner rule): symptom index, failure families. **Look up new failures here first.** |
| [releasing.md](releasing.md) | The version scheme `<Zig>-<Fil-C>.<zilc release>` (DESIGN, workspace P8), where the number lives, the release checklist. |
| [filc-abi.md](filc-abi.md) | Fil-C 0.685's runtime ABI as observed: flight pointers, object header, function objects, calling convention. |
| [zig-upstream-notes.md](zig-upstream-notes.md) | Zig behaviours we may need to report (Z-1…Z-5), each with whether it is really a Zig bug. |
| [ports/](ports/README.md) | Port notes, one file per new Zig line: basis, API changes, sites touched. |
| [history-map-2026-10-27.md](history-map-2026-10-27.md) | The 2026-10-27 history purge (drive paths): what was removed, how it was checked, every old → new commit id. |
| [best-practices.md](best-practices.md) | Method rules: zilc's own (§§ 1–5) and the workspace ★ block copied verbatim (§ 6). |
| `local/` | Gitignored, machine-only facts. Absent in a clone. |

## Related files outside cmem

- `README.md`: the public, user-facing doc. NOT project memory.
- `third_party/LICENSES.md`: the compliance ledger, adoption checklist and verified inventory.
- `LICENSE-APACHE` / `LICENSE-MIT` / `NOTICE`: the dual license texts and attribution notice.
- `tools/README.md`: how the Bun tools run, and how they bridge into WSL.
