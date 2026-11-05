# open-work.md — the state of zilc and what is outstanding

The ONE place for the status line (workspace `memory-conventions.md`: "the status narrative exists
once"). Only open items live here; each points at its record. Completed work is summarized at the
end with a pointer to where the full text lives. Counts are not copied here: `testing.md` holds
them, with their dates.

## State (2026-10-30)

| what | value |
| --- | --- |
| version | **`0.15.2-0.687.1`** — `<Zig>-<Fil-C>.<zilc release>`, **published 2026-10-27** (tag `v0.15.2-0.687.1` on `be51808`; `releasing.md`); one of the five places the number lives. Before it: `0.15.2-0.686.1` (2026-10-05) |
| toolchain | Zig **0.15.2** (user code and build), Fil-C **0.687** with zilc's patched clang (`workarounds.md` KI-22, KI-4) — **since 2026-10-30 compiled by Zig** (`zig build patched-clang`; the GCC-built one kept as `~/zilc-work/tools/filc-0.687-zilc-gcc` for rollback); 0.686's kept installed and archived (`toolchain/filc-0.686/`) |
| unpushed | `main` is 5 commits ahead of `origin/main` (2026-10-30: `91e7959`, `5e31ef8`, `31a911a`, `896d1a7`; 2026-11-04: `e46fc05`, the GCC-free chain and `compare-chains.ts`) plus UNCOMMITTED work from the rest of 2026-11-04 (NEXT SESSION B); nothing pushed (owner's call) |
| gates | `zig build gate`, `zig build test`, Fil-C's suite, the corpus in four modes, the output comparison: all re-run 2026-10-27 on Fil-C 0.687, counts in `testing.md` |
| remote | `origin` = `github.com/synapticforge1/zilc` (since 2026-10-27; was `jrmarcum/zilc`, which GitHub redirects). **Purged history pushed 2026-10-27**: `main` = `origin/main`, `v0.15.2` = tag `v0.15.2-0.686.1` = `13ce96a` (was `19e7172`; map `history-map-2026-10-27.md`) |
| branches | `main` carries the Bun port (`c2841dd`, was `44e0b1a`), merged `--no-ff` 2026-10-27 (owner: "we will merge all to bun tooling since deno is going away"), and the 2026-10-27 work since; `bun-port` (merged, never pushed) deleted 2026-10-27 (owner). Branches: `main`, `v0.15.2` |
| sibling | **zailc** (`../zailc`, started 2026-10-08) translates Fil-C into Zig; zilc is its stable reference and test oracle and changes nothing for it (`design-decisions.md`) |

## ▶️ NEXT SESSION — pick up here (paused 2026-11-04 by the owner)

**Start with these, in order** (the numbered list below keeps the history):

A. ✅ **Re-proof read 2026-11-05** (owner: "proceed with item A"): it had completed on 2026-11-04
   16:11, before the pause. The zig chain rebuilt WITH the CET and archive-name fixes (confirmed in
   the tested tree: archive member lists = the release's, `endbr64` = the release's) is still
   **14/14** against the GCC chain: suite 0 differences vs stock and vs the GCC chain, gate 8/8
   both line for line, corpus verdicts identical in all four modes, output comparison 0
   unexplained both (one allowed thread-order flip, `36_worker-pools`). `~/zilc-work/equiv-tool/verdicts.txt`.
B. **Commit the uncommitted work** (owner's word first): item 5's `zig build gcc-reference`
   (`build/gcc_reference.zig`, `tools/gcc-reference.zig`, `tools/gcc-host-shim.zig`, the 5 lazy deps
   in `build.zig.zon`, `filc_source.named()`), `third_party/gcc-patches/` (GCC's own PR 111632
   backports + README), the two parity fixes (`tools/archive-rename.zig`, CET in
   `build/pure_zig.zig`, `verify-libpas.ts`), the hardening fix (`build/pure_zig.zig`,
   `verify-compiler-rt.ts`), `compare-chains.ts`'s all-or-nothing REUSE, `cmem/toolchain-quirks.md` (new, in INDEX), and the
   record updates (testing, workarounds W-14, best-practices, LICENSES, README, this file). Run
   `zig build test`, the gate and the path scan first.
C. **Finish item 5**: both pinned GCCs are BUILT by Zig (`~/zilc-work/tools/gcc-11.4.0`, 174 MB;
   `gcc-12.3.0`; ~5 min each once staged; smoke-tested 11.4.0: C and C++ run, PIE and SSP on).
   Remaining: (1) give them Ubuntu's other compile defaults through a GCC `specs` file in each
   install (`-fcf-protection`, `-fstack-clash-protection`, `-D_FORTIFY_SOURCE=2` when optimizing;
   GCC reads `<libdir>/gcc/x86_64-linux-gnu/<v>/specs` by itself) — written by
   `tools/gcc-reference.zig` after `make install-strip`, then checked (endbr64, `__fprintf_chk`);
   (2) point `build-filc-from-source.ts MODE=upstream` at them per step as the release's
   `.comment`s say (compiler-rt + projeny: 11.4.0; yolo musl: 12.3.0; libpas/yolounwind stay the
   host clang — the release used Ubuntu clang 14, not built here); (3) rebuild the GCC chain and
   rerun `compare-chains.ts` — expected: the GCC chain's `libyolort.a` now equals the release's.
D. **Owner calls waiting:** item 8 (link with GNU ld for relocation parity, W-14 family) and the
   optional cosmetic items listed in item 9.

(Older: paused 2026-10-30; items 1–4 done 2026-11-04.)

In order. The owner's conditions, verbatim: libpas finished and *"make sure that the entire
compilation no longer needs gcc at all"*; *"before we fully remove the gcc, we should make sure that
the resulting compilations are functionally the same from gcc or the zig only compilation chain"*;
GCC then stays **maintainer-only** (*"Yes maintainer only. User no."*); *"document all of this for
future reference"*.

1. ✅ **The chains are FUNCTIONALLY THE SAME, read 2026-11-04** (owner: "finish item 1"): the
   2026-10-30 run had completed; suite 0 differences (zig vs stock, zig vs GCC chain), gate 8/8
   both line for line, corpus verdicts identical chain against chain in all four modes (PID
   masked), output-comparison reports identical; the `libpizlo.so` gap explained by symbol name
   (`testing.md` "THE ZIG-ONLY CHAIN").
2. ✅ **`tools/filc/compare-chains.ts`, written 2026-11-04** (owner: "then perform Item 2"): the
   five parts with pass criteria (exports = release, no `GCC:` in the zig chain; every differing
   relocation names a symbol defined in that library or a weak undefined; suite; gate; corpus and
   output comparison). From scratch: **14/14 PASS**; inverted twice (exports, corpus), exit 1
   both (`testing.md`). `REUSE=1` re-analyses existing results without rebuilding.
3. ✅ **Committed 2026-11-04** (owner: "proceed with Item 3 and Item 4"; tests 40/40, gate 8/8,
   path scan clean). Was: `build/pure_zig.zig` (libpas whole, W-12),
   `tools/filc/build-filc-from-source.ts` (MODE=zig / MODE=upstream), and the memory updates
   (design-decisions top row, testing, workarounds W-12/W-13, Fil-C.md, LICENSES, releasing,
   best-practices, this file), and `tools/filc/compare-chains.ts` with its README row. `zig build test` passed on it at the pause (40/40, check-pins
   11/11); run the gate too before committing; scan for paths.
4. ✅ **Deleted 2026-11-04** (owner): the GCC build directory of the clang,
   `~/zilc-work/patched-clang/filc-0.687/build-system` — measured **32 GB** (the 25 GB was an
   estimate), its `clang-20` `.comment` = GCC 15.2; `patched-clang/` 44 → 12 GB (`build-zig` 9.8 GB
   and the staged `src` stay). Kept: the system GCC (maintainer QC) and
   `~/zilc-work/tools/filc-0.687-zilc-gcc`. `-Dclang-cc=system` would rebuild it from scratch
   (~25 min).
5. **Maintainer-only: GCC pinned to upstream's versions (11.4, 12.3), built by Zig** — measure
   build time and size first; then point `MODE=upstream` at it (item under "Open work" below).
6. ✅ **Documentation, done 2026-11-04** (owner: "proceed with 5, 6, and 7"): README "Building
   Fil-C's side from a clone" gains the from-source note (no compiler needed; GCC maintainer-only);
   `tools/README.md` and `Fil-C.md` § 4 done earlier the same day.
7. ✅ **Housekeeping, done 2026-11-04**: removed `~/zilc-work/pz-libpas`, `path-no-compilers`,
   `equiv` (superseded by `equiv-tool`, compare-chains' run), two stray logs, and the suite's
   per-test outputs of three one-off proofs (`test-output-from-source`, `-zigbuild`, `-zigcc`,
   1.8 GB each; their `results-*.json` kept). Kept: the two from-source trees (compare-chains'
   inputs), `equiv-tool`, and the suite outputs for stock, patched and both chains.

8. 🗓️ **Owner call: relocation parity for `libpizlo.so` (W-14), scoped 2026-11-04** (owner: "review
   and test the issue … and scope the fix for it to bring it into parity").
   - **Cause (measured):** the LINKER only. Zig's LLD has no `.plt.got`; GNU ld does. Same objects:
     GNU ld 2,134, LLD 2,139. The objects of both chains are equivalent: the zig chain's objects
     linked by GNU ld are IDENTICAL to the GCC chain's library by (type, name) relocations,
     exports, dynamic tags and segment kinds.
   - **Fix:** link zilc's shared objects with GNU ld (`ld`, binutils) instead of `zig ld.lld`, same
     flags: `build/pure_zig.zig`'s four `libpizlo.so` links (and, optionally, `libyoloc.so`, which
     would also lose its LLD-only `PHDR` segment, W-11 part 3; its `GNU_PROPERTY` difference stays,
     as it comes from GCC's object notes). Suggested shape: `-Dpizlo-linker=gnu|lld`, ~20 lines.
   - **Cost:** no new tool for users — Fil-C's clang already links every program with `/usr/bin/ld`
     (binutils), so binutils is a prerequisite today. It is a step away from "Zig links everything"
     for these libraries.
   - **Proof after the change:** `verify-libpas` / `verify-yolomusl`, `compare-chains.ts` (relocs
     part must show 0 differing names), Fil-C's suite, the gate.
   - **Or keep LLD:** functionally the same (every name resolves to the same definition; suite,
     gate and corpus agree), recorded as W-14.

9. **Parity items found by the 2026-11-04 inventory** (`testing.md` "Parity inventory"); owner:
   "fix the two new items and document the rest if not fixable, or review and scope fixable items".
   - ✅ **Archive member names** (Z-b-8): fixed, `tools/archive-rename.zig`.
   - ✅ **CET** (C-7): fixed, `-fcf-protection` on the GCC-built pieces. The GNU_PROPERTY
     allowance in `verify-yolomusl.ts` STAYS: the remaining note is GNU `as`'s (C-9).
   - ✅ **Ubuntu GCC's other hardening defaults — FIXED 2026-11-05** (owner: "yes"; `testing.md` 3b,
     toolchain-quirks C-7b, C-10–C-12; functional re-proof 2026-11-05: `compare-chains.ts`
     14/14, corpus after a same-sitting rerun, see `testing.md` 3b). Was scoped as
     (C-7b; found 2026-11-05, owner asked again "are
     there any other items that are not in parity"): add to the GCC-built pieces in
     `build/pure_zig.zig`, beside `ubuntu_gcc_cet` — compiler-rt builtins
     `-fstack-protector-strong -fstack-clash-protection -D_FORTIFY_SOURCE=2`; crtbegin/crtend the
     first two (`-O0`: Ubuntu applies fortify only when optimizing); yolo musl
     `-fstack-clash-protection` (its stack-protector use already equals the release's). Check:
     the counts in `testing.md` 3b equal the release's, the three `verify-*` oracles, then
     `compare-chains.ts`. W-8's allowance for `__stack_chk_fail` / `__fprintf_chk` in
     `verify-compiler-rt.ts` then goes. Unmeasured: whether Zig's glibc headers honour
     `_FORTIFY_SOURCE` (test first).
   - **Reviewed, FIXABLE, scoped:**
     - the linker family (W-14 `JUMP_SLOT`s, L-7 `__environ`, L-8 `.plt.got` / `.relro_padding`,
       W-11 `PHDR`): link with GNU ld — item 8, owner call;
     - Ubuntu GCC's other defaults for the pinned VANILLA GCC (item 5): MODE=upstream must pass
       `-fcf-protection -fstack-clash-protection` and `-D_FORTIFY_SOURCE=2` at `-O` (PIE and SSP
       are configured) — part of pointing MODE=upstream at the pinned GCC;
     - optional, cosmetic: `-fno-addrsig` on the GCC-built pieces would remove clang's
       `.llvm_addrsig` sections (only `--icf` reads them); `-gdwarf-aranges` would add GCC's
       `.debug_aranges`. Debug/section level only, no code change — not recommended unless byte
       parity of sections is wanted;
     - host binutils version (L-9): only by building binutils 2.38 as a pinned maintainer tool, as
       for GCC; it affects both chains equally, so it does not bear on Zig vs GCC.
   - **Reviewed, NOT fixable here, documented:** GNU `as`'s ISA-used notes (C-9: clang's assembler
     has none); compiler families W-4, W-8, C-8 (inlining) — inherent to compiling with a different
     compiler, which is what the maintainer's GCC chain exists to measure; Fil-C's clang
     nondeterminism (F-1, upstream's; zilc records, does not file); the release's install-time
     `RUNPATH` (Fil-C's `setup.sh`, not the build).

## 🗓️ Owner calls (evidence gathered; nothing done without the owner)

0. ✅ **Released `0.15.2-0.687.1`, 2026-10-27** (owner: "release"): tag, branch `v0.15.2` and
   `main` at `be51808`, pushed and read back (`releasing.md`). A GitHub Release page stays
   optional (call 5).

1. ✅ **Purged history force-pushed 2026-10-27** (owner: "perform the open items"): `main`
   `19e7172` → `2c7faf0`, `v0.15.2` `19e7172` → `13ce96a`, tag `v0.15.2-0.686.1` `fda2d43` →
   `7dbddf8`, each `--force-with-lease` on its old value; `ls-remote` = local. zilc has no CI
   workflow, so the tag move re-ran nothing. A fresh mirror clone from GitHub (80 commits, 959
   blobs, every ref, `grep -a`): no personal path; the only candidates are the privacy rule's own
   placeholder line in 5 versions of `working-rules.md`; no commit message. Locally: reflogs
   expired, `gc --prune=now` → 1 pack / 840 KiB, `fsck` clean, the old commit and tag objects gone.
   zailc told (ledger C22, H19). The pre-purge bundle was deleted the same day (owner: "delete the
   pre-purge backup also"); no copy of the old history is left on this machine. **Owner,
   2026-10-27: the old commits must stop being served by hash too** — measured the same day: still
   served (`19e7172`, `780625c64` resolve through the API; 0 forks, 0 pull requests ever). The
   GitHub Support request (gc + purge cached views; first changed commit `780625c64`) is drafted
   in the gitignored `cmem/local/github-support-purge.md`; the owner submits it at
   support.github.com. Re-check after: both hashes must 404.
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
5. ✅ **No GitHub Release object, closed 2026-10-27** (owner: the tag's page "is enough for what I
   need it for"). A pushed tag already gets `…/releases/tag/<tag>` (200: the annotation, the
   commit, source archives); a Release object would add only notes and the sidebar entry (API:
   0 releases). Release notes stay in `RELEASE-NOTES.md` and the tag annotation.

## Open work

- ✅ **Moved to Fil-C 0.687, 2026-10-27** (owner: "run through the check list now"): reviewed
  (`upstream.md` "Review of Fil-C 0.687"; 4 pass commits in the release — `f565a56` and `7d4ed7b`
  came after the tag and wait for the next review), KI-4 / KI-18 still upstream, prebuilt SHA-256
  recorded, constants moved (`b33b6eb`), patched clang rebuilt, Fil-C's suite 0 differences on
  7,269, gate 8/8, tests 29/29, corpus 78/78 as designed ×4 modes, output comparison 0
  unexplained, re-archived, marked reviewed at `e7947f0`. **Release = owner call 0.**
- ✅ **`gate-zig-modules` on 0.687**: runs on zilc's own 0.687 pure-Zig modules since 2026-10-27
  (`testing.md`).
- ✅ **Clone-then-build, done 2026-10-30** (owner: *"proceed with the implimentation"*; *"Leave
  the download of Fil-C and LLVM as is, no distributable in our repo"*; `design-decisions.md` top
  row). A clone, with Zig, cmake, ninja and the kernel headers installed, builds both sides:
  `zig build pure-zig` (no options; libpas, yolo musl, compiler-rt pass the release oracle) and
  `zig build patched-clang` (**compiled by Zig alone**, 5a: Fil-C's suite 0 differences on 7,269
  against stock, gate 8/8). Fil-C's sources: the lazy `filc` dependency, fetched only when a step
  that reads them is named; measured 2.2 GB download, 11 GB unpacked. Proved equal to the commit as
  checked out (`tools/upstream/verify-filc-package.ts`); every Fil-C reference is checked by
  `zig build check-pins` (owner: *"all of these references should be updated each time Fil-C
  updates"*). Numbers and method: `testing.md`; lessons: `best-practices.md` § 5.
  **Still open from it:**
  - ✅ **Zig fetches cmake and ninja on the user's opt-in, done 2026-10-30** (owner: "yes, with a
    user opt-in"): `-Dfetch-build-tools`; lazy deps `cmake` (Kitware 4.2.3, 58 MB, SHA-256 =
    Kitware's published file) and `ninja` (1.13.1, = GitHub's asset digest), requested only when
    `patched-clang` is named. Both come out executable (Zig's ELF rule) and run. Tested with a
    PATH holding every system program but cmake and ninja: without the option the build stops
    naming it; with it, a full rebuild (2,991 steps, 20 min) gives a **byte-identical
    clang-20**. LLVM's CMake also takes the host's Python 3 (README lists it).
  - ✅ **Fil-C compiles with the Zig-built clang, verified 2026-10-30** (owner):
    `tools/filc/build-filc-from-source.ts` runs upstream's own build steps with it; the toolchain
    that results, built entirely from source, passes Fil-C's suite with 0 differences on 7,269
    (`testing.md`). This is upstream's route (its scripts, the host's cc for the stock pieces);
    zilc's own pure-Zig route for the Fil-C-compiled pieces is still Z1 item 3.
  - 🛠️ **Maintainer-only: GCC pinned to upstream's versions, built by Zig** (owner, 2026-10-30;
    `design-decisions.md` top row). A `zig build` step like `patched-clang`: hash-pinned GCC
    11.4 and 12.3 sources plus GMP/MPFR/MPC, `--disable-bootstrap --disable-multilib
    --enable-languages=c,c++`, compiled by `zig cc`/`zig c++` (GNU `as` from binutils still
    needed; libgcc/libstdc++ are compiled by the new GCC, as always). Then
    `build-filc-from-source.ts MODE=upstream` uses them instead of Ubuntu's GCC 15. Measure
    first: build time and installed size per version (estimate 0.3–0.5 GB each). Upstream's
    libpas stock half was compiled by Ubuntu clang 14; mirroring that too would be one more LLVM
    build — decide after the GCC half.
  - **5b. Fil-C's prebuilt becomes optional**: the from-source tree above shows it CAN be replaced
    (every library but GCC-built `libyolort.a` exports the release's symbols). Still needed today
    for the Fil-C-compiled runtime pieces in zilc's own build (Z1 item 3), as the tree the patched clang is installed into (`patched-clang` installs only
    `clang-20` and `llvm-split`; assembling the toolchain tree is still `build-patched-clang.ts`'s
    copy-and-replace, done by hand for the 2026-10-30 proofs), and as the oracle.
  - ✅ **zilc's installed patched toolchain is the Zig-built clang since 2026-10-30** (owner: "yes"):
    `~/zilc-work/tools/filc-0.687-zilc` (the GCC build kept beside it as `filc-0.687-zilc-gcc` for
    rollback), gate 8/8, re-archived in `toolchain/` (SHA256SUMS now names the compiler).
    `check-toolchain` compares `git diff --full-index` (short blob ids grew 9 → 10 characters
    after 18 blobs were fetched into the clone; the patch file was regenerated with full ids,
    content unchanged). Rebuilt from the re-applied patch: clang-20 and llvm-split
    **byte-identical** — Zig's build of the clang is reproducible.
  - ✅ Branch `wip/reference-duplicate` (`04aa53d`) deleted 2026-10-30 (owner); its proof code lives
    on, corrected, in `verify-filc-package.ts`.
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
- ~~Next phase (P3 or P4)~~ — **P3, P4 and P5 moved to zailc and are abandoned here**
  (owner, 2026-10-27; `design-decisions.md` top row). zilc's work is its four-part role: track
  Fil-C, follow the matching Zig, keep Zig and C correct on x86_64 Linux, be zailc's reference.
- 🔒 **zilc stays on the compatible Zig, always** (owner, 2026-10-27; `design-decisions.md` top
  row): no newer-Zig line, so the 0.16.0 examples under zilc and stage B are not zilc's;
  recommendations for a 0.17.0+ upgrade only (`upstream.md`). Still zilc's: the benchmark suite,
  for comparing one reference release with the next (stage C's first column). Abandoned with P3:
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
  clone-upstream. Run each once under Bun before relying on it.
  (`compile-check`, `check-toolchain` and `check-upstream` ran fully on 2026-10-27; so did `all-modes`, which runs
  `zilc-check` for every mode, and `compare-output`, against the swapped toolchain, `testing.md`.)

## Workspace letters (`../cmem/workspace-correspondence.md`)

| letter | asks zilc | state (2026-10-27) |
| --- | --- | --- |
| H26 | pull line; ★ block; path test; drive paths at HEAD; exFAT recipe; `origin` + stale links; per-repo items | answered in the 2026-10-27 compliance commit: pull line atop `INDEX.md`; ★ block = `best-practices.md` § 6 (28 = 28 text check, inverted); path test in `working-rules.md`; `INDEX.md:11` fixed; recipe recorded (owner call 4); `origin` and the four stale links moved; `tests/basics` BasicsOfCoding links measured still live at `jrmarcum/` (200; 404 at `synapticforge1/`), so they stay; INDEX 45 → under 10 KB. Version scheme is DESIGN (P8), stays. Owner calls 1–3 done 2026-10-27 (above) |
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
