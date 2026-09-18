# Design Decisions & Invariants

## Decisions made

| Date | Decision | Why |
| --- | --- | --- |
| 2026-09-18 | Project layout and `cmem/` policy mirror wazmrt | Owner request; proven structure |
| 2026-09-18 | License `Apache-2.0 WITH LLVM-exception OR MIT` | Compatible with all three upstreams; see `licensing.md` |
| ~~2026-09-18~~ | ~~Target Zig **0.16.0**~~. **Superseded the same day**, see the full-compatibility row below | Was: installed toolchain; matched wazmrt |
| 2026-09-18 | Upstream = Fil-C `deluge` branch; not fetched into this repo yet | The Fil-C tree is a full llvm-project fork (multi-GB). How to consume it is an open question below |
| 2026-09-18 | **First milestone (owner-agreed):** a Zig program plus a C library, compiled through Fil-C's *existing* pass and runtime, panics correctly on OOB/UAF | Tests the premise (Zig IR survives GIMSO) before any zilc code. The Zig runtime rewrite and C++ come later |
| 2026-09-18 | **No WSL on the Windows dev machine** (not permitted by IT). Fil-C work happens on a **separate Linux machine**, at a later date | Owner. Windows stays the dev box for zilc's own Zig code and cmem |
| 2026-09-18 | **The WHOLE repo is on Zig 0.15.2**, not just the experiments ("for full compatibility", owner). `minimum_zig_version = "0.15.2"`, and `main.zig` was ported off the 0.16 APIs | 0.15.2 bundles **clang 20.1.2** (checked with `zig cc --version`), the same major as Fil-C 20.1.8. One Zig for everything: nothing in the repo can drift onto an LLVM the pass cannot read |
| 2026-09-18 | **Follow Fil-C's LLVM version; never port the pass ahead of upstream.** zilc stays on Zig 0.15.2 until Fil-C moves to LLVM 21, then the whole repo converts to 0.16.0 | Owner. Porting 17k lines of FilPizlonator to a newer LLVM ourselves would fork us from upstream. **Switch condition:** Fil-C's `cmake/Modules/LLVMVersion.cmake` reports major 21 (checked at every upstream sync, `upstream.md`) |

## Invariants (proposed. Confirm with the owner.)

1. **Semantics come from Fil-C.** Where zilc and Fil-C disagree on what a program may do, Fil-C's
   documented GIMSO semantics win unless a deviation is recorded here with its reason.
2. **Every bug example must panic.** Anything in `examples/` that is UB under `zig build baseline`
   must be a deterministic trap under the safe build. A new unsafe pattern gets an example first.
3. **Our own files carry `SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT`.**
   Adapted files carry the upstream's SPDX (`third_party/LICENSES.md`).

## ❓ Open questions — to settle with the owner

These shape everything else. Listed roughly in order of how much they constrain the rest.

1. **How does the pass get into Zig?**
   - (a) **Patch the Zig compiler** and ship a custom `zig`. This matches the "single binary" goal
     but means maintaining a fork of Zig *and* Fil-C.
   - (b) **An LLVM pass plugin** (`-fpass-plugin=` for `zig cc`). Zig's own codegen does not expose
     a plugin hook today, so this covers C/C++ only.
   - (c) **A wrapper driver** (`zilc cc …`). It emits bitcode via `zig cc -emit-llvm` /
     `zig build-obj -femit-llvm-bc`, runs the pass with a separately-built LLVM, then links.
     Nothing is patched, but it needs its own LLVM build.
2. **LLVM version skew.** ✅ *Settled 2026-09-18 (owner).* zilc follows Fil-C's LLVM version and
   does not port the pass itself. Zig 0.15.2 (LLVM 20) is used until Fil-C moves to a clang that
   Zig 0.16.0 covers (LLVM 21), and the conversion happens then. See the decision table above.
3. **Runtime: port or rewrite?** Porting `libpas`/`filc_runtime.c` to Zig is faster but carries
   BSD-2-Clause into every user binary (`licensing.md`). A clean-room Zig runtime avoids that but is
   far more work.
4. **Platform.** ◐ *Partly settled 2026-09-18.* **Linux x86_64 is the first target**, developed on
   a separate Linux machine (no WSL here). Whether Windows is ever a *target* remains open: it would
   need a new syscall/libc layer that Fil-C never had.
5. **Zig-language semantics.** ✅ *Settled 2026-09-18.* The first milestone includes Zig **as a
   source language** from the start, via the existing Fil-C pass (see the milestone decision
   above). It is not C-only. Since GIMSO accepts any LLVM IR, putting Zig first is how the premise
   gets tested.
6. **Relationship to upstream in git.** Options: vendor Fil-C as a subtree, keep a separate fork and
   reference it, or copy only the pass + runtime files. See `upstream.md`.

## Zig 0.15.2 API notes (this project targets 0.15.2)

- `pub fn main() !void`; args via `std.process.argsAlloc(arena)`.
- stdout (post-"Writergate" I/O): `var w = std.fs.File.stdout().writer(&buf); const out = &w.interface;`
  and **flush before returning**.
- `build.zig`: `addExecutable`/`addLibrary(.{ .linkage = … })`/`addTest` all take `.root_module`.
  That is the same shape as 0.16, so `build.zig` needed no change in the port.
- `build.zig.zon` requires a `.fingerprint`. Zig prints a suggested value if it is missing.
- ⚠️ **Don't copy code from wazmrt without checking.** wazmrt is on **0.16** (`std.process.Init`,
  `std.Io`), and its `main`/I/O code does not compile here.
- ⚠️ `minimum_zig_version` only rejects *older* Zigs. **Zig 0.16 is not rejected up front; it fails
  with a compile error in `main.zig`.** Those errors mean the wrong Zig, not a code bug.

## Windows build gotchas (dev machine: win32, D: = exFAT)

- **Zig 0.15.2 lives at `C:\zig\0.15.2\zig.exe`** (official zip, SHA-256 verified against
  ziglang.org's `index.json`, installed 2026-09-18). It is **not on PATH**. Bare `zig` is the scoop
  shim, which is **0.16.0**, and wazmrt still needs that. So invoke by full path, or put
  `C:\zig\0.15.2` first on PATH for the session.
- `ZIG_LOCAL_CACHE_DIR=C:\zig-cache\zilc` is required (KI-2).
- The repo lives on exFAT, so git reports *dubious ownership*. Use
  `git -c safe.directory='*' …`, or add the path to the global `safe.directory` once.
- Writing Zig multiline strings (`\\`) through a bash heredoc can drop a backslash. Write Zig
  sources with the file tools instead.
