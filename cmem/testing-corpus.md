# testing-corpus.md — the tests/basics corpus, the output comparison and the benchmark suite (split from testing.md 2026-11-23)

## 🧪 `tests/basics`: 156 CORRECT programs (C + Zig), added 2026-09-30

The owner's "Basics of Coding" lessons, 78 in C and the same 78 in Zig (provenance, licence and every
change: `tests/basics/README.md`). The gate proves **bugs trap**. This corpus proves **correct
programs don't**, and gives size numbers against plain Zig. Tools in `tools/basics/`.

- compiles + links, plain Zig 0.15.2, `-lc`, musl — **78/78** (after 5 portability fixes)
  - Zig 0.15.2: **78/78** (after converting 60 files from 0.13/0.14)
- runs as designed, plain ReleaseSafe — **78/78**
  - Zig 0.15.2: **78/78** exit codes. ⚠️ Outputs were wrong when redirected until the stdio streaming fix (2026-09-30, `tests/basics/README.md`)
- **builds with zilc** — **78/78**
  - Zig 0.15.2: ReleaseSafe ~~50/78~~ → **77/78** after the KI-8 fix (only KI-9 left) · ReleaseSmall **77/78** (KI-9)
- **runs as designed under zilc** (ReleaseSafe) — **78/78** (`42_panic` traps via Fil-C, as designed)
  - Zig 0.15.2: ~~24~~ → 26 (KI-8) → 45 (KI-7) → 50 (panic handler + KI-9) → **71/78** (KI-13
    overflow fold + `fromPage` patch, KI-14 `-fno-valgrind`). 65 clean exits plus 6 intentional
    (`42` panic, `66` exit 1 without a subcommand, `77` exit 3, three servers). Then the
    **unoptimized-IR route** (KI-17, the default since 2026-09-30) → **76/78**: the 5 thread joins
    pass, and `76_signals` now runs (it waits, as designed). **Left, 2:** the KI-18 Fil-C assertion
    (`22_strings-and-runes`, `69_http-client`)
- **every mode** (KI-16, default route) — same in every mode (C ignores `-O`)
  - Zig 0.15.2: ~~ReleaseSafe 76 · ReleaseFast 76 · ReleaseSmall 76 · Debug 63~~ → 2026-10-01: 78 ·
    78 · 78 · 65 (KI-18, KI-20) → **2026-10-01 (evening): 78/78 as designed in ALL FOUR MODES**,
    with the patched Fil-C clang (KI-22 colouring, KI-4 `indirectbr`) and Debug at `filc -O1` (fixes
    KI-19). Gate 4/4 with it. Tool: `tools/basics/all-modes.ts` (defaults to the patched clang)
- **on Fil-C 0.687** (2026-10-27; patched 0.687 clang, in WSL, on commit `b33b6eb`) — —
  - Zig 0.15.2: **Still 78/78 as designed in all four modes**: 71 OK + the designed 7 in every mode
    and both languages, by name (`42_panic` traps, `66` exit 1, `77_exit` exit 3, `70`–`72` and
    `76_signals` time out; `tests/basics/README.md`); KillUB's new defined results changed no
    output. Gate 8/8, tests 29/29. Output comparison: **0 unexplained** (`{same 500, expected 56,
    varies 68, variesBad 0, differs 0}`; 3 fewer "same" than 0.686 and 3 more "varies", the native
    side varying by itself)
- **on Fil-C 0.686** (2026-10-05; patched 0.686 clang, `ZILC_VERIFY_INTERFERENCE=1` + `ZILC_VERIFY_COLOURING=1`) — —
  - Zig 0.15.2: **Still 78/78 as designed in all four modes** (71 OK + the designed 7, C and Zig
    alike), **0 builds with a verification difference**, gate 8/8, tests **29/29**. `69` ReleaseSafe
    alone **38.0 s** cold (35.9 on 0.685). Output comparison re-run: 0 unexplained
- **+ dense interference graph, object cache** (KI-22 levers (b), (c); 2026-10-02, same load, `ZILC_JOBS=4`, `ZILC_CACHE=0`) — —
  - Zig 0.15.2: **Still 78/78 as designed in all four modes**, gate 4/4, tests **25/25** (26/26 with
    `--clean-cache`, same day). **Verified run:** the whole corpus in all four modes with
    `ZILC_VERIFY_INTERFERENCE=1` and `ZILC_VERIFY_COLOURING=1`: 78/78 as designed, **no graph or
    colouring difference** (verified `69` builds 154–431 s, so the original code really ran). `69`
    under load: Debug **56 s** (was 68), ReleaseSafe **58 s** (70), ReleaseFast **82 s** (97),
    ReleaseSmall **52 s** (61). Alone, through the driver: `69` ReleaseSafe **35.9 s** split (43.9
    before (b)), 49.9 s at `-j 1`; rebuild unchanged, same output path: **2.3 s** (cache hit; `62`
    0.5 s). Byte-identical to the prebuilt on every deterministic input (`compare-clangs.ts`)
