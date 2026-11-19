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
- **Impact:** building or running upstream Fil-C needs Linux. ✅ _Superseded 2026-09-23 — WSL2 is
  installed; see above._
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

🎯 **Owner goal 2026-09-30:** after the initial work, zilc moves to the _latest_ Zig with minimal
layout rework. The LLVM match binds only the Zig that compiles **user code**, not the one that
builds zilc (`design-decisions.md` invariant 4).

**Owner decision 2026-09-18: we do not port the pass to LLVM 21 ourselves.** When Fil-C moves to
a clang that Zig 0.16.0 covers, the whole repo converts to 0.16.0. **Reopen condition:** Fil-C's
`LLVMVersion.cmake` major becomes 21, checked at every upstream sync (`upstream.md` step 1).

✅ **Superseded 2026-09-18: the whole repo moved to 0.15.2** (owner: "for full compatibility").
The installed binary reports **clang 20.1.2**. When the switch condition fires, **the 0.16 port is
the reverse of that change.** `main.zig` goes back to `std.process.Init`/`std.Io`,
`minimum_zig_version` becomes `0.16.0`, and the Zig API notes in `design-decisions.md` get updated.

> 📝 **Upstream policy (owner, 2026-09-30):** upstream defects are **noted for the record, not
> filed**. The KI-4 crash report in `tools/p2/repro/` stays as a record. Applies by default to
> KI-18 and the Zig notes too.

## 🔑 KI-4 — Fil-C's IR is a PATCHED-LLVM DIALECT. ⚠️ **PARTLY REVERSED SAME DAY — stock IR CAN enter it**

> ✅ **2026-10-01: the Debug `-O1` CRASH recorded in this entry is FIXED** by zilc's patched Fil-C
> clang. The cause was Fil-C's `indirectbr` lowering (copied from LLVM's `IndirectBrExpandPass`):
> with several `indirectbr`s in one function (Zig emits one per `continue :label`) it merged them
> into one `switch_bb` and left the destinations' phis stale. Debug now compiles at `-O1` like
> every mode, which also fixed KI-19. Full why, the failed first attempt, and the fix:
> `workarounds.md` KI-4. The dialect facts below are unaffected.

> ⚠️ **READ THE REVERSAL AT THE END OF THIS ENTRY BEFORE ACTING ON ANYTHING ABOVE IT.** The dialect
> facts below are all correct and still load-bearing. The _conclusion_ drawn from them — "externally
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
appending `-ni:0` produces a _different_ layout and fails the backend's match check. The exact
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

| input                                     | stock LLVM verdict                                                                    |
| ----------------------------------------- | ------------------------------------------------------------------------------------- |
| Fil-C's emitted IR, unmodified            | ❌ `unknown target property` — **the `datalayout_after_filc` line, and nothing else** |
| the same file with only that line deleted | ✅ **accepted**                                                                       |
| any module whose layout contains `ni:0`   | ❌ `address space 0 cannot be non-integral`                                           |
| the same with `ni:1`                      | ✅ accepted — **`ni` is standard; only `ni:0` is Fil-C's extension**                  |

🔑 **So Fil-C does NOT emit or consume "invalid" IR.** Its output is ordinary LLVM IR plus one extra
target-property line; its _input_ requirement (`ni:0`) is the one thing stock LLVM refuses to
express — deliberately, since non-integral AS 0 is what forbids the optimizer from round-tripping
pointers through integers behind the pass's back. And Fil-C not re-reading its own output is a
**round-trip** mismatch (output carries the _after_ layout, the pass wants the _before_ one), not
malformedness.

🙂 **This is encouraging for P2:** if the divergence really is two layout lines plus the pass, then
teaching Zig's LLVM backend to emit them may be a small change, with everything else ordinary IR.
⚠️ Do not assume it — hand-patching those two lines still segfaulted inside the pass, so something
beyond the layout differs. Finding out _what_ is P2's first experiment.

### ✅ THE REVERSAL (2026-09-23, P2 experiment 1) — **the two layout lines ARE enough**

