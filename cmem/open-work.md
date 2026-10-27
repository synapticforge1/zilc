# open-work.md — the state of zilc and what is outstanding

The ONE place for the status line (workspace `memory-conventions.md`: "the status narrative exists
once"). Only open items live here; each points at its record. Completed work is summarized at the
end with a pointer to where the full text lives. Counts are not copied here: `testing.md` holds
them, with their dates.

## State (2026-10-27)

| what | value |
| --- | --- |
| version | **`0.15.2-0.686.1`** — `<Zig>-<Fil-C>.<zilc release>`, published 2026-10-05 (`releasing.md`); one of the five places the number lives |
| toolchain | Zig **0.15.2** (user code and build), Fil-C **0.686** with zilc's patched clang (`workarounds.md` KI-22, KI-4) |
| gates | `zig build gate`, `zig build test`, the corpus in four modes, the output comparison: counts and dates in `testing.md` (gate + tests last run 2026-10-27 in WSL; the corpus 2026-10-05, Fil-C 0.686) |
| remote | `origin` = `github.com/synapticforge1/zilc` (since 2026-10-27; was `jrmarcum/zilc`, which GitHub redirects). **Purged history pushed 2026-10-27**: `main` = `origin/main`, `v0.15.2` = tag `v0.15.2-0.686.1` = `13ce96a` (was `19e7172`; map `history-map-2026-10-27.md`) |
| branches | `main` carries the Bun port (`c2841dd`, was `44e0b1a`), merged `--no-ff` 2026-10-27 (owner: "we will merge all to bun tooling since deno is going away"), and the 2026-10-27 work since; `bun-port` (merged, never pushed) deleted 2026-10-27 (owner). Branches: `main`, `v0.15.2` |
| sibling | **zailc** (`../zailc`, started 2026-10-08) translates Fil-C into Zig; zilc is its stable reference and test oracle and changes nothing for it (`design-decisions.md`) |

## 🗓️ Owner calls (evidence gathered; nothing done without the owner)

1. ✅ **Purged history force-pushed 2026-10-27** (owner: "perform the open items"): `main`
   `19e7172` → `2c7faf0`, `v0.15.2` `19e7172` → `13ce96a`, tag `v0.15.2-0.686.1` `fda2d43` →
   `7dbddf8`, each `--force-with-lease` on its old value; `ls-remote` = local. zilc has no CI
   workflow, so the tag move re-ran nothing. A fresh mirror clone from GitHub (80 commits, 959
   blobs, every ref, `grep -a`): no personal path; the only candidates are the privacy rule's own
   placeholder line in 5 versions of `working-rules.md`; no commit message. Locally: reflogs
   expired, `gc --prune=now` → 1 pack / 840 KiB, `fsck` clean, the old commit and tag objects gone.
   zailc told (ledger C22, H19). The pre-purge bundle was deleted the same day (owner: "delete the
   pre-purge backup also"); no copy of the old history is left on this machine. **Left for the
   owner:** a GitHub Support request if old commits served by hash must go too (GitHub keeps them
   until its own GC).
2. ✅ **`setup-wsl.sh` → Bun, done 2026-10-27** (owner: "perform the open items"). Bun cannot
   install itself and runs inside Linux only, so the Bun install is a **documented one-time step**
   (`tools/README.md` "First-time setup", the same npm-tarball commands and SHA) and the rest is
   **`tools/p1/setup-wsl.ts`**. **Proved** on a fresh WSL home at one fixed path (so Fil-C's
   `setup.sh` writes the same absolute paths): (a) fresh install — `.sh` vs the Bun step + `.ts`:
   22,159 entries identical by type, size, mode and SHA-256; the `.ts` home has 5 more, Bun's own
   transpiler cache (`~/.bun/install/cache/@t@/*.pile`, written whenever Bun runs a `.ts`); output
   identical but step 4 (`sha256 OK` → `already installed`, the declared difference); (b) a second
   run on the installed tree: output identical; (c) must-fail, a corrupt Zig download: identical
   `SHA MISMATCH` line, exit 1 both. Then `setup-wsl.sh` was deleted; zilc commits no shell script.
3. ✅ **Windows-side tool path retired in code, done 2026-10-27** (`bac5a85`): `tools/lib/tool.ts`
   refuses any platform but Linux at import (exit 2, with the WSL command); `linuxOnly()` only
   asserts; the five tools that did not import it now do; `compile-check.ts` has no Windows Zig
   default. **Checked:** gate before/after in WSL identical line for line (8/8), tests 29/29,
   capi-smoke and baseline exit 0, `check-toolchain` identical; the five tools reach their own
   usage; `compile-check` 78/78 C + 78/78 Zig; inverted from Windows' Bun: `run-gate`,
   `patch-pass`, `compile-check`, `check-upstream`, `llreduce` all exit 2 with the refusal, nothing
   built. Building zilc with Windows' Zig retired too (INDEX item 3, `testing.md`, `overview.md`,
   README).
4. ✅ **The exFAT `.git` recipe (divergence P7): switched to the workspace standard 2026-10-27**,
   `maintenance.strategy gc` (the two task keys unset). Measured the same day (git 2.54, traced
   `maintenance run`): the old recipe (`geometric-repack.enabled=false` + `gc.enabled=true`, for
   KI-23) ran the SAME `gc` plus one more task, `commit-graph write --split`; the stock default
   runs `repack --geometric=2 --write-midx` + `multi-pack-index write`, the KI-23 failure.
5. A GitHub Release page for `v0.15.2-0.686.1` (optional; `RELEASE-NOTES.md` is its text; needs
   `gh` or the web UI — the owner's).

## Open work

- 🔴 **Fil-C 0.687 is released (2026-10-23) — zilc's role, item 1** (found 2026-10-27 by the
  memory update's upstream check, `upstream.md` "Run of 2026-10-27"). Same LLVM 20.1.8, so Zig
  stays 0.15.2; the release would be `0.15.2-0.687.1`. zilc's patches still apply. To do, as for
  0.686 (`upstream.md` "Review of Fil-C 0.686" is the template): review the 7 pass commits — two are
  ABI changes (`f565a56` callee roots the arguments, `43d345a` setjmp) — and re-check KI-4 / KI-18
  against the stock 0.687; install the prebuilt (record its SHA-256 in `setup-wsl.ts`); move
  `tools/lib/tool.ts` `FILC_VERSION`/`FILC_SHA` and `src/root.zig`'s `filc_release`; rebuild the
  patched clang; Fil-C's suite stock vs patched at 0 differences; the gate, tests, corpus in four
  modes and the output comparison; re-archive; the five version places; `--mark-reviewed`. Needs
  the owner's go-ahead to release (and to push).
- **The pure-Zig track (owner, 2026-10-27), after the 0.687 move:** bring zailc's step-2 build
  into zilc (`roadmap.md` Z1) — read from `../zailc` (`src/gen`, `src/runtime`, `tests/link`,
  `tools/gen`, `tools/runtime`, its `build.zig` steps `gen` / `libpas` / `yolomusl` /
  `compiler-rt`, its `oracle.md`), keep only what is faithful to Fil-C (zailc's departures W-n stay
  there), re-verify against 0.687, and run `zig build gate-zig-modules` on the result; then the
  rest of Z1, then Z2 (the pass in Zig). Licence: the ported pieces carry Fil-C's notices; ledger
  entries in `third_party/LICENSES.md` before the first file lands.
- ~~Next phase (P3 or P4)~~ — **P3, P4 and P5 moved to zailc and are abandoned here**
  (owner, 2026-10-27; `design-decisions.md` top row). zilc's work is its four-part role: track
  Fil-C, follow the matching Zig, keep Zig and C correct on x86_64 Linux, be zailc's reference.
- **Still zilc's, for the next Zig move** (upgrade procedure, `upstream.md`): the benchmark suite
  (stage C) and the 0.16.0 examples under zilc (`testing.md`). Abandoned with P3:
  `-Druntime=both`, the byte-identity check.
- ✅ **Code left from P3, removed 2026-10-27** (`5dc54c5`): `--runtime zig` is no longer a value
  (`--runtime filc` still accepted); the refusal test replaced by one pinning the values, inverted
  (with `zig` put back: exactly that test fails, 28/29); tests 29/29.
- **Partly open defects:** KI-7 (`getcontext`) — `known-issues.md`.
- ~~Cosmo leaves~~ — **not zilc work since 2026-10-27** (owner: zilc stays Fil-C on Linux x86_64 only;
  cross-platform is zailc's). The open points (`statx` missing from the cosmo runtime, real Windows
  unverified, aarch64 Windows / iOS / Android) are in `platforms.md` for zailc.
- **Not yet re-run under Bun** (see the Bun port below): build/archive/restore-patched-clang,
  build-cosmo, run-filc-tests (2026-10-27: only its usage line), os-surface, size-compare,
  zilc-check, all-modes, check/clone-upstream. Run each once under Bun before relying on it.
  (`compile-check` and `check-toolchain` ran fully on 2026-10-27.)

## Workspace letters (`../cmem/workspace-correspondence.md`)

| letter | asks zilc | state (2026-10-27) |
| --- | --- | --- |
| H26 | pull line; ★ block; path test; drive paths at HEAD; exFAT recipe; `origin` + stale links; per-repo items | answered in the 2026-10-27 compliance commit: pull line atop `INDEX.md`; ★ block = `best-practices.md` § 6 (28 = 28 text check, inverted); path test in `working-rules.md`; `INDEX.md:11` fixed; recipe recorded (owner call 4); `origin` and the four stale links moved; `tests/basics` BasicsOfCoding links measured still live at `jrmarcum/` (200; 404 at `synapticforge1/`), so they stay; INDEX 45 → under 10 KB. Version scheme is DESIGN (P8), stays. Open: owner calls 1–3 |
| H15 | committed scripts in Bun | ✅ done 2026-10-27: tools Bun since 2026-10-22 (`c2841dd`); `setup-wsl.sh` → documented Bun step + `setup-wsl.ts`, proved (owner call 2); `git ls-files '*.sh' '*.ps1' '*.bat' '*.py' '*.nu'` empty |
| H19 | purge drive paths from history | ✅ **purged and force-pushed 2026-10-27** (`history-map-2026-10-27.md`; owner call 1); a fresh GitHub clone scans clean |
| H22 | record the path test | `working-rules.md` § Privacy |
| H27 | old-folder prose (`upstream.md:127`) | sibling-relative now; `git grep -i` for the old folder name is empty |
| H28 | record-only: maintainer address; wabt-ts/binaryen-ts retired | recorded in `working-rules.md`; zilc carries the address in no tracked file; binaryen-ts is cited only as history |

## The Bun port (2026-10-22, `c2841dd`, was `44e0b1a`): what was verified

Moved verbatim from `INDEX.md` (2026-10-27). **Every tool is Bun** (owner: "Bun only", Deno is
going away). All 38 `.ts` files (37 tools + `lib/tool.ts`) ported from `Deno.*`/`jsr:` to
`node:*` + `Bun.spawn`/`Bun.Glob`/`Bun.YAML`; run `bun tools/<group>/<tool>.ts`. Bun 1.4.3 in WSL
at `~/.bun/bin` (then `setup-wsl.sh`; since 2026-10-27 the documented step in `tools/README.md`; from npm's tarball: no `unzip`/root). Checked against Deno runs:
gate 8/8 identical (also started from Windows through the WSL bridge), run-native identical (632
files; differences only in times, random values, thread order, PIDs, paths), the p1–p3 experiments
same exit codes and reports (byte-identical or differing only in ASLR/PIDs/paths),
patch-pass/patch-split outputs byte-identical, Bun.YAML = @std/yaml on all 14,252 Fil-C manifests.
Not re-run under Bun: the list under "Open work".

## Done — summarized (full text: `git show c2841dd:cmem/INDEX.md`)

The INDEX carried a dated log from 2026-09-18 to 2026-10-22 until 2026-10-27. Each milestone's
substance lives in the topic file named.

- **2026-09-18 → 09-23: P0–P2 complete (`0.3.0`).** One command compiles Zig and C into a binary
  whose memory-safety violations trap at a named source line, with no Zig fork and no LLVM build:
  stock Zig emits IR, zilc rewrites two `target datalayout` lines into Fil-C's dialect
  (`src/ir.zig`, KI-4), Fil-C's clang runs the pass and links (`architecture.md`, `roadmap.md`).
  Two wrong conclusions published that day and overturned are kept in `roadmap.md` P1 step 3 and
  KI-5.
- **2026-09-30:** Zig runtime plan (Linux first, checked against Fil-C; `--runtime filc|zig`, `zig`
  refused); the runtime contract measured (`architecture.md`); Fil-C's ABI observed (`filc-abi.md`);
  the unoptimized-IR pipeline (KI-17); the std overlay (`src/stdpatch.zig`, KI-11); the
  `tests/basics` corpus (`testing.md`); version scheme, lines and basis (`releasing.md`); the
  fidelity-first goal (`design-decisions.md`).
- **2026-10-01:** KI-18, KI-20, KI-21, KI-19, KI-4 fixed; the patched Fil-C clang (KI-22 option 2)
  is the default and is archived in `toolchain/` (gitignored); `workarounds.md` and
  `UPSTREAM-ISSUES.md` created; the `upstream/fil-c/` reference clone and its monitor
  (`upstream.md`); LF everywhere (`.gitattributes`; the owner also set global
  `core.autocrlf=input`, `core.eol=lf` across all projects); KI-23 closed.
- **2026-10-02:** build-speed levers (a) parallel code generation, (b) dense interference graph,
  (c) object cache + `--clean-cache` (`workarounds.md` KI-22); output comparison vs native, 0
  unexplained (`testing.md`); library mode; KI-5 (`std.os.environ`).
- **2026-10-05:** `zilc --version` + `RELEASE-NOTES.md`; Fil-C's own test suite against the
  patched clang (`testing.md`); every tool Deno (`design-decisions.md`); move to Fil-C 0.686 and
  its review (`upstream.md`); version `0.15.2-0.686.1`; platforms scope pass (`platforms.md`);
  Zig version of Fil-C scoped (`zig-filc-scope.md`); **published** (`releasing.md`).
- **2026-10-08:** cosmo evaluation closed (`platforms.md`); the WSL-only rule (`workarounds.md`);
  zailc started (`design-decisions.md`).
- **2026-10-22:** every tool Bun (above; `design-decisions.md`).
- **2026-10-27:** workspace-floor compliance (letters above; `working-rules.md`).
