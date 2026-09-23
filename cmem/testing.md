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

## Current gates (2026-09-23)

| Step | Checks | State |
| --- | --- | --- |
| `zig build gate` | Every example traps at the right line (needs Fil-C) | **4/4** |
| `zig build test` | Runtime module + CLI module + the IR rewrite | 9/9 pass |
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
2. **Fil-C differential.** Run the same program under upstream Fil-C (Linux) and zilc. The panic
   kind and location must match.
3. **Upstream test corpus.** `filc/tests` from Fil-C, adopted under the ledger.
4. **ABI completeness.** As in wazmrt, a C file that takes the address of every function declared in
   `zilc.h`, so a declared-but-undefined symbol breaks the build.
