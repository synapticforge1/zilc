# Known Issues — environment and project constraints

The OPEN and still-binding entries (constraints, partly open defects, the key facts KI-4 and KI-17).
Closed entries moved on 2026-11-23 (letter H38 step 4), IDs kept — search the ID:
`archive/known-issues-to-0.15.2-0.686.1.md` (KI-1, 5, 6, 8–12, 14, 15, 18–23) and
`archive/known-issues-after-0.15.2-0.687.1.md` (KI-24–KI-39, review round 1). Last verified 2026-11-23.

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

## ◐ KI-7 — Zig's std makes RAW `syscall` asm even with `-lc`; Fil-C refuses it (2026-09-30)

**MOSTLY FIXED the same day**: rewritten to the checked `zilc_syscall` helper; Zig OK 26 → 45/78,
no syscall-asm traps left. Remaining: `getcontext` (std level)

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

## 🔑 KI-17 — Zig's emitted IR is ALREADY OPTIMIZED, under an integral data layout (2026-09-30)

✅ **The unoptimized route is now the DEFAULT** (`--verbose-llvm-ir` + `-fllvm`;
`ZILC_OPTIMIZED_IR=1` restores the old one). Release modes all 76/78 as designed; gate 4/4

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
