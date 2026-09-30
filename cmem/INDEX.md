# cmem — Portable Project Memory for zilc

This folder is the **authoritative, portable project memory** for `zilc`. It lives inside the
project tree, so it travels with the project (USB drive, clones) and is **committed to git**, unlike
a machine-local `CLAUDE.md`.

**Format:** plain Markdown. One focused topic file per domain, so any single concern can be reviewed
and revised without wading through one giant file. Keep files small and single-topic.

Modeled on the `cmem/` of the sibling project `wazmrt`
(`../wazmrt/cmem`), which is the template
for structure and policy.

---

## 🆕 2026-09-30 — the Zig runtime and other platforms now have a plan (no version bump)

- **Decided (owner):** the Zig-native runtime (P3) is built **on Linux first, checked against
  Fil-C**. Fil-C's pass and checked musl stay fixed; the runtime is swapped one layer at a time, and
  every gate case must match under both runtimes. The pass is **not** ported (`design-decisions.md`).
- **Shipped:** `zilc build --runtime filc|zig`. `filc` is the default; **`zig` is reserved and
  refused** until the Zig runtime is ready for testing. Tests **10/10**, gate **4/4** re-run.
- **Measured:** Fil-C's runtime contract. `libpizlo` exports 294 `filc_*` (pass → runtime), 1,032
  allocator/GC, and 335 `zsys_*` (the OS boundary). Details: `architecture.md` "The runtime contract".
- **Proposed, not adopted:** **P6 — other platforms**. Safe Zig on the major 64-bit OSes, safe C on
  Linux first. Zig's portability covers the runtime, but not the per-OS checked wrappers or a safe
  libc (`roadmap.md` P6, `design-decisions.md` open question #4).
- ▶️ **NEXT, the owner picks:** the **`zsys_write` spike** (`roadmap.md` P3: learns Fil-C's
  internal calling convention and the linking question) or **P4**. ⚠️ Before any runtime code:
  settle open question #3, port vs. clean-room rewrite.
- 🎯 **Goal (owner):** after the initial work, move to the **latest Zig with the least rework of
  the file layout**. Design for it now (`design-decisions.md` invariant 4): keep version-sensitive
  std calls few (about 31 sites today), and remember there are **two Zigs**, the one that builds
  zilc and the one that compiles user code, and only the second is pinned by Fil-C's LLVM.
- 🔄 **Upgrade procedure (owner):** **A** follow Fil-C to the Zig with the matching LLVM (the
  reference) → **B** port to the latest Zig if different, and require identical gate results →
  **C** benchmark comparison between versions. `upstream.md` "Upgrade procedure". The benchmark
  suite doesn't exist yet (`testing.md`).
- 🔖 **Versioning (owner), APPLIED: the version is now `0.15.2-3`**, `<Zig line>-<zilc
  release>` (was `0.3.0`). Spelling verified with Zig's parser (`0.15.2_3` rejected: Zig reads it as
  `0.15.23`). **No 1.0, ever**: only `-N` advances, and **`N` restarts at 1 for every new Zig
  version, patch releases included** (e.g. `0.16.1-1`, `0.16.2-1`). Scheme fully settled
  (`releasing.md`).
