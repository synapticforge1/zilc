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
but it must be a *decision*, recorded in the ledger entry — not an accident. A clean-room Zig runtime
avoids it entirely. See `cmem/licensing.md`.

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

**EMPTY as of 2026-09-18 — zilc has incorporated no third-party code yet.** The license texts are
staged so the first adoption is compliant on day one.

Newest first. Copy the template for each adopted component.

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
