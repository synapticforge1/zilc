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

⚠️ **Not filed as an issue.** Both repros here are summarised for maintainers in `../../../UPSTREAM-ISSUES.md` (owner, 2026-10-01); `UPSTREAM-REPORT.md` is the older issue
draft.

---

# Second repro — Fil-C 0.685 asserts on a global with a 3-byte value type (KI-18, 2026-10-01)

`filc-0.685-i21-global.ll` (16 lines) aborts `FilPizlonator.cpp:16714` with
`Assertion '!(CSize % WordSize)' failed`, at `-O0`, `-O1` and `-O2`. One global
`@g = internal unnamed_addr constant i21 65533` is enough. It comes from Zig 0.15.2's
`std.unicode.replacement_character: u21`, found by `../llreduce.ts` reducing globals.

| tried | result |
| --- | --- |
| a global of type `i17`, `i21`, `i24`, constant or mutable | ❌ asserts |
| a global of type `<3 x i8>`, `<24 x i1>`, `<17 x i1>`, `<2 x i12>` (found in `69_http-client`) | ❌ asserts |
| a global of type `i2`, `i8`, `i9`, `i12`, `i16`, `i25`, `i31`, `i32`, `i33`, `i39`, `i40`, `i41`, `i48`, `i49`, `i56`, `i57`, `i63`, `i64`, `i65`, `i100`, `i120` | ✅ |
| a global of type `<3 x i1>`, `<5 x i8>`, `<6 x i8>`, `<7 x i8>`, `<9 x i8>`, `<11 x i8>`, `<12 x i8>`, `<3 x i16>`, `<3 x i32>`, `<3 x float>` | ✅ |
| `{ i21 }`, `{ i21, i8 }`, `[2 x i21]`, `[3 x i8]`, `{ <3 x i8> }` | ✅ |
| `i21` in an `alloca`, a load or a store; a load of `i21` from an `i32` global | ✅ |

So the trigger is a **global whose value type has a 3-byte store size**. zilc wraps such a value in
a one-field struct (`ir.wrapThreeByteGlobals`), which has the same size, alignment and bytes. The
full reasoning is in `cmem/workarounds.md`.
