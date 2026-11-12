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

```sh
bun tools/run-gate.ts            # from a WSL or Linux shell (the tools run inside Linux only)
ZILC_FILC=…/build/bin/clang ZILC_ZIG=…/zig zig build gate    # the same, by hand
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
| **on Fil-C 0.687** (2026-10-27; patched 0.687 clang, in WSL, on commit `b33b6eb`) | — | **Still 78/78 as designed in all four modes**: 71 OK + the designed 7 in every mode and both languages, by name (`42_panic` traps, `66` exit 1, `77_exit` exit 3, `70`–`72` and `76_signals` time out; `tests/basics/README.md`); KillUB's new defined results changed no output. Gate 8/8, tests 29/29. Output comparison: **0 unexplained** (`{same 500, expected 56, varies 68, variesBad 0, differs 0}`; 3 fewer "same" than 0.686 and 3 more "varies", the native side varying by itself) |
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
| **`tiny-ni2.ll`** (`$WORK/p1`, copied to `$WORK/p2`) | `tiny.ll` | `bun tools/p1/zig-ir-spike.ts`; read by `tools/p2/dialect-probe.ts` part C. **The one input with no committed source of its own** |

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

**The clang `zig build patched-clang` builds from the FETCHED sources (2026-10-30, system cc/c++):
0 differences on all 7,269 tests** against stock AND against the 2026-10-27 patched clang (built by
`build-patched-clang.ts` from the git checkout): 6,027 run, 6,026 pass, 1 fail
(`inlineasm_rdpkru`), 0 timeouts, 1,242 skipped, 446 s at 24 jobs. Its `clang --version` is the
prebuilt's, letter for letter (LLVM_FORCE_VC_*). Tree assembled as `build-patched-clang.ts` does:
the prebuilt copied, `clang-20` and `llvm-split` replaced, `fix-os-include.ts`.

**The same clang compiled and linked by ZIG (2026-10-30, `-Dclang-cc=zig`, now the default):
0 differences on all 7,269 tests** against stock and against the GCC-built patched clang (6,027
run, 6,026 pass, 1 fail `inlineasm_rdpkru`, 439 s at 24 jobs), and **`zig build gate` 8/8** with it
(`ZILC_FILC=<tree> bun tools/run-gate.ts`; run the gate through run-gate.ts — a bare `zig build gate`
without `ZILC_ZIG` fails every Zig case on `zig env`, as one attempt did). Its `.comment` names Zig's
clang and LLD 20.1.2; it needs only glibc (libc++ is static); 1.55 GB with debug info against
GCC's 3.8 GB; ~20 min at 12 jobs. Unchanged incremental rerun: 9 s, `ninja: no work to do`.

**THE ZIG-ONLY CHAIN (2026-10-30, late; owner: "make sure that the entire compilation no longer
needs gcc at all")** — `MODE=zig bun tools/filc/build-filc-from-source.ts`, run with a PATH holding
every system program EXCEPT `gcc* g++* cc c++ cpp* c89 c99 clang*` and the `*-linux-gnu-gcc*`
names (checked: none resolves): **builds all of Fil-C in ~2 min** — projeny by `zig c++`; every
stock piece and libpas whole by `zig build pure-zig -Dfilc-clang=…` (27 s); user musl, libc++,
minilute, sarcasm by the Zig-built Fil-C clang through upstream's scripts. `pizfix/lib` = the
release's 37 entries. Still from the host: binutils' `ld` (Fil-C's clang links with it; its driver
"selects" the GCC installation but takes nothing from it: no `/usr/lib/gcc` path, no libgcc on the
link line, measured with `-v`/`-###`), make, cmake/ninja, python3, perl, ar, patchelf, libcurl
headers, kernel headers.
- **libpas whole, by `zig build libpas -Dfilc-clang=<Fil-C clang>`:** all four `libpizlo.so`
  (lib 2,504 exports, lib_gcverify 2,504, lib_test 2,512, lib_test_gcverify 2,512) and
  `libpizlo.a` (2,546 exports, 183 members) define **exactly the release's symbols**; NEEDED
  `libyoloc.so` only, `.gnu.hash`, RELRO, `.eh_frame_hdr`, no INTERP, like the release.
