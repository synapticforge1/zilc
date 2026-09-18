# Reference Projects

We **study** these freely and **adopt** selectively. Every adoption is gated by the Adoption
Checklist and a Component Ledger entry in `third_party/LICENSES.md`. Licenses were verified against
the upstream license files **and** source headers on 2026-09-18.

| Project | License (SPDX) | Lang | What to mine it for | Status |
| --- | --- | --- | --- | --- |
| [Fil-C](https://github.com/pizlonator/fil-c) — compiler pass | `Apache-2.0 WITH LLVM-exception` | C++ | `FilPizlonator.cpp`: the IR transformation itself | Evaluating (**primary upstream**) |
| Fil-C — runtime (libpas, filc runtime) | `BSD-2-Clause` | C | FUGC, capability layout, syscall/libc shims, `stdfil.h` API | Evaluating |
| Fil-C — musl (`usermusl`/`yolomusl`) | `MIT` | C | The two-level libc approach | Evaluating |
| Fil-C — docs | n/a | — | `invisicap.txt`, `invisicaps_by_example.md`, `gimso_semantics.md`, `Manifesto.md` | **Read first** |
| [LLVM](https://github.com/llvm/llvm-project) | `Apache-2.0 WITH LLVM-exception` | C++ | Pass infrastructure, plugin API, clang 20→21 deltas | Evaluating |
| [Zig](https://codeberg.org/ziglang/zig) | `MIT` | Zig | LLVM backend, `zig cc` driver, bundled libcs, `std.heap` | Evaluating |

All permissive; all compatible with our dual `Apache-2.0 WITH LLVM-exception OR MIT`. See
`licensing.md` for the runtime-linking caveat.

## Candidates to look at later (not yet verified)

- **CHERI / CheriBSD**: hardware capabilities. The conceptual ancestor of InvisiCap-style
  bounds.
- **AddressSanitizer / HWASan** (in LLVM): *detection* tools, not safety guarantees, but useful
  as a performance and coverage comparison.
- **Zig issue tracker**: search for the "safe / Fil-C-like target" proposal that the vision
  discussion referenced (unverified; see `vision.md`).
