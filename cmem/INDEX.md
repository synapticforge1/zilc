# cmem — Portable Project Memory for zilc

**At session start, read `../cmem/workspace-correspondence.md` (then `../cmem/handoffs.md`) for
items addressed to this repo** — the workspace pull line (letter H26). zilc has no `CLAUDE.md`, so
the line lives here.

The **authoritative, portable project memory** for `zilc`, committed with the project; one
topic file per domain, modeled on wazmrt's (`../wazmrt/cmem`). The workspace floor
(`../cmem/working-rules.md`) as it applies here: [working-rules.md](working-rules.md).

**State and everything outstanding: [open-work.md](open-work.md)**, the one status line (the dated
log this file held until 2026-10-27: `git show c2841dd:cmem/INDEX.md`). Commit ids written before
2026-10-27 are pre-purge: [history-map-2026-10-27.md](history-map-2026-10-27.md).

## 🔒 What bites in the first five minutes

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
3. **Toolchain: Zig 0.15.2** (owner, 2026-09-18), WSL's at `~/zilc-work/tools/zig-0.15.2/zig`
   (`tools/p1/setup-wsl.ts`); bare `zig` may be a newer Zig that fails to build zilc (KI-3). The
   repo is on exFAT, so **keep the Zig cache in the Linux home** (KI-2), as `run-gate.ts` does:

   ```sh
   ZIG_LOCAL_CACHE_DIR=~/.cache/zilc-zig ~/zilc-work/tools/zig-0.15.2/zig build test
   ```
4. **`zig build gate` must be green before anything is believed**, and it prints `SKIPPED` (exit
   0) when the Fil-C toolchain is missing — read its first line. `~/.bun/bin/bun tools/run-gate.ts`;
   everything else in `testing.md`.
5. **LF everywhere** (owner): `.gitattributes` is `* text=auto eol=lf`; reference clones use
   `core.autocrlf=false`.

## Policy (durable — adopted from wazmrt 2026-09-18)

- **`cmem/` is the single home for ALL project memory**; this index stays one line per file and
  under about 10 KB; state goes in `open-work.md`, once.
- **`README.md` is NOT project memory**: it is the public document; no decision logs in it.
- **`third_party/LICENSES.md` is the compliance source of truth**; `licensing.md` records the *why*.
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
   (in WSL). Record in `upstream.md` anything that touches a watched file, above all whether
   zilc's pass patch still applies. After reviewing, `--mark-reviewed`, and commit
   `tools/upstream/REVIEWED`. The reference clone is `upstream/fil-c/` (gitignored, never built).
6. **Scan the diff for personal information before committing** ([working-rules.md](working-rules.md)
   § Privacy).

### The "workaround" rule (binding on every agent; owner, 2026-10-01)

**Every workaround gets copious WHY notes in [`workarounds.md`](workarounds.md) when it is made**,
whether the cause is an upstream defect or a system limitation: the exact symptom, the class, the
root cause (measured vs. surmised, kept apart), why the fix is correct, what was ruled out, how it
was found, how to recognise a relative, and the cost and exit condition. **A new failure is looked
up in `workarounds.md`'s symptom index and families first.**

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
| [upstream.md](upstream.md) | How zilc tracks Fil-C: pinned release, watched files, the `upstream/fil-c/` monitor, the 0.686 and 0.687 reviews, the upgrade procedure. |
| [licensing.md](licensing.md) | `Apache-2.0 WITH LLVM-exception OR MIT`: why, the runtime-linking rule, the copyleft exclusion. |
| [reference-projects.md](reference-projects.md) | Fil-C, LLVM, Zig: verified licenses, what to mine each for, adoption status. |
| [zig-filc-scope.md](zig-filc-scope.md) | Scope of a Zig version of Fil-C on 0.15.2 (2026-10-05) — the brief zailc started from. |
| [platforms.md](platforms.md) | The P6 scope pass and the cosmo evaluation (closed 2026-10-08) — since 2026-10-27 the record zailc's platform work starts from. |
| [roadmap.md](roadmap.md) | Closed for zilc 2026-10-27: P0–P2 done; P3–P6 moved to zailc (abandoned here), kept as the record. |
| [security-model.md](security-model.md) | The safety guarantees targeted, and what is out of scope. |
| [testing.md](testing.md) | Every gate with its command and dated count; the output comparison; corpus results per mode; planned gates. |
| [known-issues.md](known-issues.md) | The defect log, KI-1…KI-23: root cause, fix, status. |
| [workarounds.md](workarounds.md) | The WHY of every workaround (owner rule): symptom index, failure families. **Look up new failures here first.** |
| [releasing.md](releasing.md) | The version scheme `<Zig>-<Fil-C>.<zilc release>` (DESIGN, workspace P8), where the number lives, the release checklist. |
| [filc-abi.md](filc-abi.md) | Fil-C 0.685's runtime ABI as observed (P3 scoping; P3 moved to zailc 2026-10-27, kept as its record). |
| [zig-upstream-notes.md](zig-upstream-notes.md) | Zig behaviours we may need to report (Z-1…Z-5), each with whether it is really a Zig bug. |
| [ports/](ports/README.md) | Port notes, one file per new Zig line: basis, API changes, sites touched. |
| [history-map-2026-10-27.md](history-map-2026-10-27.md) | The 2026-10-27 history purge (drive paths): what was removed, how it was checked, every old → new commit id. |
| [best-practices.md](best-practices.md) | Method rules: zilc's own (§§ 1–5) and the workspace ★ block copied verbatim (§ 6). |
| `local/` | Gitignored, machine-only facts. Absent in a clone. |

## Related files outside cmem

- `README.md` (public), `third_party/LICENSES.md` (the compliance ledger), `LICENSE-*` / `NOTICE`.
- `tools/README.md`: first-time setup, and how the Bun tools run (inside Linux only).
- `Fil-C.md`, `Zig.md` (owner, 2026-10-27): **the notes on how zilc got from base (stock Fil-C and
  Zig) to pure-Zig parity, for zailc to build on** — the base and its workarounds (KI records),
  then the route piece by piece (recipe, Zig build, oracle, allowed differences, status); upstream
  defects stay in `UPSTREAM-ISSUES.md`. Update them with every Fil-C or Zig move and every track step.
