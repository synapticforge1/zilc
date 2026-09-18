# Upstream — tracking Fil-C

**Upstream:** https://github.com/pizlonator/fil-c, default branch **`deluge`**.
**Pinned at project start (2026-09-18):** `cd830ff67170486aaa74c253ae6ba665a2a601b5`.
**Site/docs:** https://fil-c.org/

The Fil-C repo is a **full llvm-project fork** (llvm, clang, lld, lldb, mlir, flang, libcxx…) plus
Fil-C's own directories. GitHub's license detector reports it as `NOASSERTION` because the tree is
multi-licensed (see `licensing.md`).

## Files that matter to zilc

| Upstream path | What it is | License |
| --- | --- | --- |
| `llvm/lib/Transforms/Instrumentation/FilPizlonator.cpp` | **The pass.** "Apply GIMSO semantics to LLVM IR" | Apache-2.0 WITH LLVM-exception |
| `clang/` (Fil-C diffs vs clang 20.1.8) | Frontend changes; size TBD | Apache-2.0 WITH LLVM-exception |
| `libpas/src/libpas/filc_runtime.c`, `filc_*.c/h` | **The runtime** | BSD-2-Clause |
| `libpas/` (rest) | Allocator substrate, incl. FUGC | BSD-2-Clause |
| `filc/include/stdfil.h` | Public Fil-C API header for programs | BSD-2-Clause |
| `filc/tests`, `filc/run-tests` | **Test corpus**, a candidate conformance suite for zilc | BSD-2-Clause (verify per file) |
| `projects/usermusl`, `projects/yolomusl` | The two-level libc | MIT |
| `yolounwind/` | Unwinder | verify |
| `invisicap.txt`, `invisicaps_by_example.md`, `gimso_semantics.md`, `Manifesto.md` | **Design docs**, read first | n/a (docs) |
| `README.md` | Build and license overview | n/a |

Excluded: `projects/*` other than the musl pair, `pizlix/`, and the glibc variant (see
`third_party/LICENSES.md` → Copyleft exclusion).

## Sync procedure (draft)

1. Record the new upstream SHA here with the date.
   **Check Fil-C's LLVM version** (`cmake/Modules/LLVMVersion.cmake`; 20.1.8 at the pinned SHA).
   If the major moved to 21, the Zig 0.15.2 → 0.16.0 conversion is due (`design-decisions.md`,
   `known-issues.md` KI-3). If it moved to 22+, find the Zig release that bundles that major.
2. Diff only the files in the table above between the old and new SHA.
3. For each changed file that zilc has adapted (see the ledger), port the change and update the
   ledger entry's pinned commit.
4. Re-run `zig build test` and the bug-example gate.

## Git remote

Not added yet. How Fil-C enters the repo (subtree, submodule, sparse checkout of the paths above, or
reference-only) is open question 6 in `design-decisions.md`. A sparse, blob-filtered clone keeps
the llvm-project history out:

```sh
git clone --filter=blob:none --sparse https://github.com/pizlonator/fil-c.git
git -C fil-c sparse-checkout set llvm/lib/Transforms/Instrumentation libpas filc projects/usermusl projects/yolomusl
```