- **Chains compared (`~/zilc-work/equiv/`, part A, 2026-10-30):** 35 libraries: the zig chain
  matches the release's exports on ALL; the GCC chain (`MODE=upstream`, Ubuntu GCC 15 + clang 21)
  differs on one, `libyolort.a` (GCC 15's extra half-float builtins). No `GCC:` string in any
  zig-chain library. Self-binding relocations (R_X86_64_JUMP_SLOT/GLOB_DAT/64) equal in all three
  trees for `libyoloc.so` 21, `libc.so` 281, `libc++.so.1.0` 8,883; `libpizlo.so` 2,139 (zig) /
  2,134 (GCC chain) / 2,133 (release).
- **✅ FUNCTIONALLY THE SAME (parts B–F, run 2026-10-30, read 2026-11-04):** Fil-C's suite on the
  zig chain: 6,027 run, 6,026 pass, 1 fail (`inlineasm_rdpkru`), 0 timeouts, 1,242 skipped; **0
  differences on all 7,269 tests against stock AND against the GCC chain**. Gate **8/8** with each
  chain, line for line. Corpus (`tests/basics`, C and Zig, all four modes, 156 programs each):
  **identical verdicts chain against chain** in every mode once the PID in Fil-C's panic prefix
  (`[555607] filc panic`, program `42_panic`) is masked; 71 OK / 78 per language and mode, as
  designed. Output comparison against native: **identical reports** for both chains — 496 same,
  60 expected, 68 shape-checked, 0 unexplained, 0 missing.
- **`tools/filc/compare-chains.ts` (2026-11-04), the repeatable form:** run from scratch on both
  chains (suites re-run, native runs, corpus ×2) — **14 of 14 checks PASS**: exports (34 binary
  libraries; `libc++.so` is a linker script and skipped), relocations (8 shared libraries, every
  differing one names a symbol defined there or a weak undefined), suite ×2, gate ×3, corpus ×7.
  Inverted: the GCC tree passed as the zig tree → `exports` FAIL; a zig-chain report doctored to
  one `DIFFERS` → corpus FAIL; exit 1 both. The output-comparison reports are NOT byte-identical
  run to run: thread-order programs flip between allowed verdicts (2026-11-04: `36_worker-pools`
  SAME ↔ EXPECTED, `35_waitgroups` SAME ↔ shape ok; the 2026-10-30 pair happened to match), so the
  check is "the same programs fail in both chains, and a flip only between SAME / EXPECTED /
  shape ok". Outputs in `~/zilc-work/equiv-tool/` (`verdicts.txt`).
- **Parity inventory (2026-11-04; owner: "are there any other items that are not in parity like
  the one we just fixed?")** — every binary library of the zig chain against the release and the
  GCC chain on eight properties (defined and undefined symbols, self-binding relocations by name,
  dynamic tags, segments, section names, NEEDED/SONAME, notes; scan `~/zilc-work/parity/`; its
  first run missed `JUMP_SLOT` through a pattern typo and was rerun until it saw the known 5).
  Exports: equal everywhere. The differences, by cause:
  1. **Linker (LLD vs GNU ld)** — `libpizlo.so` ×4: the 5 `JUMP_SLOT`s (W-14), an unused
     undefined `__environ` (GNU ld only), `.plt.got` vs `.relro_padding`, LLD's `PHDR`;
     `libyoloc.so`: `PHDR`, `.relro_padding`. All follow the linker (measured by relinking).
  2. ✅ **Archive member names — FIXED 2026-11-04** (owner: "fix the two new items"). Were: Zig's
     static libraries named members by full cache paths (`libyoloc.a` 1,343, `libpizlo.a` 183,
     `libyolort.a` 167, `libyolounwind.a` 1; Z-b-8). Now `tools/archive-rename.zig`: `ar t` of all
     four equals the release's line for line (names and order), no member holds a `/`.
  3. ✅ **CET — FIXED 2026-11-04.** Were: Ubuntu's GCC defaults to `-fcf-protection`, so the
     release's GCC-built pieces had `endbr64` and IBT/SHSTK notes and the zig chain none (C-7).
     Now `-fcf-protection` on yolo musl, compiler-rt and the crt objects: `endbr64` equal to the
     release's per member (`libyoloc.a` 1,715, `libyolort.a` 170, `crt1.o` 1, `rcrt1.o` 2,
     `crtbegin.o` 2; 0 where the release has 0); `libyoloc.so` 1,694 vs 1,695 is C-8 (inlining).
     `verify-libpas` / `-yolomusl` / `-compiler-rt` OK after the change. **Re-proof with both
     fixes (2026-11-04, read 2026-11-05): `compare-chains.ts` 14/14** — suite 0 differences on
     7,269 vs stock and vs the GCC chain, gate 8/8 both, corpus and output comparison unchanged
     (CET's `endbr64` is a no-op where CET is not enforced, as expected).
  3b. **Ubuntu GCC's other hardening defaults (found 2026-11-05 by a rescan; was misfiled under
     W-8)** — the release's compiler-rt: stack protector (9 `__stack_chk_fail` calls, 18 guard
     loads, 8 members) and fortify (`__fprintf_chk`); its yolo musl: 15 stack-clash probes. The
     zig chain: none (C-7b). The rescan (2026-11-05, after the CET and archive fixes): 61 → 52
     (library, property) pairs, nothing new. ✅ **FIXED 2026-11-05** (owner: "yes"): fortify 1 = 1
     (C-11: clang's `__vfprintf_chk` for GCC's `__fprintf_chk`); stack-clash page probes 15 = 15 in
     `libyoloc.a` and `.so` (0 before; C-12 says how to count them); stack protector: all 8
     release-guarded compiler-rt members guarded, plus 8 clang adds by its own rule (C-10;
     `verify-compiler-rt.ts` checks both directions); `endbr64` unchanged. Oracles: all three OK;
     `verify-compiler-rt`'s undefined ratchet 14 → 13 (one member now equal). **Re-proof
     (2026-11-05): `compare-chains.ts` 14/14** — exports, relocs, suite (0 differences on 7,269),
     gate on the first run; the corpus part (7 checks: 500 same / 56 expected / 68 varies, 0 bad, 0
     flips, all four modes) only after a rerun with every run fresh. The first try failed
     `07_switch` and `52_time-formatting-parsing` because `REUSE=1` paired a day-old native run
     with a new corpus; both programs print the time of day. `compare-chains.ts` now reuses the
     corpus only when the native runs AND both chains' corpora all exist, otherwise it reruns all
     three together.
  4. **Compiler families, known and ratcheted** — W-4, W-8 (`_GLOBAL_OFFSET_TABLE_`, libcalls,
     empty TU), inlining (C-8: `__ftello_unlocked`), sections `.llvm_addrsig` (clang) vs empty
     `.data`/`.bss` (GCC), `.text.unlikely.` (clang 14 vs 20), DWARF relocation section names
     (GCC emits `.debug_aranges`, clang does not by default), and GNU `as`'s ISA-used notes (C-9).
  5. **Fil-C's clang is not reproducible (F-1)** — `libc.a` 79/1,332, `libc++.a` 22/54,
     `libc++abi.a` 5/18 members differ between the chains; the same command twice differs by
     6–8 bytes, code identical. Not a chain difference.
  6. **Host binutils version** — the release's `libc.so` / `libc++.so.1.0` / `libc++abi.so.1.0`
     have one more `LOAD` than both chains (binutils 2.38 vs 2.45; Fil-C's clang uses the host's
     `ld` in both) (L-9).
  7. **Install time, not build** — the release's `RUNPATH` (Fil-C's `setup.sh` patchelf).
  8. **GCC chain only** — `libyolort.a`'s 6 extra half-float definitions (GCC 15), which the pinned
     GCC 11.4 is meant to remove. ✅ **GONE 2026-11-05** (NEXT SESSION C): `MODE=upstream` now
     builds with the pinned reference GCCs (projeny and compiler-rt: 11.4.0; yolo musl: 12.3.0),
     with Ubuntu's defaults in a `specs` file (toolchain-quirks B-7–B-9). The GCC chain against
     the release, measured: `.comment` the same versions on the same pieces (`zilc reference`
     for `Ubuntu …-1ubuntu1~22.04.3`); `libyolort.a` defined globals 188 = 188, no difference;
     `endbr64` 170 = 170; stack-protector members 8 = 8; fortify 1 = 1; `libyoloc.so` `endbr64`
     1,695 = 1,695; stack-clash probes 15 = 15 in `libyoloc.a` and `.so`. The zig chain on the
     same counts: 188, 170, 16 (C-10), 1, 1,694 (C-8), 15. **`compare-chains.ts` against the
     reference-GCC chain, everything fresh (2026-11-05, `OUT=~/zilc-work/equiv-refgcc`): 14/14** —
     exports: zig chain = release on 34 of 34 AND the GCC chain = release on 34 of 34 (was 33,
     `libyolort.a`); relocs ok; suite 0 differences on 7,269 vs stock and vs the GCC chain; gate
     8/8 both, line for line; corpus 500 same / 56 expected / 68 varies, 0 bad, 0 flips, all four
     modes. **Then with Zig's clang for the reference chain's libpas stock half and yolounwind**
     (owner: "not what is in ubuntu"; `tools/host-clang-shim.zig`; no `Ubuntu clang` `.comment`
     left), everything fresh (2026-11-05, `OUT=~/zilc-work/equiv-zigclang`): **14/14** — exports
     34/34 both; relocs ok; suite 0 differences on 7,269 vs stock and vs the reference chain; gate
     8/8 both, line for line; corpus GCC chain 505 same / 52 expected / 67 varies, zig chain 501 /
     56 / 67, 0 bad, 6 verdict flips, all of the allowed kinds (SAME / EXPECTED / thread-order
     shape), all four modes. **Then with the user libc from `zig build`** (roadmap Z1 item 3;
     MODE=zig no longer runs `build_usermusl.sh`; `verify-usermusl.ts` OK), everything fresh
     (2026-11-06, `OUT=~/zilc-work/equiv-usermusl`): **14/14** — exports 34/34 both, relocs ok,
     suite 0 differences on 7,269 vs stock and vs the reference chain, gate 8/8 both line for
     line, corpus GCC chain 502 / 57 / 65 and zig chain 504 / 56 / 64, 0 bad, 2 allowed flips,
     all four modes. **Then with libc++ / libc++abi from `zig build` too** (MODE=zig runs only
     `fix_clang.sh`, minilute and sarcasm of upstream's scripts; `verify-libcxx.ts` OK; minilute
     builds and runs on the zig-built libc++), everything fresh (2026-11-06,
     `OUT=~/zilc-work/equiv-libcxx`): **14/14** — exports 34/34 both, relocs ok, suite 0
     differences on 7,269 vs stock and vs the reference chain, gate 8/8 both line for line,
     corpus 499 / 60 / 65 on both chains, 0 bad, 2 allowed flips, all four modes.
