# Testing

## 🎯 `zig build gate` — THE SAFETY GATE (new 2026-09-23). **8/8 green** (2026-10-02: + the KI-5 environ case and 3 library-mode cases, which must RUN)

Builds every example with the zilc driver and asserts each one **traps at the right source line**.
This is the gate the whole project exists to keep green.

| # | case | traps at | fault |
| --- | --- | --- | --- |
| 1 | interop: C allocates, Zig overflows | `bounds.zig:13:6` | `ptr >= upper` |
| 2 | whole Zig program (generated entry shim) | `hello.zig:25:6` | `ptr >= upper` |
| 3 | C out-of-bounds write | `oob_write.c:15` | `ptr >= upper` |
| 4 | C use-after-free | `use_after_free.c:13` | `free object` |

**Each case asserts four things**, because any one alone is fakeable: the process died on **SIGTRAP**;
the output contains `filc safety error`; the `semantic origin` names **that file:line**; and the
violation is of the expected **kind**. ⚠️ *Exit status alone accepts a crash for the wrong reason —
and a `-O0` link failure earlier in this very session produced an equally non-zero exit for a
completely unrelated reason (a missing stack probe).*

✅ **Inversion-tested 2026-09-23:** with one expected origin changed to a line that does not exist,
the gate **failed** and printed the real panic. A gate that cannot fail proves nothing.

```powershell
deno run -A tools/run-gate.ts            # from Windows
```
```sh
ZILC_FILC=…/build/bin/clang ZILC_ZIG=…/zig zig build gate    # from Linux
```

⚠️ **Where Fil-C is absent the gate SKIPS and exits 0**, printing what to set. A build that never had
a chance to pass must not read as a failure — but that also means *a green `zig build gate` on
Windows means nothing*. Read the first line.

## 🧪 `tests/basics`: 156 CORRECT programs (C + Zig), added 2026-09-30

The owner's "Basics of Coding" lessons, 78 in C and the same 78 in Zig (provenance, licence and every
change: `tests/basics/README.md`). The gate proves **bugs trap**. This corpus proves **correct
programs don't**, and gives size numbers against plain Zig. Tools in `tools/basics/`.

