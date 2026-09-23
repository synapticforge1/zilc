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
| version | **`0.3.0`** | P1 + P2 shipped; cadence in `releasing.md` |
| **`zig build gate`** | **4/4** | 🎯 **the safety gate** — every example traps at the right file:line. **Inversion-tested.** ⚠️ SKIPS (exit 0) without Fil-C |
| `zig build test` | 9/9 | incl. the IR-rewrite unit tests, which caught two real bugs |
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
| [architecture.md](architecture.md) | Target pipeline (frontend → LLVM IR → zilc pass → `zilc_runtime`), the InvisiCap and FUGC components, and what exists today. |
| [design-decisions.md](design-decisions.md) | Invariants, decisions made so far, and the **open questions** that must be settled with the owner. Zig 0.15.2 API + Windows build notes (0.15.2 is at `C:\zig\0.15.2`, not on PATH). |
| [upstream.md](upstream.md) | How zilc relates to Fil-C upstream: what to track, which files matter, pinned commit, and how to sync. |
| [licensing.md](licensing.md) | **License = `Apache-2.0 WITH LLVM-exception OR MIT`** (2026-09-18). Why, the runtime-linking rule, the copyleft exclusion. |
| [reference-projects.md](reference-projects.md) | Fil-C, LLVM, Zig: verified licenses, what to mine each for, adoption status. |
| [roadmap.md](roadmap.md) | P0 scaffold ✅ → **P1 feasibility milestone (agreed 2026-09-18, ⏸️ awaiting a Linux machine)** → P2 integrate the pass with Zig → P3 Zig runtime → P4 Zig-language fidelity → P5 C++. P1 lists the expected first breakages. |
| [security-model.md](security-model.md) | The safety guarantees being targeted (spatial, temporal, thread-safe capability updates), and what is explicitly out of scope. |
| [testing.md](testing.md) | Current gates (all green on Zig 0.15.2, with the exact commands) and the planned "every bug example must panic" gate. |
| [known-issues.md](known-issues.md) | 🔑 **KI-4 (2026-09-23): Fil-C's IR is a PATCHED-LLVM DIALECT** (`ni:0` + `datalayout_after_filc`), so stock IR cannot enter the pass — this decided the integration route. KI-1 ✅ resolved (WSL2 installed; `sudo` needs a password); KI-2 exFAT zig-cache; KI-3 LLVM 20 vs 21 skew. |
| [releasing.md](releasing.md) | **Version `0.3.0`** (P1 + P2 shipped), the four places the number lives, and the minor-per-phase cadence. |
| [best-practices.md](best-practices.md) | Method rules. Seeded from wazmrt, plus zilc's own (2026-09-18): verify toolchain versions in the build files **and** the binary; a minimum-version field is not a pin; no heredocs; Deno/Bun for scripts. |

## Related files outside cmem

- `README.md`: the public, user-facing doc. NOT project memory.
- `third_party/LICENSES.md`: the compliance ledger, adoption checklist and verified inventory.
- `LICENSE-APACHE` / `LICENSE-MIT` / `NOTICE`: the dual license texts and attribution notice.