- **build time, + parallel code generation** (KI-22 lever (a); 2026-10-02, same load, `ZILC_JOBS=4` per build) — —
  - Zig 0.15.2: **Still 78/78 as designed in all four modes** (71 OK + the designed 7: `42` panic,
    `66` exit 1, `77` exit 3, `70`/`71`/`72` servers, `76_signals`), gate 4/4, tests 24/24. Medians
    unchanged (Debug 4 s, ReleaseSafe 4 s, ReleaseFast 4 s, ReleaseSmall 3 s). `69`: Debug **68 s**
    (was 79), ReleaseSafe **70 s** (81), ReleaseFast **97 s** (107), ReleaseSmall **61 s** (70).
    Alone, through the driver: `69` ReleaseSafe **60.6 s → 43.9 s** (`-j 1` vs default 16 parts),
    `62` 7.0 → 5.0 s, same program output. Code identity: 2,840/2,840 functions of `69` identical to
    the unsplit compile of the same bitcode (`workarounds.md` KI-22)
- **build time, + overlay v5** (Debug-only KI-21 route guarded; 2026-10-01 late, same load) — —
  - Zig 0.15.2: Still 78/78 as designed in all four modes, gate 4/4. Medians: **Debug 4 s** (was
    19), ReleaseSafe 4 s, ReleaseFast 3 s, ReleaseSmall 2 s. `69`: Debug 79 s, ReleaseSafe 81 s,
    ReleaseFast 107 s, ReleaseSmall 70 s. Alone: `04_constants` Debug 2.1 s (was 9.9; native Zig
    with LLVM 1.1 s), `69` ReleaseSafe 55.9 s (native 16.9 s)
- **build time with the patched clang** (2026-10-01 evening, same load) — —
  - Zig 0.15.2: `69`: ReleaseSafe **112 s**, ReleaseFast **154 s**, ReleaseSmall **87 s**, Debug
    **83 s** (was a 30-min timeout). Medians: Debug 19 s, ReleaseSafe 4 s, ReleaseFast 3 s,
    ReleaseSmall 2 s. Alone, Fil-C's clang on `69` (`-O1`): prebuilt 112 s, patched 54 s
- **build time** (2026-10-01, all 4 modes × 8 jobs at once, so inflated) — —
  - Zig 0.15.2: After KI-21: ReleaseSafe median **4 s**, `62` 19 s (was 92), `48_json` 30 s (was
    86); `69` 214 s (ReleaseSafe), 754 s (ReleaseFast), timeout (Debug), all KI-22. Alone: `62`
    ReleaseSafe 8.0 s vs native 6.7 s; `69` 132 s vs native 20 s. `zilc-check.ts` now reports
    `BUILD-TIMEOUT` (`TBUILD`, default 1800 s) and writes `build seconds:` into each `build.log`

**C already works under zilc across the whole corpus. Zig's gaps are all in std**, not the pipeline:
raw system calls, stack probes, f128 helpers, thread handles. That is P4, now with a
measured to-do list.

### Binary sizes (2026-09-30, x86_64-linux-musl, bytes, medians)

Zig's musl binaries are **static**. zilc's are **dynamic** and load Fil-C's shared runtime:
**`libc.so` 7.3 MB + `libpizlo.so` 9.1 MB + `libyoloc.so` 3.6 MB ≈ 20 MB**, installed once per
machine, not per program. zilc passes `-g`, so stripped sizes are the fair comparison.

|                                          | Zig ReleaseSmall | Zig ReleaseSafe | zilc ReleaseSafe | zilc ReleaseSmall    |
| ---------------------------------------- | ---------------- | --------------- | ---------------- | -------------------- |
| **C** (78), raw                          | 19,800           | 938,960         | 27,976           | n/a (C ignores `-O`) |
| **C**, stripped                          | 19,800           | 20,536          | **18,592**       | n/a                  |
| **Zig** (the 50 all flavours built), raw | 16,832           | 2,330,200       | 565,624          | 89,632               |
| **Zig**, stripped                        | 16,832           | 270,512         | 341,360          | 76,896               |

