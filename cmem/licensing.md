# Licensing

## 🔒 2026-10-27: the licence stays as it is (owner)

Asked what an Apache-only licence would mean for liability (the summary given: warranty and
liability disclaimers are equivalent in both licences; Apache adds the §3 patent grant with its
retaliation clause; plain Apache-2.0 without the LLVM exception would put §4's notice duties on
programs built with zilc; Apache-only would drop GPLv2 compatibility and the MIT route into the
Zig ecosystem; published releases keep the dual licence either way), the owner decided: *"keep
licensing as is"*. zilc stays **`Apache-2.0 WITH LLVM-exception OR MIT`**. This also settles the
"pending owner confirmation" below.

**Compliance audit the same day** (owner: *"make sure all of the licensing is compliant for this
repo"*), against this repo's own rule (`third_party/LICENSES.md`, practical rule 4: a file holding
third-party code carries the upstream's SPDX identifier):
- the edit scripts `tools/filc/patch-pass.ts` / `patch-split.ts` (verbatim Fil-C/LLVM text) are now
  `Apache-2.0 WITH LLVM-exception` with a §4(b) change notice; `src/stdpatch.zig` (verbatim Zig std
  text) is `MIT`; the saved patch's licence is stated in `third_party/filc-patches/README.md`;
- the pure-Zig track's ports carry their upstream's licence and full notice: `src/gen/forwarders.zig`,
  `sig.zig`, the generated `signatures.zig` (BSD-2-Clause, Fil-C), `musl_headers.zig` (MIT, musl);
  ledger entries `forwarder-generator`, `musl-header-install`;
- 11 files that had no SPDX line got one at their END (no recorded line number moves): zilc's own
  probes, and the two KI repros, which are IR compiled from Zig's std (`MIT`);
- `NOTICE` lists every ported piece; `zig build` installs the licence texts and `NOTICE` under
  `share/licenses/zilc/` beside the binaries.
Scan after: every tracked code file has an SPDX line, and every file holding third-party code
names that code's licence.

## Decision (2026-09-18): dual **`Apache-2.0 WITH LLVM-exception OR MIT`**

zilc's own code is licensed under **either** Apache-2.0 with LLVM Exceptions (`LICENSE-APACHE`)
**or** MIT (`LICENSE-MIT`), at the consumer's option.
SPDX: `Apache-2.0 WITH LLVM-exception OR MIT`.

This replaced the GitHub-template plain Apache-2.0 `LICENSE` from the initial commit (`961a9d5`).
It follows wazmrt's dual-license pattern, with the Apache arm upgraded to the LLVM-exception
variant. **Proposed by Claude and pending owner confirmation**, since the owner asked only for
"compliant with the upstreams".

### Why this combination

| Upstream | License | How our choice fits |
| --- | --- | --- |
| LLVM, Fil-C compiler (`FilPizlonator.cpp`) | Apache-2.0 WITH LLVM-exception | The Apache arm is **identical**, so pass code can move between zilc and LLVM-derived trees with no relicensing friction |
| Zig | MIT | The MIT arm is **identical**, so runtime code could move into Zig's ecosystem as-is |
| Fil-C runtime (libpas) | BSD-2-Clause | Compatible with both arms (permissive). Adapted files stay BSD-2 |
| musl | MIT | Same as Zig |

**Why the LLVM exception matters here specifically:** zilc is a *compiler*, and its runtime gets
**embedded in other people's binaries**. Under plain Apache-2.0, §4 would technically require every
program built with zilc to carry our license and NOTICE. The LLVM exception waives §4(a)(b)(d) for
portions embedded in object code, which is exactly why LLVM adopted it. Plain MIT already covers the
MIT arm, but MIT also asks for the notice "in all copies or substantial portions". A user who picks
the Apache+exception arm is fully clear.

## ⚡ Status 2026-09-23 — **zilc still vendors NOTHING, and that is a design property now**

The driver **invokes** Fil-C's clang and stock Zig; it does not embed, bundle or redistribute either.
So the ledger stays EMPTY and zilc is `Apache-2.0 WITH LLVM-exception OR MIT` end to end, even though
the *compiler pipeline* a user runs includes Apache-2.0-with-LLVM-exception, BSD-2-Clause and MIT
code. Invoking a tool is not distributing it.

⚠️ **The moment that changes:** if zilc ever ships a Fil-C build, a `pizfix`, or a copy of Fil-C's
runtime, every obligation in this file attaches at once — including the **runtime-linking rule
below**, since Fil-C's runtime (BSD-2-Clause) ends up inside every binary a user compiles. Bundling
for convenience is therefore a **licensing decision**, not a packaging one.

⚠️ **Already true and worth knowing:** a binary built by `zilc build` today *does* contain Fil-C's
BSD-2-Clause runtime and musl (MIT) — because Fil-C linked them. Anyone **distributing programs built
with zilc** owes those notices. That obligation is the user's, not ours, but the README should say
so before anyone ships something.

## The runtime-linking rule — ⚠️ the one that is easy to miss

The dual license only covers **our** code. If `zilc_runtime` incorporates **BSD-2-Clause (libpas)**
or **MIT (Zig std, musl)** code, then *every user program* linking the runtime must reproduce
those notices in its distribution documentation. Neither license has an object-code exception.

- Porting code into the **toolchain** (the pass, the driver) is harmless for users.
- Porting code into the **runtime** is a user-visible obligation. It is acceptable (Fil-C ships
  exactly this way), but it has to be an explicit decision recorded in the ledger entry.
- Note: **Zig's own `std` is MIT**, and anything from `std` compiled into the runtime is technically
  Zig code in the user binary. This is universal to every Zig program and is not zilc-specific, but
  it is worth knowing.

✅ **Settled 2026-10-01 (owner, open question 3 in `design-decisions.md`): comply, don't avoid.**
The Zig runtime is new Zig code; Fil-C's source may be read; wherever Fil-C code or design is
adapted into the runtime, this rule applies and the BSD-2-Clause notice ships with user binaries.
Each adoption gets its ledger entry in `third_party/LICENSES.md` at the time it is made. The record
of workarounds and upstream issues (`workarounds.md`, `UPSTREAM-ISSUES.md`) is part of that
compliance trail.

## Copyleft exclusion

Fil-C's `/opt/fil` build uses **glibc (LGPL-2.1-or-later)**, and `projects/` / `pizlix/` hold ports
under many licenses, some GPL. **Out of scope.** Only the paths listed in `third_party/LICENSES.md`
→ Upstream inventory are candidate sources.

## Files

- `LICENSE-APACHE`: the Apache-2.0 text + LLVM Exceptions, taken verbatim from llvm-project's
  `LICENSE.TXT` (the llvm-specific header line and third-party trailer are removed).
- `LICENSE-MIT`: MIT, `Copyright (c) 2026 Jon Marcum`.
- `NOTICE`: attribution for all upstreams + the binary-distribution warning.
- `third_party/<component>/`: **staged** upstream license texts, verified 2026-09-18.
- `third_party/LICENSES.md`: **the operational source of truth** (obligations table, adoption
  checklist, Component Ledger, inventory).

## Contribution terms

Inbound = outbound: contributions are dual-licensed as above unless explicitly stated (in
`README.md`).

## Gotchas worth remembering

- **Verify per file, not per repo.** GitHub reports Fil-C as `NOASSERTION`. The README states the
  split: compiler = LLVM license, runtime = PAS license (BSD-2), musl = MIT. That was confirmed from
  the file headers of `FilPizlonator.cpp`, `filc_runtime.c` and `stdfil.h` on 2026-09-18.
- **libpas's LICENSE also contains a BSD-3-Clause section** (OpenSSH `setproctitle`). The third
  clause, no endorsement, applies to that portion.
- Zig moved its canonical repo to **Codeberg** (`codeberg.org/ziglang/zig`). The GitHub mirror's
  newest tag is 0.15.2. The license (MIT) is unchanged.
