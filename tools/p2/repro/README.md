# Upstream repro — Fil-C 0.685 segfaults on Zig Debug IR at clang `-O1`

`filc-0.685-O1-crash.ll` (9,773 lines, 8 functions, 604 KB) is the reduced test case for the crash
recorded in `cmem/known-issues.md` KI-4. Reproduce:

```sh
filc/build/bin/clang -O1 -c -o /dev/null filc-0.685-O1-crash.ll   # segfault in FilPizlonatorPass
filc/build/bin/clang -O0 -c -o /dev/null filc-0.685-O1-crash.ll   # fine
```

## What it is

Zig 0.15.2 `-ODebug` IR for `x86_64-linux-musl`, with the data layout rewritten into Fil-C's dialect
(`ni:0` + `datalayout_after_filc`, see KI-4) and then reduced by `../llreduce.ts`.

The 8 surviving functions are all from Zig's `std.compress.flate.Decompress` — the Huffman decoder.
Debug builds pull it in because Zig's stack-trace printing decompresses DWARF sections.

## What is known

| question | answer |
| --- | --- |
| Is it inline asm? | **No.** Fil-C compiles `__asm__` in C and `asm sideeffect` in hand-written IR |
| Is it debug metadata? | **No.** All `!dbg`/`!DI`/`#dbg_*` records were stripped; it still crashes |
| Is it odd-width integers (`i46` appears in an `sret`)? | **Not on their own.** A hand-written module storing/loading `i46` through `sret` compiles at `-O0`, `-O1` and `-O2` |
| Is it this Zig code in general? | **No.** The same `std.compress.flate` code in **ReleaseSafe** (146,488 lines) compiles fine |
| Is it the optimizer? | **Yes, in part.** Identical IR: `-O0` ✅, `-O1` ❌, `-O2` ❌ |
| Can it be reduced further? | Not at function granularity — all 8 are required (verified by a second reduction pass) |

**So: unoptimized (Debug-shaped) Zig codegen of these functions, plus LLVM's `-O1` pipeline around
the pass.** A finer answer needs a line-level reduction or a debug build of Fil-C's clang, neither of
which zilc needs in order to work around it (`src/driver.zig` compiles Debug IR at `-O0`).

## Environment

- Fil-C **0.685** prebuilt (`clang 20.1.8`, `Build config: +assertions`), Linux x86_64
- Zig **0.15.2** (LLVM 20.1.2), target `x86_64-linux-musl`, `-ODebug -fno-stack-check`
- Ubuntu 26.04 on WSL2, glibc 2.43

⚠️ **Not yet reported upstream.** Filing it is the owner's call — see `UPSTREAM-REPORT.md` for the
draft.