Per-program ratios (median): C zilc/ReleaseSmall **0.86** stripped (smaller, since libc is not
inside). Zig zilc ReleaseSafe/ReleaseSafe **1.26** stripped; zilc ReleaseSmall/ReleaseSmall **4.36**
stripped (instrumentation plus Fil-C's calling-convention thunks). Tools:
`tools/basics/size-compare.ts`, `size-report.ts`.

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

| program                                         | why it cannot match                                                             |
| ----------------------------------------------- | ------------------------------------------------------------------------------- |
| `17_pointers`, `46_string-formatting`           | print an address (native's is fixed: non-PIE)                                   |
| `27_goroutines`, `36_worker-pools`              | thread scheduling decides the order (27 matched natively twice by chance, in C) |
| `42_panic`                                      | designed: under zilc the panic is reported by Fil-C (`zerror`)                  |
| `64_command-line-arguments`                     | prints its own path, which differs between the harnesses                        |
| `74_execing-processes`, `75_spawning-processes` | `ls -la` of the working directory, `date`                                       |

Also learned: the program's **environment** works under zilc (67 lists it and reads `FOO`),
and so do `argv`, files, stdin, child processes and threads.

**How to run it** (WSL; ~40 s per native pass, the corpus as usual):
1. `OUTROOT=~/zilc-work/outcmp/native1 bun tools/basics/run-native.ts`, then the same with
   `native2` (two runs, to tell programs whose own output varies).
2. `LANGS="c zig" bun tools/basics/all-modes.ts`.
3. `bun tools/basics/compare-output.ts ~/zilc-work/outcmp/native1
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

## Benchmark suite (`tools/bench/bench.ts`, `tests/bench/`; first baseline 2026-11-06)

**What runs.** 19 programs, 28 pairs. (a) upstream's `filc/benchmarks` (9 + upstream's
binarytrees), READ from the fetched Fil-C package, built as its Makefile does (`-O3 -g`, each
program's flags): Fil-C's clang/clang++ against plain `zig cc`/`zig c++`; pcre_benchmark left out
(needs a Fil-C-built libpcre2). (b) Zig versions of four of them (`tests/bench/zig/`: nbody,
spectralnorm, fannkuch, binarytrees). (c) zilc's own Zig programs (hashmap_churn, sort_format,
dispatch, slices) and one Zig ⇄ C (`tests/bench/interop/`: libc qsort calling a Zig comparator,
Zig calling a C kernel; needs `--entry zig`). (b) and (c) run in ReleaseSafe and ReleaseFast,
`zilc build` against `zig build-exe`, both `x86_64-linux-musl`.

**Method.** Same CPU both sides (Fil-C's clang defaults to x86-64-v2, so plain C gets
`-mcpu=x86_64_v2`; both Zig sides are baseline x86-64; Z-cc-4 respelling for `-march`). Every
program prints a result, and the two builds must print the same one (stdout + stderr, since
Fil-C's `zprintf` writes stderr; masks for deltablue's timing and n-body's pointer print;
stepanov_container prints only timings, unchecked). One warm-up each, then 5 runs alternating
plain/zilc; median, min, noise = MAD/median; "within noise" = inside twice the larger noise. Build
time: shared libraries warmed first, an empty local cache per build, zilc `--no-cache`, one build
at a time. Startup floor measured: an empty program 0.10 ms static vs 1.36 ms with Fil-C's runtime
(negligible beside the shortest program, 0.15 s). `compare` flags pairs whose input differs.

**First baseline** (2026-11-06; its `results.json` and `summary.md`, the input of
`bench.ts compare`, moved 2026-11-19 to the gitignored `cmem/local/bench/0.15.2-0.687.1/`; i9-13980HX, 32 threads,
idle; 3 runs that day: upstream 2.25× / 2.11× / 2.07×, Zig ReleaseFast 1.67× / 1.66× / 1.66×; the
first had parallel builds still loading the machine). Geometric-mean slowdown, zilc / plain:
upstream C/C++ under Fil-C **2.07×** (9 programs; fannkuch-redux 1.04× … richards 5.06×, n-body-2
4.13×); Zig ports **1.68× ReleaseFast / 1.82× ReleaseSafe**; zilc's own Zig **1.66× / 1.85×**
(ReleaseFast: slices 1.40×, sort_format 1.47×, hashmap_churn 1.51×, dispatch 1.64×, interop
2.46×); all Zig pairs 1.29×–3.04×, the top being zig-binarytrees (a malloc/free per node, 2.93×
/ 3.04×). Noise ≤ 2 % but deltablue (6 %) and reversecomplement (20 %, 0.09 s mostly I/O: its
1.36× is "within noise"). **Upstream's binarytrees is NOT a cost figure:** it never frees
(written for the GC) and runs 32 threads, so plain musl leaks and serializes on its malloc lock
(4.5 s) while Fil-C takes 0.15 s; excluded from the means, noted in every summary. Build time:
zilc 1.7–4.4 s against plain Zig 0.4–5.6 s (plain ReleaseSafe ~5 s: the stack-trace code; zilc
splits code generation, KI-22 lever a). Sizes: Fil-C binaries are dynamic (runtime separate),
plain ones static.

**Per Fil-C move:** run `bun tools/bench/bench.ts` on an idle machine, then `bun tools/bench/bench.ts
compare <old>/results.json <new>/results.json` (stage C's first column).
5. **Upstream test corpus.** `filc/tests` from Fil-C, adopted under the ledger.
6. **ABI completeness.** As in wazmrt, a C file that takes the address of every function declared in
`zilc.h`, so a declared-but-undefined symbol breaks the build.
