# Roadmap

> **Updated 2026-09-23 (twice — read the P2 section).** WSL arrived, P1 ran, and its step-3 verdict
> ("the wrapper-driver route is dead") was **REVERSED by P2 the same afternoon**. ✅ **THE P1
> MILESTONE IS MET:** a Zig object and a C caller, both through Fil-C's pass, panic correctly with
> the fault located **inside the Zig source**. No Zig fork and no LLVM build were needed.

## ✅ P0 — Scaffold (`0.1.0`, 2026-09-18)

Repo layout, dual license + staged upstream licenses, compliance ledger, `cmem/`, build graph with
`test` / `capi-smoke` / `baseline`, two bug examples.

## ✅ P1 — The feasibility milestone. **MET 2026-09-23** (see P2 below for how; step 3's verdict was reversed).

> **Milestone:** a Zig program plus a C library, compiled through Fil-C's *existing* pass and
> runtime, panics correctly on out-of-bounds and use-after-free. ✅ **Reached** — via the
> ReleaseSafe/Small/Fast path, with Zig exporting a C-ABI function and C owning `main`.

### ✅ Step 1 — environment (2026-09-23, WSL2 Ubuntu 26.04)

Everything lives in the WSL home, **nothing installed system-wide, no root used**:

| item | location | note |
| --- | --- | --- |
| Fil-C **0.685** | `~/zilc-work/tools/filc-0.685-linux-x86_64` | prebuilt release; `setup.sh` run; `build/bin/clang` reports `clang 20.1.8 (Fil-C 0.685 …bb0d0a64)` |
| Zig **0.15.2** | `~/zilc-work/tools/zig-0.15.2` | official tarball, SHA-256 verified; `zig cc` = clang 20.1.2 |
| patchelf 0.19.1 | `~/zilc-work/tools/bin` | `setup.sh` needs it; `sudo` needs a password, so it was installed from the upstream prebuilt tarball instead |
| Deno 2.9.7 | `~/.deno/bin` | pre-existing |

⚠️ `sudo` on this WSL requires an interactive password, so **an agent cannot apt-install anything.**
Prefer no-root prebuilt binaries.

### ✅ Step 2 — Fil-C's reference behavior on our examples (the gate's expected output)

Both compile with `build/bin/clang -O2 -g` and **panic correctly, exit 133** (SIGTRAP):

```
oob_write.c:15 → filc safety error: cannot write pointer with ptr >= upper.
                 expected 4 writable bytes.
use_after_free.c:13 → filc safety error: cannot access pointer to free object.
                 expected valid capability.
both → [pid] filc panic: thwarted a futile attempt to violate memory safety.
```

The panic names the **source file, line and column**, so the future gate can assert the fault kind
*and* its location, not just a non-zero exit (`testing.md`).

### ⚠️ Step 3 — "Zig IR does NOT go through Fil-C's clang" — **WRONG, and corrected below in P2.**

> Everything in this step is reported as it happened. Every run used Zig's **default Debug mode**,
> and that — not "Zig IR" — is what crashes the pass. Read it as the cautionary tale it is; the
> corrected picture is in P2 and `known-issues.md` KI-4's reversal.

What was tried, in order, and what each attempt proved:

