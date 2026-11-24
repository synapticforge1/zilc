# Design Decisions & Invariants

Decisions from 2026-10-22 on, and the invariants. Split on 2026-11-23 (letter H38 step 5): the
decisions of 2026-09-18 to 2026-10-05 in [design-decisions-early.md](design-decisions-early.md);
the questions for the owner in [open-questions.md](open-questions.md); the Zig 0.15.2 API notes in
`toolchain-quirks.md`; the Windows build gotchas in `workarounds-machine.md`.

## Decisions made

- **2026-11-24** — 🔒 **THE BASICS CORPUS TAKES THE OWNER'S CURRENT C, C++ AND ZIG LESSONS; ZILC LINKS
  C++** (owner: "Please add … BasicsOfCodingC / Cpp / Zig", then three answers). (1) `tests/basics/c`
  and `zig-0.15.2` are replaced by the repositories' current heads (12 C and 13 Zig lessons renamed
  since 2026-09-30); `zig-0.16.0` is dropped (zilc stays on 0.15.2; the repo now targets 0.17.1);
  a `cpp/` set is added (78 lessons, C++23); the reference results are re-derived once.
  (2) The driver links with Fil-C's `clang++` when any input is C++ (today it links with `clang`
  and no C++ program links: R2-B3), and gains a `-std=<std>` option passed to C and C++ compiles;
  the default stays the compiler's. (3) Done AFTER review 2's fixes (`STATE.md` § Next item 4).
- **2026-11-24** — 🔒 **FIL-C COMPONENTS MOVE ONLY WITH A FIL-C RELEASE** (owner: "until a new
  release is released do not update the associated components"). The patched clang, the runtime
  pieces and the sarcasm port stay on the pinned release's commit; `deluge` commits between
  releases are watched and noted, never adopted (`upstream.md`, `sarcasm-port.md`).
- **2026-11-24** — 🔒 **THE SARCASM PORT IS BSD-2-CLAUSE, THE TERMS OF `projects/sarcasm/install.sh`**
  (owner, review 1 L1: "it is referenced in the same location, so it does"). The `.luau` files
  carry no header, but `install.sh`'s licence header also describes what it installs, the sarcasm
  logic in `../lib/sarcasm`. The 17 `src/sarcasm/*.zig` headers, `SARCASM-LICENSE.txt`, the ledger
  entry `sarcasm-port` and NOTICE say so; the word ASSUMED is gone. No question to the author;
  the release no longer waits on one.
- **2026-11-23** — 🔒 **NO TIME LIMIT ON THE COMPILER DRIVER'S OR THE BUILD TOOLS' SUBPROCESSES**
  (owner, review 1 triage, H12: "No limit; document it"). `zilc build` runs zig, Fil-C's clang, ld
  and llvm-split; `zig build patched-clang` and `gcc-reference` run ninja and make for many
  minutes. Like zig, gcc and clang themselves, a compile takes as long as it takes, and Ctrl-C
  stops it. The release scripts' gate steps DO have limits (`release.ts`, `bump.ts`), and every
  network request has one.
  - Why: a fixed limit would kill legitimate builds (KI-22: single modules took many minutes before
    the patched clang); a hung tool is visible to the person running it.

- **2026-11-19** — 🔒 **THE MEMORY GUIDE'S LAYOUT: `STATE.md` + A ROUTER `INDEX.md`** (owner,
  2026-11-17, letter H38; steps 1–3 done 2026-11-19). The status moved from `open-work.md`'s State
  table to `STATE.md`; `INDEX.md` (20 KB) became a 2.4 KB router; its rules moved to
  `working-rules.md` (§§ Session routine, What bites in the first five minutes, Memory policy and
  triggers); the root `CLAUDE.md` names the two files. Dropped in the move: "this index stays under
  about 10 KB" (now 3 KB) and **"never run a formatter on `cmem/` / `tests/basics/`"**, retired
  - Why: The rule against a formatter predates Biome: since 2026-11-15 (owner) Biome formats every
    `.md`, `cmem/` included, and since 2026-11-06 `zig fmt` formats the `tests/basics` copies; the
    old line contradicted both. The INDEX's earlier history: it held the dated log until 2026-10-27
    (`git show c2841dd:cmem/INDEX.md`) and was modeled on wazmrt's `cmem/` (2026-09-18)
