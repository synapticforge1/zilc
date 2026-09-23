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

## 🔑 KI-4 — Fil-C's IR is a PATCHED-LLVM DIALECT, so stock IR cannot enter it (2026-09-23)

**This is the most consequential finding so far; it killed one integration route and picked another.**

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
