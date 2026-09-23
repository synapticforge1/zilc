# Known Issues — environment and project constraints

## ✅ KI-1 — RESOLVED 2026-09-23. WSL2 is installed; Fil-C runs on this machine

**Ubuntu 26.04.1 LTS on WSL2**, x86_64, 32 cores, 31 GB RAM, ~950 GB free, glibc 2.43. The earlier
IT prohibition no longer applies. Fil-C 0.685, Zig 0.15.2 and patchelf are installed under
`~/zilc-work/` (see `roadmap.md` P1 step 1). Fil-C itself is still Linux-only, which is why the work
happens there.

⚠️ **Two environment rules learned on 2026-09-23:**
- **`sudo` requires an interactive password**, so an agent cannot `apt install` anything. Use
  upstream prebuilt binaries into `$HOME` instead. That is how `patchelf` (needed by Fil-C's
  `setup.sh`) got installed.
- **PowerShell mangles inline shell text passed to `wsl.exe`** (`||`, quotes and `$HOME` all break).
  **Write the script to a file and run `wsl.exe -e sh <file>`.** The scratchpad is reachable from
  WSL under `/mnt/c/...`.

## ~~KI-1 (original) — Fil-C upstream is Linux-only~~ (2026-09-18, kept for context)

Fil-C's README: *"Fil-C only works on Linux/X86_64 or Linux/ARM64."* The earlier Darwin and
FreeBSD ports were dropped in favor of a faithful libc. This dev machine is **Windows 11**.
- **Impact:** building or running upstream Fil-C needs Linux. ✅ *Superseded 2026-09-23 — WSL2 is
  installed; see above.*
- Upstream publishes **prebuilt releases**, so the LLVM fork never needs building for the
  experiments: `filc-<ver>-linux-x86_64.tar.xz` (v0.685 was published 2026-09-16) at
  https://github.com/pizlonator/fil-c/releases.
- **Reopen condition:** if Windows becomes a zilc target, a Windows syscall/libc layer is new work
  that has no upstream to borrow from.

## KI-2 — `.zig-cache` on exFAT is poisoned after one build (inherited from wazmrt)

D: is exFAT. A `.zig-cache` there builds once, and every later build fails with a bare
`error: Unexpected` until the cache is deleted. **Reconfirmed in zilc 2026-09-18.**
- **Fix:** `ZIG_LOCAL_CACHE_DIR=C:\zig-cache\zilc` (or `--cache-dir`).
- `std.testing.tmpDir` uses `.zig-cache/tmp` **relative to the cwd**, not the configured cache.
  Filesystem tests may need an NTFS cwd:
  `cd C:\somewhere && zig build --build-file D:\…\zilc\build.zig test`.
- In wazmrt this took **four** misdiagnoses (hardware, antivirus, damaged volume) to find. Don't
  re-diagnose it.

## KI-3 — LLVM version skew: Zig 0.16 = clang 21.1.0, Fil-C = clang 20.1.8 (2026-09-18)

The pass is written against LLVM 20's APIs. ⚠️ **2026-09-23: the version match turns out to be
necessary for a different and larger reason than bitcode compatibility — Zig must eventually LINK
Fil-C's LLVM** (KI-4, `roadmap.md` P1 step 4), and Zig 0.15.2 requires LLVM 20, which Fil-C is.

**Workaround (verified at the source 2026-09-18): Zig 0.15.2 is LLVM 20.** Its `CMakeLists.txt`
requires `find_package(llvm 20)` / `clang 20` / `lld 20`. `Findllvm.cmake` rejects anything
below 20 or at 21 and above, and its bundled libc++ is `_LIBCPP_VERSION 200100` (20.1). Fil-C's
`cmake/Modules/LLVMVersion.cmake` is **20.1.8**. Same major version, so the IR is compatible.
Experiments use 0.15.2.

**Owner decision 2026-09-18: we do not port the pass to LLVM 21 ourselves.** When Fil-C moves to
a clang that Zig 0.16.0 covers, the whole repo converts to 0.16.0. **Reopen condition:** Fil-C's
`LLVMVersion.cmake` major becomes 21, checked at every upstream sync (`upstream.md` step 1).

✅ **Superseded 2026-09-18: the whole repo moved to 0.15.2** (owner: "for full compatibility").
The installed binary reports **clang 20.1.2**. When the switch condition fires, **the 0.16 port is
the reverse of that change.** `main.zig` goes back to `std.process.Init`/`std.Io`,
`minimum_zig_version` becomes `0.16.0`, and the Zig API notes in `design-decisions.md` get updated.