- **2026-11-06** — 🔒 **SARCASM, FIL-C'S ASSEMBLER, IS PORTED TO ZIG; minilute and the Luau
  toolchain go once it is proven** (owner: _"the minilute and sarcassm should also move into zig
  build. The Fil-C Luau tools should be converted to bun based typescript tools"_; then, shown that
  sarcasm is Fil-C's assembler — ~34,400 lines of Luau in 28 modules that Fil-C's clang runs for
  every `.s` input at USER compile time, and that minilute, C++ plus the Luau VM (27 MB), exists
  only to run it — and offered "as they are" / Bun-TS / Zig: **"Port sarcasm to Zig"**). So: a Zig
  sarcasm, built by `zig build` into a native tool installed as `pizfix/bin/sarcasm`, no runtime
  dependency for users (not Bun, not Luau). **The port replaces upstream's only after an output-diff
  proves them equivalent** (workspace tooling rule: a port replaces its original only after an
  output-diff), over Fil-C's asm tests and a wider corpus; until then the zig chain keeps upstream's
  sarcasm on minilute (upstream's scripts). Each Fil-C update brings upstream's Luau changes, ported
  and re-proven: part of `upstream.md` Stage A. Plan and progress: `roadmap.md` Z1
  - Why: The project's language, a native tool like zilc-gen (the Ruby generator's port), and no new runtime on a user's machine; the equivalence proof keeps it faithful to Fil-C
