# workarounds-build-time.md — build-time workarounds (split from workarounds.md 2026-11-23)

## KI-21 — std's stack-trace code compiled into every program (build time)

**Symptom.** Builds many times slower than native Zig: `62_directories` ReleaseSafe 40 s under
zilc vs 6.7 s natively, its IR 228k lines and 1,265 functions. Half of it is `debug.Dwarf`,
`debug.SelfInfo`, `compress.flate`, `sort.block` (sorting DWARF tables) and
`debug.FixedBufferReader`: std's DWARF unwinder and symbolizer.

**Class.** zilc's own gap, created by KI-17 (the unoptimized-IR route) together with KI-15.

**Root cause, measured** (IR caller analysis, 2026-10-01). KI-15 set `sys_can_stack_trace = false`,
but std tests it at RUN time. Two entry points keep the whole unwinder referenced:
`DebugAllocator` calls `debug.captureStackTrace` from `free`, `resize*` and `reportDoubleFree`
(with 0 frames), and `builtin.StackTrace.format` calls `getSelfDebugInfo` and `writeStackTrace`.
On the optimized route LLVM proved them dead and deleted them before Fil-C. On the unoptimized
route Fil-C instruments and compiles all of it, and Fil-C's code generation costs about 6× stock
LLVM's on the same IR (38.4 s vs 5.7 s for 62).