- **The `libpizlo.so` relocation gap: it is the LINKER, nothing else** (proved 2026-11-04; W-14).
  The zig chain has exactly 5 more `JUMP_SLOT`s than the GCC chain (`__cxa_finalize`,
  `__register_frame_info`, `__deregister_frame_info`,
  `pas_bootstrap_free_heap_{allocate_simple,deallocate}_for_config`) and no other difference. ⚠️ The
  first explanation recorded here (unoptimized `crtbegin.o`; Zig's clang not inlining) was WRONG,
  found by testing it: the objects' relocations are identical in both chains (`crtbegin.o` = the
  release's GCC-11.4 one, `PLT32` + `REX_GOTPCRELX` for each weak function; the libpas callers
  4/2 and 5/3 `PLT32`/`GOTPCRELX` in both). What differs: GNU ld gives a function referenced
  through BOTH the PLT and the GOT one `.plt.got` stub that jumps through its GOT slot (one
  `GLOB_DAT`); LLD has no `.plt.got` and adds a `.got.plt` `JUMP_SLOT`. Same 183 GCC-chain objects:
  GNU ld 2,134, LLD 2,139. The ZIG chain's objects linked by GNU ld: 2,134 and **identical** to the
  GCC chain's library by (type, name), exports, dynamic tags and segment kinds. (Comparing by the
  `Info` column is wrong: it holds the symbol's per-link dynsym index.) Functionally the same
  either way — every name is defined in `libpizlo.so` or weak, and the suite, gate and corpus
  agree — and the 5 are removable by linking with GNU ld (scope: `open-work.md`).
