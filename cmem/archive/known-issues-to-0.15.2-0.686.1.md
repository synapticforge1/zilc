# Known issues closed by release 0.15.2-0.686.1 (2026-10-05) — archived 2026-11-23 from known-issues.md

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

## ✅ KI-11 — Zig 0.15.2's `indexOfSentinel` over-reads; under Fil-C it is an OOB read. **FIXED 2026-09-30 by backporting upstream's 0.16.0 fix** (owner chose option 1)

`67_environment-variables`: `cannot read 16 bytes when upper - ptr = 12` at `mem.zig:1118:48`. std's
SIMD sentinel scan reads past the end of the string's object, up to the page boundary. Full analysis,
minimal reproduction and report draft: `zig-upstream-notes.md` **Z-1**,
`tools/zig-reports/sentinel-overread/`. **Fixed upstream in 0.16.0** (a scalar `findSentinel`).

✅ **Done:** `src/stdpatch.zig` builds a cached **std overlay**
(`~/.cache/zilc/std-overlay/0.15.2-v1`: a real copy of `std/`, everything else symlinked) and
applies the **0.16.0 `findSentinel` body**; the driver passes `--zig-lib-dir`. Each patch **verifies
the exact original** and fails the build otherwise; Zig 0.16.0 has no patch set and gets no overlay.
Result: the repro prints `len = 11` under zilc, `67` gets past `getenv`, gate 4/4, no corpus
regressions. Ledger: `zig-std-backports`. History of the decision follows.
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

## ✅ KI-20 — `std.crypto.random` probes `madvise` with an invalid advice (2026-10-01, FIXED)

`69_http-client`: `filc safety error: attempting to use unrecognized madvise advice -1`. std's
CSPRNG deliberately passes `0xffffffff` to detect QEMU and expects `EINVAL`; Fil-C stops instead.
**Fix:** the entry shim sets std's official `std_options.crypto_always_getrandom = true` (kernel
CSPRNG on every fill, fork-safe). 69 now completes a real HTTPS request in every Release mode.
Library mode covered 2026-10-02 (library root; gate case 7). Details: `workarounds.md` KI-20.

## ✅ KI-21 — Build time: std's stack-trace code was compiled into every program (2026-10-01, FIXED)

KI-15 disabled native stack walking at run time only; on the unoptimized route (KI-17) Fil-C still
instrumented and compiled the whole DWARF unwinder (about half of `62_directories`' IR). **Fix:** two
std-overlay guards with a comptime-known early return (`captureStackTrace`,
`StackTrace.format`), overlay v4. **62 ReleaseSafe 40 s → 8.0 s** (native 6.7 s); IR 228k → 87k
lines. **Third route, Debug only (2026-10-01 evening):** `posix.unexpectedErrno` →
`dumpCurrentStackTrace` (std's Debug "unexpected error tracing"); two more guards, overlay v5.
Trivial Debug programs 9.9 s → 2.1 s. Details: `workarounds.md` KI-21.

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