| experiment                                                                            | result                                                                  |
| ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| **hand-written** `.ll` (never touched by Fil-C's frontend) carrying both layout lines | ✅ **ACCEPTED** at `-O0` and `-O1`                                      |
| Zig IR, layouts patched, **ReleaseSmall / ReleaseFast / ReleaseSafe**                 | ✅ **ACCEPTED** (37 / 161 / 4,007 lines)                                |
| Zig IR, layouts patched, **Debug**                                                    | ❌ segfault — 189,740 lines, **1,110 functions, 114 inline-asm blocks** |

🎓 **The segfault was never about "Zig IR" or about frontend provenance. It was about DEBUG-MODE
Zig IR**, and every earlier test happened to use Debug because that is Zig's default. One variable —
the optimization mode — was never varied, and a structural conclusion was drawn from a single
setting. _This is `best-practices.md` §2's "vary one thing at a time" all over again._

**So the wrapper-driver route is ALIVE**: emit IR with stock Zig → rewrite two `target datalayout`
lines → hand it to Fil-C's clang. No Zig fork, no LLVM build. See `roadmap.md` P1/P2 for what that
already achieves, and KI-5/KI-6 for the two limits that remain.

### ✅ DEBUG MODE IS SUPPORTED NOW (2026-09-23, P2 item 1) — two concessions, and the cause is upstream's

**❌ Inline asm was NOT the cause.** Fil-C accepts `__asm__` in ordinary C _and_ an `asm sideeffect`
call in a hand-written dialect module. 114 occurrences, all innocent — the prime suspect named in the
original entry was wrong.

**The actual shape of it, measured on identical Debug IR (189,741 lines, 1,110 functions):**

| what changed                                       | result                                                                                                   |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `filc -O0`                                         | ✅ **compiles**                                                                                          |
| `filc -O1` / `-O2`                                 | ❌ segfault inside the pass                                                                              |
| Zig `-fstrip` (11,326 lines, 163 defines) at `-O1` | ✅ compiles — but it removes **code as well as** the 54,636 `!DI` lines, so it proves nothing on its own |

🔑 **So it is an interaction between LLVM's OPTIMIZER and the pass on this module, not a construct
Fil-C refuses.** At `-O0` the same IR is fine. **The crash is upstream's.**

#### 🔬 Reduced to 8 functions — and four hypotheses died on the way (2026-09-23)

`tools/p2/llreduce.ts` (delta debugging, 1,648 compiler runs) took the module from **1,110 functions
to 8**, then a metadata strip took it from 60,602 lines to **9,773**. A second pass confirms all 8
are required. The repro and its reproduction steps: **`tools/p2/repro/`**.

**The 8 are Zig's `std.compress.flate.Decompress` Huffman decoder** — Debug builds pull it in because
Zig's stack-trace printer decompresses DWARF.

| hypothesis                          | verdict                                                                 |
| ----------------------------------- | ----------------------------------------------------------------------- |
| inline asm                          | ❌ Fil-C compiles `__asm__` in C and `asm sideeffect` in IR             |
| debug metadata / `!DI` records      | ❌ stripped every one; **still crashes**                                |
| odd-width ints (`i46` in an `sret`) | ❌ a hand-written `i46`-through-`sret` module builds at `-O0/-O1/-O2`   |
| "this Zig code is unsupported"      | ❌ the same flate code in **ReleaseSafe** (146,488 lines) compiles fine |

**What is left:** the _unoptimized shape_ of that code plus LLVM's `-O1` pipeline around the pass.
Narrowing further needs line-level reduction or a debug build of Fil-C's clang — neither of which
zilc needs, since the driver compiles Debug IR at `-O0`.

📤 **A draft upstream issue is written but NOT filed** (`tools/p2/repro/UPSTREAM-REPORT.md`).
~~Filing it is the owner's call.~~ **Settled 2026-10-01:** upstream reporting is optional and not
planned (`design-decisions.md`), and this crash is fixed in zilc's patched clang (top of KI-4).

**What zilc does about it (`src/driver.zig`):** `-O Debug` now _works_, with two concessions applied
automatically and announced:

1. **`filc -O0`** for the instrumented IR — the segfault above.
2. **`-fno-stack-check`** on the Zig side. Zig's `__zig_probe_stack` lives in its compiler-rt, which
   never goes through the pass, so the link fails on it. Dropping probes is honest here: Fil-C's
   checks are what make the program safe and they do not rely on guard pages.

📏 **The cost is size: 13,766,024 bytes vs 127,424 for ReleaseSafe — 108×.** Same panic, same line.
`tools/p2/debug-mode.ts` runs both.

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

`zilc build hello.zig` now works with **no C file**. The driver writes `zilc_entry.zig`, makes _it_
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
`pub fn main` and no C/C++ input is present. `tools/p2/whole-program.ts` runs it.

~~⚠️ **What this does NOT do:** the program gets no `std.os.environ`, no Zig stack-size expansion,
and no Zig segfault handler.~~ **Settled 2026-10-02 (pre-publish item), each measured:**

- ✅ **`std.os.environ`: now SET.** Before, it read as EMPTY (0 entries where native saw 3; the
  `undefined` global happens to be zero), silently. std itself never needed it with libc linked
  (`getenv`, `getEnvMap`, `execv`, `Child` all read libc's `environ` when `link_libc`), so only
  user code reading `std.os.environ` directly was affected. The entry shim now fills it from
  `std.c.environ`, the same array `start.zig` snapshots, and a real Fil-C object (exact
  capability; not main's third argument, whose path through Fil-C's own start code was not
  verified). Native and zilc now print the same, Debug and Release; gate case 5
  (`examples/whole_program/environ.zig`).
- ✅ **Stack-size expansion: NOT NEEDED.** Native Zig records a 16 MiB stack in `PT_GNU_STACK`
  and `start.zig` raises the soft limit to it (from the shell's 8 MiB). zilc's binaries record 0.
  Measured with a 1 KiB-per-level recursion that cannot be optimized away
  (`noinline`, `.never_tail`, `doNotOptimizeAway`): native stops at ~15,400 levels (~15 MiB) with
  a SEGFAULT (rc 139); zilc goes to ~65,300 levels (~4× deeper) and then stops with a clean
  `filc safety error: stack overflow`. ⚠️ A first probe was wrong both ways: native turned the
  recursion into a loop, and the buffers escaped, so Fil-C kept them off the machine stack.
- ✅ **Segfault handler: not applicable.** Fil-C stops memory errors before any segfault, with
  its own report.
- **Library mode** (C owns `main`): `std.os.environ` and `std.os.argv` stay unset, exactly as
  natively, where Zig's start code does not run either. Not a zilc gap.

## ✅ KI-6 — Zig must target **musl**, not gnu, or the link fails on `*64` symbols (2026-09-23). **Handled: zilc's default target is `x86_64-linux-musl`** (`src/driver.zig`, `src/main.zig`); a non-musl `--target` gets a warning

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
  `panic.zig:6:5`, instead of a stack overflow in the trace code. ✅ **Library mode covered 2026-10-02**
  (C owns `main`): a generated library root (`library_shim`) carries the same handler (gate case 8).
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

## ✅ KI-11 — Zig 0.15.2's `indexOfSentinel` over-reads; under Fil-C it is an OOB read. **FIXED 2026-09-30 by backporting upstream's 0.16.0 fix** (owner chose option 1)

`67_environment-variables`: `cannot read 16 bytes when upper - ptr = 12` at `mem.zig:1118:48`. std's
SIMD sentinel scan reads past the end of the string's object, up to the page boundary. Full analysis,
minimal reproduction and report draft: `zig-upstream-notes.md` **Z-1**,
`tools/zig-reports/sentinel-overread/`. **Fixed upstream in 0.16.0** (a scalar `findSentinel`).

✅ **Done:** `src/stdpatch.zig` builds a cached **std overlay** (`~/.cache/zilc/std-overlay/0.15.2-v1`: a real copy of `std/`, everything else symlinked) and applies the **0.16.0 `findSentinel` body**; the driver passes `--zig-lib-dir`. Each patch **verifies the exact original** and fails the build otherwise; Zig 0.16.0 has no patch set and gets no overlay. Result: the repro prints `len = 11` under zilc, `67` gets past `getenv`, gate 4/4, no corpus regressions. Ledger: `zig-std-backports`. History of the decision follows.
std has no hook to swap this function out (unlike `panic` and `page_allocator`). ❓ ~~**Owner decision
pending:**~~ decided 2026-09-30, option 1.
1. **(recommended)** a small **zilc std overlay**: build with `--zig-lib-dir` pointing at a cached
   copy of Zig's lib with a few patched files. The first patch is **upstream's own 0.16.0 loop**, a
   backport rather than an invention. It is likely also needed for Z-5 (`DebugAllocator`).
   Re-checked at every Zig move (`ports/`).
2. Leave it as an explicit Fil-C stop until zilc is on 0.16. Safe, but C-string handling is
   everywhere.
3. An IR-level rewrite: rejected, nothing reliable to anchor to.

## ✅ KI-12 — `PageAllocator`'s `mmap` hint rejected by Fil-C. **FIXED 2026-09-30**

`69_http-client`: `cannot write pointer with ptr >= upper` inside `zsys_mmap`. The hint is the end of
the previous mapping, a pointer at an object's upper bound (`zig-upstream-notes.md` **Z-2**; not a
Zig bug). **Fix:** the entry shim declares std's official hook `root.os.heap.page_allocator =
std.heap.c_allocator`, so pages are Fil-C malloc objects. 69 now gets past it and stops on Z-5
(`DebugAllocator`) instead. ✅ Library mode (C owns `main`) covered 2026-10-02 by the library root, like the panic
handler.

## ✅ KI-13 — Pointers rebuilt from integers lose their capability (the "null object" class). **MOSTLY FIXED 2026-09-30**

The `DebugAllocator` traps (`cannot write pointer with null object` at `debug_allocator.zig:782`/`798`)
had **two independent causes**, each confirmed by experiment, not reasoning alone:

1. **Overflow-checked arithmetic hides provenance (all safe-mode Zig code).** In ReleaseSafe and
   Debug, Zig compiles `+ - *` to `llvm.*.with.overflow` and reads the result with
   `extractvalue …, 0`. Fil-C's `inttoptr` recovery starts at BOTTOM for any call or `extractvalue`
   result (`gimso_semantics.md`), so `@ptrFromInt(@intFromPtr(p) + off)` comes out with **no
   capability**, even within one function. Seen in the IR of `fromPage`: `ptrtoint` →
   `uadd.with.overflow` → `extractvalue` → `usub.with.overflow` → `extractvalue` → `inttoptr`.
   **Fix (`ir.foldOverflowValues`):** each `extractvalue …, 0` of such a call becomes the plain
   `add`/`sub`/`mul`, which is the identical value. The overflow flag (field 1) and its panic branch
   are untouched. This is general: it fixes the pattern in **all** Zig code, std and user alike.
   Zig 0.16 itself rewrote `fromPage` with wrapping `+% -%`, which emits plain arithmetic, so the
   direction matches upstream.
2. **An address passed as an integer parameter.** `BucketHeader.fromPage(page_addr: usize, …)`:
   an integer _parameter_ is BOTTOM, whatever the caller held. **Fix: std overlay patch**
   (`src/stdpatch.zig`, zilc's own, **not a backport**, since 0.16.0 has the same signature):
   `fromPage` takes the page **pointer**; the three call sites pass `page`, or
   `@ptrFromInt(page_addr)` computed in the same function as `@intFromPtr(memory.ptr)`.
   Addresses are computed identically.

⚠️ **Proof that both are needed, and a method lesson:** with only the fold, ReleaseSafe passed,
**but only because Fil-C's clang inlined `fromPage` at `-O1` before the pass**. A Debug build
(`-O0`, no inlining) still trapped at the same site. Relying on an optimiser decision would be
"leaving it to chance" (invariant 5). The patch stays.

**Result (ReleaseSafe):** Zig as designed **50 → 71/78** (65 clean exits plus 6 intentional).
**Left: 7** (6 × `cannot read pointer with null object`, 1 × `cannot access pointer with null
object`), to be analysed individually.

## ✅ KI-14 — Valgrind client requests are inline asm (Debug). **FIXED 2026-09-30**

Debug defaults to `-fvalgrind`: Zig emits Valgrind's magic no-op sequence (`rolq $3,%rdi; … xchgq
%rbx,%rbx`) in allocation paths (seen in `heap.CAllocator.alignedAlloc`). Fil-C refuses all inline
asm (`literal register %rdi not covered…`). **Fix:** the driver always passes `-fno-valgrind`.
Natively the sequence is a no-op unless running under Valgrind, which a zilc program never does,
so no behaviour changes.

## ✅ KI-15 — Debug: `DebugAllocator` captures a stack trace for EVERY allocation, by walking raw frame pointers. **FIXED 2026-09-30: option 1, owner-approved** (`std.debug.sys_can_stack_trace = false` in the std overlay; the original switch kept, renamed). Debug `09_slices`, `10_maps` and `34_atomic-counters` (50 threads) now run on both routes

**Owner: "make sure to make a note on this item for sure."**

- **What happens:** in Debug, `DebugAllocator`'s `stack_trace_frames` defaults to **6**
  (`debug_allocator.zig:106`: `default_sys_stack_trace_frames = if (std.debug.sys_can_stack_trace)
  6 else 0`; ReleaseSafe/Fast/Small default to 0). Every `alloc` and `free` calls
  `std.debug.captureStackTrace`, which walks the stack **by reading raw frame pointers** and probes
  whether each address is readable with **`process_vm_readv` (syscall 310)**.
- **Under Fil-C:** the probe goes through `zilc_syscall` → Fil-C's `syscall()` → **`filc user error:
  unsupported syscall: 310`**, an explicit, safe stop. Without the probe, the walk itself would turn
  saved frame-pointer integers into pointers (`@ptrFromInt`), which have no capability. **Native
  stack walking cannot be made safe under Fil-C in any form**, the same family as `getcontext`
  (KI-7, Z-4).
- **Effect:** **every Debug-mode Zig program that allocates through `DebugAllocator`** (i.e.
  `GeneralPurposeAllocator`) **stops on its first allocation.** ReleaseSafe/Fast/Small are
  unaffected (0 frames). Found 2026-09-30 by `09_slices` built with `-O Debug`.
- **std offers no switch:** `std.Options` has no stack-trace knob; `sys_can_stack_trace` is a fixed
  per-architecture constant (`debug.zig:171`).
- **Safe equivalents (owner chose 1, 2026-09-30, "I agree with your recommendation"; 3 stays possible later, on top of 1):**
  1. **std overlay patch: `std.debug.sys_can_stack_trace = false` under zilc** _(recommended)_.
     It tells std the truth, that native stack walking is unavailable, so every std path that would
     walk the stack (allocator traces, panic traces, `dumpCurrentStackTrace`) takes its existing
     "no stack traces" branch. Fil-C already supplies traces for every safety stop, with
     file:line, and the panic handler uses `zerror` (KI-7). Loses only `DebugAllocator`'s leak and
     double-free _allocation-site_ traces; Fil-C itself catches double free and use-after-free.
  2. Patch only `default_sys_stack_trace_frames` to 0: narrower, but leaves other stack-walking
     paths reachable.
  3. Later: implement `captureStackTrace` over **Fil-C's `zstack_scan`** (frames with function,
     file and line) to keep allocation-site traces. More work, but no loss.
- Also check: whether other std paths reach syscall 310 or raw frame-pointer walks in Release
  modes (part of the all-modes check below).

## 🔑 KI-17 — Zig's emitted IR is ALREADY OPTIMIZED, under an integral data layout (2026-09-30). ✅ **The unoptimized route is now the DEFAULT** (`--verbose-llvm-ir` + `-fllvm`; `ZILC_OPTIMIZED_IR=1` restores the old one). Release modes all 76/78 as designed; gate 4/4

**The most important pipeline finding since KI-4.** `-femit-llvm-ir` emits the module **after**
Zig's LLVM optimization passes (Zig's help: "Produce a .ll file with optimized LLVM IR"). Those
passes ran under Zig's ordinary data layout, where pointers are plain integers, so LLVM is free to
canonicalise a pointer load into **`load i64` + `inttoptr`**. Under Fil-C a loaded integer has **no
capability**, so the pointer dies. Fil-C's `ni:0` layout exists to forbid exactly that transform,
but zilc applied it _after_ Zig had already optimized.

- **Found by** the 5 thread-join failures (KI-10): Zig's source keeps `pthread_t` as a pointer
  throughout, but in the emitted IR `Thread.join` did `%v = load i64, ptr %slot; %p = inttoptr i64
  %v to ptr; call @pthread_join(%p)`.
- **Zig's unoptimized module** is available through the debug flag **`--verbose-llvm-ir=PATH`**.
  In it, `join` does `load ptr` as written. On `34_atomic-counters`, `inttoptr`s drop from **386
  (optimized) to 117** (the rest are real `@ptrFromInt` in source).
- **This is how Fil-C's own C pipeline works:** the front end hands over unoptimized IR, and all
  optimisation happens inside Fil-C's clang, under `ni:0`. zilc should do the same.
- **Experiment, 2026-09-30 (`ZILC_UNOPT_IR=1`, env-gated in `driver.compileZig`):** 34
  (`ops: 50000` from 50 threads) and 27 now pass, the controls still pass, and the KI-4 pass crash
  did **not** reappear on them. **The full corpus in all 4 modes is running** to decide whether
  this becomes the default.
- **Explains the per-mode differences** (KI-16): how often LLVM rewrites pointers as integers
  depends on the optimisation level (optimized route: ReleaseSafe 71, ReleaseFast 75, ReleaseSmall
  69 as designed).
- ⚠️ **Open costs, to measure:** speed (Fil-C's clang at `-O1` instead of Zig's full pipeline;
  Fil-C's `-O2` is worth trying, since the pass placement is upstream's); compile time; and the
  risk of the KI-4 crash on larger unoptimized modules.
- KI-13's fixes still apply: overflow intrinsics come from Zig's front end and are in the
  unoptimized IR too, and `fromPage`'s integer parameter is source-level.

## ✅ KI-18 — Fil-C pass assertion `!(CSize % WordSize)` on unoptimized Zig IR (2026-09-30, fixed 2026-10-01)

**Root cause (2026-10-01): any GLOBAL whose value type is `i17`…`i24`** (a 3-byte store size),
constant or mutable, at every `-O`. Here it was Zig's `std.unicode.replacement_character: u21`
→ `@unicode.replacement_character = internal unnamed_addr constant i21 65533`. Found by extending
`tools/p2/llreduce.ts` to reduce globals as well as functions (globals become `external`
declarations): 320 units → 1 in 11 runs.

- **Probed widths:** `i17`, `i21`, `i24` assert. `i2`, `i8`, `i9`, `i12`, `i16`, `i25`, `i31`,
  `i32`, `i33`…`i64`, `i65`, `i100`, `i120` pass, and so do `{ i21 }`, `{ i21, i8 }`, `[2 x i21]`,
  `[3 x i8]`, and `i21` in allocas, loads and stores. The `i2` suspicion below was **wrong**: `i2`
  fields are harmless.
- **Fix:** `ir.wrapThreeByteGlobals` (driver step 2d) rewrites such a global's value to
  `{ iN } { iN V }`: the same size, alignment and bytes, with field 0 at the global's address, and
  with opaque pointers no use names the type. Declarations are left alone. Unit-tested.
- **Recorded, not filed:** 16-line repro `tools/p2/repro/filc-0.685-i21-global.ll`, notes in
  `tools/p2/repro/README.md`.
- **Also hit by vectors** (found in `69_http-client`): `@__anon_9482 = … constant <3 x i8>`. The
  rule is the 3-byte store size, so the rewrite (renamed `ir.wrapThreeByteGlobals`) covers integer
  vectors of 17–24 bits too. Mechanism, from the pass source: `workarounds.md` KI-18.
- **Results (2026-10-01, corpus in all 4 modes):** `22` runs in every mode; `69` builds in every
  Release mode (Debug: KI-22 build time) and then hit KI-20, now fixed too. ReleaseSafe,
  ReleaseFast and ReleaseSmall are each **78/78 as designed**; Debug 65/78 (12 × KI-19, 69's
  build time). Tests 24/24, gate 4/4.

**Original notes (2026-09-30), kept for the record:**

On the unoptimized route (KI-17), **2 of 78 programs crash Fil-C's clang in every mode**:
`22_strings-and-runes` and `69_http-client`. The crash is `FilPizlonator.cpp:16714: void
{anonymous}::Pizlonator::run(): Assertion '!(CSize % WordSize)' failed`, an abort (exit 134) inside
`FilPizlonatorPass::run`. Both build fine on the optimized route.

- **Reduced** with `tools/p2/llreduce.ts` (`--opt -O1`): 21,523 → 7,710 lines, **one function body
  left** (`os.linux.x86_64.syscall4`, which is innocent: four `inttoptr` and a call). The reducer only
  removes function bodies, and **the remaining module is mostly GLOBALS**, kept alive through the
  debug metadata's global list. The assertion is about a **constant's size**, so a global is the
  likely trigger.
- **Prime suspect (unverified):** Zig's unoptimized constants are full of **`i2` fields**
  (error-union and optional tags), e.g. `{ { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, …, i8, i2,
  [6 x i8] }`. A 2-bit integer has no whole-byte size, which fits an assertion about word-multiple
  sizes. LLVM's optimizer likely rewrote these away on the optimized route.
- **Next:** extend the reducer to drop globals (replace initializers with `zeroinitializer`, or
  remove unreferenced ones) until one global remains. Then decide: an IR workaround (widen `iN`
  fields in pointer-bearing constants to bytes), and/or **an upstream Fil-C report** (an assertion
  on valid IR, like KI-4's crash).
- Reduced module: `~/zilc-work/csize/csize-reduced.ll` (WSL); input `…/runes.zilc-tmp/
  strings-and-runes.filc.ll`.

## ✅ KI-23 — Git's automatic maintenance fails on the exFAT drive (2026-10-01). **Mitigated; mitigation is FINAL (owner: projects stay on D: for portability)**

> **Owner decision 2026-10-01:** "The reason it is on the D: drive is for portability. We won't be
> placing project on the NTFS drive." The repo and its `.git` stay on the exFAT D: drive. The
> NTFS-gitdir idea below is **rejected**. The mitigation (repo-local `maintenance.*` config) is
> permanent, and it travels with the project, because `.git/config` is on D: too.

**Symptom:** after commits, `fatal: could not write multi-pack-index: Permission denied` /
`error: task 'geometric-repack' failed`. A forced `gc` fails with `renaming pack to '…pack' failed:
File exists`. **Commits and objects are unaffected** (fsck clean, 1,080 objects, before and after).

**Cause (measured):** two Windows/exFAT file semantics that Linux doesn't have. (1) The geometric
task's child `multi-pack-index write` replaces the MIDX file while its parent `repack` still has it
memory-mapped: Windows refuses ("Permission denied"); a plain `git multi-pack-index write` works.
(2) A repack sometimes writes a pack whose content-derived name already exists. Git for Windows on
exFAT cannot rename over the existing read-only pack ("File exists"); on Linux the rename replaces
it. A full `git repack -a -d` consolidated six packs to one, but the next repack hit (2) again.

**Mitigation (repo-local config, not committed):** since 2026-10-27 the workspace standard,
**`maintenance.strategy gc`** (divergence P7). Until then `maintenance.geometric-repack.enabled=false`
- `maintenance.gc.enabled=true`, which a traced run on git 2.54 showed to be the same `gc` plus one
  more task, `commit-graph write --split`; both keep the failing geometric repack and
  `multi-pack-index write` from running. The automatic run after commits is clean. `gc` only runs when
  loose objects pass `gc.auto` (~6,700), so the error is rare, and harmless when it occurs. This is
  the final answer (owner decision above). ~~Full fix: keep repos on NTFS~~: rejected, because the
  projects stay on D: for portability.

_History (2026-10-01)._ The owner pointed to wazmrt's NTFS setup (`working-rules.md`:
`ZIG_LOCAL_CACHE_DIR=C:\zig-cache\wazmrt`, plus an NTFS cwd for `test-security`). That covers the
**Zig cache**, which zilc already handles the same way (`C:\zig-cache\zilc`, KI-2); it does not
move git's object store. Moving `.git` to NTFS behind a `gitdir:` pointer file was proposed and
**rejected** (portability). Other projects on D: are outside zilc's scope and are not tracked here.
**Nothing about KI-23 is open.**

## ✅ KI-22 — Build time: Fil-C's frame-slot colouring is cubic on big Zig functions (2026-10-01). **Option 2 DONE (patched Fil-C clang, the default); option 3 rejected; levers (a), (b), (c) DONE 2026-10-02**

**Status 2026-10-02 (later): all three approved levers are in.** (b) builds the pass's
interference graph over dense ids: the pass on `69` 11.2 → 4.3 s, verified equal to the original
on the whole corpus in all four modes (`ZILC_VERIFY_INTERFERENCE=1`). (c) caches Fil-C objects by
a key over the IR and the tools' identity: an unchanged `69` rebuilds in 2.3 s. `69` ReleaseSafe
alone: **55.9 s (2026-10-01) → 35.9 s** cold (38.0 s on Fil-C 0.686, 2026-10-05), against native Zig's 16.9 s. What remains is mostly
LLVM's own `-O1` optimizer on the instrumented code (~20 s of the whole-module step), which zilc
cannot change without changing the output. Detail: `workarounds.md` KI-22.

**Status 2026-10-02 (lever a):** lever (a) is in: big modules (≥ 4 MB of Fil-C-dialect IR) run Fil-C's pass
and the optimizer whole, then generate their code in parallel parts with zilc's mode of
`llvm-split` (`-j`/`ZILC_JOBS`). Same code: 2,840/2,840 of `69`'s functions identical to the
unsplit compile of the same bitcode. `69` ReleaseSafe alone 60.6 → **43.9 s**; under corpus load
Debug 68 s, ReleaseSafe 70 s, ReleaseFast 97 s, ReleaseSmall 61 s; corpus 78/78 as designed in all
four modes. Splitting BEFORE the pass was faster (~24 s) but made binaries 37% bigger and was
rejected by the owner. Next: (b) the faster interference build in the pass (the whole-module step
is now ~34 s of `69`), then (c) the object cache. Detail: `workarounds.md` KI-22 "Lever (a)".

**Status 2026-10-01 (evening):** the patched clang is built and is the default in zilc's scripts
(prebuilt kept for comparison). Its colouring was verified equal to the original's on every build
of the corpus in all 4 modes (`ZILC_VERIFY_COLOURING=1`). Together with the KI-4 fix (Debug at
`-O1`), `69`'s builds under full corpus load: ReleaseSafe 214 → **112 s**, ReleaseFast 742 →
**154 s**, ReleaseSmall 178 → **87 s**, Debug timeout → **83 s**. Corpus medians: Debug 19 s,
ReleaseSafe 4 s, ReleaseFast 3 s, ReleaseSmall 2 s.

**Option 3 researched and rejected (same day):** Fil-C's pass erases the lifetime markers of
escaping allocas before its liveness runs, and those are the only values whose interference costs
time, so zilc-inserted markers could not help. Debug's "~5× Release" was a third KI-21 route
(`unexpectedErrno` → `dumpCurrentStackTrace`), now guarded: trivial Debug builds 9.9 s → 2.1 s.
Remaining gap, inherent to instrumentation: `69` alone 55.9 s vs native 16.9 s (pass 11 s; the rest
is LLVM optimizing and generating the instrumented code). Further levers (parallel per-part
compile, faster interference build, object cache) are listed in `workarounds.md` KI-22, not
started.

Original entry:

`69_http-client`: ReleaseSafe 132 s alone (native Zig 20 s), ReleaseFast 754 s under corpus load;
Debug times out (30 min). 75% of it is in `FilPizlonatorPass`, almost all in one greedy colouring
loop that rescans every neighbour per candidate frame index, which is cubic when Zig's unoptimized
IR keeps hundreds of escaping allocas live together (no lifetime markers). Found by synthetic
scaling, gdb sampling and the pass source (allowed, owner 2026-10-01). **Owner chose option 2**:
build Fil-C's clang locally from the prebuilt's own commit with an output-identical fix
(`tools/filc/`, `third_party/filc-patches/`, ledger `filc-pass-fixes`), **then research
option 3** (zilc-inserted lifetime markers). The full why, what was ruled out, and the options:
`workarounds.md` KI-22. Open data: why ReleaseFast compiles 69 3.5× slower than ReleaseSafe, and
why trivial Debug programs take ~36 s under load.

## ✅ KI-21 — Build time: std's stack-trace code was compiled into every program (2026-10-01, FIXED)

KI-15 disabled native stack walking at run time only; on the unoptimized route (KI-17) Fil-C still
instrumented and compiled the whole DWARF unwinder (about half of `62_directories`' IR). **Fix:** two
std-overlay guards with a comptime-known early return (`captureStackTrace`,
`StackTrace.format`), overlay v4. **62 ReleaseSafe 40 s → 8.0 s** (native 6.7 s); IR 228k → 87k
lines. **Third route, Debug only (2026-10-01 evening):** `posix.unexpectedErrno` →
`dumpCurrentStackTrace` (std's Debug "unexpected error tracing"); two more guards, overlay v5.
Trivial Debug programs 9.9 s → 2.1 s. Details: `workarounds.md` KI-21.

## ✅ KI-20 — `std.crypto.random` probes `madvise` with an invalid advice (2026-10-01, FIXED)

`69_http-client`: `filc safety error: attempting to use unrecognized madvise advice -1`. std's
CSPRNG deliberately passes `0xffffffff` to detect QEMU and expects `EINVAL`; Fil-C stops instead.
**Fix:** the entry shim sets std's official `std_options.crypto_always_getrandom = true` (kernel
CSPRNG on every fill, fork-safe). 69 now completes a real HTTPS request in every Release mode.
Library mode covered 2026-10-02 (library root; gate case 7). Details: `workarounds.md` KI-20.

## ✅ KI-19 — Debug only: syscall POINTER arguments arrive without a capability (2026-09-30). **FIXED 2026-10-01 by moving Debug to `filc -O1`**

**Fix (2026-10-01):** the hypothesis below was right. The cause was `filc -O0`: no stack-slot
promotion, so integers loaded back from Zig's Debug stack slots reached the syscall wrappers with
no capability. Debug ran at `-O0` only because of KI-4's crash; the KI-4 patch (Fil-C's
`indirectbr` lowering, `workarounds.md` KI-4) lets Debug use `-O1` like every mode. **All 12
programs now run; the corpus is 78/78 as designed in Debug, as in every mode.** No zilc-side
rewrite (candidate fix (a)) was needed. Candidate (b) below is the one that worked.

Original entry:

On the default (unoptimized) route, Debug is 63/78 as designed against 76 in every Release mode.
**All 13 Debug-only traps are the same thing:** a system call's pointer argument has no
capability when Fil-C's runtime uses it: `clock_nanosleep`'s timespec (7: 29, 30, 31, 32, 35, 37,
76), the futex timed-wait timeout (3: 28, 33, 36), `getdents`' buffer (2: 62, 63), and `statx`'s
buffer (1: 58).

- 🔸 **Hypothesis, not yet verified:** Debug compiles the instrumented IR at **`filc -O0`** (the
  KI-4 workaround), so no pass promotes stack slots to registers. Zig's Debug IR keeps each
  `@intFromPtr` result in a stack slot (`store i64` then `load i64`) before calling the `syscallN`
  wrapper. A **loaded** integer is BOTTOM to Fil-C's `inttoptr` analysis, so the `inttoptr` that
  `rewriteSyscalls` inserts at the call site recovers nothing. KI-17's problem again, in Debug's form.
- **To check first:** the IR of `31_timers` in Debug around the `syscall4` call.
- **Candidate fixes:** (a) in the rewrite, follow the operand back through a same-function
  `store`/`load` of a stack slot to its `ptrtoint`, and pass the original pointer directly;
  (b) re-test whether KI-4's `-O1` crash still occurs on the unoptimized route, since `-O1` would
  promote the slots; (c) run only `mem2reg`/SROA before the pass at `-O0`, if Fil-C's pipeline
  allows it.

## 🧪 KI-16 — Every optimisation mode must be checked separately (owner, 2026-09-30)

**Owner: "We may also need to check that all release modes do not have differing issues with
these found conditions."** The conditions found so far **depend on the mode**:

| condition                              | Debug                        | ReleaseSafe        | ReleaseFast     | ReleaseSmall        |
| -------------------------------------- | ---------------------------- | ------------------ | --------------- | ------------------- |
| overflow-checked arithmetic (KI-13 #1) | yes                          | yes                | no (plain wrap) | no                  |
| inlining hides or exposes KI-13 #2     | **no inlining** (`filc -O0`) | `-O1` inlines      | `-O1`           | `-O1`               |
| Valgrind client requests (KI-14)       | **yes** (default)            | no                 | no              | no                  |
| `DebugAllocator` stack traces (KI-15)  | **6 frames**                 | 0                  | 0               | 0                   |
| stack-probe symbol (KI-8)              | yes                          | yes (large frames) | ?               | ?                   |
| stack-trace / panic code in the binary | full                         | full               | full            | **mostly stripped** |

So **the corpus runs in every mode** (`tools/basics/zilc-check.ts`, `MODE=…`), and results are
recorded per mode in `testing.md`.

**Measured 2026-09-30 (Zig corpus, as designed out of 78):**

| route                                                           | ReleaseSafe | ReleaseFast | ReleaseSmall | Debug                              |
| --------------------------------------------------------------- | ----------- | ----------- | ------------ | ---------------------------------- |
| optimized IR (old)                                              | 71          | 75          | 69           | stopped by KI-15                   |
| **unoptimized IR (default now)**, plus the wrapper-call rewrite | **76**      | **76**      | **76**       | **63** (57 clean exits); see KI-19 |

**The modes differed because of LLVM's pre-optimisation (KI-17). Once it was removed, the three Release
modes give identical results.** The 2 left in each are the KI-18 Fil-C assertion. Two
mode-specific fixes were needed along the way: **`-fllvm`** (Debug otherwise uses Zig's own x86_64
backend, so there was no LLVM module and every Debug build failed), and **rewriting calls to Zig's
`syscallN` wrappers at the call site** (in unoptimized ReleaseSmall the wrapper is not inlined, so
an asm-only rewrite received pointers as integer parameters, with no capability).

## ✅ KI-10 — `pthread_join` traps on a pointer with no capability (2026-09-30). **FIXED 2026-09-30 by the unoptimized-IR route (KI-17); label corrected 2026-10-01**

**Status:** fixed the same day as found, but the label was never updated. KI-17 records "the 5
thread joins pass" once zilc took Zig's unoptimized IR: the `pthread_t` round trip had been LLVM's
pre-optimisation turning a pointer load into an integer one. Verified 2026-10-01: the threading
programs `28`–`37` (incl. `33_mutexes`) pass in Debug, ReleaseSafe, ReleaseFast and ReleaseSmall.

Original entry:

`33_mutexes` and one more threading example: `cannot read pointer with null object` in musl's
`__pthread_timedjoin_np`. Most likely Zig's std keeps the `pthread_t` it got from `pthread_create`
in a form that loses its capability (an integer round trip). The same family as KI-5 and P4's
`@ptrFromInt` question. ◐ **The mechanism is confirmed by the design docs** (`gimso_semantics.md`,
`filc-abi.md` "inttoptr"): an integer that comes from a **load or a call** always turns back into a
pointer with a **null capability**. The exact Zig code path is still unverified.

Also seen, not yet analysed: `42_panic` hits `stack overflow` in Zig's panic path under zilc, and
`76_signals` accesses a pointer with no capability.

## ✅ KI-24 — The release guard accepted any entry that mentioned both reviews (review round 1, D1; 2026-11-15, FIXED)

**Class:** a guard that passes on text, not on fact (round 1, class 1; `open-work.md` § Review).
**Measured** (reviewer D, run; the session re-read the code): `bump.ts` and `release.ts` tested
`/security review/i` and `/hardening review/i` on the entry, so `security review: not run.
hardening review: skipped.` made the bump commit. **Fix** (`tools/release/guards.ts`): a review is
a RECORD in one fixed form, one line per kind (`REVIEW_FORM`; `release.md` § "Review records"),
exactly one of each, a real date, at least one round; and the record is checked against the
history: its range starts at the previous release's tag, names a commit in the history being
released, and after that commit only `cmem/` and `RELEASE-NOTES.md` changed. **Test:**
`guards.test.ts` (a throwaway repository: negation, placeholders, a heading, one kind, zero rounds,
a bad date, a duplicate, the wrong base, a commit off the history, code after the review). The
reviewer's reproducer now refuses (`bump.ts release` exit 1, both records named).

## ✅ KI-25 — CI released any push of an untagged version, without reading the reviews (D2; 2026-11-15, FIXED)

**Same class.** `release.yml`'s decide step set `release=true` for any `main` commit whose version
had no tag, and `checks` never read the reviews: a plain `git push` bypassed `release.ts`, and a
memory commit pushed after the bump commit could race it for the tag. **Fix:** a commit is a
release only when its subject is `bump to v<version>`; on a release, `checks` runs
`tools/release/check-reviews.ts "$GITHUB_SHA"` (the same check `release.ts` runs before it pushes):
the bump commit changes only `README.md`, `build.zig.zon`, `src/root.zig`, and the entry's records
cover the history (KI-24). **Test:** `guards.test.ts` (the CLI on a non-bump commit and on a git
failure, exit 1 and 2); the decide step run on a scratch bump commit (`release=true`) and its child
(`release=false`), 2026-11-15. Still CI's half: the first real release runs it on GitHub.

## ✅ KI-26 — `bump --check` passed a version place on a substring (D5; 2026-11-15, FIXED)

**Same class.** Each place was an `includes`: the version test pinning `0.687.0` with `0.687.1` in
a trailing comment passed (run, session); so did a State row naming the version as "previous", and
any line naming a longer version (`…687.10` for `…687.1`). **Fix:** each place is the one line that
carries it, matched whole and anchored, and exactly one such line (`guards.ts` `disagreements`);
build.zig.zon must hold exactly one `.version` line. The State row must BEGIN with the version.

## ✅ KI-27 — A release entry was found by `startsWith` and ran to the end of the file (D6; 2026-11-15, FIXED)

**Same class, latent** (no `.10` yet). `### v0.15.2-0.687.10` answered a lookup for `…687.1`, an
entry without the `v` counted, and the last entry swallowed every later section. **Fix:**
`guards.ts` `findEntry`: the exact `### v<version>` heading (a space or the line's end after it),
ending at the next heading of any level; two entries for one version is an error.

**Inversion for KI-24–KI-27, 2026-11-15:** 16 mutants, each putting one part back to the first
version's behaviour (substring places, first match only, `startsWith`, to end of file, two entries,
the form not enforced, zero rounds, no date check, no base check, off-history allowed, later code
allowed, bump extras allowed, the CLI's subject check, a git failure as a pass): **16 of 16 caught**
by `guards.test.ts`. One check written first (a reviewed commit from before the previous release)
was seen by no test of its own — the later-changes check always fires first — and was removed.

## ✅ KI-28 — The review check read file NAMES, not content (class 1 retest 1; 2026-11-15, FIXED)

**Same class, found by the class's first retest (a fresh reviewer, all three RUN):** (1) the diff
after the review used git's rename detection, so `git mv src/x cmem/x` listed only the `cmem/`
side and a deletion of reviewed code passed; (2) the bump commit was checked for WHICH files it
touched, not what it put in them — a hand-made `bump to v…` commit adding a line to `src/root.zig`
or `build.zig.zon` passed; (3) git quoted a non-ASCII `cmem/` name (`"cmem/caf\303\251.md"`), so a
correct release was refused. **Fix** (`guards.ts`): every diff is `--no-renames -z` (`changedPaths`:
both sides of a move, names never quoted); the bump's edits are one function, `bumpEdits`, which
bump.ts writes through and the check recomputes from the bump commit's parent, requiring the three
files byte for byte. **Test:** `guards.test.ts` (a smuggled line in each of the three files, a move
into `cmem/`, a `cmem/café.md`, and `bumpEdits` on the real repository); 3 more mutants (rename
detection back, quoted names, content unchecked), **19 of 19 caught**; `bun test tools/release/`
61/61; the end-to-end scratch release still bumps and passes `check-reviews.ts` (2026-11-15).
**Limit, not fixed (inherent):** CI runs the guard code of the commit it judges, so a pushed
commit that edits `tools/release/` or `release.yml` judges itself (`release.md` § "Review records").

## ✅ KI-29 — The review check compared decoded text, file names without modes, and records nobody sees (class 1 retest 2; 2026-11-15, FIXED)

**Same class, found by the class's second retest (fresh reviewer; 1–4 RUN, 5 by grep):** (1) the
bump commit was compared as text decoded from UTF-8, so changing an invalid byte or adding a BOM
in the bump commit passed; (2) a mode change (`chmod +x`) of a bump file passed; (3) a gitlink moved
after the review was invisible when `.gitmodules` said `ignore = all`; (4) a record inside an HTML
comment or a code fence counted; (5) `Fil-C.md` named the current version, a sixth place no guard
checked or bumped. **Found by the session while fixing:** `bump.ts` itself read and wrote the three
files as UTF-8, so a bump of a file holding an invalid byte would have rewritten it as U+FFFD.
**Fix** (`guards.ts`, `bump.ts`, `Fil-C.md`): git output kept as bytes (`Git` → `raw`); the bump
compared blob for blob (`git cat-file blob`, `Buffer.equals`), edited one character per byte
(latin1) in both the check and `bump.ts`; each bump file must be mode `100644` on both sides
(`git ls-tree`; a symlink, gitlink or executable is refused by the mode); every diff
`--ignore-submodules=none --no-textconv`; every git call `--no-replace-objects`; records count only
outside HTML comments (an unclosed one runs to the end) and fences; `Fil-C.md` now names
`0.15.2-0.687.<N>` and points at the five places. **Test:** `guards.test.ts` (an invalid byte changed,
an exact bump of a file with one, a BOM, a chmod, a symlink, a submodule with `ignore = all`, a
replace ref showing a clean bump, records in comments and fences, and a sweep that the current
version is named only in its known places); 8 more mutants. **Inversion 2026-11-15: 26 of 26 caught,
the unmutated copy passing first** (the mutant run now refuses to start otherwise — the first run of
this round was void: the sweep failed in every copy on a doc comment naming the real version, which
the working tree hid because `guards.ts` was untracked; the example is a placeholder now). A type
check added first was seen by no test (the mode check always refuses first) and was removed.
`bun test tools/release/` 73/73.

## ✅ KI-30 — Stale version mentions, entries hidden from the page, and tags the owner's machine had not fetched (class 1 retest 3; 2026-11-15, FIXED)

**Same class, found by the class's third retest (fresh reviewer; no way for unreviewed code
through; 1–4 RUN):** (1) the version-places sweep exempted whole bump files, so a second mention of
the version in `README.md` or `src/root.zig` passed every guard and would go stale at the bump
(`src/root.zig` itself named it 4 times: two doc examples and an ordering-test literal); (2) a
`### v<version>` heading inside a fence or an HTML comment counted as the entry; (3) the fence
parser closed on any fence line (a shorter one, one with text after it, the other character), and
records inside `<script>` / `<style>` / `<pre>` / `<textarea>` blocks counted; (4) `bump.ts` never
fetched, so after CI tagged a release the owner's clone named an older "previous release" than CI
would — `bump.ts` accepted what CI then refused, and a refused bump commit can never be released
(the decide step releases only `bump to v…`), so the version would be skipped. **Fix:** every bump
file must name the current version exactly once (`guards.ts` `mentions`, in `disagreements`, so
`bump --check` and CI see it); `src/root.zig`'s examples use `0.15.2-0.680.4` / `0.700.1`; one
`visibleLines` for the entry lookup and the records (CommonMark closers; the four hiding HTML blocks);
`bump.ts` and `release.ts` fetch origin's tags and refuse when the `v*` tags here and on origin
differ in either direction (`tagsDifferFrom`). **Test:** `guards.test.ts`: second mentions in each
bump file, `…1` in `…10`, entry headings in a fence / comment / `<pre>`, the fence and HTML cases,
records after a properly closed fence, `bump.ts`'s pre-bump path (`bumped = false`, which had no
test), the tag comparison against a bare-clone origin each way and with origin gone, and **the
workflow's decide step run as written in `release.yml`** (bump commit, child, re-run, released
before). 7 more mutants: **33 of 33 caught** on a passing baseline; `bun test tools/release/`
90/90; the scratch end-to-end release bumps (its `zig build test` on the edited `src/root.zig`
passing) and passes `check-reviews.ts` (2026-11-15). **Not fixed — owner, 2026-11-15: "c", decided at the next Fil-C move (item 5
of the retest; `upstream.md` Stage A step 9):** a Fil-C or Zig move cannot pass `check-reviews.ts`, which requires the bump commit
to be exactly `bumpEdits` (N + 1, three files), while the upgrade procedure moves every pin and
resets N to 1 (`open-work.md` § Review).

## ✅ KI-31 — The guard emulated GitHub's Markdown, and each retest found another corner; now it refuses what it cannot read (class 1 retest 4; 2026-11-15, FIXED)

**Same class, found by the class's fourth retest (fresh reviewer; no way for unreviewed code
through; 1–5 RUN):** (1) comments were stripped before fences were read, so `<!-- -->` + ` ``` ` on
one line closed a fence for the guard that stays open on GitHub, and `<!--` inside inline code ate
text to the next `-->`; (2) `<?…?>` and `<![CDATA[…]]>` were read as visible, and an entry did not
end at a setext heading, an indented `##`, a bare `###` or `#<tab>`; (3) the five-places check read
RELEASE-NOTES.md and the State row RAW, so a notes heading in a comment or a fence passed; (4) no
time limit on `ls-remote` or on `release.ts`'s git calls (a hung remote waited forever); (5) a CR
byte broke the entry lookup. **The class's lesson:** four retests found four more ways an emulation
of a renderer can be made to disagree with the renderer. **Fix — refuse, do not emulate**
(`guards.ts`): `unreadable` refuses, by name, a CR byte (LF only — owner, 2026-10-01 and again
2026-11-15: "we should be using LF as the standard not CRLF") and any HTML comment, declaration,
processing instruction, CDATA or HTML block outside inline code and fences; the three Markdown
places are read only from files it passes, outside fences; `findEntry` reads only inside the one
`## Release History` section, which may hold no fence at all, and an entry ends at any heading-like
line; an entry holding a fence or a heading-like line is refused; one fence reader (`fenceLines`)
serves both `unreadable` and `visibleLines`, so they cannot disagree about what is code; every git
call has a time limit that returns when it fires (killing git does not close pipes a remote helper
still holds — found by this round's own test). Measured first: none of the real files holds a CR, a
comment, a PI or an HTML block; the one fence in `cmem/release.md` is above the section. **Test:**
`guards.test.ts` (each refused form; the notes and State-row hiding cases; inline code naming markup
allowed; a comment inside a fence allowed; a shorter fence line not closing a longer fence; the
branches no test reached — an empty bump commit, a record naming a non-commit, a parent without a
version, a parent `bumpEdits` cannot bump, bump files executable on both sides, injected git
failures in `describe` and `merge-base`, a remote helper that never answers). **Inversion,
2026-11-15: 45 of 45 mutants caught on a passing baseline** (two missed at first — no test showed a
comment inside a fence allowed, or a shorter fence line not closing — tests added).
`bun test tools/release/` 120/120.

## ✅ KI-32 — A fence inside a list item: the guard's one remaining reading of Markdown structure (class 1 retest 5; 2026-11-15, FIXED)

**Same class, found by the class's fifth retest (fresh reviewer; RUN end to end):** the fence reader
took an INDENTED fence (` ```` under`- item`) as a fence running to its matching closer, but on
GitHub a fence in a list item ends with the item, so a column-0 `<!--`after it is a live comment
that can hide the whole Release History section — while the guard skipped that`<!--` as "inside a
fence" and passed (`check-reviews.ts`exit 0,`bump --check` exit 0). The same trick split the
README status line in two readings. Smaller, same round: a one-dash setext underline (`-`) was not
heading-like; `outsideCode`paired an escaped backtick and backtick runs of different lengths
(CommonMark § 6.1 pairs only equal runs); the shared`run()`in`tools/lib/tool.ts`(release.ts's
git helper, bump.ts's fetch) waited for the pipes after a timeout kill — the hang`gitIn` had just
been fixed for. **Fix:** fences only at column 0 (`fenceLines`), and any fence-like line after
indentation, a list marker or `>` is refused by name (`containerFence`) — the guard no longer reads
container structure at all, it refuses it; `headingLike`takes`-+`; `outsideCode`removes escaped
backticks first and pairs only equal runs;`run()` stops waiting 2 s after its timeout kill
(`tools/lib/tool.ts`, all tools: behaviour changes only where a timeout fires and something still
holds the pipes, which used to hang). Measured first: none of the four Markdown files holds an
indented or prefixed fence, a lone `-`line, or an escaped backtick. **Test:** the reviewer's trap
above the section and in the README; fences indented, quoted, nested-quoted, after`-`/`1.`/ a
tab; an indented CLOSER of a column-0 fence still closing (allowed); the one-dash underline; both
backtick cases;`run()`against the never-answering remote helper (exit 124 within the limit).
**Inversion 2026-11-15: 51 of 51 mutants caught** on a passing baseline;`bun test tools/release/`
133/133; the scratch end-to-end release passes.

## ✅ KI-33 — The comment check subtracted code spans first, which is the renderer's call (class 1 retest 6; 2026-11-15, FIXED)

**Same class, found by the class's sixth retest (fresh reviewer; RUN at unit level; spec-reasoned):**
`unreadable` removed what it took for inline code spans before looking for `<!--`, but which
backticks pair is decided by CommonMark's precedence: a backtick inside a tag's attribute
(`<b title="`">`) is no span opener, and a backslash inside a span does not escape (§ 6.1, § 6.6) —
so a live comment passed, and the README status line could pass while a reader saw no version.
Smaller: inline `<details>`/`<summary>` (which collapse what follows on GitHub, everything after an
unclosed one) passed anywhere but a line start; the status line's version could sit in a tag
attribute, a code span or strikethrough. The records, entry headings, notes heading and State row
were NOT reachable (fixed column-0 text, which an inline construct cannot swallow — the reviewer's
analysis). **Fix:** the checks run on the RAW line — no code span is ever subtracted (`<!--`even in
backticks is refused; zilc's files hold none, measured);`<details>`/`<summary>`refused anywhere
outside column-0 fences; the text before the status line's version may hold no`<`, backtick,
backslash or `~`. Placeholders such as `<n>` or `` `<Zig>` `` mid-line stay allowed (they hide
nothing a guard counts). A `(?!~)`written for strikethrough after the version was seen by no test
(GFM strikethrough needs`~~`on both sides, and the prefix rule already refuses the opening one)
and was removed. **Test:** the reviewer's two inputs,`<details>`mid-line / indented / quoted / in a
list,`</summary>`, the status version in an attribute / struck through / in a code span, and
placeholders allowed. **Inversion 2026-11-15: 51 of 51 mutants caught** on a passing baseline;
`bun test tools/release/`144/144 (with a test that the real`cmem/release.md` stays readable — this ledger's own first wording of the rule put a literal tag there); the scratch end-to-end release passes.

## ✅ KI-34 — The two free-text places could be hidden by their surroundings (class 1 retest 7; 2026-11-15, FIXED)

**Same class, found by the class's seventh retest (fresh reviewer; rendered with Bun 1.4.4's
`Bun.markdown` — md4c, not GitHub's renderer; the CommonMark rules cited are documented, GitHub's
sanitizer behaviour inferred):** the records, entry heading and end, and the notes heading HELD
(block starts, which no inline construct crosses). The two places with free text around them did
not: (1) the README status version could be an image's alt text (`![logo (v…)](logo.svg)` — the
prefix allowed `!`, `[`, `]`); (2) a line BEFORE the status line in the same quote paragraph could
open a tag attribute (`> see <span title="`) that runs over it (an inline tag's quoted attribute
may span lines, § 6.6); (3) the State row was counted even when it was not in a table, so a
paragraph line before it could swallow it the same way. **Fix** (`guards.ts` `disagreements`):
before the status version only `[A-Za-z0-9 ,.:;/+-]`; the status line must follow a blank line (it
opens its own paragraph); the State row must be a row of a real table (a header and a delimiter
row above it, all lines `|`-led) — a cell cannot be reached by an attribute opened outside it.
Measured first: the real README and `open-work.md` already have that shape. **Test:** the alt-text
form, each of `[ ] ! $ * _` before the version, the quote-paragraph continuation, a State row
outside a table and one under a header with no delimiter row. **Inversion 2026-11-15: 54 of 54
mutants caught** on a passing baseline; `bun test tools/release/` 154/154; the scratch end-to-end
release passes.

## ✅ KI-35 — The State-row table check did not count cells (class 1 retest 8; 2026-11-15, FIXED)

**Same class, found by the class's eighth retest (fresh reviewer; RUN end to end — `bump --check`
exit 0 on the edited real file; GFM's rules documented, cmark-gfm not run, md4c agrees):** the
State row was required to sit under a header and a delimiter row, but GFM makes those a table ONLY
when both have the same number of cells, and drops a row's cells past that number. So (A) a header
of 2 cells over a delimiter of 3, its header cell opening `<a title="`, was no table at all — one
paragraph, the State row inside an attribute; (B) a one-column table rendered the State row without
its version cell. Smaller: the status message hid the real cause when an em dash or an apostrophe
came before the version (both harmless, now allowed); YAML front matter (`---` at line 1, rendered
by GitHub as a table) was not refused; `run()`'s raced promise could reject unhandled after its
give-up. Nothing in the non-Markdown core was broken. **Fix:** `cells()` splits a row on every
unescaped `|` (in code spans too, as GFM does); the header and the delimiter row must have the same
count, at least 2, and the State row the same; the header may hold no `<`; front matter refused;
the status message names the expected form and the allowed characters; `run()` catches the
raced promise. Measured first: the real State table is 2 cells in every row; every file starts
with `#`. **Test:** shapes A and B, a wider State row, the cell split (code span, `\|`, no outer
pipes), front matter, an em dash and an apostrophe allowed. **Inversion 2026-11-15: 60 of 60
mutants caught** on a passing baseline; `bun test tools/release/` 160/160; the scratch end-to-end
release passes.

## ✅ KI-36 — A fence that splits the State table, symlinked counted files, entries past their section (class 1 retest 9; 2026-11-15, FIXED)

**Same class, found by the class's ninth retest (fresh reviewer; 1–2 RUN end to end, `bump --check`
exit 0):** (1) the State table's rows were walked on VISIBLE lines, which had the fence lines
removed — a column-0 fence between the table and the State row (or between header, delimiter and
rows) ends the table on GitHub, and the row renders as a paragraph; (2) `RELEASE-NOTES.md` or
`cmem/open-work.md` as a symlink passed — the guard read through the link, while GitHub shows the
link at that path (the Release page links `blob/<tag>/RELEASE-NOTES.md`); (3) a `### v<version>`
entry under a LATER `##` / `#` section still counted; (4) a `$$` math block was not refused
(unverified on GitHub; refused by name, cheap); (5) no test tied `release.yml`'s review step and its
`if:` to the guard. The non-Markdown core held again. **Fix:** the State table is checked on the raw
lines (a fence line breaks it; the row is the first one outside a fence); the four counted Markdown
files must be mode `100644` at the commit (`MD_PLACES`, in `reviewsCoverRelease`, so CI and both
tools), and `bump.ts` refuses a symlink in the working tree; the Release History section ends at
the next level-1 or level-2 heading; `$$` refused; a test asserts the review step, its `if:`, its
command, and `tag` needing `checks`. Measured first: no `$$` line, all four files `100644`, nothing
after Release History at level 2. **Test:** fences splitting the table (two places), `$$`, an entry
under a later section (two forms), the section's last entry ending at the next section, each of the
two files as a symlink at the commit, the workflow's review step. **Inversion 2026-11-15: 64 of 64
mutants caught** on a passing baseline; `bun test tools/release/` 168/168; the scratch end-to-end
release passes.

