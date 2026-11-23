# testing-filc-suite.md — Fil-C's own test suite against zilc's patched clang (split from testing.md 2026-11-23)

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

Owner: run upstream's tests _"to make sure we are not missing anything that upstream has already
identified"_. **Result: stock Fil-C 0.685 clang and zilc's patched clang give the SAME result on
all 7,003 tests (0 differences).** So zilc's three pass patches (colouring, `indirectbr` lowering,
dense interference graph) change nothing Fil-C's own suite checks.

|                                   | stock 0.685                                                                             | zilc patched |
| --------------------------------- | --------------------------------------------------------------------------------------- | ------------ |
| run (x86_64 + SHA-NI, musl build) | 5,779                                                                                   | 5,779        |
| **pass**                          | **5,778**                                                                               | **5,778**    |
| fail                              | 1: `inlineasm_rdpkru`                                                                   | the same 1   |
| skipped (cannot run here)         | 1,224: 694 need AVX-512, 504 ARM-only, 24 glibc-build-only, 1 macOS-only, 1 marked skip | the same     |
| time, 24 jobs                     | ~6 min                                                                                  | ~6.5 min     |

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