| check | C | Zig 0.15.2 |
| --- | --- | --- |
| compiles + links, plain Zig 0.15.2, `-lc`, musl | **78/78** (after 5 portability fixes) | **78/78** (after converting 60 files from 0.13/0.14) |
| runs as designed, plain ReleaseSafe | **78/78** | **78/78** exit codes. ⚠️ Outputs were wrong when redirected until the stdio streaming fix (2026-09-30, `tests/basics/README.md`) |
| **builds with zilc** | **78/78** | ReleaseSafe ~~50/78~~ → **77/78** after the KI-8 fix (only KI-9 left) · ReleaseSmall **77/78** (KI-9) |
| **runs as designed under zilc** (ReleaseSafe) | **78/78** (`42_panic` traps via Fil-C, as designed) | ~~24~~ → 26 (KI-8) → 45 (KI-7) → 50 (panic handler + KI-9) → **71/78** (KI-13 overflow fold + `fromPage` patch, KI-14 `-fno-valgrind`). 65 clean exits plus 6 intentional (`42` panic, `66` exit 1 without a subcommand, `77` exit 3, three servers). Then the **unoptimized-IR route** (KI-17, the default since 2026-09-30) → **76/78**: the 5 thread joins pass, and `76_signals` now runs (it waits, as designed). **Left, 2:** the KI-18 Fil-C assertion (`22_strings-and-runes`, `69_http-client`) |
| **every mode** (KI-16, default route) | same in every mode (C ignores `-O`) | ~~ReleaseSafe 76 · ReleaseFast 76 · ReleaseSmall 76 · Debug 63~~ → 2026-10-01: 78 · 78 · 78 · 65 (KI-18, KI-20) → **2026-10-01 (evening): 78/78 as designed in ALL FOUR MODES**, with the patched Fil-C clang (KI-22 colouring, KI-4 `indirectbr`) and Debug at `filc -O1` (fixes KI-19). Gate 4/4 with it. Tool: `tools/basics/all-modes.ts` (defaults to the patched clang) |
| **on Fil-C 0.686** (2026-10-05; patched 0.686 clang, `ZILC_VERIFY_INTERFERENCE=1` + `ZILC_VERIFY_COLOURING=1`) | — | **Still 78/78 as designed in all four modes** (71 OK + the designed 7, C and Zig alike), **0 builds with a verification difference**, gate 8/8, tests **29/29**. `69` ReleaseSafe alone **38.0 s** cold (35.9 on 0.685). Output comparison re-run: 0 unexplained |
| **+ dense interference graph, object cache** (KI-22 levers (b), (c); 2026-10-02, same load, `ZILC_JOBS=4`, `ZILC_CACHE=0`) | — | **Still 78/78 as designed in all four modes**, gate 4/4, tests **25/25** (26/26 with `--clean-cache`, same day). **Verified run:** the whole corpus in all four modes with `ZILC_VERIFY_INTERFERENCE=1` and `ZILC_VERIFY_COLOURING=1`: 78/78 as designed, **no graph or colouring difference** (verified `69` builds 154–431 s, so the original code really ran). `69` under load: Debug **56 s** (was 68), ReleaseSafe **58 s** (70), ReleaseFast **82 s** (97), ReleaseSmall **52 s** (61). Alone, through the driver: `69` ReleaseSafe **35.9 s** split (43.9 before (b)), 49.9 s at `-j 1`; rebuild unchanged, same output path: **2.3 s** (cache hit; `62` 0.5 s). Byte-identical to the prebuilt on every deterministic input (`compare-clangs.ts`) |
| **build time, + parallel code generation** (KI-22 lever (a); 2026-10-02, same load, `ZILC_JOBS=4` per build) | — | **Still 78/78 as designed in all four modes** (71 OK + the designed 7: `42` panic, `66` exit 1, `77` exit 3, `70`/`71`/`72` servers, `76_signals`), gate 4/4, tests 24/24. Medians unchanged (Debug 4 s, ReleaseSafe 4 s, ReleaseFast 4 s, ReleaseSmall 3 s). `69`: Debug **68 s** (was 79), ReleaseSafe **70 s** (81), ReleaseFast **97 s** (107), ReleaseSmall **61 s** (70). Alone, through the driver: `69` ReleaseSafe **60.6 s → 43.9 s** (`-j 1` vs default 16 parts), `62` 7.0 → 5.0 s, same program output. Code identity: 2,840/2,840 functions of `69` identical to the unsplit compile of the same bitcode (`workarounds.md` KI-22) |
| **build time, + overlay v5** (Debug-only KI-21 route guarded; 2026-10-01 late, same load) | — | Still 78/78 as designed in all four modes, gate 4/4. Medians: **Debug 4 s** (was 19), ReleaseSafe 4 s, ReleaseFast 3 s, ReleaseSmall 2 s. `69`: Debug 79 s, ReleaseSafe 81 s, ReleaseFast 107 s, ReleaseSmall 70 s. Alone: `04_constants` Debug 2.1 s (was 9.9; native Zig with LLVM 1.1 s), `69` ReleaseSafe 55.9 s (native 16.9 s) |
| **build time with the patched clang** (2026-10-01 evening, same load) | — | `69`: ReleaseSafe **112 s**, ReleaseFast **154 s**, ReleaseSmall **87 s**, Debug **83 s** (was a 30-min timeout). Medians: Debug 19 s, ReleaseSafe 4 s, ReleaseFast 3 s, ReleaseSmall 2 s. Alone, Fil-C's clang on `69` (`-O1`): prebuilt 112 s, patched 54 s |
| **build time** (2026-10-01, all 4 modes × 8 jobs at once, so inflated) | — | After KI-21: ReleaseSafe median **4 s**, `62` 19 s (was 92), `48_json` 30 s (was 86); `69` 214 s (ReleaseSafe), 754 s (ReleaseFast), timeout (Debug), all KI-22. Alone: `62` ReleaseSafe 8.0 s vs native 6.7 s; `69` 132 s vs native 20 s. `zilc-check.ts` now reports `BUILD-TIMEOUT` (`TBUILD`, default 1800 s) and writes `build seconds:` into each `build.log` |

