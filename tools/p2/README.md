# tools/p2 — integration experiments (2026-09-23)

The scripts that established how zilc reaches Fil-C: **stock Zig emits IR → rewrite two
`target datalayout` lines → Fil-C's clang runs the pass and links.** No Zig fork, no LLVM build.

Same conventions as `../p1` (POSIX shell, run through WSL from a file path).

| script | what it establishes |
| --- | --- |
| `dialect-probe.sh` + `minimal-dialect.ll` | A **hand-written** module carrying Fil-C's two layout lines is accepted. The pass does not care which frontend produced the IR |
| `optmode-matrix.sh` | Zig IR passes in **ReleaseSmall / ReleaseFast / ReleaseSafe** and crashes only in **Debug**. This is the run that overturned the previous day's conclusion |
| `milestone.sh` + `c_caller.c` | 🎯 **The milestone.** C allocates, a Zig function overflows, Fil-C panics naming `tiny.zig:4:6` under `c_caller.c:15:5` |
| `whole-zig-program.sh` | A whole Zig program links and runs (musl target, KI-6) and then traps in Zig's start code walking the aux vector (KI-5) |

The layout rewrite each script performs:

```
target datalayout = "e-m:e-ni:0-p270:32:32-…-S128"        # ni:0 added, right after m:e
target datalayout_after_filc = "e-m:e-p270:32:32-…-S128"  # new line, Fil-C-only directive
```

⚠️ Position matters — LLVM compares layout strings textually. See `cmem/known-issues.md` KI-4.
