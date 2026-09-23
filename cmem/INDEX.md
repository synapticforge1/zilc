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

## 🏁 STATE — 2026-09-23. ✅ **THE P1 MILESTONE IS MET. Zig ⇄ C memory safety works through Fil-C today.**

🎯 **Proven end to end (`roadmap.md` P2, `tools/p2/milestone.sh`):** C `malloc`s 4 ints, calls a
**Zig** function that writes one past the end, and Fil-C panics with

```
filc safety error: cannot write pointer with ptr >= upper.
semantic origin:  tiny.zig:4:6: zig_add   ←  c_caller.c:15:5: main
```

**The fault is attributed to the Zig line from a C call site** — the capability survived the language
boundary. ✅ **And it needs no Zig fork and no LLVM build**: stock Zig emits IR, a two-line
`target datalayout` rewrite puts it in Fil-C's dialect, Fil-C's clang does the rest.

✅ **Two of the three limits are gone as of 2026-09-23 evening:** `-O Debug` works (compiled at `filc -O0`,
108× size, KI-4) and **whole Zig programs run** via a generated C-ABI entry shim (KI-5). The
remaining requirement is `-target x86_64-linux-musl` (KI-6).

🔑 **KI-5's cause, once read rather than guessed: Zig forges a pointer from an integer** —
`@ptrFromInt(getauxval(AT_PHDR))` in `start.zig`. InvisiCap forbids that outright, so the fix is to
keep `start.zig` out of the build, not to bound anything. ⚠️ **`@ptrFromInt` is ordinary Zig, used
across `std`** — every use is a potential trap site, which is P4's problem.

⚠️ **The morning's verdict, "the cheap route is dead", was WRONG and is kept in `roadmap.md` P1 step 3
as a cautionary tale.** Every failing run had used Zig's default Debug mode; nobody varied it.

## ~~STATE — 2026-09-23 (morning)~~ — superseded by the section above

**2026-09-18 (session 1):** scaffold + dual license + staged upstream licenses (`0.1.0`); goals
discussion settled the first milestone and 3 of 6 open questions; repo pinned to **Zig 0.15.2**.

**2026-09-23 (session 2): WSL2 arrived, so P1 ran the same day.** Fil-C 0.685 + Zig 0.15.2 are
installed under `~/zilc-work/` in WSL, Fil-C's panics on our two bug examples are **recorded as the
gate's expected output** (`testing.md`), and the spike answered open question 1 **by experiment**:

🔑 **Fil-C's IR is a patched-LLVM dialect** — it demands `ni:0` (non-integral address space 0) plus a
`datalayout_after_filc` directive, and Fil-C's clang cannot even re-consume its own emitted IR. So
"stock Zig emits IR → `filcc` runs the pass" **cannot work**, and neither can a pass plugin in a
stock LLVM. ▶️ **The surviving route is building Zig against Fil-C's LLVM 20 fork.** Full evidence:
`known-issues.md` **KI-4** and `roadmap.md` P1 step 3.

| gate (all on Zig 0.15.2) | value | note |
| --- | --- | --- |
| version | `0.1.0` | `build.zig.zon` + `src/root.zig` |
| `zig build` | green | CLI `zilc` + static `zilc_runtime.lib` + `zilc.h` |
| `zig build test` | 1/1 | version-string test only |
| `zig build capi-smoke` | green | C client links the runtime via `zilc.h` |
| `zig build baseline` | green | bug examples compiled with plain `zig cc`: **OOB write runs "fine", exit 0** (the bug zilc exists to catch) |
| third-party code | **none incorporated** | license texts staged; ledger EMPTY |

**Toolchain: Zig 0.15.2, for the whole repo** (owner, 2026-09-18). It bundles clang **20.1.2**,
the same major as Fil-C's LLVM **20.1.8**. ⚠️ **It is at `C:\zig\0.15.2\zig.exe`, not on PATH.**
Bare `zig` is scoop's **0.16.0** (kept for wazmrt), and it fails to build zilc. zilc moves to 0.16
only when Fil-C reaches LLVM 21. See `known-issues.md` KI-3.

```powershell
$env:ZIG_LOCAL_CACHE_DIR = 'C:\zig-cache\zilc'
& C:\zig\0.15.2\zig.exe build test
```

### 🎯 NEXT — write the `zilc` driver, then Debug mode and startup

1. **The driver.** Automate emit → layout rewrite → `filc clang` so the milestone reproduces with
   one command instead of `tools/p2/*.sh`. **This is the next code to write**, and the placeholder
   CLI in `src/main.zig` is where it goes.
2. **Debug mode** (KI-4): find what crashes the pass — 114 inline-asm blocks are the suspect. Debug
   is where Zig's own safety checks live, so it cannot stay unsupported.
3. **Startup** (KI-5): keep C `main`, or patch `start.zig` for a Fil-C target.
4. Building Zig against Fil-C's LLVM is now a **reserve** option, not the entry price.

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
| [releasing.md](releasing.md) | Version (`0.1.0`), where the number lives, cadence. |
| [best-practices.md](best-practices.md) | Method rules. Seeded from wazmrt, plus zilc's own (2026-09-18): verify toolchain versions in the build files **and** the binary; a minimum-version field is not a pin; no heredocs; Deno/Bun for scripts. |

## Related files outside cmem

- `README.md`: the public, user-facing doc. NOT project memory.
- `third_party/LICENSES.md`: the compliance ledger, adoption checklist and verified inventory.
- `LICENSE-APACHE` / `LICENSE-MIT` / `NOTICE`: the dual license texts and attribution notice.