| attempt | result |
| --- | --- |
| `zig build-exe -femit-llvm-ir` (musl and gnu targets) → `filc clang prog.ll` | ❌ assert: `DLBefore.isNonIntegralAddressSpace(TargetAS)` (`FilPizlonator.cpp:16043`) |
| Same, with Zig's datalayout replaced by Fil-C's *printed* one | ❌ same assert — the printed layout is not the one the pass wants |
| **Fil-C's own `-emit-llvm` output fed back into Fil-C** | ❌ **same assert.** Its `.ll` is POST-pass (`pizlonated_` symbols) and it cannot re-consume its own output |
| `-ni:0` appended to Zig's datalayout + a `datalayout_after_filc` line | assert passed, then **SIGSEGV inside the pass** |
| `-ni:0` in the **exact position** Fil-C uses (`e-m:e-ni:0-p270:…`) | assert passed, **SIGSEGV** again, on both a tiny module and a std-using one |
| Zig **bitcode** (`-femit-llvm-bc`) via `-flto` | ❌ same assert (bitcode carries Zig's datalayout) |

🔑 **The two facts that decide the architecture:**

1. **Fil-C's "before" data layout marks address space 0 NON-INTEGRAL** —
   `e-m:e-ni:0-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128` — and the
   module also carries a Fil-C-only directive, **`target datalayout_after_filc`** (read by their
   added `Module::getDataLayoutAfterFilC()`), holding the same layout *without* `ni:0`. `ni:0` is
   not expressible in stock LLVM, which forbids a non-integral AS 0; this is a **patched-LLVM
   dialect**, not standard IR. The exact string was recovered from a backend error message, and
   position matters: LLVM compares layout strings textually.
2. **Externally produced IR is not an entry point.** Fil-C's clang cannot even re-consume its own
   `-emit-llvm` output. The frontend, not the text IR, is what establishes the dialect the pass
   requires. Getting past the assert by hand-patching the layout only reaches a segfault, because
   the layout string is a symptom of the dialect, not the whole of it.

**What was concluded (and is wrong):** that options (b) and (c) were both impossible. The dialect
facts are right; the inference from them was not. ▶️ **P2 varied the one variable nobody had varied.**

## ◐ P2 — Integrate the pass with Zig. **Started 2026-09-23. The cheap route WORKS.**

### 🔑 Experiment 1 — the segfault was Zig's DEBUG mode, not Zig IR

| input to the pass | result |
| --- | --- |
| **hand-written** `.ll` with both layout lines, no Fil-C frontend involved | ✅ accepted (`-O0` and `-O1`) |
| Zig IR, layouts patched — **ReleaseSmall** (37 lines) / **ReleaseFast** (161) / **ReleaseSafe** (4,007) | ✅ **all accepted** |
| Zig IR, layouts patched — **Debug** (189,740 lines, 1,110 functions, **114 inline-asm blocks**) | ❌ segfault |

**So the whole integration is:** stock Zig emits IR → rewrite two `target datalayout` lines →
Fil-C's clang. **No Zig fork. No LLVM build.** `tools/p2/` has the scripts.

### ✅ Experiment 2 — THE MILESTONE. Zig object + C caller, both instrumented

`tiny.zig` (ReleaseSafe) → IR → layout rewrite → `filc clang -c`, linked with `c_caller.c` which
`malloc`s 4 ints and calls Zig's `zig_add(a, 4, 99)` — one past the end. Exit **133**:

```
in bounds ok, sum=6
filc safety error: cannot write pointer with ptr >= upper.   expected 4 writable bytes.
semantic origin:
    (prog1) tiny.zig:4:6: zig_add          <-- the fault is located IN THE ZIG SOURCE
check scheduled at:
    (prog1) tiny.zig:4:6: zig_add
    (prog1) c_caller.c:15:5: main
```

🎯 **This is the P1 milestone**: C allocates, Zig overflows, Fil-C traps, and the panic names the
Zig file, line and column. Cross-language capability enforcement, working today.

### ◐ Experiment 3 — a WHOLE Zig program links and runs, then traps in Zig's start code

With `-target x86_64-linux-musl` (KI-6) all three Release modes **link and run**. They panic before
`main`, inside `start.zig:547 expandStackSize`, which walks off the end of `envp` to find the ELF
aux vector — three separate capabilities under Fil-C, one flat array under Zig's assumption (KI-5).

▶️ **So zilc's first shipping shape is clear:** Zig exports C-ABI functions, C owns `main`.
Whole-Zig-program startup needs `start.zig` work, which is what "a zilc *target*" will eventually mean.

### ✅ Experiment 4 — **the `zilc` driver exists** (2026-09-23). One command, not a script

```
$ zilc build c_caller.c bounds.zig -o interop      # ZILC_ZIG / ZILC_FILC point at the tools
$ ./interop
in bounds ok, sum=6
filc safety error: cannot write pointer with ptr >= upper.
semantic origin:  bounds.zig:13:6: zig_add   ←  c_caller.c:26:5: main      exit 133
```

- `src/ir.zig` — the rewrite, **unit-tested** (9/9 green). Idempotent, and derives *both* layouts
  from the plain one. ⚠️ Two bugs the tests caught before any Linux run: a double `-ni:0` on
  re-rewrite, and a stray trailing newline.
- `src/driver.zig` — `.zig` → `zig build-obj -femit-llvm-ir` → rewrite → `filc clang -c`; `.c/.cpp/.o/.a`
  straight to Fil-C; then one link. `--keep-temps` leaves every intermediate.
- `src/main.zig` — `zilc build`, with the guardrails as first-class behavior: **Debug is refused
  with an explanation** rather than passed through to a compiler segfault, and a non-musl target
  warns (KI-4, KI-6).
- `examples/interop/` — the milestone as a real example, not a scratch file.

### ▶️ P2 remaining work
2. **Debug mode** — find what crashes the pass (inline asm suspected). Debug is where Zig's own
   safety checks live, so it cannot stay unsupported.
3. **Startup** — KI-5: either keep C `main`, or patch `start.zig`.
4. **Only if 1–3 hit a wall:** build Zig against Fil-C's LLVM (the heavy route, now clearly *not*
   the first thing to try).

## P3 — `zilc_runtime` in Zig

Replace the C runtime with Zig, piece by piece, behind the same ABI the pass emits calls to.
**Exit criterion:** P2's gate still passes with no Fil-C C code linked.

## P4 — Zig language fidelity

P1 tests whether Zig IR survives the pass at all. P4 makes it *right*. Define how Zig's pointer
kinds (slices, many-pointers, optionals, `allowzero`, `@ptrCast`, `@intFromPtr`/`@ptrFromInt`) map
onto capabilities, and how Zig's own safety checks interact with GIMSO. **Exit criterion:** a
Zig ⇄ C program where C overflows a Zig-owned slice and panics, across the full Zig test corpus.

## P5 — C++ and polish

libc++/libc++abi under the target, exceptions/unwinding, threads with atomic capability updates,
performance measurement against Fil-C.
