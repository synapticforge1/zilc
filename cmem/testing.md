# Testing

## Current gates (2026-09-18)

| Step | Checks | State |
| --- | --- | --- |
| `zig build test` | Runtime module + CLI module unit tests | 1/1 pass |
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

## Planned gates

1. **Bug-example gate** (invariant 2 in `design-decisions.md`): every `examples/*.c` built with the
   zilc target must exit with the runtime's panic status, **and** its panic message must name the
   right fault (OOB vs UAF). Checking the exit code alone would pass a crash for the wrong reason.
2. **Fil-C differential.** Run the same program under upstream Fil-C (Linux) and zilc. The panic
   kind and location must match.
3. **Upstream test corpus.** `filc/tests` from Fil-C, adopted under the ledger.
4. **ABI completeness.** As in wazmrt, a C file that takes the address of every function declared in
   `zilc.h`, so a declared-but-undefined symbol breaks the build.
