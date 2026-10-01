# Testing

## 🎯 `zig build gate` — THE SAFETY GATE (new 2026-09-23). **4/4 green**

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
| **runs as designed under zilc** (ReleaseSafe) | **78/78** (`42_panic` traps via Fil-C, as designed) | ~~24~~ → 26 (KI-8) → 45 (KI-7) → 50 (panic handler + KI-9) → **71/78** (KI-13 overflow fold + `fromPage` patch, KI-14 `-fno-valgrind`). 65 clean exits plus 6 intentional (`42` panic, `66` exit 1 without a subcommand, `77` exit 3, three servers). **Left, 7:** 6 × `cannot read pointer with null object`, 1 × `cannot access pointer with null object`. The 2 bounds violations are fixed (KI-11, KI-12) |
| **other modes** (KI-16) | same as ReleaseSafe (C ignores `-O`) | Debug / ReleaseFast / ReleaseSmall: **being measured** (`tools/basics/all-modes.sh`). Debug is known to stop at the first allocation (KI-15) |

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

## Current gates (re-run 2026-09-30)

| Step | Checks | State |
| --- | --- | --- |
| `zig build gate` | Every example traps at the right line (needs Fil-C) | **4/4** (2026-09-30, after `--runtime` was added) |
| `zig build test` | Runtime module + CLI module + the IR rewrite + the `--runtime zig` refusal + the version round-trip | **11/11** pass |
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
