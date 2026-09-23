# Roadmap

> **Updated 2026-09-23.** WSL is available now, and **P1 steps 1–2 are DONE**. Step 3 ran and
> **falsified the wrapper-driver route** — see the results below. The later phases are still a sketch.

## ✅ P0 — Scaffold (`0.1.0`, 2026-09-18)

Repo layout, dual license + staged upstream licenses, compliance ledger, `cmem/`, build graph with
`test` / `capi-smoke` / `baseline`, two bug examples.

## ◐ P1 — The feasibility milestone. Steps 1–2 ✅ 2026-09-23. Step 3 ran and **answered the route question**.

> **Milestone:** a Zig program plus a C library, compiled through Fil-C's *existing* pass and
> runtime, panics correctly on out-of-bounds and use-after-free. **Not reached** — and the reason
> is structural, not a bug in our test.

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

### ❌ Step 3 — Zig IR does NOT go through Fil-C's clang. **The wrapper-driver route is dead.**

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

**Therefore:** option (c), "stock Zig emits IR, Fil-C's clang runs the pass", **cannot work**, and
option (b), an LLVM pass plugin in a stock LLVM, is equally blocked — `ni:0` and
`datalayout_after_filc` do not exist there. See `design-decisions.md` open question 1, now settled.

### ▶️ Step 4 — the remaining route: **Zig built against Fil-C's LLVM**

Zig's compiler links LLVM's C++ API, and Zig 0.15.2 wants **LLVM 20** — which is exactly what Fil-C
is (20.1.8). So the viable shape is: build the Zig compiler against Fil-C's `llvm-project-deluge`,
teach Zig's codegen to emit the Fil-C data layout (both lines) and to run `FilPizlonatorPass`.
**That is a compiler build, not a script**, and it is the next thing to size (P2).

Not yet tried, and worth an hour before committing to that: **`zig cc` cannot be the frontend, but
Fil-C's clang can be** — Fil-C compiles C and C++ today, so the C half of the milestone is already
available. Only the *Zig* half needs the custom build.

## P2 — Integrate the pass with Zig (route now known)

Build Zig against Fil-C's LLVM 20 fork; emit Fil-C's data layout; run the pass in Zig's pipeline.
We do not port the pass to a newer LLVM ourselves (owner, 2026-09-18), so the Zig version stays
0.15.2 until Fil-C moves. **Exit criterion:** the P1 milestone reproduces through zilc's own
tooling instead of hand-run commands.

**First questions for P2 sizing:** can Fil-C's LLVM be built as the libraries Zig links against
(`find_package(llvm 20)`), and how much of Zig's `codegen/llvm.zig` has to change to set two data
layouts and add one pass?

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
