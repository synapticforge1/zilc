# Reference Projects

We **study** these freely and **adopt** selectively. Every adoption is gated by the Adoption
Checklist and a Component Ledger entry in `third_party/LICENSES.md`. Licenses were verified against
the upstream license files **and** source headers on 2026-09-18.

- [Fil-C](https://github.com/pizlonator/fil-c) — compiler pass — `Apache-2.0 WITH LLVM-exception`
  - Lang: C++
  - What to mine it for: `FilPizlonator.cpp`: the IR transformation itself
  - Status: ✅ **USED AS A TOOL** (2026-09-23): invoked by `zilc build`, **never vendored**, nothing copied
- Fil-C — runtime (libpas, filc runtime) — `BSD-2-Clause`
  - Lang: C
  - What to mine it for: FUGC, capability layout, syscall/libc shims, `stdfil.h` API
  - Status: ✅ **linked into zilc-built binaries by Fil-C itself**; not vendored here. P3 would replace it with Zig
- Fil-C — musl (`usermusl`/`yolomusl`) — `MIT`
  - Lang: C
  - What to mine it for: The two-level libc approach
  - Status: ✅ in use — it is why `-target …-musl` is required (KI-6)
- Fil-C — docs — n/a
  - Lang: —
  - What to mine it for: `invisicap.txt`, `invisicaps_by_example.md`, `gimso_semantics.md`, `Manifesto.md`
  - Status: **Read first** — `gimso_semantics.md` explained the `ni:0` requirement
- [LLVM](https://github.com/llvm/llvm-project) — `Apache-2.0 WITH LLVM-exception`
  - Lang: C++
  - What to mine it for: Pass infrastructure, plugin API, clang 20→21 deltas
  - Status: Evaluating
- [Zig](https://codeberg.org/ziglang/zig) — `MIT`
  - Lang: Zig
  - What to mine it for: LLVM backend, `zig cc` driver, bundled libcs, `std.heap`
  - Status: ✅ **First adoption 2026-09-30:** the 0.16.0 `findSentinel` body, backported to 0.15.2 by `src/stdpatch.zig` (ledger: zig-std-backports). zilc otherwise _invokes_ Zig

All permissive; all compatible with our dual `Apache-2.0 WITH LLVM-exception OR MIT`. See
`licensing.md` for the runtime-linking caveat.

## Candidates to look at later (not yet verified)

- **CHERI / CheriBSD**: hardware capabilities. The conceptual ancestor of InvisiCap-style
  bounds.
- **AddressSanitizer / HWASan** (in LLVM): _detection_ tools, not safety guarantees, but useful
  as a performance and coverage comparison.
- **Zig issue tracker**: search for the "safe / Fil-C-like target" proposal that the vision
  discussion referenced (unverified; see `vision.md`).
