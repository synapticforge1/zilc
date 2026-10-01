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

🎯 **Owner goal 2026-09-30:** after the initial work, zilc moves to the *latest* Zig with minimal
layout rework. The LLVM match binds only the Zig that compiles **user code**, not the one that
builds zilc (`design-decisions.md` invariant 4).

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
Fil-C refuses.** At `-O0` the same IR is fine. **The crash is upstream's.**

#### 🔬 Reduced to 8 functions — and four hypotheses died on the way (2026-09-23)

`tools/p2/llreduce.ts` (delta debugging, 1,648 compiler runs) took the module from **1,110 functions
to 8**, then a metadata strip took it from 60,602 lines to **9,773**. A second pass confirms all 8
are required. The repro and its reproduction steps: **`tools/p2/repro/`**.

**The 8 are Zig's `std.compress.flate.Decompress` Huffman decoder** — Debug builds pull it in because
Zig's stack-trace printer decompresses DWARF.

| hypothesis | verdict |
| --- | --- |
| inline asm | ❌ Fil-C compiles `__asm__` in C and `asm sideeffect` in IR |
| debug metadata / `!DI` records | ❌ stripped every one; **still crashes** |
| odd-width ints (`i46` in an `sret`) | ❌ a hand-written `i46`-through-`sret` module builds at `-O0/-O1/-O2` |
| "this Zig code is unsupported" | ❌ the same flate code in **ReleaseSafe** (146,488 lines) compiles fine |

**What is left:** the *unoptimized shape* of that code plus LLVM's `-O1` pipeline around the pass.
Narrowing further needs line-level reduction or a debug build of Fil-C's clang — neither of which
zilc needs, since the driver compiles Debug IR at `-O0`.

📤 **A draft upstream issue is written but NOT filed** (`tools/p2/repro/UPSTREAM-REPORT.md`).
Filing it is the owner's call.

**What zilc does about it (`src/driver.zig`):** `-O Debug` now *works*, with two concessions applied
automatically and announced:

1. **`filc -O0`** for the instrumented IR — the segfault above.
2. **`-fno-stack-check`** on the Zig side. Zig's `__zig_probe_stack` lives in its compiler-rt, which
   never goes through the pass, so the link fails on it. Dropping probes is honest here: Fil-C's
   checks are what make the program safe and they do not rely on guard pages.

📏 **The cost is size: 13,766,024 bytes vs 127,424 for ReleaseSafe — 108×.** Same panic, same line.
`tools/p2/debug-mode.sh` runs both.

## ✅ KI-5 — Zig's start code traps under Fil-C. **SOLVED 2026-09-23 with a generated entry shim**

> ⚠️ **The cause below was stated wrongly at first.** "It walks off the end of `envp` to find auxv"
> was a guess from the function name. Reading `start.zig` shows the real mechanism, which is both
> simpler and more fundamental — see **What it actually is**.

A whole Zig program (`zig build-exe … -lc`, musl target) now **links and runs** under Fil-C — and
then panics **before reaching `main`**, in Zig's own start code:

```
filc safety error: cannot read pointer with null object.
    pointer: 0x…040,<null>            expected 4 bytes.
semantic origin:
    start.zig:547:21: start.expandStackSize (inlined)
    start.zig:599:24: main
```

### 🔑 What it actually is: **Zig forges a pointer from an integer**

`lib/std/start.zig`, the libc entry path:

```zig
const at_phdr = std.c.getauxval(elf.AT_PHDR);
const at_phnum = std.c.getauxval(elf.AT_PHNUM);
const phdrs = (@as([*]elf.Phdr, @ptrFromInt(at_phdr)))[0..at_phnum];
expandStackSize(phdrs);            // ← first read of phdrs traps
```

`getauxval` returns an **integer**. `@ptrFromInt` turns it into a pointer, and under InvisiCap a
pointer made from an integer has **no capability at all** — hence `cannot read pointer with null
object`. This is not a bounds violation; it is the single thing the capability model forbids
outright, and it is what "integers cannot be forged into pointers" means in practice
(`security-model.md`).