## ✅ KI-37 — A paragraph line above the State table, GFM's ASCII-only trim, and smaller (class 1 retest 10; 2026-11-15, FIXED)

**Same class, found by the class's tenth retest (fresh reviewer, on the committed `2e557d5`; 1–2
RUN, rendered with md4c; a 20,000-mutation fuzz found 2 independently):** (1) the State table was
not required to start a block: a quote or list line (`> <a title="`) just above the header takes it
as a lazy continuation, and the "table" is that paragraph, the version row inside an attribute;
(2) `cells()` used `trim()`, which strips Unicode whitespace (NBSP, BOM, U+3000 …) where GFM trims
only space, tab, VT and FF — a header ending in NBSP is 3 cells to GitHub, 2 to the guard. Smaller:
a leading BOM hid front matter from its check; `.github/README*` (which GitHub shows instead of
`README.md`) was not refused; `$$` was refused only at a line start; the `<` ban covered only the
header (and its delimiter half was dead code); an autolink at a line start and a one-dash delimiter
row (`|-|`, valid GFM) were refused. **Fix:** the State table follows a blank line or a heading; no
`<` from its header to the State row; `cells()` trims ASCII only; a BOM or non-ASCII whitespace
anywhere in a counted file is refused (`ODD_SPACE`, built from code points so the source holds no
invisible character); `$$` anywhere; `.github/README*` refused at the commit; autolinks and `-+`
delimiters allowed. Measured first: none of the four files holds a BOM, Unicode whitespace or `$$`
(the round record in `open-work.md` mentioned `$$` mid-line — reworded). **Test:** the lazy
continuation (four leads), four code points, the ASCII-only trim, a BOM before front matter, `<` in
a row above, a one-dash delimiter allowed, an autolink allowed and `<div>` refused, `$$` in four
positions, `.github/README.md`. **Inversion 2026-11-15: 72 of 72 mutants caught** on a passing
baseline; `bun test tools/release/` 182/182; the scratch end-to-end release passes.

