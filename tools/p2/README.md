# tools/p2 — integration experiments (2026-09-23)

The scripts that established how zilc reaches Fil-C: **stock Zig emits IR → rewrite two
`target datalayout` lines → Fil-C's clang runs the pass and links.** No Zig fork, no LLVM build.

Same conventions as `../p1`: Deno tools since 2026-10-05, `deno run -A tools/p2/<tool>.ts` from
Windows or Linux. Four more tools beyond the table record later steps: `debug-mode.ts`,
`driver-milestone.ts`, `whole-program.ts` (the zilc driver and its entry shim, P2).

| script | what it establishes |
| --- | --- |
| `dialect-probe.ts` + `minimal-dialect.ll` | A **hand-written** module carrying Fil-C's two layout lines is accepted. The pass does not care which frontend produced the IR |
| `optmode-matrix.ts` | Zig IR passes in **ReleaseSmall / ReleaseFast / ReleaseSafe** and crashes only in **Debug**. This is the run that overturned the previous day's conclusion |
| `milestone.ts` + `c_caller.c` | 🎯 **The milestone.** C allocates, a Zig function overflows, Fil-C panics naming `tiny.zig:4:6` under `c_caller.c:15:5` |
| `whole-zig-program.ts` | A whole Zig program links and runs (musl target, KI-6) and then traps in Zig's start code walking the aux vector (KI-5) |

The layout rewrite each script performs:

```
target datalayout = "e-m:e-ni:0-p270:32:32-…-S128"        # ni:0 added, right after m:e
target datalayout_after_filc = "e-m:e-p270:32:32-…-S128"  # new line, Fil-C-only directive
```

⚠️ Position matters — LLVM compares layout strings textually. See `cmem/known-issues.md` KI-4.

## 📌 Record: `tiny-ni2.ll`, the input with no committed source (owner, 2026-10-05)

`dialect-probe.ts` part C reads **`tiny-ni2.ll`** (11.7 MB), copied from `$WORK/p1`. Unlike every
other input of these experiments, it is not in the repo and no tool here makes it: it is
**generated**, in this order:

1. `tools/p1/tiny.zig` → Zig 0.15.2 → `$WORK/p1/tiny.ll`: the exact command is in
   `../p1/README.md` ("Inputs that live outside the repo"), recovered and verified 2026-10-05
   (same code; only 3 debug-info path lines differ);
2. `deno run -A tools/p1/zig-ir-spike.ts` → `$WORK/p1/tiny-ni2.ll` (patches in the two layouts);
3. `deno run -A tools/p2/dialect-probe.ts` copies it into `$WORK/p2`.

Copies on 2026-10-05: `tiny.ll` 11,669,818 bytes (sha256 `5db471c2…`), `tiny-ni2.ll` 11,669,936
bytes (sha256 `3e81eb75…`). The other inputs of these tools are committed (`minimal-dialect.ll`,
`c_caller.c`, `tiny.zig`, `../p1/zig_oob.zig`); until 2026-10-05 some were copied from a session
scratchpad that no longer exists, and silently fell back to leftovers.