**It is the FIRST GENUINE Zig-vs-Fil-C SEMANTIC CONFLICT**, and it is not fixable by configuration:
any code that reconstructs a pointer from an integer address is unrunnable under Fil-C, by design.
⚠️ **Worth remembering for P4:** Zig's `@ptrFromInt` is legal Zig, used across `std` for exactly this
kind of platform plumbing. Each use is a potential trap site.

### ✅ The fix that shipped: a generated C-ABI entry shim

`zilc build hello.zig` now works with **no C file**. The driver writes `zilc_entry.zig`, makes *it*
the root module and the user's file a module named `user`, so **Zig never pulls `start.zig` in**:

```
zig build-obj … -lc --dep user -Mroot=<tmp>/zilc_entry.zig -Muser=hello.zig
```

The shim exports a plain C `main`, sets `std.os.argv`, and calls the user's `main`, handling `void`,
`u8` and error-union returns. Fil-C's musl start-up calls it like any C program. Measured:

```
$ zilc build examples/whole_program/hello.zig -o hello && ./hello
hello from a whole Zig program
filc safety error: cannot read pointer with ptr >= upper.
semantic origin:  hello.zig:25:6: hello.main (inlined)  ←  zilc_entry.zig:16:22: main      exit 133
```

`--entry auto|zig|c` overrides the choice; `auto` picks the shim when a lone `.zig` input declares
`pub fn main` and no C/C++ input is present. `tools/p2/whole-program.sh` runs it.

⚠️ **What this does NOT do:** the program gets no `std.os.environ`, no Zig stack-size expansion, and
no Zig segfault handler. Nothing that has been tested needs them, and Fil-C's own checks replace the
last one — but a program that reads `std.os.environ` will find it empty until the shim sets it.

## 🟡 KI-6 — Zig must target **musl**, not gnu, or the link fails on `*64` symbols (2026-09-23)

Fil-C's libc is **musl**. With `-target x86_64-linux-gnu`, Zig emits glibc-style names and the link
fails with `undefined reference to pizlonated_getrlimit64 / setrlimit64 / mmap64 / getcontext`.
**Use `-target x86_64-linux-musl`** and they resolve. (The `pizlonated_` prefix in the error is just
the pass's renaming — a plain "missing libc symbol", not a Fil-C-specific failure.)

## ◐ KI-7 — Zig's std makes RAW `syscall` asm even with `-lc`; Fil-C refuses it (2026-09-30). **MOSTLY FIXED the same day**: rewritten to the checked `zilc_syscall` helper; Zig OK 26 → 45/78, no syscall-asm traps left. Remaining: `getcontext` (std level)

Found by the `tests/basics` corpus: **~23 of 78 Zig programs trap at run time**, even
`01_hello-world`. Fil-C: `cannot handle inline asm (unsupported mnemonic for safe inline asm: syscall)`.
The system call numbers show which paths bypass libc on Linux even when libc is linked:
**186 `gettid`**, **202 `futex`**, **230 `clock_nanosleep`**.

Hello-world's backtrace: `std.debug.print` → `debug.lockStderrWriter` → `Progress.lockStderrWriter`
→ `Thread.Mutex.Recursive.lock` → `Thread.getCurrentId` → `LinuxThreadImpl.getCurrentId` →
`linux.gettid` → `syscall0`. **So `std.debug.print` itself cannot run under zilc today.** The gate's
`hello.zig` passes only because it never takes that lock.

- **Why it's P4:** it is Zig std talking to the kernel behind libc's back, which a checked world
  cannot allow. The same family as KI-5.
- ⚠️ **It is also a GC hazard (from the design docs, `filc-abi.md` §5b):** a raw `futex` or
  `clock_nanosleep` blocks **without exiting**, so FUGC's soft handshakes would wait on that thread
  forever. Routing through the runtime is **required**.
- 🔸 **The one asm block the rewrite cannot touch: `std.debug`'s `getcontext`**, a long asm sequence
  that stores every register into a context struct, with a `syscall` (`rt_sigprocmask`) inside, for
  stack traces. Its problem is not the syscall but **copying raw registers**, which can never carry
  capabilities, so no rewrite of it can be safe. **The safe equivalent exists at a higher level:**
  Fil-C's `stdfil.h` has **`zdump_stack()`**, **`zstack_scan()`** (frames with function, file and
  line) and **`zfiber_context_getcontext()`**. The fix belongs in **std, not the IR**: zilc's entry
  shim is the root module, so it can define Zig's root `panic` override (and stack-trace hooks) to
  report through `zdump_stack`/`zstack_scan`, and `getcontext` is never reached. It is reached only
  on panic and stack-trace paths. (Owner asked, 2026-09-30.) ✅ **Done the same day for whole
  programs:** the entry shim defines `pub const panic = std.debug.FullPanic(zilcPanic)`, which calls
  Fil-C's **`zerror`**. `42_panic` now prints `zig panic: a problem` with Fil-C's trace naming
  `panic.zig:6:5`, instead of a stack overflow in the trace code. ⚠️ **Not yet covered: library mode**
  (C owns `main`), where the user's file is the root, so the default handler still applies.
