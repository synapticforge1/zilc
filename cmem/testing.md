# Testing

## 🎯 `zig build gate` — THE SAFETY GATE (new 2026-09-23). **7/7 green** (2026-10-02: + 3 library-mode cases that must RUN)

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
wsl.exe -e sh /mnt/d/…/zilc/tools/run-gate-wsl.sh            # from Windows
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
| **every mode** (KI-16, default route) | same in every mode (C ignores `-O`) | ~~ReleaseSafe 76 · ReleaseFast 76 · ReleaseSmall 76 · Debug 63~~ → 2026-10-01: 78 · 78 · 78 · 65 (KI-18, KI-20) → **2026-10-01 (evening): 78/78 as designed in ALL FOUR MODES**, with the patched Fil-C clang (KI-22 colouring, KI-4 `indirectbr`) and Debug at `filc -O1` (fixes KI-19). Gate 4/4 with it. Tool: `tools/basics/all-modes.sh` (defaults to the patched clang) |
| **+ dense interference graph, object cache** (KI-22 levers (b), (c); 2026-10-02, same load, `ZILC_JOBS=4`, `ZILC_CACHE=0`) | — | **Still 78/78 as designed in all four modes**, gate 4/4, tests **25/25** (26/26 with `--clean-cache`, same day). **Verified run:** the whole corpus in all four modes with `ZILC_VERIFY_INTERFERENCE=1` and `ZILC_VERIFY_COLOURING=1`: 78/78 as designed, **no graph or colouring difference** (verified `69` builds 154–431 s, so the original code really ran). `69` under load: Debug **56 s** (was 68), ReleaseSafe **58 s** (70), ReleaseFast **82 s** (97), ReleaseSmall **52 s** (61). Alone, through the driver: `69` ReleaseSafe **35.9 s** split (43.9 before (b)), 49.9 s at `-j 1`; rebuild unchanged, same output path: **2.3 s** (cache hit; `62` 0.5 s). Byte-identical to the prebuilt on every deterministic input (`compare-clangs.sh`) |
| **build time, + parallel code generation** (KI-22 lever (a); 2026-10-02, same load, `ZILC_JOBS=4` per build) | — | **Still 78/78 as designed in all four modes** (71 OK + the designed 7: `42` panic, `66` exit 1, `77` exit 3, `70`/`71`/`72` servers, `76_signals`), gate 4/4, tests 24/24. Medians unchanged (Debug 4 s, ReleaseSafe 4 s, ReleaseFast 4 s, ReleaseSmall 3 s). `69`: Debug **68 s** (was 79), ReleaseSafe **70 s** (81), ReleaseFast **97 s** (107), ReleaseSmall **61 s** (70). Alone, through the driver: `69` ReleaseSafe **60.6 s → 43.9 s** (`-j 1` vs default 16 parts), `62` 7.0 → 5.0 s, same program output. Code identity: 2,840/2,840 functions of `69` identical to the unsplit compile of the same bitcode (`workarounds.md` KI-22) |
| **build time, + overlay v5** (Debug-only KI-21 route guarded; 2026-10-01 late, same load) | — | Still 78/78 as designed in all four modes, gate 4/4. Medians: **Debug 4 s** (was 19), ReleaseSafe 4 s, ReleaseFast 3 s, ReleaseSmall 2 s. `69`: Debug 79 s, ReleaseSafe 81 s, ReleaseFast 107 s, ReleaseSmall 70 s. Alone: `04_constants` Debug 2.1 s (was 9.9; native Zig with LLVM 1.1 s), `69` ReleaseSafe 55.9 s (native 16.9 s) |
| **build time with the patched clang** (2026-10-01 evening, same load) | — | `69`: ReleaseSafe **112 s**, ReleaseFast **154 s**, ReleaseSmall **87 s**, Debug **83 s** (was a 30-min timeout). Medians: Debug 19 s, ReleaseSafe 4 s, ReleaseFast 3 s, ReleaseSmall 2 s. Alone, Fil-C's clang on `69` (`-O1`): prebuilt 112 s, patched 54 s |
| **build time** (2026-10-01, all 4 modes × 8 jobs at once, so inflated) | — | After KI-21: ReleaseSafe median **4 s**, `62` 19 s (was 92), `48_json` 30 s (was 86); `69` 214 s (ReleaseSafe), 754 s (ReleaseFast), timeout (Debug), all KI-22. Alone: `62` ReleaseSafe 8.0 s vs native 6.7 s; `69` 132 s vs native 20 s. `zilc-check.sh` now reports `BUILD-TIMEOUT` (`TBUILD`, default 1800 s) and writes `build seconds:` into each `build.log` |

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
`tools/basics/size-compare.sh`, `size-report.sh`.

## 🔍 Output comparison: zilc vs native, not just exit codes (pre-publish item, ✅ 2026-10-02)

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
1. `OUTROOT=~/zilc-work/outcmp/native1 sh tools/basics/run-native.sh`, then the same with
   `native2` (two runs, to tell programs whose own output varies).
2. `LANGS="c zig" sh tools/basics/all-modes.sh`.
3. `deno run --allow-read tools/basics/compare-output.ts ~/zilc-work/outcmp/native1
   ~/zilc-work/outcmp/native2 ~/zilc-work` (exit 0 = no unexplained difference).

**Harness fixes it needed (2026-10-02):**
- Both runners now start programs with the SAME fixed environment (`env -i HOME PATH USER
  LANG=C.UTF-8 TERM=dumb`): each script's own variables (`ZILC_*`, `OUTROOT`, `JOBS`) were
  showing up in 67's listing.
- `run-native.sh` runs in parallel (`JOBS`, default 8) and writes where `OUTROOT` says: one at a
  time into the repo on exFAT, its Zig half alone took over 30 minutes; now ~40 s per pass.
- `zilc-check.sh` works under `sh` (dash) again: `export -f` is bash-only and made dash exit 2,
  silently, before any program ran (`all-modes.sh` used bash, which hid it).
- `zilc-check.sh` clears its WHOLE mode folder, so a C-only run deletes that mode's Zig results:
  run both languages together (`LANGS="c zig"` in `all-modes.sh`).

## Current gates (re-run 2026-10-02)

| Step | Checks | State |
| --- | --- | --- |
| `zig build gate` | Every bug example traps at the right line; the library-mode example runs (needs Fil-C) | **7/7** (2026-10-02, library mode added; earlier 4/4 with the parallel code generation of KI-22 lever (a)) |
| `zig build test` | Runtime module + CLI module + the IR rewrites (incl. the KI-18 three-byte-global wrap) + the std-overlay patches (incl. the KI-21 guards) + the `--runtime zig` refusal + the version round-trip + the object cache key and `--clean-cache` (KI-22 lever c) | **26/26** pass (2026-10-02, incl. `--clean-cache`) |
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

### ✅ The Zig ⇄ C gate, measured 2026-09-23 (`tools/p2/milestone.sh`)

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