## 🔑 KI-4 — Fil-C's IR is a PATCHED-LLVM DIALECT. ⚠️ **PARTLY REVERSED SAME DAY — stock IR CAN enter it**

> ⚠️ **READ THE REVERSAL AT THE END OF THIS ENTRY BEFORE ACTING ON ANYTHING ABOVE IT.** The dialect
> facts below are all correct and still load-bearing. The *conclusion* drawn from them — "externally
> produced IR is not an entry point" — was **wrong**, and was falsified the same afternoon by the
> first P2 experiment. Kept in full, because the mistake is the lesson.

Fil-C's `FilPizlonatorPass` asserts on its input module (`FilPizlonator.cpp:16041-16046`):

```
DLBefore.getPointerSizeInBits(0) == 64
DLBefore.getPointerABIAlignment(0) == 8
DLBefore.isNonIntegralAddressSpace(0)        <-- stock LLVM cannot express this for AS 0
!DL.isNonIntegralAddressSpace(0)             <-- DL = M.getDataLayoutAfterFilC(), a Fil-C-only API
```

So a module entering the pass must carry **two** layouts:

```llvm
target datalayout = "e-m:e-ni:0-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target datalayout_after_filc = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
```

⚠️ **Position matters** (`ni:0` goes right after `m:e`): LLVM compares layout strings textually, so
appending `-ni:0` produces a *different* layout and fails the backend's match check. The exact
string was recovered from the error emitted by `clang -Xclang -disable-llvm-passes`.

**Consequences, all verified 2026-09-23 (`roadmap.md` P1 step 3):**
- Zig's `.ll` and `.bc` (any target, `-flto` or not) hit the `ni:0` assert.
- Hand-patching both layout lines gets **past** the assert and then **segfaults inside the pass** —
  the layout is a symptom of the dialect, not the whole of it.
- **Fil-C's clang cannot re-consume its own `-emit-llvm` output** (that output is post-pass, with
  `pizlonated_` symbols). There is no supported text-IR entry point at all.
- Therefore **an LLVM pass plugin in a stock LLVM is impossible too** — the dialect does not exist there.

**The route that survives:** build Zig against Fil-C's LLVM fork so Zig's own codegen emits the
dialect and runs the pass in-process. **Reopen condition:** if upstream ever documents an IR-level
entry point (or a `-fno-filc`-style pre-pass emit), re-test — it would restore the cheap route.

### ⚖️ How far from standard IR is it, exactly? (measured 2026-09-23, and it is NARROWER than the above implies)

Stock LLVM here = Zig 0.15.2's bundled clang (LLVM 21), fed each module by `.ll` extension:

| input | stock LLVM verdict |
| --- | --- |
| Fil-C's emitted IR, unmodified | ❌ `unknown target property` — **the `datalayout_after_filc` line, and nothing else** |
| the same file with only that line deleted | ✅ **accepted** |
| any module whose layout contains `ni:0` | ❌ `address space 0 cannot be non-integral` |
| the same with `ni:1` | ✅ accepted — **`ni` is standard; only `ni:0` is Fil-C's extension** |

🔑 **So Fil-C does NOT emit or consume "invalid" IR.** Its output is ordinary LLVM IR plus one extra
target-property line; its *input* requirement (`ni:0`) is the one thing stock LLVM refuses to
express — deliberately, since non-integral AS 0 is what forbids the optimizer from round-tripping
pointers through integers behind the pass's back. And Fil-C not re-reading its own output is a
**round-trip** mismatch (output carries the *after* layout, the pass wants the *before* one), not
malformedness.

🙂 **This is encouraging for P2:** if the divergence really is two layout lines plus the pass, then
teaching Zig's LLVM backend to emit them may be a small change, with everything else ordinary IR.
⚠️ Do not assume it — hand-patching those two lines still segfaulted inside the pass, so something
beyond the layout differs. Finding out *what* is P2's first experiment.

### ✅ THE REVERSAL (2026-09-23, P2 experiment 1) — **the two layout lines ARE enough**