- 🧭 **Lines and basis (owner):** the Zig part names the Zig a line is **built with**, not the Zig
  user code needs (corrected the same day; `root.zig`'s constant is now `zig_line`). The
  **reference line** tracks Fil-C's LLVM. Each **latest line** is ported from the newest reference
  release and names it as its **basis** (`0.16.2-1`, basis `0.15.2-100`). Port notes go in
  `cmem/ports/`. ⚠️ There's no release-notes file yet, and `zilc --version` should show the
  user-code Zig and the Fil-C release.
- 🧪 **`tests/basics`: 156 correct programs (owner's C + Zig lessons), 2026-09-30 → `testing.md`.**
  **C: 78/78 build and 77/78 run identically under zilc** (the one difference is `abort()` exiting
  133). **Zig 0.15.2: all 78 build and run with plain Zig, but only 24/78 run under zilc**, all
  because of std: **KI-7** raw `syscall` asm (even `std.debug.print`), **KI-8** `__zig_probe_stack`
  in ReleaseSafe (an easy driver fix), **KI-9** f128 helpers, **KI-10** `pthread_join`. Sizes: C
  zilc is 0.86× Zig ReleaseSmall stripped. Zig zilc is 1.26× ReleaseSafe and 4.36× ReleaseSmall,
  stripped. Every zilc program also needs a ~20 MB shared runtime. Licence: CC BY 3.0 via Go by
  Example, test-only, first ledger entry.
- 🔭 **P3 SCOPING STARTED (2026-09-30), on 0.15.2 → `filc-abi.md`.** Fil-C's runtime ABI was
  decoded from post-pass IR, headers and binaries, **not runtime source**. `pizlonated_X` is a
  *getter* returning a **function object**; calls use a fast or generic entry through the thread's
  cc buffers; the header word at `lower−8` holds the aux pointer and object kind. **This reorders P3:
  the shared ABI core is step 0**, before any `zsys_*`. Overriding by linking looks workable (not
  yet run). It's also evidence that a **clean-room** runtime is feasible (open question #3).
  **Next:** read upstream's design docs to close the 🔸 gaps. Probes: `tools/p3/`.
- 🔒 **STAY ON ZIG 0.15.2 UNTIL THERE IS A STABLE BASE (owner).** A 0.16.0 trial port was
  stopped. Its facts are in `ports/README.md` "Scouting": Fil-C head is still LLVM 20.1.8, latest
  Zig is 0.16.0 (clang 21), and Fil-C ships ARM64 builds.
- 🌿 **One git branch per Zig line (owner), named `v<zig>`:** `main` is the base (the reference
  line), and **`cmem/` is authoritative on `main` only**, with port notes in `cmem/ports/`. The
  first release tag is **`v0.15.2-3`**, and branch **`v0.15.2`** was cut from the same commit
  (local, not pushed). ⚠️ Never create a tag named just `v0.15.2`; it would clash with the branch
  (`releasing.md`).
  Tests **11/11**, gate 4/4 after the change.
- **Loose ends unchanged:** the upstream Debug report (owner files it) and `std.os.environ` (KI-5).

## 🏁 STATE AT PAUSE — 2026-09-23. ✅ **P1 AND P2 ARE COMPLETE (`0.3.0`). zilc WORKS.**

**Read this first; it is the shortest true summary of where the project stands.**

🎯 **One command compiles Zig and C into a binary where memory-safety violations trap at a named
source line** — and it needs **no Zig fork and no LLVM build**:

```
$ zilc build examples/interop/c_caller.c examples/interop/bounds.zig -o interop && ./interop
in bounds ok, sum=6
filc safety error: cannot write pointer with ptr >= upper.
semantic origin:  bounds.zig:13:6: zig_add   ←  c_caller.c:26:5: main      exit 133
```

C allocated the memory, **Zig** overflowed it, and the capability survived the language boundary.

| gate | value | note |
| --- | --- | --- |
| version | **`0.15.2-3`** | zilc release 3, for Zig 0.15.2 (was `0.3.0`; scheme changed 2026-09-30, `releasing.md`) |
| **`zig build gate`** | **4/4** | 🎯 **the safety gate** — every example traps at the right file:line. **Inversion-tested.** ⚠️ SKIPS (exit 0) without Fil-C |
| `zig build test` | 11/11 | incl. the IR-rewrite unit tests, which caught two real bugs, the `--runtime zig` refusal, and the version round-trip (2026-09-30) |
| `zig build` | green | CLI `zilc` + static `zilc_runtime` + `zilc.h` |
| `zig build capi-smoke` | green | C client links the runtime via `zilc.h` |
| `zig build baseline` | green | the same bugs under plain `zig cc`: **exit 0, undetected** — the contrast the project exists for |
| third-party code | **none incorporated** | zilc *invokes* Fil-C and Zig; it ships neither. Ledger EMPTY |

### How it works, in three lines

1. Stock **Zig** emits LLVM IR (`zig build-obj -femit-llvm-ir`).
2. zilc rewrites **two `target datalayout` lines** into Fil-C's dialect (`src/ir.zig`).
3. **Fil-C's clang** runs the GIMSO pass and links. C/C++ inputs go straight to it.

### What was learned that the code does not say

- 🔑 **Fil-C's IR is a two-line dialect, not a different IR.** `ni:0` on address space 0 (which stock
  LLVM refuses on purpose) plus `datalayout_after_filc`. Everything else is ordinary LLVM IR — KI-4.
- 🔑 **Zig's `start.zig` cannot run under Fil-C**: `@ptrFromInt(getauxval(AT_PHDR))` forges a pointer
  from an integer, which InvisiCap forbids outright. zilc generates a C-ABI entry instead — KI-5.
  ⚠️ **`@ptrFromInt` is ordinary Zig used across `std`; every use is a potential trap site.** That is
  P4's problem, and the most likely source of future surprises.
- ⚠️ **A Debug-mode crash in Fil-C's pass is upstream's bug**, reduced from 1,110 functions to 8 and
  written up in `tools/p2/repro/`. **The owner will file it** (owner, 2026-09-23).
- 🎓 **Two wrong conclusions were published in this very file during the day and later overturned**
  ("the cheap route is dead"; "Zig walks off the end of envp"). Both are kept with their corrections,
  in `roadmap.md` P1 step 3 and KI-5. *The failure mode was the same twice: reasoning from one
  unvaried default, and from a function's name instead of its body.*

**Toolchain: Zig 0.15.2, for the whole repo** (owner, 2026-09-18). It bundles clang **20.1.2**,
the same major as Fil-C's LLVM **20.1.8**. ⚠️ **It is at `C:\zig\0.15.2\zig.exe`, not on PATH.**
Bare `zig` is scoop's **0.16.0** (kept for wazmrt), and it fails to build zilc. zilc moves to 0.16
only when Fil-C reaches LLVM 21. See `known-issues.md` KI-3.

```powershell
$env:ZIG_LOCAL_CACHE_DIR = 'C:\zig-cache\zilc'
& C:\zig\0.15.2\zig.exe build test
```

### 🎯 NEXT — **P4: Zig language fidelity** (nothing is blocked; this is a fresh start)

P1 and P2 are closed. The next work is making Zig's *language* safe under the target rather than
just its output: how slices, optionals, `allowzero`, `@ptrCast` and above all **`@ptrFromInt`** map
onto capabilities, and what breaks when real `std` code runs. See `roadmap.md` P4.

**Two loose ends, neither blocking:** the owner files the upstream report when ready, and the entry
shim leaves `std.os.environ` unset (nothing tested needs it yet — KI-5).

**Where to start next session:** `zig build gate` must be 4/4 before anything is believed. Run
`tools/run-gate-wsl.sh`, and read the first line — it prints `SKIPPED` rather than failing when the
Fil-C toolchain is missing.

### 🔒 Three things to know before touching anything

1. **Fil-C work happens in WSL2** (Ubuntu 26.04), under `~/zilc-work/`. ⚠️ **`sudo` needs an
   interactive password**, so install prebuilt binaries into `$HOME` rather than using `apt`. ⚠️
   **Pass shell text to WSL as a FILE** (`wsl.exe -e sh <file>`); PowerShell mangles it inline.
   See `known-issues.md` KI-1.
2. **D: is exFAT. Set `ZIG_LOCAL_CACHE_DIR=C:\zig-cache\zilc` before any `zig build`.** A
   `.zig-cache` on exFAT works for exactly one build, then fails with `error: Unexpected` until it
   is deleted. This was learned the hard way in wazmrt and reconfirmed here 2026-09-18. See
   `known-issues.md` KI-2.

---

## Policy (durable — adopted from wazmrt 2026-09-18)

- **`cmem/` is the single home for ALL project memory.** When the owner says "**update the project
  memory**", fold the latest decisions, found bugs, design changes and current state into the
  matching `cmem/` topic file(s), then refresh its one-line pointer in the Files table below.
  Convert relative dates to absolute. Update existing entries rather than duplicating them.
- **`README.md` is NOT project memory.** It is the public, user-facing document. Keep internal
  decision logs and post-mortems out of it.
- **`third_party/LICENSES.md` is the compliance source of truth.** `licensing.md` records the *why*;
  the ledger of actually-reused code lives in `third_party/LICENSES.md`. Keep them consistent.

### The "update the project memory" trigger (binding on every agent)

When the owner says **"update the project memory"** (or "update memory", "record this", "remember
this for the project"), do all of the following:

1. **Revise all relevant `cmem/` files.** Fold in the change, refresh the Files-table pointer,
   convert dates to absolute, and update entries instead of duplicating them.
2. **Sync `README.md` only where the change is user-relevant** (build, usage, status).
3. **If the work produced a transferable METHOD lesson, add it to
   [`best-practices.md`](best-practices.md)** as one bold rule plus a citation to the incident.

### The "adopt upstream code" trigger (binding on every agent)

Before incorporating or adapting code from Fil-C, LLVM or Zig (see `reference-projects.md`,
`upstream.md`), complete the **Adoption Checklist** in `third_party/LICENSES.md`, add a Component
Ledger entry, and update `reference-projects.md`. *Looking at* upstream code is free. *Copying or
porting* it always requires the ledger entry, and code that ends up in the **runtime** also needs
the runtime-linking rule checked.

---

## Files

| File | What it holds |
| --- | --- |
| [overview.md](overview.md) | What zilc is, repo layout, key files, build steps. |
| [vision.md](vision.md) | The goal: one `zig` binary that compiles Zig, C and C++ to a single memory-safe target. Owner's framing (via a Gemini discussion, 2026-09-18), with the claims that still need verifying marked. |
| [architecture.md](architecture.md) | Target pipeline (frontend → LLVM IR → zilc pass → `zilc_runtime`), the InvisiCap and FUGC components, what exists today, and 🔑 **the runtime contract measured 2026-09-30** (`libpizlo`'s four layers, by symbol count). |
| [design-decisions.md](design-decisions.md) | Invariants, decisions made so far, and the **open questions** that must be settled with the owner. **2026-09-30: Linux-first Zig runtime checked against Fil-C, `--runtime filc\|zig`, the pass not ported; #4 platform analysis; #3 now blocks runtime code.** Zig 0.15.2 API + Windows build notes (0.15.2 is at `C:\zig\0.15.2`, not on PATH). |
| [upstream.md](upstream.md) | How zilc relates to Fil-C upstream: what to track, which files matter, pinned commit, and 🔄 **the three-stage upgrade procedure (2026-09-30)**: Fil-C + compatible Zig → latest Zig → benchmarks. |
| [licensing.md](licensing.md) | **License = `Apache-2.0 WITH LLVM-exception OR MIT`** (2026-09-18). Why, the runtime-linking rule, the copyleft exclusion. |
| [reference-projects.md](reference-projects.md) | Fil-C, LLVM, Zig: verified licenses, what to mine each for, adoption status. |
| [roadmap.md](roadmap.md) | P0 ✅ → P1 ✅ → P2 ✅ (`0.3.0`) → **P3 Zig runtime (plan 2026-09-30: Linux first, checked against Fil-C, `zsys_*` first; next step the `zsys_write` spike)** → P4 Zig-language fidelity → P5 C++ → **P6 other platforms (proposed 2026-09-30)**. |
| [security-model.md](security-model.md) | The safety guarantees being targeted (spatial, temporal, thread-safe capability updates), and what is explicitly out of scope. |
| [testing.md](testing.md) | Current gates (gate 4/4, tests 10/10 on 2026-09-30, with the exact commands), the recorded expected panics, and the planned gates: `-Druntime=both`, the between-versions comparison, and the benchmark suite. |
| [known-issues.md](known-issues.md) | 🔑 **KI-4 (2026-09-23): Fil-C's IR is a PATCHED-LLVM DIALECT** (`ni:0` + `datalayout_after_filc`), so stock IR cannot enter the pass — this decided the integration route. KI-1 ✅ resolved (WSL2 installed; `sudo` needs a password); KI-2 exFAT zig-cache; KI-3 LLVM 20 vs 21 skew. |
| [releasing.md](releasing.md) | 🔖 **Version `0.15.2-3`** (applied 2026-09-30): `<Zig line>-<release>`, the **basis** each latest-line release names, how to bump it, why `.` and `_` were rejected, no 1.0, `-N` restarts at 1 per Zig version, the four places the number lives. The old minor-per-phase cadence is retired. |
| [filc-abi.md](filc-abi.md) | 🆕 2026-09-30. **Fil-C 0.685's runtime ABI as OBSERVED** (post-pass IR, headers, binaries; no runtime source): flight pointers, the object-header word, function objects and getters, the fast and generic calling convention, the thread layout, linking and overriding. What P3 must match, and its scoping consequences. |
| [ports/](ports/README.md) | 🆕 2026-09-30. **Port notes: one file per new Zig line, named by its first release** (`ports/0.16.2-1.md`): its basis, each API change and fix, the sites touched. `ports/README.md` holds the guide, the template, and, seeded with the 2026-09-18 0.16 → 0.15.2 move, whose API list is the 0.15.2 → 0.16 port in reverse. |
| [best-practices.md](best-practices.md) | Method rules. Seeded from wazmrt, plus zilc's own: verify toolchain versions in the build files **and** the binary; a minimum-version field is not a pin; no heredocs; Deno/Bun for scripts; (2026-09-30) measure the contract before planning a port; reserve a switch by refusing, never by falling back. |

## Related files outside cmem

- `README.md`: the public, user-facing doc. NOT project memory.
- `third_party/LICENSES.md`: the compliance ledger, adoption checklist and verified inventory.
- `LICENSE-APACHE` / `LICENSE-MIT` / `NOTICE`: the dual license texts and attribution notice.