- **The alias route, measured and NOT adopted** (`workarounds.md` W-13): pointing upstream's own
  host-compiler steps at `zig cc` needs five fixes and still links `libyoloc.so` differently
  without an error.

**Fil-C COMPILES with the Zig-built clang (2026-10-30; owner: "verify that Fil-C compiles with the
zig-built clang")** — `bun tools/filc/build-filc-from-source.ts`: upstream's own `build_base.sh`
steps after the LLVM build, unchanged, on the fetched sources, with `build/` holding only the
Zig-built clang. All ten succeed (projeny, compiler-rt, yolounwind, os-include, yolo musl, the
runtime, the user musl, libc++/libc++abi, minilute and sarcasm with their smoke runs; ~4 min).
`pizfix/lib`: the release's 37 entries; **31 of 32 libraries define exactly the release's global
symbols** — every one the clang compiles (`libpizlo`, `libc`, libc++, libc++abi, crt objects); the
one difference is `libyolort.a`, compiled by the HOST's GCC as upstream does: 5 extra bf16/half
conversions (`__extendbfsf2` …) because GCC 15 here supports those types and the release's GCC
11.4 did not. **Fil-C's suite on that toolchain, built entirely from source: 0 differences on all
7,269 tests** against stock (6,027 run, 6,026 pass, 1 fail `inlineasm_rdpkru`, 399 s at 24 jobs).
The tree a copy needs (found by failing): `libc` (libc++'s charconv) and `projects/lute-1.0.0`
(minilute's Luau) besides the obvious; `build/include` must exist.

**The fetched Fil-C sources (2026-10-30)**, proved by `tools/upstream/verify-filc-package.ts`:
650,987 entries equal the commit `e7947f0` as a checkout has them — every blob id; the 110 CRLF files
are exactly those upstream's own `.gitattributes` mark `eol=crlf` (`git check-attr --source`, all 23
attribute files made local first; controls `crlf` / `unspecified`); 7,477 executable bits differ
from git's modes by Zig's content rule (shebang/ELF/Mach-O, ziglang/zig#17463), as expected;
inversion caught. From that package, with no options: `zig build pure-zig` builds all 15 pieces,
and `verify-libpas` (also with no `-Dpizfix`), `verify-yolomusl` and `verify-compiler-rt` pass
(`ZILC_FILC_SRC=<package>`), as they do from the git checkout. `zig build test` 40/40 with
`check-pins` 11/11, and it downloads nothing.

**On 0.687 (2026-10-27): 0 differences on all 7,269 tests** (`compare results-stock.json
results-patched.json`, tests cloned at the `v0.687` tag). Stock and patched alike: **6,027 run,
6,026 pass, 1 fail (`inlineasm_rdpkru`, as always), 0 timeouts, 1,242 skipped**; 799 s at 12 jobs
(stock, beside the clang build), 405 s at 24 (patched).

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

**How to run it** (WSL): `tools/filc/run-filc-tests.ts`, a Bun port (Deno until 2026-10-22) of Fil-C's Ruby
`filc/run-tests` (same build, run and check rules; ledger `filc-test-runner-port`). The tests are
NOT in zilc: clone them at the compiler's commit into `~/zilc-work/filc-tests-<release>`
(`git clone --depth 1 --branch v0.686 --filter=blob:none --no-checkout
https://github.com/pizlonator/fil-c.git`, then `sparse-checkout set filc/tests
projects/openssl-3.6.4/crypto/aes/asm`, `checkout`; the second path is the input of
`sarcasm-mb-pl-sink-att`, see above), then from that folder:
`bun …/run-filc-tests.ts run --pizfix <tree>/pizfix --label stock` (and `--label patched`
with zilc's tree), then `… compare results-stock.json results-patched.json` (exit 0 = same).
`--filter REGEX` runs a subset. ⚠️ Use the tests of the COMPILER's release (`v0.687`: 7,269 —
cloned at the tag, whose tests differ from the compiler's commit `e7947f0` only by `spawnmt2`'s
skip; `v0.686`: 7,205; `v0.685`: 7,003), not upstream's newest, which test features the release
lacks.

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

## Current gates (re-run 2026-10-27 in WSL on Fil-C 0.687, commit `b33b6eb`: gate 8/8, tests 29/29, capi-smoke and baseline exit 0, `zilc --version` ok/ok; the same on 0.686 that morning)

**CI (since 2026-11-12, not yet run on GitHub):** `.github/workflows/release.yml` runs, on every
push to `main`, the steps that need no Fil-C: `zig fmt --check`, `zig build test` (40/40 on a fresh
clone with empty caches, rehearsed in WSL 2026-11-12), `bun test tools/release/` (27 cases against a
mock GitHub API), `bump.ts --check`, the privacy scan. The rows below that need Fil-C stay local;
`tools/release/release.ts` runs the gate before it pushes (`release.md` § "What runs where").

| Step | Checks | State |
| --- | --- | --- |
| `zig build gate` | Every bug example traps at the right line; the library-mode example runs (needs Fil-C) | **8/8** (2026-10-05 on Fil-C 0.686; 2026-10-02, KI-5 environ and library mode added; earlier 4/4 with the parallel code generation of KI-22 lever (a)) |
| `zig build test` | Runtime module + CLI module + the IR rewrites (incl. the KI-18 three-byte-global wrap) + the std-overlay patches (incl. the KI-21 guards) + the runtime values (`filc` only; `zig` refused 2026-09-30, removed 2026-10-27) + the version round-trip + the object cache key and `--clean-cache` (KI-22 lever c) | **29/29** pass (2026-10-05, incl. `--clean-cache`, the KI-20 note, the version facts and the `0.15.2-0.686.1` scheme) |
| `zig build capi-smoke` | `tests/capi_smoke.c` links `zilc_runtime` via `zilc.h` and calls it | pass |
| `zig build baseline` | Builds `examples/*.c` with plain `zig cc` | builds. `baseline_oob_write` prints `a[3] = 3`, exit 0: **the undetected bug** |

All gates were re-verified on **Zig 0.15.2** after the toolchain move (2026-09-18). Run them with
that Zig, not the `zig` on PATH, **inside Linux** (a WSL shell here; owner, 2026-10-27), with the
cache in the Linux home because the repo is on exFAT (KI-2, KI-3):

```sh
export ZIG_LOCAL_CACHE_DIR=~/.cache/zilc-zig
Z=~/zilc-work/tools/zig-0.15.2/zig
~/.bun/bin/bun tools/run-gate.ts
$Z build test --summary all
$Z build capi-smoke
$Z build baseline
```

Re-run 2026-10-27 this way, before and after the Linux-only tools change: gate 8/8, tests 29/29,
capi-smoke and baseline exit 0, every line of the gate's output identical. (Until 2026-10-27 the
commands ran with Windows' Zig, `C:\zig\0.15.2\zig.exe`, and the cache `C:\zig-cache\zilc`.)

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

## The pure-Zig track's oracles (2026-10-27)

Byte for byte against Fil-C's own build, for the release zilc is on (`roadmap.md` Z1), in WSL:

| check | tool | 0.687 result |
| --- | --- | --- |
| forwarder generator = Ruby's `generate_pizlonated_forwarders.rb` | `bun tools/gen/verify-forwarders.ts` | both files SAME (45,695 B, 983,629 B) |
| musl header install = `make install-headers` | `bun tools/gen/verify-musl-headers.ts` | 219 files identical |
| the same bytes, pinned | `zig build test` (`src/gen/forwarders.zig`) | SHA-256 + size; **unit tests 40/40** (29 + the generators' 11) |
| libpas's stock half, `filc_crt.o`, `filc_mincrt.o`, `libyolounwind.a` = the release tarball's | `bun tools/runtime/verify-libpas.ts` | **178/178 objects define exactly upstream's global symbols**; 1 known undefined difference (W-4); 16 assert-presence differences (budget 16); source paths in upstream's form; the three small pieces SAME |
| yolo musl's static half = the release's | `bun tools/runtime/verify-yolomusl.ts` | **1,343 members in upstream's order**, each defining upstream's symbols, binding included; 28 with compiler-only undefined differences (budget 28, W-8); 1,342 compile-unit names equal + 1 empty TU (budget 1); crt objects, `libyolom.a` |
| compiler-rt = the release's | `bun tools/runtime/verify-compiler-rt.ts` | **167 members in upstream's order**, exactly upstream's symbols, **0 departures** (`_Float16` off, as the release: W-10); 14 objects with compiler-only undefined differences (W-8) |

The three tables these build from are regenerated per release (`bun tools/runtime/import-libpas-sources.ts`,
`import-yolomusl-sources.ts`, `import-compiler-rt-sources.ts`; the last needs `ninja` on `PATH`:
`~/zilc-work/tools/ninja`). 0.687: libpas 174 C + 1 generated + 1 assembly; yolo musl 1,343 libc
members, 5 crt, 2 ldso; compiler-rt 167 builtins (3 assembly). The libraries install under
`~/zilc-work/pure-zig/filc-0.687/lib`.

After a Fil-C move: `bun tools/gen/import-signatures.ts`, then the two oracles, then re-pin the
SHA-256 values Ruby printed.

## The gate with pure-Zig modules (`zig build gate-zig-modules`, 2026-10-27)

**Owner, 2026-10-27:** after a Fil-C update has passed every checklist item, the same build runs
again "by just swapping out the fil-c specific modules with the pure zig modules", as a `build.zig`
step (`design-decisions.md`, top row). Run in WSL:

```sh
ZILC_FILC=~/zilc-work/tools/filc-<release>-zilc/build/bin/clang ZILC_ZIG=~/zilc-work/tools/zig-0.15.2/zig \
  zig build gate-zig-modules -Dzig-modules=<dir with lib/> -Dzig-modules-filc=<release>
```

`tools/swap-modules.zig` (built and run by `build.zig`) copies the `ZILC_FILC` toolchain to
`-Dzig-modules-out` (default `~/zilc-work/zig-modules/filc-<release>-zig-modules`; the repo is on
exFAT), replaces every file of `pizfix/lib/` that `<dir>/lib/` has under the same name, then asks
the copy's clang for its default link line (`clang -###`) and marks each module **PURE ZIG,
linked** / **pure Zig, but NOT in the default link** / Fil-C's. The gate (`tools/gate.zig`,
unchanged) then runs against the copy. The table is written to the copy's `ZIG-MODULES.txt`. For
the corpus and the output comparison, run those tools with `ZILC_FILC` set to the clang it prints.

⚠️ **Swapped is not used:** Fil-C's clang links dynamically, so `-lc`, `-lpizlo`, `-lyoloc` resolve
to the `.so` files; a swapped `libyoloc.a` changes nothing. Only what the link line names counts.

**Refuses (exit 1):** without `-Dzig-modules`; when `-Dzig-modules-filc` is not the release the
toolchain's own `clang --version` names; when no file would be swapped; when no swapped module is
linked.

**First run, 2026-10-27** (Fil-C 0.686, zilc's patched clang; the pure-Zig modules read from
zailc's step-2 build at `~/zailc-work/out`, as a test input — nothing written there): 13 of 32
modules swapped, **9 linked** (`Scrt1.o`, `crti.o`, `crtn.o`, `crtbegin.o`, `crtend.o`,
`filc_crt.o`, `libyolom.a`, `libyolort.a`, `libyolounwind.a`); not linked: `libyoloc.a`, `crt1.o`,
`rcrt1.o`, `filc_mincrt.o`; `libpizlo-stock.a` ignored (half of `libpizlo`, no module of that
name). **Gate 8/8**, every case trapping at the same file:line. Still Fil-C's in that run: the
shared runtime (`libc.so`, `libpizlo.so`, `libyoloc.so` and its loader `ld-fil1-x86_64.so`) and
libc++. Refusals measured: no `-Dzig-modules` → exit 1; declared 0.687 on a 0.686 toolchain →
exit 1; a directory with no Fil-C module names → exit 1.

**On 0.687 with zilc's OWN pure-Zig modules, 2026-10-27** (`build/pure_zig.zig`, installed at
`~/zilc-work/pure-zig/filc-0.687`; zilc's patched 0.687 clang as the base): the same 13 swapped and
**9 linked**; **gate 8/8**. The checklist's corpus and output comparison against the same swapped
toolchain (`ZILC_FILC` = the copy's clang; `zilc-check.ts` hands `filc()`, i.e. `ZILC_FILC`, to zilc
— the logs do not print the path, so that is read from the code): **78/78 as designed in all four
modes**, the designed 7 by name; output comparison **0 unexplained** (`{same 501, expected 55,
varies 68, variesBad 0, differs 0}`). Unit tests 40/40, plain gate 8/8 on the same tree.

**With yolo musl's shared half, 2026-10-27** (`libyoloc.so`, which is also the loader
`ld-fil1-x86_64.so`; `cmem/workarounds.md` W-11): `verify-yolomusl.ts` OK, with 1,653 exports
equal by name and type, 0 undefined, dynamic tags equal, segment kinds equal but for the allowed
`PHDR` / `GNU_PROPERTY`, and the entry at `_dlstart`. Then **14 of 32 swapped, 10 linked**
(`libyoloc.so` added); **gate 8/8**; corpus with the swapped clang **78/78 as designed in all four
modes**, C and Zig; output comparison **0 unexplained**, with the same totals as above. Unit tests
40/40, plain gate 8/8. Fil-C's still in the default link: `libc.so`, `libpizlo.so`.

## Planned gates

1. **Bug-example gate** (invariant 2 in `design-decisions.md`): every `examples/*.c` built with the
   zilc target must reproduce the table above — same fault kind, same line. Checking the exit code
   alone would pass a crash for the wrong reason.
2. 🔁 **ABANDONED in zilc 2026-10-27** (P3 moved to zailc, `design-decisions.md` top row; zilc
   has no runtime of its own to compare). Was: **Fil-C differential → `zig build gate -Druntime=filc|zig|both`** (shape set 2026-09-30,
   `roadmap.md` P3). Each case is built under Fil-C's runtime and zilc's (`zilc build --runtime`).
   Output, exit code, fault kind and file:line must match. This becomes the proof of P3, and it
   stays meaningless until `--runtime zig` is enabled.
3. 🔁 **Not zilc's since 2026-10-27** (owner: zilc stays on the compatible Zig, always; kept as a
   recommendation, `upstream.md`). Was: **Version comparison (2026-09-30).** Stage B of an upgrade (`upstream.md`): zilc built by the
   latest Zig must produce **identical gate results** to the stage-A reference built by the
   compatible Zig. The gate already takes `ZILC_ZIG`/`ZILC_FILC`, so this needs two zilc builds
   and a comparison of the two reports, not a new gate. Worth automating once it has been done by
   hand once.
4. ✅ **Benchmark suite — BUILT 2026-11-06** (planned 2026-09-30 for upgrade stage C; owner
   2026-11-05: *"upstream's plus our zig only ports of upstreams plus new ones that we write to
   test the zig only version specifically"*). See "Benchmark suite" below.

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

**First baseline** (2026-11-06, `~/zilc-work/bench/0.15.2-0.687.1/`; i9-13980HX, 32 threads,
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