- **2026-11-05** — 🔒 **PARITY MEANS THE SAME END RESULT, NOT THE SAME BUILD PRODUCT** (owner, on
  item 8, the LLD-vs-GNU-ld relocation gap: _"We are looking for the end result being the same. Not
  specifically that the end compilation product is the same. I would imagine that it would be
  equally different if tinyc compiler were to be used and checked against also."_). The Zig-only
  chain is held to **functional** sameness with the release and the GCC chain: exports, behaviour
  (Fil-C's suite, the gate, the corpus, `compare-chains.ts`), and the safety a release build has
  (hardening that changes what code DOES: CET, stack protector, stack-clash, fortify — fixed
  2026-11-05). Layout and byte-level differences that any other compiler or linker would equally
  produce (relocation and PLT shapes, section names, inlining, notes, archive internals) are
  **recorded, not chased**. So: **item 8 — keep LLD** (W-14 stays documented); the linker family
  (L-7, L-8, W-11 `PHDR`), the cosmetic section items (`.llvm_addrsig`, `.debug_aranges`) and
  pinning binutils 2.38 (L-9) are **not pursued** (`open-work.md` items 8, 9); nor is pinning
  Ubuntu's clang 14 for the reference chain's libpas stock half (owner, the same day: "proceed with
  1-3"); that chain uses **Zig's clang**, not the host's, for the pieces upstream gives a plain
  clang (owner: _"The available clang should be the one that is being uses to compile that corpus,
  not what is in ubuntu"_; `open-work.md` item 5)
  - Why: Byte parity would tie zilc to one toolchain's layout choices without making any program behave differently; the proof that matters is what runs
- **2026-10-30 (later)** — 🔒 **GCC IS A MAINTAINER-ONLY QUALITY-CONTROL TOOL; A USER'S BUILD NEVER
  NEEDS IT** (owner: _"make sure that the entire compilation no longer needs gcc at all"_; then
  _"before we fully remove the gcc, we should make sure that the resulting compilations are
  functionally the same from gcc or the zig only compilation chain"_; then, on how future Fil-C
  releases are checked: _"I think we need to keep the compiled gcc and its libraries to perform this
  quality control check"_; settled: _"Yes maintainer only. User no."_). **Users:** clone, Zig +
  cmake/ninja (or `-Dfetch-build-tools`) + Python 3 + kernel headers + binutils' `ld`; no GCC, no
  host clang — `tools/filc/build-filc-from-source.ts` (MODE=zig) builds all of Fil-C with no C/C++
  compiler on PATH. **Maintainer:** keeps GCC to build the same sources the upstream way
  (MODE=upstream) and compare the two chains on every Fil-C move, beside the release tarball (which
  IS upstream's GCC build, on upstream's machine). Planned, maintainer-only (owner agreed): GCC
  pinned to upstream's versions (11.4, 12.3), built by Zig from hash-pinned sources, so the QC chain
  neither drifts with Ubuntu's GCC nor differs from the release by compiler version alone
  (`open-work.md`)
  - Why: Two references explain a difference the release alone cannot: Zig's vs a newer GCC's (e.g.
    GCC 15 here enabling half-float builtins the release's GCC 11.4 lacks); and if upstream stops
    publishing prebuilt releases, the local GCC chain is the only reference left
- **2026-10-30** — ✅ **CLONE-THEN-BUILD: GO-AHEAD, AND THE SOURCES ARE GITHUB'S ARCHIVE AS-IS**
  (owner: _"I agree with track 1 proceed with the implimentation"_; then, shown the measured size:
  _"Leave the download of Fil-C and LLVM as is, no distributable in our repo."_). `build.zig.zon`
  has a lazy `filc` dependency on GitHub's archive of the fork at the compiler commit, pinned by
  Zig's package hash; `build/filc_source.zig` requests it only when a step that reads Fil-C's
  sources is named (`pure-zig`, `libpas`, `yolomusl`, `compiler-rt`, `patched-clang`), so `zig build
  test` and the gate never download it; `-Dfilc-src` stays the offline override. **No trimmed or
  re-packed Fil-C source is made or published by zilc**, whatever the size (measured 2026-10-30: 2.2
  GB download, 11 GB / 650,987 entries unpacked, ~10 min to download and ~10 min for `zig fetch`
  here). The fetched tree is proved equal to the commit as checked out
  (`tools/upstream/verify-filc-package.ts`; `testing.md`). Also the same day (owner): **_"all of
  these references should be updated each time Fil-C updates"_** → `zig build check-pins` (in `zig
  build test`) fails when any place that names the Fil-C release or commit disagrees, and the
  release checklist bumps them together. **Zig is the only compiler** (owner, 2026-10-27): `zig
  build patched-clang` compiles the clang with `zig cc`/`zig c++` by default, proven by Fil-C's
  suite (0 differences on 7,269) and the gate (8/8); `-Dclang-cc=system` keeps GCC
  - Why: One pinned, public upstream download that every clone reaches the same way; zilc stays its own sources only, and nothing of Fil-C's is redistributed from zilc
- **2026-10-27 (late night)** — 🔒 **THE GOAL: CLONE zilc, INSTALL THE BUILD TOOLS, BUILD EITHER
  SIDE** (owner: _"the goal is to be able to clone this repository and build for the fil-c side or
  the pure zig side once the user has the build tools installed"_; then, on how: _"when a user
  clones our repository and performs the fil-c side build (first build) the build goes and gets all
  of the files necessary to build, then builds it. And we just have our zig sources files in the
  repo"_). So **the repo holds zilc's own sources only; the first build fetches Fil-C's build files
  itself.** Proposed (✅ go-ahead 2026-10-30, row above; was scoped in `open-work.md`, first item): a
  lazy `build.zig.zon` dependency on GitHub's archive of the fork at the build commit, pinned by
  Zig's package hash; `-Dfilc-src` kept as the offline override; a Fil-C-side step that patches and
  builds the clang from it. **Refines the row below:** its "exact, hash-checked duplicate" is then
  Zig's verified package cache, reachable from any clone; the gitignored `reference/` folder (first
  attempt) is parked on local branch `wip/reference-duplicate`
  - Why: A gitignored folder never reaches a clone; a fetched, hash-pinned dependency does, without carrying Fil-C in zilc's history
- **2026-10-27 (night)** — 🔒 **WHAT ZILC BUILDS FROM IN WSL IS ALSO IN THE PROJECT FOLDER, AS AN
  EXACT DUPLICATE, FOR PORTABLE REFERENCE** (owner: _"we need to add a rule that whatever lives in
  wsl must also be in the project folder for portable reference"_; scope, asked the same night: _"an
  exact duplicate of the build files needed to build the project via the fil-c side versus the zig
  side"_). **In scope — the BUILD FILES only** (owner, the same night: _"we do not need ninja and
  zig of course just the build files"_, _"or bun"_): Fil-C's sources at the build commit, for **(a)
  the Fil-C way** (what zilc's patched clang is built from: the top-level build scripts and the
  LLVM, clang and cmake trees) and **(b) the Zig way** (every directory the pure-Zig steps and the
  next ones read: today `libpas`, `projects/yolomusl`, `compiler-rt`, `yolounwind`, `filc/main`,
  `filc/include`, `filc/src`, `projects/usermusl`, `libcxx`, `libcxxabi`, `runtimes`) — in
  `reference/` (`tools/reference/sync-reference.ts`). zilc's own build files are the repo itself;
  the patched clang's archive is in `toolchain/`. **Exact:** the same bytes as the commit, checked
  by git blob id, mode and link target against the commit's tree, and re-synced whenever the WSL
  side moves (a Fil-C move, a widened sparse set). **Not in scope:** the tools (Zig, Fil-C's
  prebuilt release, Bun, patchelf, Ninja — reinstalled from their sources; `reference/MANIFEST.txt`
  names each with its recorded SHA-256), build outputs, caches, corpus and experiment results.
  Gitignored; never committed or distributed (the repo bundles no toolchain, `licensing.md`). The
  machine that runs it stays Linux (row below); the duplicate is a reference, never built on the
  Windows host
  - Why: If the WSL VM is lost, or zilc moves to another machine, every input its two builds need is
    in the project folder with proof it is the same, so a build can be redone and a recorded result
    re-derived without re-finding sources at the right commits
- **2026-10-27 (latest)** — 🔒 **zilc STAYS ON THE ZIG WHOSE LLVM MATCHES FIL-C'S — ALWAYS** (owner:
  _"this repo will stay on the compatible LLVM version of zig. it can make some recommendations for
  the newest zig version upgrade procedures to 0.17.0 but not do them here. this repo will remain on
  the compatible zig version always."_). zilc moves Zig **only** when Fil-C moves LLVM (upgrade
  stage A). **No latest-Zig line in zilc:** stage B (porting zilc to a newer Zig), stage C
  (benchmarking lines against each other), the `v0.16.0` line, the 0.16.0 examples under zilc and
  the two-Zig split are not done here. zilc **may write recommendations** for a newer-Zig upgrade
  (0.17.0 and later) from what it has measured, as notes for whoever does it (zailc owns the
  Zig-version path past the compatible one, row below); `upstream.md` "Recommendations for a
  newer-Zig upgrade" holds them. **Supersedes** the 2026-10-05 row's 0.16.0 line for zilc,
  `releasing.md`'s latest lines and per-Zig-line branches beyond the reference, and `upstream.md`
  stages B and C as zilc work
  - Why: One Zig that Fil-C can read keeps zilc a fixed reference: every result is checked directly against Fil-C, with no line that Fil-C's LLVM cannot verify
- **2026-10-27 (later)** — 🔒 **zilc ALSO KEEPS THE PURE-ZIG BUILDS OF FIL-C'S OWN MODULES, AND IS
  THE CORPUS OF TRUTH** (owner, in sequence: _"when an update is done on the fil-c side we perform
  all of the checklist items. then when we have a pure zig build of those changes we run the same
  build by just swapping out the fil-c specific modules with the pure zig modules. that needs to be
  a build item in the build.zig file"_; _"Not in zailc — here"_; _"I intend to do the first steps
  here not zailc"_; _"that way they stay up to date here and the zailc modifications stay there.
  this will be the corpus of truth"_). So: **(a)** the first steps — Fil-C's modules built as pure
  Zig, faithful to the release, no modifications — are done in zilc and move with every Fil-C
  release; **(b)** zailc keeps its own modifications; **(c)** after a Fil-C update passes every
  checklist item, the same gate runs again with Fil-C's modules swapped for the pure-Zig ones:
  **`zig build gate-zig-modules -Dzig-modules=<dir> -Dzig-modules-filc=<release>`**
  (`tools/swap-modules.zig`; `testing.md`). This narrows the P3 row below: what moved to zailc is a
  DIFFERENT runtime; Fil-C's own modules built as Zig are zilc's. ✅ **Boundary settled the same day
  (owner): _"all of zailc's build to the point of pure zig implemenation running in linux should be
  in zilc"_** — zailc's **step 2** (Fil-C's runtime built from its sources by `zig build`: the
  generators, libpas, yolo musl static and shared, compiler-rt, the three Fil-C-compiled pieces, a
  program linked entirely from `zig build`'s outputs, Fil-C's suite against it) and **step 3** (the
  pass in Zig, with its IR model and analyses) are zilc's, on Linux x86_64, faithful to each Fil-C
  release with no departures (`roadmap.md` "The pure-Zig track"). zailc keeps its modifications (its
  recorded departures W-n), the zail language, the Zig-version path past 0.15.2, and cross-platform.
  zailc's existing step-2 work is brought here by reading it (nothing written into zailc), adapted
  to zilc's layout, and re-verified against the release zilc is on
  - Why: One place where each Fil-C release, and its pure-Zig counterpart, are kept current and
    compared module by module; zailc's departures are then measured against an unmodified,
    release-current baseline instead of carrying both
- **2026-10-27** — 🔒 **P3, P4 AND P5 HAVE MOVED TO zailc AND ARE OFFICIALLY ABANDONED IN zilc**
  (owner: _"P3, P4 and P5 have moved to zail and are officially obandoned here."_) — the Zig runtime
  (P3), Zig language fidelity (P4), C++ and polish (P5), with what hung off them: `--runtime zig`,
  `-Druntime=both`, the byte-identity check, the `zsys_write` spike, open question #3. 🔒 **zilc's
  whole remaining role** (owner, same exchange: *"the only thing this repo is keeping up to date is
  tracking the changes in fil-c and making the necessary adjustments for x86_64 compatilbility for
  zail to reference"*): **(1)** track Fil-C releases — upstream review, zilc's pass patches
  re-applied, the patched clang rebuilt, Fil-C's suite at 0 differences, a new `<Zig>-<Fil-C>.<n>`
  release; **(2)** move to the Zig whose LLVM matches Fil-C's when Fil-C moves (upgrade stage A);
  **(3)** keep Zig and C compiling and running correctly under Fil-C on x86_64 Linux (the std
  overlay, the KI workarounds, the gates); **(4)** be zailc's fixed reference. Work outside these
  four is not zilc's
  - Why: zailc translates Fil-C into Zig and develops the cross-platform part; a second Zig runtime
    or language-fidelity effort here would compete with it. zilc stays small enough to follow every
    Fil-C release faithfully, which is what makes it a reference. The P3–P5 plans, `filc-abi.md` and
    the P3 probes in `tools/p3/` stay as the record zailc inherits
- **2026-10-27** — 🔒 **zilc IS FIL-C ON LINUX ONLY, WORKED IN WSL OR LINUX — ALWAYS** (owner:
  _"since this repo is being used by zail as a base and that repo will fully develop the cross
  platform part, this repo will always remain as fil-c on wsl and linux only"_). **Target:** Linux
  **x86_64** only (owner, same day: *"we need it to be on x86_64 linux. that is why we are working
  with it to make it work here"*) — Fil-C's aarch64 Linux build is out of scope for zilc as well.
  **Environment:** every Fil-C step, build of user programs, test and run of their output happens on
  Linux, natively or in WSL on a Windows host. **No cross-platform work in zilc:** macOS, Windows,
  iOS, Android and cosmo/APE output are zailc's (`../zailc`). **Supersedes** the 2026-09-30
  platforms goal (row below), open question #4's non-Linux rows and `roadmap.md` P6;
  `archive/platforms-p6-cosmo-2026-10-08.md` and the cosmo evaluation stay as the measured record
  zailc started from. **Tooling, the same day (owner):** _"this also means that bun will need to be
  used from wsl on this machine in a linux environment on another machine"_ — **Bun runs inside
  Linux only**: WSL's Bun (`~/.bun/bin/bun`) on a Windows host, the machine's own Bun on Linux.
  Starting a tool with Windows' Bun is retired, including the `linuxOnly()` bridge that re-launched
  tools into WSL and the tools that ran natively on Windows — done in code 2026-10-27 (`bac5a85`:
  `tools/lib/tool.ts` refuses any platform but Linux). Building zilc's own code with Windows' Zig
  (`C:\zig\0.15.2\zig.exe build test`) is retired with it (owner: "perform the open items",
  2026-10-27); zilc builds with WSL's Zig
  - Why: zilc is zailc's base and test oracle: it stays faithful to Zig + Fil-C releases, and Fil-C
    runs only on Linux. Keeping the cross-platform work in one repo avoids two competing ports; an
    oracle that changes platform would stop being a fixed point to compare against. It also matches
    the 2026-10-08 rule that nothing built by Fil-C, cosmo or zilc runs on the Windows host
- **2026-10-22** — 🥟 **ALL TOOL SCRIPTS ARE BUN; DENO IS DROPPED** (owner: _"since deno is going
  away, make the rule exclusive to bun"_; then chose to port every tool now rather than as touched).
  The rule in `best-practices.md` is Bun only (was Deno or Bun since 2026-09-18)
  - Why: Tools use Node's APIs plus `Bun.spawn`/`Bun.Glob`/`Bun.YAML`, so no `jsr:` downloads. The
    design of 2026-10-05 (below) is unchanged: one script per tool, `linuxOnly()` bridges into WSL,
    now with `~/.bun/bin/bun`. Bun's `exited` gives 128+signal like Deno, so recorded exit codes
    stay comparable. Verification: `open-work.md` "The Bun port (2026-10-22)" (moved from `INDEX.md`
    2026-10-27)

## Invariants (proposed. Confirm with the owner.)

1. **Semantics come from Fil-C.** Where zilc and Fil-C disagree on what a program may do, Fil-C's
   documented GIMSO semantics win unless a deviation is recorded here with its reason.
2. **Every bug example must panic.** Anything in `examples/` that is UB under `zig build baseline`
   must be a deterministic trap under the safe build. A new unsafe pattern gets an example first.
3. **Our own files carry `SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT`.**
   Adapted files carry the upstream's SPDX (`third_party/LICENSES.md`).
4. 🔒 **NOTHING UNSAFE IS LEFT TO CHANCE (owner, 2026-09-30): "We definitely don't want to leave
   anything unsafe to chance. That would be totally the opposite of what our end goal with this
   port is."** Binding on every fix:
   - An unsafe construct (raw `syscall` asm, register-copying `getcontext`, `@ptrFromInt` of a
     forged address) is **replaced by a safe equivalent**, never bypassed, whitelisted, or left
     "rarely reached". If no safe equivalent exists yet, the program must **stop with an explicit
     Fil-C error**. It must never run unchecked.
   - Glue zilc adds (the entry shim, `zilc_syscall`) is **compiled by Fil-C**, so it is checked code
     itself, and reaches the kernel only through Fil-C's libc and runtime.
   - "Only on the panic path" is not an exemption: `getcontext` gets a safe replacement
     (`zdump_stack`/`zstack_scan`, KI-7), not a pass.
5. **Written to be upgraded (owner goal, 2026-09-30).** Moving to the latest Zig must mean editing a
   few known places, not reorganising files. The rules:
   - **The file layout stays stable** (`src/`, `include/`, `tools/`, `examples/`). Zig API churn is
     absorbed inside files, never by moving or splitting them.
   - **Keep std calls that change between Zig versions in few places.** Baseline 2026-09-30: about
     **31 sites** (`std.fs` 10, `std.process` 13, `ArrayListUnmanaged` 8) across `driver.zig`,
     `main.zig`, `ir.zig` and `tools/gate.zig`, plus **36** build API calls in `build.zig`. New code,
     above all the P3 runtime, should not grow this freely. When a second file needs the same
     version-sensitive call, route both through one small helper instead of duplicating it. Prefer
     plain slices and explicit allocators, which change least between releases.
   - 🔑 **There are TWO Zigs, and only one is pinned by Fil-C.** The Zig that _builds zilc_ (host
     toolchain, and the P3 runtime, which is linked as an ordinary object) is limited only by our
     own code. The Zig that _compiles user code_ (`ZILC_ZIG`) must emit IR that Fil-C's LLVM reads,
     so it follows Fil-C's LLVM major (KI-3). Today both are 0.15.2 by owner decision (2026-09-18).
     Separating them is what lets zilc itself reach the latest Zig **before** Fil-C moves.
     ◐ **Implied by the upgrade procedure's stage B (2026-09-30)**, which moves only the Zig
     that builds zilc. The 2026-09-18 "one Zig for everything" decision therefore holds only up
     to stage A. ⚠️ Confirm with the owner that this is intended.
   - **Zig source that zilc generates or ships is compiled by the USER-CODE Zig**: the entry shim
     in `driver.zig` and `examples/**/*.zig`. It tracks `ZILC_ZIG`'s version, not the host's, so
     keep it minimal (it is ~30 lines today).
   - **Every upgrade** follows the three-stage procedure in `upstream.md`. Porting code between Zig
     versions is the same checklist in stages A and B: bump `minimum_zig_version`, fix the counted
     sites, run `zig build test` + `gate`, then refresh the Zig API notes below.