| experiment | result |
| --- | --- |
| **hand-written** `.ll` (never touched by Fil-C's frontend) carrying both layout lines | ✅ **ACCEPTED** at `-O0` and `-O1` |
| Zig IR, layouts patched, **ReleaseSmall / ReleaseFast / ReleaseSafe** | ✅ **ACCEPTED** (37 / 161 / 4,007 lines) |
| Zig IR, layouts patched, **Debug** | ❌ segfault — 189,740 lines, **1,110 functions, 114 inline-asm blocks** |

🎓 **The segfault was never about "Zig IR" or about frontend provenance. It was about DEBUG-MODE
Zig IR**, and every earlier test happened to use Debug because that is Zig's default. One variable —
the optimization mode — was never varied, and a structural conclusion was drawn from a single
setting. *This is `best-practices.md` §2's "vary one thing at a time" all over again.*

**So the wrapper-driver route is ALIVE**: emit IR with stock Zig → rewrite two `target datalayout`
lines → hand it to Fil-C's clang. No Zig fork, no LLVM build. See `roadmap.md` P1/P2 for what that
already achieves, and KI-5/KI-6 for the two limits that remain.

### ✅ DEBUG MODE IS SUPPORTED NOW (2026-09-23, P2 item 1) — two concessions, and the cause is upstream's

**❌ Inline asm was NOT the cause.** Fil-C accepts `__asm__` in ordinary C *and* an `asm sideeffect`
call in a hand-written dialect module. 114 occurrences, all innocent — the prime suspect named in the
original entry was wrong.

**The actual shape of it, measured on identical Debug IR (189,741 lines, 1,110 functions):**

| what changed | result |
| --- | --- |
| `filc -O0` | ✅ **compiles** |
| `filc -O1` / `-O2` | ❌ segfault inside the pass |
| Zig `-fstrip` (11,326 lines, 163 defines) at `-O1` | ✅ compiles — but it removes **code as well as** the 54,636 `!DI` lines, so it proves nothing on its own |

🔑 **So it is an interaction between LLVM's OPTIMIZER and the pass on this module, not a construct
Fil-C refuses.** At `-O0` the same IR is fine. **The crash is upstream's**, and `tools/p2/llreduce.ts`
exists to shrink it into a report worth sending.

**What zilc does about it (`src/driver.zig`):** `-O Debug` now *works*, with two concessions applied
automatically and announced:

1. **`filc -O0`** for the instrumented IR — the segfault above.
2. **`-fno-stack-check`** on the Zig side. Zig's `__zig_probe_stack` lives in its compiler-rt, which
   never goes through the pass, so the link fails on it. Dropping probes is honest here: Fil-C's
   checks are what make the program safe and they do not rely on guard pages.

📏 **The cost is size: 13,766,024 bytes vs 127,424 for ReleaseSafe — 108×.** Same panic, same line.
`tools/p2/debug-mode.sh` runs both.

## 🔴 KI-5 — Zig's libc start code TRAPS under Fil-C: it walks the aux vector (2026-09-23)

A whole Zig program (`zig build-exe … -lc`, musl target) now **links and runs** under Fil-C — and
then panics **before reaching `main`**, in Zig's own start code:

```
filc safety error: cannot read pointer with null object.
    pointer: 0x…040,<null>            expected 4 bytes.
semantic origin:
    start.zig:547:21: start.expandStackSize (inlined)
    start.zig:599:24: main
```

**Why it is not a bug in Fil-C:** `expandStackSize` reads the ELF **auxiliary vector**, which is
found by walking off the end of `envp`. Fil-C gives `envp` a capability bounded to `envp` itself, so
stepping past its end is exactly the access the model forbids. Zig assumes a flat address space where
`argv`/`envp`/`auxv` are contiguous; **under Fil-C they are three separate capabilities.**

**This is the FIRST GENUINE Zig-vs-Fil-C SEMANTIC CONFLICT** — not a build-config problem.

Options, cheapest first:
1. ✅ **Avoid Zig's start code** — export a C-ABI `main` from Zig (`zig build-obj`) and let C, compiled
   by Fil-C, own startup. **This works today** (`roadmap.md` P2 Test 1) and is the shape zilc should
   ship first.
2. Patch `start.zig` for a Fil-C target so it does not touch auxv (upstream Zig has no such target;
   this is the "zilc target" in the long run).
3. Ask upstream Fil-C for an auxv accessor (`stdfil.h` may already expose one — **unchecked**).

## 🟡 KI-6 — Zig must target **musl**, not gnu, or the link fails on `*64` symbols (2026-09-23)

Fil-C's libc is **musl**. With `-target x86_64-linux-gnu`, Zig emits glibc-style names and the link
fails with `undefined reference to pizlonated_getrlimit64 / setrlimit64 / mmap64 / getcontext`.
**Use `-target x86_64-linux-musl`** and they resolve. (The `pizlonated_` prefix in the error is just
the pass's renaming — a plain "missing libc symbol", not a Fil-C-specific failure.)