## ✅ KI-38 — The guard stops reading Markdown for itself: GitHub's renderer decides what is shown, Biome formats (owner, 2026-11-15; FIXED)

**Why (owner, 2026-11-15):** retests 2–10 each found another way GitHub's rendering could differ
from the guard's own reading of Markdown, and KI-31–KI-37 answered by FORBIDDING valid Markdown.
The owner: "Characters that define valid markdown elements are not forbidden"; "a markdown record
that is not rendered is an error"; and, for formatting, "biome. I know it works correctly" (the
tool the other projects use). **Measured first:** GitHub's `POST /markdown` (`gfm`, unauthenticated,
8 calls) on the reviewers' hiding cases — a comment removed; an attribute's and an image's alt text
kept out of the text; `<details>` kept, collapsed; a list item's fence ending with the item; a
mismatched table not a table; a plain record a visible `<li>`. Biome 2.5.x ignores `.md` (2.5.14:
"These paths were provided but ignored"); 2.6.0 (2026-10-21) is the first with Markdown; 2.6.4
(2026-10-28, the newest at least two weeks old) parses, formats and fails `ci` on an unformatted
file; it refuses comments in `biome.json` (so `biome.jsonc`). **Fix:** (1) `renderedProblems`
(`guards.ts`) renders the counted files with GitHub's renderer (`githubRender`: the REST API, never
`gh`; CI's token; any failure throws) and requires, as TEXT nodes (an attribute is never text) not
inside a collapsed `<details>`: the `v<version>` heading with both records under it, the notes'
`## <version>` heading, the README status version in its quote, the State row as a table row —
in `check-reviews.ts` (CI, `release.ts`) and `bump.ts release`; (2) every forbidden-construct rule
of KI-31–KI-37 removed (only LF stays, owner's standard); the text side reads plain lines and ATX
headings — eight lines of fence and setext reading were then seen by no test (the rendered check
backs them) and were removed; (3) Biome: `biome.jsonc` (Markdown only, width 100, prose kept),
`tools/md/biome.ts` (Biome 2.6.4 fetched from npm's `@biomejs/cli-linux-x64`, sha256
`71d293b5…`, = the registry's sha512 integrity; a wrong hash installs nothing — RUN), a `checks`
step and `release.ts`'s cold gate; all 46 `.md` reformatted (43 files changed: table padding,
`_emphasis_`, list markers; one file needed a second pass). The reformat padded the State row
(`| version   |`), which the old exact pattern refused — the place is now matched with any padding.
**Test:** GitHub's own HTML for the eight cases (fixtures, verbatim); a stand-in renderer (Bun's
md4c, which keeps comments and `<details>`) for records in a comment / `<details>` / a fence / an
indented block, an entry heading in a fence, records under a later heading, two entry headings,
the status version in alt text and outside its quote, the notes heading in a comment, the State
row outside a table, the renderer's failures (non-200, no answer, a throwing renderer), the CLI
refusing a record GitHub would not show; and a live test against GitHub (`ZILC_LIVE_RENDER=1`,
off by default: 60 unauthenticated calls an hour) — PASSES. **Inversion 2026-11-15: 42 of 42
mutants caught** on a passing baseline; `bun test tools/release/` 117/117 (+1 live, skipped by
default). **Limit, recorded:** GitHub does not document that `/markdown` is the repository page's
exact pipeline; every case measured agrees (its output carries the page's `notranslate` classes and
`target="_blank"` links). `bump.ts`'s own render call and `tools/md/biome.ts` have no unit test
(both RUN by hand, 2026-11-15).
**Also:** Biome padded `Fil-C.md`'s table, and `zig build check-pins` (a Zig program that checks text pins, run by `zig build test`) matched the old spacing exactly and failed. For `.md` pins it now treats a run of spaces as one (`squeezeSpaces`, with its own unit test, wired into `zig build test`: 41/41); inverted — a `Fil-C.md` naming another release still fails. `zig fmt` formats the `.zig` files, Biome the `.md` files (owner, 2026-11-15: "zig fmt checks the zig format").

