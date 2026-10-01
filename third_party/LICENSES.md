# Third-Party Licenses & Attribution

zilc's own original code is licensed **`Apache-2.0 WITH LLVM-exception OR MIT`**. Code incorporated
or adapted from another project stays under **its own original license**, and every such use is
recorded in the [Component Ledger](#component-ledger) below. This file is the single source of truth
for license compliance. The *why* behind the choices lives in `cmem/licensing.md`.

> **Rule of thumb:** you may *look at* any project freely. Before you *copy or adapt* even a few
> lines, complete the [Adoption Checklist](#adoption-checklist) and add a ledger entry.
> "I reimplemented the idea from scratch without looking at their code" needs no entry;
> "I ported their function" always needs one.

---

## License obligations at a glance

| License | To reuse code you MUST | Patent grant | Reaches user binaries? |
|---|---|---|---|
| **MIT** (Zig, musl) | Preserve the copyright + permission notice in source; reproduce it in binary distributions' docs. | No | **Yes** — notice must accompany binaries |
| **BSD-2-Clause** (Fil-C runtime / libpas) | Retain notice in source; **reproduce notice in binary distributions' docs**. | No | **Yes** — notice must accompany binaries |
| **BSD-3-Clause** (OpenSSH `setproctitle` inside libpas) | As BSD-2, plus no use of contributors' names for endorsement. | No | Yes |
| **Apache-2.0** | Preserve notices; include the license; **propagate NOTICE**; **mark changes** in modified files (§4). | **Yes** (§3) | Yes |
| **Apache-2.0 WITH LLVM-exception** (LLVM, Fil-C compiler) | As Apache-2.0, **except** §4(a)(b)(d) are waived for portions embedded into compiled/object output. | Yes | **No** (the exception covers it) |
| **LGPL-2.1-or-later** (glibc, *Fil-C's `/opt/fil` distribution only*) | Copyleft. **Not adopted — see below.** | — | — |

**Practical rules for this repo:**

1. The upstream license texts are staged in `third_party/<component>/` (done 2026-09-18).
2. If an upstream ships a `NOTICE` file, copy it too and reference it from the top-level `NOTICE`.
   (None of the three currently do.)
3. In any source file adapted from third-party code, add a header change-note, e.g.
   `// Adapted from Fil-C FilPizlonator.cpp (Apache-2.0 WITH LLVM-exception); modified by zilc — see third_party/LICENSES.md`.
4. Keep an **SPDX tag** at the top of every such file — the *upstream's* identifier, not ours:
   - LLVM / Fil-C compiler code → `// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception`
   - Fil-C runtime / libpas code → `// SPDX-License-Identifier: BSD-2-Clause`
   - Zig std/compiler code → `// SPDX-License-Identifier: MIT`
5. Our own files carry `// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT`.

### The runtime-linking rule (⚠️ the one that is easy to miss)

zilc produces **two kinds of artifact** with different license exposure:

- **The toolchain** (compiler pass, driver) — only the zilc distribution ships it.
- **The runtime** (`zilc_runtime`: GC, capability tables, syscall shims) — **gets linked into every
  program a user compiles.** Whatever license the runtime's code carries, *the user's binary* carries.

LLVM-derived code is fine in the runtime (the LLVM exception waives attribution in object output).
**BSD-2-Clause (libpas) and MIT (Zig, musl) are not** — each requires its notice to accompany binary
distributions. So: **porting libpas/filc-runtime code into `zilc_runtime` imposes an attribution
obligation on every downstream program.** That is an acceptable trade (Fil-C itself works this way),
but it must be a *decision*, recorded in the ledger entry — not an accident. **Owner decision
2026-10-01: comply rather than avoid.** Fil-C's source may be read, and each adaptation into the
runtime is ledgered here, with the BSD-2-Clause notice carried with user binaries. See
`cmem/licensing.md`.

### Copyleft exclusion

Fil-C's `/opt/fil` distribution uses **glibc (LGPL-2.1-or-later)**, and `projects/` + `pizlix/` in
the Fil-C tree contain ported programs under **many** licenses, some GPL. **None of these are in scope.**
Only the paths listed in the inventory below are candidate sources. Anything else requires an explicit
owner decision first.

---

## Adoption Checklist

Run this **before** incorporating code from any project.

- [ ] **Benefit vs. drawback** documented: what it buys (correctness, coverage, time) vs. cost
      (complexity, deps, maintenance, portability, **runtime-license exposure**).
- [ ] **License identified per FILE** and confirmed against the upstream file header / `LICENSE`
      (not the GitHub badge — GitHub reports Fil-C as `NOASSERTION`; its tree is multi-licensed).
- [ ] **Compatible** with `Apache-2.0 WITH LLVM-exception OR MIT` distribution. Copyleft → stop.
- [ ] **Artifact destination recorded:** toolchain-only, or linked into user programs? If the latter
      and the license is BSD/MIT, the runtime-linking rule above applies.
- [ ] Upstream `LICENSE`/`NOTICE` present in `third_party/<component>/`.
- [ ] **Ledger entry added** below with source, pinned commit, files, and obligation actions taken.
- [ ] Change-notes + SPDX headers added to the adapting source files.
- [ ] `NOTICE` updated; `build.zig` installs any license text that must travel with `zig-out/`.

---

## Component Ledger

~~EMPTY as of 2026-09-18.~~ **First entries 2026-09-30:** test programs, and a 4-line Zig std backport (MIT).
**2026-10-01:** a local patch to Fil-C's compiler pass (toolchain-only, not distributed). **Still no
third-party runtime code in zilc.**

Newest first. Copy the template for each adopted component.

### filc-pass-fixes (local patches to Fil-C's compiler pass; LOCAL USE ONLY)
- **Source:** https://github.com/pizlonator/llvm-project-deluge (Fil-C's LLVM fork)
- **Version / commit:** `bb0d0a64eed297ab8e171002033208fb08ad9941`, the commit the Fil-C **0.685**
  prebuilt names in `clang --version`
- **Upstream path(s):** `llvm/lib/Transforms/Instrumentation/FilPizlonator.cpp`: the two frame-slot
  colouring loops (about lines 3054–3076 and 3146–3160 at that commit), and
  `lowerIndirectBrForFunction` (Fil-C's copy of LLVM's `IndirectBrExpandPass`)
- **License (SPDX):** `Apache-2.0 WITH LLVM-exception` (the file's own header)
- **License file:** upstream `LLVM-LICENSE.txt` / `llvm/LICENSE.TXT`; nothing copied into zilc's
  source beyond the diff context
- **What we changed:** the greedy colouring picks the lowest frame index no neighbour holds by marking
  the neighbours' indices once, instead of rescanning every neighbour per candidate index. Same
  visiting order, same choice, so **the same colouring and the same output**, at O(degree) instead
  of O(degree × colours) per value (KI-22, `cmem/workarounds.md`). **Added 2026-10-01 (KI-4):**
  with several `indirectbr`s in one function, each is lowered in place into its own `switch` over
  its own destinations, instead of all being merged into one `switch_bb` (which broke the
  destinations' phis and dominance, and crashed). The single-`indirectbr` path is unchanged
- **Where it lives in zilc:** `tools/filc/patch-pass.ts` (exact-match edit script, the diff
  context), `third_party/filc-patches/zilc-filc-pass.patch` (the resulting diff, all edits),
  `tools/filc/build-patched-clang.sh` (build recipe mirroring Fil-C's `configure_llvm.sh`)
- **Artifact destination:** **toolchain-only, and local only.** The patched clang lives in
  `~/zilc-work/tools/filc-0.685-zilc/` and is **not distributed**. It is the default for zilc's
  scripts (owner, 2026-10-01); the prebuilt stays for comparison. The colouring fix emits the same
  code; the KI-4 fix only changes functions that crashed before. User binaries carry no new code
- **Modifications:** each changed block is marked `// zilc (KI-22): …` or `// zilc (KI-4): …` in the
  patched source. Also
  adds `zilcVerifyColouring()`: with `ZILC_VERIFY_COLOURING=1` the original search runs too and the
  compile aborts on any difference (off by default)
- **Obligations satisfied:** [n/a] while local: Apache-2.0 §4 applies only on redistribution.
  **If the patched clang is ever distributed:** [ ] include the Apache-2.0 + LLVM-exception licence
  [ ] carry Fil-C's NOTICE/attribution files [ ] keep the `zilc (KI-…)` change marks (§4(b)
  prominent notice of modification) [ ] state the base commit
- **Benefit / drawback note:** removes the cubic cost that made big Zig functions (TLS, crypto) and
  Debug builds impractically slow, and lets Debug compile at `-O1`, which fixed KI-19's 12 Debug
  programs. Drawback: zilc must rebuild the patched clang at every Fil-C upgrade until upstream
  changes both (`cmem/upstream.md` stage A)

### zig-std-backports (Zig standard-library backports applied by `src/stdpatch.zig`)
- **Source:** https://codeberg.org/ziglang/zig (the Zig 0.16.0 release, as installed: `lib/std/mem.zig`)
- **Version / commit:** Zig **0.16.0** release tarball (the backport source), applied to Zig **0.15.2**
- **Upstream path(s):** `lib/std/mem.zig`, `findSentinel` (0.16.0), the body of the scalar loop
- **License (SPDX):** `MIT` (Zig; verified against the installed `lib/std` and `LICENSE`)
- **License file:** `third_party/zig/LICENSE` (staged since 2026-09-18)
- **What we reused:** the 0.16.0 `findSentinel` body, 4 lines (`var i = 0; while (p[i] != sentinel) i += 1;
  return i;`), as the replacement for 0.15.2's vectorised `indexOfSentinel` (KI-11,
  `cmem/zig-upstream-notes.md` Z-1)
- **Where it lives in zilc:** `src/stdpatch.zig` (`zig_0_15_2` patch set). Applied at build time to a
  cached copy of the **user's own** Zig `std/` (`~/.cache/zilc/std-overlay/<version>-v<n>`). zilc
  ships no Zig files
- **Artifact destination:** compiled into **user programs** as part of std, like all Zig std code,
  which is already MIT. Zig's notice obligations for binaries are unchanged by the backport
- **Modifications:** a `zilc:` comment naming the backport and its reason; otherwise verbatim. Each
  patch verifies the exact original before replacing it, and fails the build if it differs
- **Obligations satisfied:** [x] license present  [x] change-notes (comment in the patched function)
  [x] SPDX on `stdpatch.zig`  [n/a] NOTICE (no new licence; Zig's MIT already applies to every Zig
  program)
- **Benefit / drawback note:** removes an out-of-bounds read in 0.15.2's std that Fil-C rightly
  rejects (`getenv`, every C-string span), by adopting **upstream's own fix**, not an invention.
  Drawback: each Zig version needs its patch set re-checked (`cmem/ports/`).

### basics-of-coding (C and Zig example programs, used as TESTS)
- **Source:** https://github.com/jrmarcum/BasicsOfCodingC and https://github.com/jrmarcum/BasicsOfCodingZig
  (the owner's own repositories)
- **Version / commit:** C `0503871a87ef7d5f80f1ade1e5d653fe7bae1299`; Zig `d85cc5f7ac19232b240bf890dcd1b915449de789`
- **Upstream path(s):** `NN_name/name.c` and `NN_name/name.zig`, 78 of each. Source files only; not the
  lesson `.md` files or build outputs
- **License (SPDX):** `CC-BY-3.0` for the lesson code, which derives (via "Basics of Coding Go") from
  **"Go by Example" by Mark McGranaghan**; `CC0-1.0` for the owner's original contributions
- **License file:** `tests/basics/c/LICENSE` + `NOTICE`, `tests/basics/zig-0.15.2/` and `zig-0.16.0/` `LICENSE` + `NOTICE`
  (copied verbatim; each NOTICE carries the CC BY 3.0 attribution)
- **What we reused:** the example programs, as a corpus of *correct* programs that zilc must build
  and run without false traps
- **Where it lives in zilc:** `tests/basics/c/`, `tests/basics/zig-0.15.2/` (converted to Zig 0.15.2),
  `tests/basics/zig-0.16.0/` (converted to Zig 0.16.0)
- **Artifact destination:** **test-only.** Never linked into zilc, its runtime or user programs
- **Modifications:** yes. Each non-obvious change is marked with a `// zilc:` or `/* zilc: */`
  comment; the full list is in `tests/basics/README.md`
- **Obligations satisfied:** [x] license present  [x] NOTICE (attribution) present  [x] change-notes
  [n/a] SPDX headers (upstream uses none; attribution is centralised in NOTICE, as upstream does)
  [n/a] binary-distribution notice (test-only)
- **Benefit / drawback note:** 156 paired C/Zig programs covering most of each language's standard
  library, owned by the project owner. CC BY 3.0 only asks for attribution, which the copied NOTICE
  files provide.

<!--
### <component-name>
- **Source:** https://github.com/<org>/<repo>
- **Version / commit:** <tag or 40-char SHA — pin it>
- **Upstream path(s):** <exact files>
- **License (SPDX):** <per-file SPDX>
- **License file:** third_party/<component>/<file>
- **What we reused:** <specific functions/files/algorithm>
- **Where it lives in zilc:** <path(s)>
- **Artifact destination:** toolchain-only | linked into user programs
- **Modifications:** <summary of changes, or "verbatim">
- **Obligations satisfied:** [ ] license present  [ ] NOTICE updated  [ ] change-notes  [ ] SPDX headers
  [ ] binary-distribution notice (if runtime + BSD/MIT)
- **Benefit / drawback note:** <one line on why it earned its place>
-->

---

## Upstream inventory

Verified against each upstream's license file **and** representative source headers on 2026-09-18.

| Component | Upstream path | License (SPDX) | Staged text | Status |
|---|---|---|---|---|
| Fil-C compiler (clang/LLVM fork, `FilPizlonator.cpp` pass) | `pizlonator/fil-c@deluge` `llvm/`, `clang/` | `Apache-2.0 WITH LLVM-exception` | `fil-c/LLVM-LICENSE.txt` | Evaluating |
| Fil-C runtime (libpas, `filc_runtime.c`, `stdfil.h`) | `libpas/`, `filc/include/` | `BSD-2-Clause` (+ `BSD-3-Clause` setproctitle) | `fil-c/PAS-LICENSE.txt` | Evaluating |
| Fil-C musl (`usermusl`, `yolomusl`) | `projects/usermusl`, `projects/yolomusl` | `MIT` | `fil-c/MUSL-LICENSE.txt` | Evaluating |
| Fil-C libc++ / libc++abi | `libcxx/`, `libcxxabi/` | `Apache-2.0 WITH LLVM-exception` | `fil-c/LLVM-LICENSE.txt` | Evaluating |
| Fil-C glibc variant | `/opt/fil` build | `LGPL-2.1-or-later` | — | **Excluded** (copyleft) |
| Fil-C `projects/`, `pizlix/` ports | various | mixed, some GPL | — | **Excluded** |
| LLVM Project | `llvm/llvm-project` | `Apache-2.0 WITH LLVM-exception` | `llvm/LICENSE.TXT` | Evaluating |
| Zig | `codeberg.org/ziglang/zig` | `MIT` | `zig/LICENSE` | Evaluating |

Pinned at verification: Fil-C `deluge` @ `cd830ff67170486aaa74c253ae6ba665a2a601b5`;
LLVM `main` @ `b65f5aca2ba2ca10611c9b5fb6f80bc34619362d` (license text byte-identical to Fil-C's copy).

> **Trademarks:** permissive licenses grant no trademark rights. "Fil-C", "LLVM" and "Zig" are named
> here for attribution only; do not use them to imply endorsement of zilc.