**C already works under zilc across the whole corpus. Zig's gaps are all in std**, not the pipeline:
raw system calls, stack probes, f128 helpers, thread handles. That is P4, now with a
measured to-do list.

### Binary sizes (2026-09-30, x86_64-linux-musl, bytes, medians)

Zig's musl binaries are **static**. zilc's are **dynamic** and load Fil-C's shared runtime:
**`libc.so` 7.3 MB + `libpizlo.so` 9.1 MB + `libyoloc.so` 3.6 MB ≈ 20 MB**, installed once per
machine, not per program. zilc passes `-g`, so stripped sizes are the fair comparison.

| | Zig ReleaseSmall | Zig ReleaseSafe | zilc ReleaseSafe | zilc ReleaseSmall |
| --- | --- | --- | --- | --- |
| **C** (78), raw | 19,800 | 938,960 | 27,976 | n/a (C ignores `-O`) |
| **C**, stripped | 19,800 | 20,536 | **18,592** | n/a |
| **Zig** (the 50 all flavours built), raw | 16,832 | 2,330,200 | 565,624 | 89,632 |
| **Zig**, stripped | 16,832 | 270,512 | 341,360 | 76,896 |

Per-program ratios (median): C zilc/ReleaseSmall **0.86** stripped (smaller, since libc is not
inside). Zig zilc ReleaseSafe/ReleaseSafe **1.26** stripped; zilc ReleaseSmall/ReleaseSmall **4.36**
stripped (instrumentation plus Fil-C's calling-convention thunks). Tools:
`tools/basics/size-compare.ts`, `size-report.ts`.

## 📌 Experiment inputs that live outside the repo (record, owner 2026-10-05)

The phase experiments (`tools/p1`–`p3`) read some inputs from the Linux work area, not the repo.
All are committed sources EXCEPT three generated Zig IR files in `$WORK/p1` (≈12 MB each). Their
exact Zig 0.15.2 commands were recovered on 2026-10-05 and verified to reproduce the originals
(same code; only 3 debug-info lines differ: the build directory, and the hash of Zig's cache folder
for `builtin.zig`):

| file | made from | how |
| --- | --- | --- |
| `$WORK/p1/tiny.ll` | `tools/p1/tiny.zig` | `zig build-obj -target x86_64-linux-gnu -femit-llvm-ir=tiny.ll -fno-emit-bin tiny.zig` (in `$WORK/p1`) |
| `$WORK/p1/zig_oob-x86_64-linux-gnu.ll` | `tools/p1/zig_oob.zig` | `zig build-exe -target x86_64-linux-gnu -lc -femit-llvm-ir=zig_oob-x86_64-linux-gnu.ll -fno-emit-bin zig_oob.zig` |
| **`tiny-ni2.ll`** (`$WORK/p1`, copied to `$WORK/p2`) | `tiny.ll` | `deno run -A tools/p1/zig-ir-spike.ts`; read by `tools/p2/dialect-probe.ts` part C. **The one input with no committed source of its own** |

The full notes are in `tools/p1/README.md` and `tools/p2/README.md` ("Record: tiny-ni2.ll") and in
both tools' headers. Found during the Deno conversion: two experiment scripts used to copy inputs
from a session scratchpad that no longer existed and silently ran on leftovers; they now use the
committed copies.

## 🧬 Fil-C's OWN test suite, against zilc's patched clang (✅ 2026-10-05)

**Re-run on Fil-C 0.686 (2026-10-05, tests at `v0.686`: 7,205): 0 differences between stock and
patched.** Run 5,968, skipped 1,237. Both fail the same 2 on the first pass:
- `inlineasm_rdpkru`: the CPU limit below (unchanged).
- `sarcasm-mb-pl-sink-att` (new in 0.686, added by `163fae5`): a TEST-SETUP gap, not a compiler
  fault. It reads OpenSSL's `projects/openssl-3.6.4/crypto/aes/asm/aesni-mb-x86_64.pl` from
  Fil-C's repo root (or `$FILC_REPO_ROOT`), outside `filc/tests`, so our sparse test checkout
  lacked it (`BAD cannot open aesni-mb-x86_64.pl`). With that folder added to the checkout, it
  **passes with both compilers** (`mb pl sink ok`). It is the only test that reads `projects/`.

**So on 0.686 every runnable test passes with zilc's patched clang except `inlineasm_rdpkru`**
(hardware). `compare-clangs.ts` against stock 0.686: the usual pattern (identical on the small
inputs and the stress test, both assert on the KI-18 repro, `62` different: two binaries).

The 0.685 run, first:

Owner: run upstream's tests *"to make sure we are not missing anything that upstream has already
identified"*. **Result: stock Fil-C 0.685 clang and zilc's patched clang give the SAME result on
all 7,003 tests (0 differences).** So zilc's three pass patches (colouring, `indirectbr` lowering,
dense interference graph) change nothing Fil-C's own suite checks.