## ⏹️ KI-39 — Render-design retest: hidden blocks GitHub does not show (class 1 retest 11; 2026-11-15; SUPERSEDED 2026-11-19)

**Found (retest 11, all RUN against GitHub's `/markdown`):** a `<details>` nested in a list item
or paragraph, a summary inside an outer collapsed `<details>`, struck-through records and status
version, and a visible code-block copy while the counted line is hidden — each let the guard count
a place the reader does not see. Accepted, not fixed: a decoy HTML table row showing the State
row's facts while the real row is not a table (the reader sees the right version). Loud refusals
noted: `/markdown`'s 400 KB limit (`open-work.md` is about 60 KB); 60 unauthenticated renders an
hour locally, about 11 per release cycle (CI uses its token).
**Fix, committed in `cdbb031` (owner, 2026-11-19):** `renderedBlocks` (`tools/release/guards.ts`)
keeps text inside a collapsed `<details>` at any depth, or inside `<del>` / `<s>` / `<strike>`, out
of its block; `<details open>` is shown; numeric and `&nbsp;` references are decoded; records must
be list items again; the redundant `seen` filter is gone. `bun test tools/release/` 128/128, Biome
clean, `bump --check` ok, the live render passes (2026-11-15). **Not done:** the mutant run (in
flight at the pause, its harness lost with the scratchpad) and the fresh class 1 retest.
**Superseded (owner, 2026-11-19):** letter H37 replaces the record-paragraph check this guards
with a run of the review set, and takes the tests out of CI; review round 1 stopped
(`open-work.md`, top). **Done 2026-11-19:** H37 (d) replaced `check-reviews.ts` and the two
record lines with `review-gate.ts` and one `- Review complete: <commit>` line (the exact-bump and
history checks kept); (e) took every test and gate out of CI (`release.md`).