- **Most zilc-shaped fix (to verify):** extend the IR rewrite (`src/ir.zig`) to replace
  `asm sideeffect "syscall"` with a call to libc's `syscall(n, …)`, which in Fil-C goes through the
  checked `zsys_*` layer (`filc-abi.md`). It needs checking that Fil-C's `syscall()` accepts these
  numbers, and that pointer arguments (futex addresses) keep their capabilities.

## ✅ KI-8 — `__zig_probe_stack` undefined in ReleaseSafe too. **FIXED 2026-09-30**: `-fno-stack-check` in every mode. Zig builds under zilc went from 50/78 to 77/78

**27 of 28 ReleaseSafe build failures** in `tests/basics` (38 references): functions with large
frames (`std/debug/SelfInfo.zig` stack traces, `std/fs/Dir.zig` path buffers) get Zig's stack probe,
which lives in compiler-rt and never goes through the pass. The driver passes `-fno-stack-check`
**only for Debug** (KI-4). ReleaseSmall avoids most of it because it drops stack-trace code (77/78
built). **Fix: pass `-fno-stack-check` in every mode.** It's safe, because Fil-C checks the stack at
every function entry (`cmp rsp, [thread]`, `filc-abi.md` §3).

## ✅ KI-9 — 128-bit float helpers missing (`__multf3`, `roundq`, …). **FIXED 2026-09-30**: when a module uses `fp128`, the driver compiles the 26 f128 compiler-rt files through the pass (checked code), internalizing every export but the f128 symbols. `48_json` now links

`48_json` (float parsing uses `f128`) fails to link: `pizlonated___multf3`, `__divtf3`, `__fixtfti`,
`__floatuntitf`, comparison helpers and `roundq`. These live in compiler-rt, which is not compiled
through the pass, and Fil-C's libc does not provide them. The fix needs compiler-rt (or those
functions) built through the pass. P3/P4.

## 🟡 KI-10 — `pthread_join` traps on a pointer with no capability (2026-09-30)

`33_mutexes` and one more threading example: `cannot read pointer with null object` in musl's
`__pthread_timedjoin_np`. Most likely Zig's std keeps the `pthread_t` it got from `pthread_create`
in a form that loses its capability (an integer round trip). The same family as KI-5 and P4's
`@ptrFromInt` question. ◐ **The mechanism is confirmed by the design docs** (`gimso_semantics.md`,
`filc-abi.md` "inttoptr"): an integer that comes from a **load or a call** always turns back into a
pointer with a **null capability**. The exact Zig code path is still unverified.

Also seen, not yet analysed: `42_panic` hits `stack overflow` in Zig's panic path under zilc, and
`76_signals` accesses a pointer with no capability.
