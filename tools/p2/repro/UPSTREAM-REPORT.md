# Draft issue for github.com/pizlonator/fil-c — not yet filed

> Filing this is the owner's call. The text below is ready to paste; attach
> `filc-0.685-O1-crash.ll`.

---

**Title:** FilPizlonatorPass segfaults at `-O1`/`-O2` on unoptimized Zig-generated IR (fine at `-O0`)

Hi — I'm experimenting with feeding Zig-generated LLVM IR through Fil-C's pass, and hit a
reproducible crash in `FilPizlonatorPass`. It only happens at `-O1` and above; the same module
compiles cleanly at `-O0`.

I appreciate that IR from another frontend isn't a supported entry point, so feel free to close this
if it's out of scope. It reproduces with a single file and no Zig involvement, so I thought it was
worth reporting.

### Reproducing

```sh
$ clang -O1 -c -o /dev/null filc-0.685-O1-crash.ll
clang-20: /fil-c/llvm/lib/Transforms/Instrumentation/FilPizlonator.cpp: ...
1. Optimizer
2. Running pass "FilPizlonatorPass" on module "filc-0.685-O1-crash.ll"
    ... Segmentation fault

$ clang -O0 -c -o /dev/null filc-0.685-O1-crash.ll   # succeeds
```

**Version:** Fil-C 0.685 prebuilt, `clang 20.1.8 (… bb0d0a64eed297ab8e171002033208fb08ad9941)`,
`Build config: +assertions`, Linux x86_64 (Ubuntu 26.04 under WSL2, glibc 2.43).

### About the input

Zig 0.15.2 `-ODebug` output for `x86_64-linux-musl`, with the data layout rewritten to
`e-m:e-ni:0-…` plus a `target datalayout_after_filc` line so the module satisfies the pass's
entry assertions. It was then reduced from 1,110 functions to 8 by delta debugging; all 8 remain
necessary. They are Zig's `std.compress.flate` Huffman decoder — Debug builds pull it in because
Zig's stack-trace printer decompresses DWARF.

### What I ruled out

- **Inline asm** — Fil-C compiles `__asm__` in C and `asm sideeffect` in hand-written IR fine.
- **Debug metadata** — every `!dbg`/`!DI`/`#dbg_*` record is stripped from the attached file.
- **Odd-width integers** — `i46` appears in an `sret` struct here, but a hand-written module storing
  and loading `i46` through `sret` compiles at all three levels.
- **The Zig code itself** — the same `std.compress.flate` code compiled `-OReleaseSafe` (146k lines
  of IR) passes without complaint. Only the unoptimized shape of it crashes.

So it looks like an interaction between the `-O1` pipeline and the pass on unoptimized code with
these shapes, rather than any single construct.

### Not blocking me

Compiling such modules at `-O0` is a fine workaround for my use, so this is a report rather than a
request. Happy to run further experiments, cut it down more, or test a patch if that would help.
