# third_party/filc-patches/

`zilc-filc-pass.patch` is the diff of zilc's local changes to two files of Fil-C's LLVM fork:
`llvm/lib/Transforms/Instrumentation/FilPizlonator.cpp` and `llvm/tools/llvm-split/llvm-split.cpp`.

- **Licence:** `SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception` — the licence of both files
  upstream (`third_party/fil-c/LLVM-LICENSE.txt`, `third_party/llvm/LICENSE.TXT`). The patch carries no
  header of its own because it is compared byte for byte with `git diff` of the patched source
  (`tools/filc/check-toolchain.ts`); this README states its licence instead.
- **Modified by zilc** (Apache-2.0 §4(b)): every `+` line is zilc's change; what each one does is in
  `third_party/LICENSES.md`, ledger entry `filc-pass-fixes`, and in the edit scripts
  `tools/filc/patch-pass.ts` and `tools/filc/patch-split.ts`, which are the source of truth.
- **Local use only:** the patched clang built from it is not distributed (`toolchain/` is gitignored).
- Current base: Fil-C 0.687, commit `e7947f0` (2026-10-27).
