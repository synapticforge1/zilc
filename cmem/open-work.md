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
| gates | `zig build gate`, `zig build test`, the corpus in four modes, the output comparison: counts and dates in `testing.md` (last full run 2026-10-05, Fil-C 0.686) |
| remote | `origin` = `github.com/synapticforge1/zilc` (since 2026-10-27; was `jrmarcum/zilc`, which GitHub redirects). `origin/main` = `19e7172` = tag `v0.15.2-0.686.1` |
| branches | `main` 10 commits past `origin/main`; **`bun-port`** 1 commit past `main` (the Bun port, `44e0b1a`) plus the 2026-10-27 compliance commit. Nothing pushed since 2026-10-05 |
| sibling | **zailc** (`../zailc`, started 2026-10-08) translates Fil-C into Zig; zilc is its stable reference and test oracle and changes nothing for it (`design-decisions.md`) |

## 🗓️ Owner calls (evidence gathered; nothing done without the owner)

1. **Merge `bun-port` into `main`, and push.** `origin/main`'s INDEX still says Deno (workspace
   letter H26). Merging and pushing are the owner's.
2. **`tools/p1/setup-wsl.sh`** is zilc's one committed shell script, against the workspace rule
   "no committed shell scripts" (letters H15, H26). It INSTALLS Bun in a fresh Ubuntu, so a Bun
   port cannot bootstrap itself. Options: an exception for this one bootstrap, or a Windows-side
   Bun script that drives `wsl.exe` with argument lists (as `tools/lib/tool.ts` `linuxOnly()`
   does). Kept in use until decided.
3. **History purge (letter H19).** Measured 2026-10-27 over every ref (68 commits): **67 carry a
   personal drive path**, all the same one, the wazmrt template path that `INDEX.md:11` held from
   the first commit until 2026-10-27; it is also in the published tag `v0.15.2-0.686.1`'s tree. No
   commit message carries one. Text and binary (`-a`) scans agree. HEAD is clean. A purge
   rewrites the published tag and needs a force-push — the owner's. When done: same-length
   placeholder or relative path, verify 0 hits on every ref, record the old → new map, then
   `gc --prune=now`.
4. **The exFAT `.git` recipe (divergence P7).** zilc's is `maintenance.geometric-repack.enabled=false`
   + `maintenance.gc.enabled=true` (2026-10-01). It answers **KI-23**: the geometric task fails on
   Windows + exFAT twice over — `multi-pack-index write` gets "Permission denied" as a child of
   `repack`, which holds the file memory-mapped, and a rename hits "File exists"
   (`known-issues.md` KI-23). The workspace standard is `maintenance.strategy gc`; the owner picks
   one recipe. Today (2026-10-27): 3 packs, 1.06 MiB, 1 prune-packable.
5. A GitHub Release page for `v0.15.2-0.686.1` (optional; `RELEASE-NOTES.md` is its text).

## Open work

- **Next phase, the owner picks** (2026-09-30): the **`zsys_write` spike** (`roadmap.md` P3) or
  **P4, Zig language fidelity** (`roadmap.md` P4; `@ptrFromInt` is the likely source of surprises).
- **Deferred past the publish** (with the port): `-Druntime=both`, the byte-identity check, the
  benchmark suite (upgrade stage C), the 0.16.0 examples under zilc (`testing.md`).
- **Partly open defects:** KI-7 (`getcontext`) — `known-issues.md`.
- **Cosmo leaves** (`platforms.md` "Cosmo evaluation"): `statx` missing from the cosmo runtime;
  real Windows unverified (never retried on this host — the WSL-only rule); aarch64 Windows, iOS
  and Android outside cosmo (P3 route).
- **Not yet re-run under Bun** (see the Bun port below): build/archive/restore-patched-clang,
  build-cosmo, run-filc-tests, os-surface, size-compare, zilc-check, all-modes,
  check/clone-upstream. Run each once under Bun before relying on it.

## Workspace letters (`../cmem/workspace-correspondence.md`)

| letter | asks zilc | state (2026-10-27) |
| --- | --- | --- |
| H26 | pull line; ★ block; path test; drive paths at HEAD; exFAT recipe; `origin` + stale links; per-repo items | answered in the 2026-10-27 compliance commit: pull line atop `INDEX.md`; ★ block = `best-practices.md` § 6 (28 = 28 text check, inverted); path test in `working-rules.md`; `INDEX.md:11` fixed; recipe recorded (owner call 4); `origin` and the four stale links moved; `tests/basics` BasicsOfCoding links measured still live at `jrmarcum/` (200; 404 at `synapticforge1/`), so they stay; INDEX 45 → under 10 KB. Version scheme is DESIGN (P8), stays. Open: owner calls 1–3 |
| H15 | committed scripts in Bun | tools are Bun since 2026-10-22 (`44e0b1a`); `setup-wsl.sh` is owner call 2 |
| H19 | purge drive paths from history | measured; owner call 3 |
| H22 | record the path test | `working-rules.md` § Privacy |
| H27 | old-folder prose (`upstream.md:127`) | sibling-relative now; `git grep -i` for the old folder name is empty |
| H28 | record-only: maintainer address; wabt-ts/binaryen-ts retired | recorded in `working-rules.md`; zilc carries the address in no tracked file; binaryen-ts is cited only as history |

## The Bun port (2026-10-22, `44e0b1a`): what was verified

Moved verbatim from `INDEX.md` (2026-10-27). **Every tool is Bun** (owner: "Bun only", Deno is
going away). All 38 `.ts` files (37 tools + `lib/tool.ts`) ported from `Deno.*`/`jsr:` to
`node:*` + `Bun.spawn`/`Bun.Glob`/`Bun.YAML`; run `bun tools/<group>/<tool>.ts`. Bun 1.4.3 in WSL
at `~/.bun/bin` (`setup-wsl.sh`, from npm's tarball: no `unzip`/root). Checked against Deno runs:
gate 8/8 identical (also started from Windows through the WSL bridge), run-native identical (632
files; differences only in times, random values, thread order, PIDs, paths), the p1–p3 experiments
same exit codes and reports (byte-identical or differing only in ASLR/PIDs/paths),
patch-pass/patch-split outputs byte-identical, Bun.YAML = @std/yaml on all 14,252 Fil-C manifests.
Not re-run under Bun: the list under "Open work".

## Done — summarized (full text: `git show 44e0b1a:cmem/INDEX.md`)

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