| | stock 0.685 | zilc patched |
| --- | --- | --- |
| run (x86_64 + SHA-NI, musl build) | 5,779 | 5,779 |
| **pass** | **5,778** | **5,778** |
| fail | 1: `inlineasm_rdpkru` | the same 1 |
| skipped (cannot run here) | 1,224: 694 need AVX-512, 504 ARM-only, 24 glibc-build-only, 1 macOS-only, 1 marked skip | the same |
| time, 24 jobs | ~6 min | ~6.5 min |

- `inlineasm_rdpkru` executes `rdpkru` (memory protection keys); this CPU, under WSL2, has no
  `pku` flag: "Illegal instruction". A hardware/VM limit, the same for both compilers.
- 🔑 **What the suite found on its first run: 9 more failures that were OUR MACHINE's setup.** The
  prebuilt's `pizfix/os-include/asm` link pointed at `/usr/include/asm`, which does not exist
  (Fil-C's `setup.sh` had run before the kernel headers were installed). Every program including
  `<linux/futex.h>`, `<linux/seccomp.h>`, … failed with `'asm/types.h' file not found`: the 7
  `seccomp-ssh*` tests, `futextimeout`, `lockchaosfutex`, and ANY zilc program using those headers.
  Fixed with `tools/filc/fix-os-include.ts` (setup.sh's own rule), now run by
  `build-patched-clang.ts` and `restore-patched-clang.ts`, and checked by `check-toolchain.ts`.
  `workarounds.md` has the entry.

**How to run it** (WSL): `tools/filc/run-filc-tests.ts`, a Deno port of Fil-C's Ruby
`filc/run-tests` (same build, run and check rules; ledger `filc-test-runner-port`). The tests are
NOT in zilc: clone them at the compiler's commit into `~/zilc-work/filc-tests-<release>`
(`git clone --depth 1 --branch v0.686 --filter=blob:none --no-checkout
https://github.com/pizlonator/fil-c.git`, then `sparse-checkout set filc/tests
projects/openssl-3.6.4/crypto/aes/asm`, `checkout`; the second path is the input of
`sarcasm-mb-pl-sink-att`, see above), then from that folder:
`deno run -A …/run-filc-tests.ts run --pizfix <tree>/pizfix --label stock` (and `--label patched`
with zilc's tree), then `… compare results-stock.json results-patched.json` (exit 0 = same).
`--filter REGEX` runs a subset. ⚠️ Use the tests of the COMPILER's commit (`v0.686`: 7,205;
`v0.685`: 7,003), not upstream's newest, which test features the release lacks.

## 🔍 Output comparison: zilc vs native, not just exit codes (pre-publish item, ✅ 2026-10-02)

**Re-run on Fil-C 0.686 (2026-10-05): 0 unexplained, 503 identical, 0 differing** (`{same 503, expected 56, varies 65, variesBad 0, differs 0}`, 624 in all).

**Re-run 2026-10-05 with the Deno tools: still 0 unexplained differences, and 505 byte-identical**
(the tools now keep stdout and stderr in order, so nine more programs match exactly; 39_logging
only matched by luck before). The numbers below are the first run's.

**Result: 0 unexplained differences.** Every tests/basics program, C and Zig, in all four modes
(624 comparisons): **496 byte-identical** to plain Zig 0.15.2; **68** whose NATIVE output already
varies between two runs (times, random numbers, thread order), all with the same shape (line
count, and the same lines once digits are masked); **60** in the short EXPECTED table, 8
programs, each with its reason:

| program | why it cannot match |
| --- | --- |
| `17_pointers`, `46_string-formatting` | print an address (native's is fixed: non-PIE) |
| `27_goroutines`, `36_worker-pools` | thread scheduling decides the order (27 matched natively twice by chance, in C) |
| `42_panic` | designed: under zilc the panic is reported by Fil-C (`zerror`) |
| `64_command-line-arguments` | prints its own path, which differs between the harnesses |
| `74_execing-processes`, `75_spawning-processes` | `ls -la` of the working directory, `date` |

Also learned: the program's **environment** works under zilc (67 lists it and reads `FOO`),
and so do `argv`, files, stdin, child processes and threads.

**How to run it** (WSL; ~40 s per native pass, the corpus as usual):
1. `OUTROOT=~/zilc-work/outcmp/native1 deno run -A tools/basics/run-native.ts`, then the same with
   `native2` (two runs, to tell programs whose own output varies).
2. `LANGS="c zig" deno run -A tools/basics/all-modes.ts`.
3. `deno run --allow-read tools/basics/compare-output.ts ~/zilc-work/outcmp/native1
   ~/zilc-work/outcmp/native2 ~/zilc-work` (exit 0 = no unexplained difference).

**Harness fixes it needed (2026-10-02):**
- Both runners now start programs with the SAME fixed environment (`env -i HOME PATH USER
  LANG=C.UTF-8 TERM=dumb`): each script's own variables (`ZILC_*`, `OUTROOT`, `JOBS`) were
  showing up in 67's listing.
- `run-native.ts` runs in parallel (`JOBS`, default 8) and writes where `OUTROOT` says: one at a
  time into the repo on exFAT, its Zig half alone took over 30 minutes; now ~40 s per pass.
- (In the shell version, before the 2026-10-05 move to Deno:) `zilc-check.sh` worked under `sh`
  (dash) again: `export -f` is bash-only and made dash exit 2, silently, before any program ran
  (`all-modes.sh` used bash, which hid it). Moot in the Deno version.
- `zilc-check.ts` clears its WHOLE mode folder, so a C-only run deletes that mode's Zig results:
  run both languages together (`LANGS="c zig"` in `all-modes.ts`).

## Current gates (re-run 2026-10-05, on Fil-C 0.686)

| Step | Checks | State |
| --- | --- | --- |
| `zig build gate` | Every bug example traps at the right line; the library-mode example runs (needs Fil-C) | **8/8** (2026-10-05 on Fil-C 0.686; 2026-10-02, KI-5 environ and library mode added; earlier 4/4 with the parallel code generation of KI-22 lever (a)) |
| `zig build test` | Runtime module + CLI module + the IR rewrites (incl. the KI-18 three-byte-global wrap) + the std-overlay patches (incl. the KI-21 guards) + the `--runtime zig` refusal + the version round-trip + the object cache key and `--clean-cache` (KI-22 lever c) | **29/29** pass (2026-10-05, incl. `--clean-cache`, the KI-20 note, the version facts and the `0.15.2-0.686.1` scheme) |
| `zig build capi-smoke` | `tests/capi_smoke.c` links `zilc_runtime` via `zilc.h` and calls it | pass |
| `zig build baseline` | Builds `examples/*.c` with plain `zig cc` | builds. `baseline_oob_write` prints `a[3] = 3`, exit 0: **the undetected bug** |

All gates were re-verified on **Zig 0.15.2** after the toolchain move (2026-09-18). Run them with
that Zig, not the `zig` on PATH, and with the NTFS cache (KI-2, KI-3):

```powershell
$env:ZIG_LOCAL_CACHE_DIR = 'C:\zig-cache\zilc'
& C:\zig\0.15.2\zig.exe build test --summary all
& C:\zig\0.15.2\zig.exe build capi-smoke
& C:\zig\0.15.2\zig.exe build baseline
```

## 🎯 THE EXPECTED OUTPUT IS RECORDED (2026-09-23) — Fil-C 0.685 on our two examples

Measured in WSL with `build/bin/clang -O2 -g` (`roadmap.md` P1 step 2). **Both exit 133** (SIGTRAP):

| example | fault line | Fil-C's message |
| --- | --- | --- |
| `oob_write.c:15:14` | store one past a 4-int allocation | `cannot write pointer with ptr >= upper.` / `expected 4 writable bytes.` |
| `use_after_free.c:13:20` | read after `free` | `cannot access pointer to free object.` / `expected valid capability.` |

Both end with `filc panic: thwarted a futile attempt to violate memory safety.` and print a
`semantic origin` with **file:line:column** plus a stack of `check scheduled at:` frames.

🔑 **The gate should assert the fault KIND and the file:line, not the exit code.** Fil-C gives both,
and 133 alone would accept a crash for the wrong reason.

### ✅ The Zig ⇄ C gate, measured 2026-09-23 (`tools/p2/milestone.ts`)

`c_caller.c` allocates 4 ints and calls Zig's `zig_add(a, 4, 99)`. Exit **133**:

```
in bounds ok, sum=6
filc safety error: cannot write pointer with ptr >= upper.   expected 4 writable bytes.
semantic origin:      tiny.zig:4:6: zig_add
check scheduled at:   tiny.zig:4:6: zig_add  ←  c_caller.c:15:5: main
```

🎯 **The fault is attributed to the Zig line, from a C call site.** That two-frame trace is the real
assertion for the interop gate — it proves the capability crossed the language boundary intact.

⚠️ **Gate-building constraints, all load-bearing (see `known-issues.md`):** target **musl** (KI-6);
let **C own `main`** (KI-5); **Debug works but costs ~108× in size** (KI-4), so gates should run
ReleaseSafe by default and Debug only where the size is acceptable.

| optimize mode | binary | same panic? |
| --- | --- | --- |
| ReleaseSafe | 127,424 B | ✅ `bounds.zig:13:6` |
| Debug (`filc -O0` + `-fno-stack-check`) | 13,766,024 B | ✅ identical |

⚠️ **When scripting a gate, capture the exit status before piping.** `./prog | sed …` reports
*sed's* status, and the exit code is half of what these tests assert. (Cost us one confusing
"run exit=0" on a run that had clearly trapped.)

## Planned gates

1. **Bug-example gate** (invariant 2 in `design-decisions.md`): every `examples/*.c` built with the
   zilc target must reproduce the table above — same fault kind, same line. Checking the exit code
   alone would pass a crash for the wrong reason.
2. **Fil-C differential → `zig build gate -Druntime=filc|zig|both`** (shape set 2026-09-30,
   `roadmap.md` P3). Each case is built under Fil-C's runtime and zilc's (`zilc build --runtime`).
   Output, exit code, fault kind and file:line must match. This becomes the proof of P3, and it
   stays meaningless until `--runtime zig` is enabled.
3. **Version comparison (2026-09-30).** Stage B of an upgrade (`upstream.md`): zilc built by the
   latest Zig must produce **identical gate results** to the stage-A reference built by the
   compatible Zig. The gate already takes `ZILC_ZIG`/`ZILC_FILC`, so this needs two zilc builds
   and a comparison of the two reports, not a new gate. Worth automating once it has been done by
   hand once.
4. **Benchmark suite (2026-09-30), for upgrade stage C.** Does not exist yet. Needed: a small set of
   programs (Zig, C, and Zig ⇄ C) that run long enough to time, run under zilc and plain `zig`, with
   repeats and a stated noise floor. Output: run time, build time and binary size per version pair.
   Its first run also produces zilc's **own** slowdown figure (`vision.md`). Scripts in Deno/Bun.
5. **Upstream test corpus.** `filc/tests` from Fil-C, adopted under the ledger.
6. **ABI completeness.** As in wazmrt, a C file that takes the address of every function declared in
   `zilc.h`, so a declared-but-undefined symbol breaks the build.
