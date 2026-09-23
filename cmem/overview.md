# Overview

`zilc` (**Zig + Fil-C**) aims to be a **Fil-C-style memory-safe compilation target for the Zig
toolchain**. The goal is for one `zig` binary to compile Zig, C and C++ to code where out-of-bounds
access and use-after-free are deterministic panics, not undefined behavior.

It is derived from [Fil-C](https://github.com/pizlonator/fil-c) (upstream) and built on Zig's
bundled LLVM/clang. See `vision.md` for the why and `architecture.md` for the how.

## Repo layout

```text
zilc/
├── build.zig              # Build graph: CLI, static runtime lib, tests, capi-smoke, baseline
├── build.zig.zon          # Package manifest (name .zilc, v0.1.0, min zig 0.15.2, no deps)
├── cmem/                  # Portable project memory (this folder)
├── include/
│   └── zilc.h             # C ABI of the runtime (the contract capi.zig implements)
├── src/
│   ├── root.zig           # library surface; re-exports `ir`
│   ├── ir.zig             # 🔑 the IR rewrite into Fil-C's dialect (unit-tested)
│   ├── driver.zig         # the pipeline: zig build-obj → rewrite → filc clang
│   ├── capi.zig           # C ABI exports: zilc_version()
│   └── main.zig           # `zilc` CLI: `zilc build [options] <inputs…>`
├── tests/
│   └── capi_smoke.c       # C client linking the runtime through zilc.h
├── examples/
│   ├── oob_write.c        # heap out-of-bounds write (must panic under zilc)
│   ├── use_after_free.c   # UAF read (must panic under zilc)
│   └── interop/           # 🎯 the milestone: C allocates, Zig overflows, Fil-C traps
│       ├── c_caller.c     #   owns main (KI-5) and calls into Zig
│       └── bounds.zig     #   C-ABI functions whose stores are capability-checked
├── tools/
│   ├── gate.zig           # 🎯 the safety gate's runner (`zig build gate`)
│   ├── run-gate-wsl.sh    # run that gate inside WSL, where Fil-C lives
│   ├── p1/                # feasibility scripts: install, reference behavior, IR spike
│   └── p2/                # integration scripts, the Debug-crash repro, llreduce.ts
├── third_party/
│   ├── LICENSES.md        # Compliance ledger (EMPTY) + adoption checklist + inventory
│   ├── fil-c/             # LLVM-LICENSE.txt, PAS-LICENSE.txt, MUSL-LICENSE.txt (staged)
│   ├── llvm/              # LICENSE.TXT (staged)
│   └── zig/               # LICENSE (staged)
├── LICENSE-APACHE · LICENSE-MIT · NOTICE
└── README.md              # Public, user-facing doc
```

## Build targets

| Step | What it does |
| --- | --- |
| `zig build` | Installs `zilc` exe, `zilc_runtime` static lib, `zilc.h` |
| `zig build gate` | 🎯 **The safety gate** — builds every example with zilc, asserts each traps at the right line. Needs Fil-C; skips with guidance otherwise |
| `zig build test` | Unit tests (runtime module + CLI module + the IR rewrite) |
| `zig build capi-smoke` | Builds and runs `tests/capi_smoke.c` against the runtime (gnu ABI) |
| `zig build baseline` | Builds `examples/*.c` with plain `zig cc`, the unsafe reference behavior |
| `zig build run -- …` | Runs the CLI |

⚠️ Use **Zig 0.15.2** (`C:\zig\0.15.2\zig.exe`), not the `zig` on PATH (0.16), and always set
`ZIG_LOCAL_CACHE_DIR=C:\zig-cache\zilc` first (see `known-issues.md` KI-2, KI-3).

## Mental model

Three pieces, one of which already exists elsewhere:

1. **Frontends**: Zig's own compiler and its embedded clang (`zig cc` / `zig c++`). These already
   produce LLVM IR. zilc does not replace them.
2. **The zilc pass**: an LLVM IR transformation that turns every pointer operation into a
   capability-checked one. Fil-C's `FilPizlonator.cpp` is the reference implementation.
3. **`zilc_runtime`**: what instrumented code calls into (allocation, the GC, capability lookup,
   syscall and libc shims). Fil-C's is C (`libpas` + `filc_runtime.c`). zilc's is intended to be Zig.