**Why the workaround is correct.** Two std-overlay patches (`src/stdpatch.zig`, overlay v4) put a
**comptime-known early return** at the top of both entry points:
`if (!sys_can_stack_trace) { stack_trace.index = 0; return; }` and
`if (!std.debug.sys_can_stack_trace) return writer.writeAll(…)`. Zig's semantic analysis stops at a
comptime-known `return`, so nothing after it is referenced or emitted. std uses this exact pattern
itself, in the same function (`if (builtin.os.tag == .freestanding) return;`, commented "avoid an
error … where it tries to call detectTTYConfig"). Behaviour is unchanged: the trace was already
empty, and a real walk would stop under Fil-C (KI-15).

**Result.** 62 ReleaseSafe 40 s → **8.0 s** (native 6.7 s); its IR 228k → 87k lines, 1,265 → 436
functions. It runs identically.

**Third route, Debug only (found 2026-10-01 evening).** `posix.unexpectedErrno` calls
`debug.dumpCurrentStackTrace` when std's "unexpected error tracing" is on, which is Debug. That
kept the whole unwinder, symbolizer and `compress.flate` in **every Debug program**: a trivial
program's Debug IR was 190,873 lines and 1,095 functions, 56k lines of them this code, plus 6
`indirectbr` (KI-4's trigger). Two more guards of the same kind (`dumpCurrentStackTraceToWriter`,
`dumpStackTrace`), overlay v5. **`04_constants` Debug: 9.9 s → 2.1 s** (IR 190k → 28k lines;
native Zig Debug with LLVM 1.1 s). Debug's "~5× Release" build time was this, not KI-22.

**Recognising a relative.** A zilc build much slower than native Zig: list the IR's lines by
namespace (`irstat.sh`-style awk over `^define`) and look for code that cannot run under zilc. Then
find who references it (callers of the namespace, from non-namespace functions). **Any std
behaviour we disable at run time must also be disabled at compile time**, or the unoptimized route
pays for it.

**Where.** `src/stdpatch.zig` (two patches, test "stack-trace entry points return before the
unwinder at compile time (KI-21)").

---

## KI-22 — Fil-C's frame-slot colouring is cubic on big Zig functions (build time, OPEN)

**Symptom.** `69_http-client` ReleaseSafe 132 s (native 20 s), 76% of it inside
`FilPizlonatorPass`. Debug (`filc -O0`) far worse: `crypto.tls.Client.init` alone ran 24 min
using 5.8 GB before it was stopped; the whole Debug build of 69 times out at 30 min.

**Class.** Upstream performance defect in Fil-C 0.685's pass, triggered by the shape of Zig's
unoptimized IR. Not fixed yet; options below.

**Root cause, measured** (time reports, synthetic scaling, gdb stack sampling and the pass source
at the binary's own commit `bb0d0a64`, 2026-10-01):

- Per function, the pass gives every pointer value the GC must see (escaping allocas and pointer
  SSA values) a frame slot (`FilPizlonator.cpp` ~2880–3076). It computes liveness (an iterative
  data flow copying an `unordered_set` per block), builds an **interference graph** (each
  definition × everything live), then **colours it greedily**: for each value, it tries
  `FrameIndex = 0, 1, 2, …` and **scans the whole adjacency set at each index**
  (lines 3054–3076).
- Zig's unoptimized IR puts **every local in an entry-block alloca, with no
  `llvm.lifetime.start/end`**. So every escaping alloca is live from function entry to its last
  use, they all interfere, and a function with N of them is a near-complete graph: the colouring
  costs about N³ hash lookups. `Client.init`: 100k lines, 912 allocas.
- gdb: **27 of 30 samples** at `-O1` were in that colouring loop (16 walking `Adjacency`, 11 in
  `FrameIndexMap` lookups). The same loop dominates at `-O0`.
- `-O0` is worse because Fil-C's own pre-pass clean-up (`filc-optimize`) only runs at `-O1`+ and
  cannot be forced on at `-O0`; without it there are more pointer values. For 62, the pass takes
  0.5 s at `-O1` and 3.6 s at `-O0`.
- Synthetic scaling at `-O1` (`scale2.ts`): N escaping allocas in one function: pass 0.08, 0.30,
  1.11, 4.67 s for N = 250…2000 (×4 per doubling). Calls alone: linear.

**Ruled out (each measured, so nobody re-tries them):** debug metadata (stripped: 116 s vs 117 s);
`llvm.assume` (120 s); Fil-C's DSE (`-filc-dse=false`: 108 s); check scheduling
(`-filc-optimize-checks`, `-filc-propagate-checks-backward`: 119–124 s, and slower builds overall);
the `-filc-inline-*` sub-passes (no effect at all: byte-identical objects); turning
`-filc-optimize` off (69: 172 s → **1,960 s**). **Splitting large basic blocks** (implemented and
measured, then removed): a synthetic single block of N stores IS quadratic at `-O0` (40k stores:
80 s vs 0.4 s in blocks of 16), but on 69 it changed nothing (131 s), because the real cost is the
colouring, and more blocks only make the liveness pass dearer.

**Specific to Fil-C, not to an LLVM version** (owner asked, 2026-10-01): the loop is in Fil-C's
own pass, which stock LLVM (and so Zig's bundled LLVM, any version) does not have. Plain Zig is
fast on the same code. **The trigger is Zig's IR shape, which does vary by Zig version:** measured
on one test module, Zig 0.16.0 still emits **no lifetime markers** and about **2× the allocas** of
0.15.2 (Debug 18,241 vs 9,202; ReleaseSafe 10,559 vs 4,755). So a 0.16 line would hit KI-22
harder. Re-check list: `ports/README.md`.

**Options (owner chose 2, then research 3; 2026-10-01):**

1. **Report upstream with a fix that changes no output.** Gather the neighbours' assigned indices
   once into a set or bitset, then take the lowest free index ≥ `NumSpecialFrameObjects`. The
   result is the same colouring (same order, same choice), so binaries stay byte-identical, at
   O(degree) per value instead of O(degree × colours). The same applies to the stack-aux colouring
   at lines 3146–3160.
2. **Build a patched Fil-C clang** with that fix. It works now and keeps output identical, but zilc
   has avoided building LLVM so far (hours; the owner's call).
3. ❌ **(Researched and rejected 2026-10-01: Fil-C erases escaping allocas' lifetime markers before
   liveness; see "Option 3 researched" below.)** **zilc inserts `llvm.lifetime.start` before each
   alloca's first use**, where that point dominates every use and lies in no loop. This shrinks the live ranges, so the graph is no longer
   a clique. It needs CFG, dominator and loop analysis in `src/ir.zig`, and a wrong marker
   miscompiles, so it carries the most risk.
4. **Accept it for now.** Typical programs are near native after KI-21; only functions with
   hundreds of escaping locals (TLS, big crypto) are slow, and Debug builds of them are impractical.

**Option 2, carried out (2026-10-01).** Fil-C's clang was built from the prebuilt's own commit with
the patch (`tools/filc/build-patched-clang.ts`; ~1 h; GCC 15.2 and CMake 4.2.3 from apt, Ninja
1.12.1 release binary). The version string matches the prebuilt exactly (the source remote must be
`git@github.com:…`, and the generated `VCSVersion.inc`/`VCSRevision.h` deleted to regenerate).
`69` at `-O1`: **112 s → 54 s** for Fil-C's clang alone.

**Option 3 researched and REJECTED (2026-10-01, owner asked to check its necessity after
option 2).**

- **Where the time is now** (`69` ReleaseSafe, patched clang, alone): zilc 55.9 s vs native Zig
  16.9 s. Fil-C's clang 55.4 s = pass **11.4 s** + LLVM's `-O1` optimizer ~18 s + code generation
  ~25 s. Stock clang on the same uninstrumented IR took ~15 s, so ~3× of the downstream work is
  the instrumentation's own size, inherent to Fil-C. Debug `69` is the same (54.5 s).
- **Inside the pass** (gdb with symbols, patched build): about 7 of 12 pass samples are in
  liveness and interference building (`FilPizlonator.cpp` 2970–2998), which is quadratic in
  simultaneously live pointers. That ~6–7 s (~12% of the build) is all that lifetime markers
  could ever have saved.
- **Why markers would not save even that:** `removeLifetimeIntrinsics()` **erases the lifetime
  markers of every ESCAPING alloca** before liveness runs, and keeps them only for non-escaping
  ones. The liveness and interference work tracks only escaping values (`LiveCast` returns null
  for anything else). So markers zilc inserted would be deleted before they could shorten any
  costly live range. **Option 3 cannot help build time.** It would also need CFG, dominator and
  loop analysis in `src/ir.zig`, with miscompile risk.
- **What did help instead:** the Debug-only std route above (KI-21, third route).
- **Levers that remain** (✅ **all three approved by the owner, 2026-10-01**; not started; next
  task):
  (a) split the module and run Fil-C's clang on the parts in parallel. Fil-C already compiles C
  one translation unit at a time, and 32 cores sit idle. (b) A faster interference build in the
  patched pass that produces the same graph. (c) Cache objects by IR hash for unchanged rebuilds.
  ✅ **(a) done 2026-10-02**, as the code-generation-only split below. ✅ **(b) and (c) done the
  same day** (sections after (a)).

**Lever (a) carried out (2026-10-02): split CODE GENERATION only, after the whole-module pass.**

- **What zilc does now** (`filcCompile` in `src/driver.zig`, for Fil-C-dialect IR ≥ 4 MB, `-j` /
  `ZILC_JOBS` jobs, default = cores up to 16, `-j 1` = off):
  1. Fil-C's clang runs the pass and the `-O1` optimizer on the WHOLE module and stops at bitcode:
     `-c -emit-llvm -Xclang -emit-llvm-uselists`.
  2. zilc's mode of `llvm-split` (`tools/filc/patch-split.ts`, installed next to clang) writes
     each part, one process per part, in parallel: `-j N --zilc-part=I --zilc-keep-global=FILE`.
  3. Fil-C's clang generates each part's code in parallel: `-Xclang -disable-llvm-passes -c -x ir`.
     This skips the IR pipeline (no pass, no optimizer) and keeps clang's own code-generation
     settings, so there is nothing to match by hand as there would be with `llc`.
  4. `ld -r` joins the parts; `objcopy --keep-global-symbols=FILE` makes local again every symbol
     the input did not define as global.
  - The splitter exits 2 on a module shape it does not handle (ifuncs, comdats, unnamed locals,
    a global named with whitespace, no globals at all); zilc then generates the code whole from
    the step-1 bitcode. No `llvm-split` next to clang = the old single clang run.
- **Result** (`69` ReleaseSafe, through the driver, alone): **60.6 s → 43.9 s**; `62`: 7.0 s →
  5.0 s. Step 1 is now most of it (~34 s of `69`): code generation went from ~22 s to ~7 s, bounded
  by `crypto.tls.Client.init` (100k IR lines, one function, cannot be split). Lever (b) attacks
  step 1.
- **Same code, checked like for like:** the parts' functions against the unsplit compile of the
  SAME step-1 bitcode: **2,840 of 2,840 functions identical** (normalized disassembly, alignment
  padding after each function excluded, since it depends on the next function's position), same
  global definitions (name, binding, visibility), same undefined references, same stripped size.
  Program output identical. Only the unstripped file grows (8.2 → 10.4 MB): each part carries
  its own DWARF copy of the types it uses. Script: this session's scratchpad `cgsplit2.sh` +
  `cmpfuncs.ts`.
- **Why "same as one clang run" cannot be the test for `62`/`69`:** the step-1 process lays out
  the pass's hash tables differently from a one-step run, so the PASS'S output differs (the
  ASLR finding above, extended). Proof: a plain one-step build of `62` with only `-ftime-report`
  added (timers, nothing else) already changes the object; the deterministic control
  (`allocas2000`) does not. On every input whose pass output IS deterministic (the gate's C
  examples, `zilc_syscall.c`, the KI-4 repro, the 2,000-alloca stress), one-step and two-step
  objects are **byte-identical**.

**Why each piece is the way it is (the workarounds inside lever (a)):**

- ❌ **Split BEFORE the pass (rejected by the owner, 2026-10-02: bloat).** Measured first: stock
  `llvm-split -j 16` on the Fil-C-dialect IR, then the full clang on each part: clang stage 55 s →
  ~24 s, but the stripped binary **+37%** (6.5 → 8.9 MB), because the optimizer can no longer
  inline across parts (each part is a separate C file, in effect). Owner: _"What is another option
  that doesn't bloat the resulting binary, is reasonably speedy and maintains fidelity?"_
- **`datalayout_after_filc` (seen only on the rejected route, kept for the record).** Stock
  llvm-split drops Fil-C's second data layout: `CloneModule` does not copy the Fil-C-only
  `Module` field, and bitcode has no record for it (the line exists only in Fil-C's text printer
  and parser). The parts crash Fil-C's clang with the "Target-incompatible DataLayout"
  assertion. After the pass the module no longer needs it, which is one reason to split there.
- 🔑 **Use-list order decides x86 code generation (measured).** Stock llvm-split CLONES each part;
  cloning rebuilds every value's use-list in a new order, and 80+ of `69`'s functions came out
  with different register allocation. Same IR, same linkage: the function's IR body was identical
  and changing `internal` → `hidden` on the whole module changed nothing; but the SAME module
  read from text instead of bitcode (text does not keep use-list order) changed 13 of 797
  functions. Hence: step 1 writes the use-lists (`-emit-llvm-uselists`), and zilc's splitter
  makes each part by DELETING the bodies it does not own (`deleteBody`), which keeps the
  surviving uses in their original order, and writes with use-list order preserved. Verified
  with `llvm-extract` on one function before writing the splitter.
- **Unused hidden declarations (`TLS reference … mismatches non-TLS reference`).** Every part
  declares every global. An unused declaration with HIDDEN visibility is still emitted as an
  undefined symbol, untyped (NOTYPE). Fil-C reads thread-locals directly
  (`@pizlonatedTP_Thread.LinuxThreadImpl.tls_thread_id = … thread_local …`), so GNU ld saw an
  untyped reference against the TLS definition in another part and refused. The splitter drops
  unused declarations; an unused declaration emits no code.
- **Locals used across parts.** Made `hidden` external with `dso_local` in every part (the
  plan is computed identically in every process: largest function first, to the least-loaded
  part, ties in module order; global variables in part 0). Linkage does not change code
  generation (measured above). After `ld -r`, `objcopy --keep-global-symbols` makes them local
  again, fed the input's OWN global definitions, not the list of exposed locals: (1) Zig names
  contain spaces (`crypto.sha2.Sha2x64(.{ 7640… })`), and objcopy's symbol files end a name at
  whitespace ("Ignoring rubbish found on this line"); the input's globals are few (49 in `69`)
  and plain, and the splitter refuses a module whose globals are not. (2) Not
  `--localize-hidden`: Fil-C's output has WEAK HIDDEN globals of its own (25 in `69`,
  `pizlonatedFI27932_write` etc.), which must stay global. (3) An EMPTY keep list means "no list"
  to objcopy, so the splitter refuses a module with no globals.
- **`ld -r` directly, not `clang -r`.** Fil-C's clang driver adds `filc_mincrt.o` even to
  `-r -nostdlib`, which put a second `main` into the joined object. zilc asks clang for its
  linker (`-print-prog-name=ld`) and runs it.
- **Memory.** Per process on `69`: splitter ~270 MB, code generation ≤ 740 MB, so 16 jobs stay
  under ~8 GB. The corpus script, which already runs 12 builds at once, sets `ZILC_JOBS=4`.

**Cost and exit.** Cost: an extra bitcode write and N parses of it (~2 s on `69`), larger
unstripped binaries (debug info). Below 4 MB of IR it is off (the processes cost more than they
save). Exit: none needed; it is how a parallel build works. If Fil-C's pass became deterministic,
one-step and two-step objects could be compared byte for byte on every input.

**Recognising a relative.** Any future "same IR, different machine code" puzzle: check use-list
order first (text vs bitcode, cloned vs original module). Any "TLS mismatches non-TLS": look for
an unused hidden declaration of a thread-local.

**Lever (b) carried out (2026-10-02): the pass's interference graph over dense ids.**

- **Where the pass's time was** (gdb samples of the whole-module step on `69`, after lever (a);
  the pass was 11.2 s of a 31 s step, the rest LLVM's own `-O1` passes): 17 of 44 pass samples
  in the interference build's hash-set inserts (`FilPizlonator.cpp` 2997–2998 at `bb0d0a64`),
  6 in the colouring's `FrameIndexMap` lookups per neighbour (3072–3073), 4 in `EraseIf`
  (1033–1035), 3 in liveness (2970).
- **The change** (`patch-pass.ts`, edit "interference graph over dense ids", plus the colouring
  edit): every value gets a number and one id per pointer slot; the live set during the
  interference walk is a dense set of value numbers (O(1) insert and erase); a neighbour list is
  a plain `std::vector<uint32_t>`; the colouring reads a dense "index held" array that mirrors
  `FrameIndexMap`. Duplicate neighbours are allowed: the colouring only asks which indices the
  neighbours hold, and its `Taken` vector, sized by the list length, still has a free slot in
  range. Liveness itself (the fixpoint) is unchanged.
- **Why it is the same graph, and the details that keep it so:**
  - The def × live loop counts a live value's slots with `countPtrsForValue(LV)`, but the
    argument loops count an argument's with `countPtrs(type)`. The two can differ for a byval
    argument, so each value's id range covers the larger, and each loop uses the count the
    original used.
  - `FrameIndexMap` already holds `Ignored` entries (index 0) when the colouring starts, and the
    original sees them as taken indices, so the dense array is filled from `FrameIndexMap`, not
    started empty.
  - `ZILC_VERIFY_INTERFERENCE=1` also runs the original construction, verbatim, and aborts unless
    every value's neighbour SET is equal (both directions: no value missing from either graph).
    With `ZILC_VERIFY_COLOURING=1` the original colouring search runs too, reading
    `FrameIndexMap` itself, which also checks the mirror array. **Both on, the whole corpus in
    all four modes: no difference** (the verified `69` builds took 154–431 s, proof the original
    code ran).
- **Result:** the pass on `69` **11.2 s → 4.3 s**; the whole-module step 31.2 → 24.7 s, peak
  ~1.0 GB. Through the driver: `69` ReleaseSafe **43.9 → 35.9 s** (split), `-j 1` 60.6 → 49.9 s.
  The 2,000-alloca stress test: unchanged (13.2 vs 13.1 s; its pass time is elsewhere). What is
  left in the pass has no hotspot (a re-profile spreads 18 samples over 14 places); the rest of
  the step is LLVM's own optimizer (SROA 4.2 s, InstCombine 3.0 s, …), which would change the
  output if touched.
- ⚠️ **Whitespace trap in the edit's original text:** `FilPizlonator.cpp` has a line of six spaces
  after `Live = LiveAtTail[BB];`. The file editor trimmed it from the edit, and the patch failed
  with "original found 0 times". Restored with `sed`, and marked in `patch-pass.ts`.
- `build-patched-clang.ts` now applies each edit script to a fresh copy of the PRISTINE file
  (`git show $SHA:path`) and replaces the tree's file only if the result differs: changing an
  edit's replacement text used to require resetting the file by hand, and rewriting an unchanged
  file made ninja rebuild clang.

**Lever (c) carried out (2026-10-02): the object cache.**

- **What:** before running Fil-C's clang on a module, zilc looks for
  `<cache>/objects/<key>.o` (cache = `$ZILC_CACHE_DIR`, else `$XDG_CACHE_HOME/zilc`, else
  `~/.cache/zilc`, the same root as the std overlay) and copies it on a hit; on a miss it compiles
  and stores the object (written through a temporary and renamed, so never half an object).
  `--no-cache` / `ZILC_CACHE=0` turn it off. `cacheLookup`, `objectKey` in `src/driver.zig`.
- **The key** (Blake3): the final Fil-C-dialect IR, zilc's version, a tag for zilc's clang
  command lines (`filc_commands_tag`: bump it when they change), the plan (parts count), and the
  IDENTITY of the clang and `llvm-split` binaries that would run: resolved path (PATH searched
  like the OS), size, mtime, inode. **Not `clang --version`:** the patched clang deliberately
  keeps the prebuilt's exact version string, so a rebuilt compiler would be invisible to it.
- **Why reuse is faithful:** Fil-C's own output is not reproducible run to run (pass ordered by
  heap addresses, above), so an earlier object for byte-identical input is as faithful as a
  fresh compile; the program it produces passed the same checks.
- **Result** (same source, same output path, built twice): `69` **36.0 → 2.3 s**, `62` 5.4 →
  0.5 s. Zig's IR is identical run to run (checked).
- **Limits:** (1) The key includes the OUTPUT path in effect: the entry shim lives in
  `<output>.zilc-tmp/`, and its path is in the IR's debug info, so the same program built to a
  different output path misses (seen in the first test, which used a new directory per run).
  (2) No automatic eviction: each entry is a full object (`69` ~11 MB). `zilc --clean-cache`
  (owner asked for it, 2026-10-02) deletes `<cache>/objects` and reports the files and MB freed;
  it keeps the std overlay, which every Zig build needs and would only recreate.
  (3) The corpus script sets `ZILC_CACHE=0` so its recorded build times stay real compiles.

**How the patch was proved output-identical, and why byte comparison could not do it:**

- 🔑 **Fil-C 0.685 is NOT reproducible run to run.** The SAME prebuilt clang compiling the SAME
  `62` IR twice gives different objects with ASLR on (Linux's default), and identical ones under
  `setarch -R`. The pass iterates hash tables keyed by pointer addresses, so heap addresses decide
  the emitted order. ⚠️ **This bears on the owner's FIDELITY FIRST goal** (user binaries
  byte-identical to upstream, `roadmap.md` P3): upstream itself is only reproducible with ASLR
  off, and probably only for one exact build of the compiler. Any byte-identity check must run
  with `setarch -R`, and between two DIFFERENT compiler binaries it can still differ on large
  inputs (heap layout differs).
- Under those rules (`tools/filc/compare-clangs.ts`), prebuilt vs patched is **identical** for the
  gate's C examples, `zilc_syscall.c`, the KI-18 repro (both assert) and the 2,000-alloca stress
  test at `-O0` and `-O1`, but **different** for `62` and `69`: two different binaries.
- So equivalence is checked **inside one run**: with `ZILC_VERIFY_COLOURING=1`, the patched pass
  also runs the original search for every frame slot and aborts on any difference. It passed on
  the stress test, `62` (`-O0`, `-O1`) and `69` (`-O1`, where it restored the original cost:
  108 s, proof it really ran), then on the whole corpus in all 4 modes (results in `testing.md`).

**Where.** Measurement scripts: this session's scratchpad (`scale.ts`, `scale2.ts`, `split.ts`,
`sample.sh` + `sampler.py`, gdb from `apt-get download` into `~/zilc-work/tools/gdb`, needs
`LD_LIBRARY_PATH`). Pass source: `~/zilc-work/filc-src/FilPizlonator.cpp` (reading the pass is
allowed, owner 2026-10-01).

---
