# toolchain/: local archive of zilc's patched Fil-C clang

**Everything in this folder except this README is gitignored and must never be pushed.** Pushing
it would distribute Fil-C (Apache-2.0 WITH LLVM-exception compiler, BSD-2-Clause runtime, MIT musl)
and bring the obligations listed in `third_party/LICENSES.md`, ledger entry `filc-pass-fixes`.

| file | what it is |
| --- | --- |
| `filc-0.686-zilc-linux-x86_64.tar.xz` | Fil-C 0.686's prebuilt tree with `build/bin/clang-20` replaced by our build: commit `163fae5` (fil-c.git; `bb0d0a64` for 0.685) + `third_party/filc-patches/zilc-filc-pass.patch` (KI-4 `indirectbr` lowering, KI-22 frame-slot colouring and, since 2026-10-02, its interference graph over dense ids), plus `build/bin/llvm-split` with zilc's `--zilc-part` mode (KI-22 lever (a), parallel code generation; since 2026-10-02). Both are stripped of debug info, which does not change what they produce |
| `filc-0.686-zilc-clang-20.debug.xz` | That binary's debug info (≈3.4 GB unpacked), for profiling with gdb. Optional |
| `SHA256SUMS` | Checksums, the patch's own checksum, and when the archive was made |
| `filc-0.685/` | The previous archive (Fil-C 0.685 + the same patch), with its own `SHA256SUMS`, kept on 2026-10-05 when zilc moved to 0.686. A record only: nothing restores it. To use it, unpack by hand into `~/zilc-work/tools/` |

- **Restore into WSL:** `deno run -A tools/filc/restore-patched-clang.ts [--with-debug-info]`, which installs
  to `~/zilc-work/tools/filc-0.686-zilc/`, where zilc's scripts look first.
- **Re-create after changing the patch:** `deno run -A tools/filc/build-patched-clang.ts`, then
  `deno run -A tools/filc/archive-patched-clang.ts` (from Windows or Linux; both run inside WSL).
- **Is it current?** `deno run -A tools/filc/check-toolchain.ts` (exit 0 = yes). It runs on every "update the
  project memory" (`cmem/INDEX.md` policy, step 4). It detects unsaved edits to the WSL source, a
  patch newer than this archive, and a compiler rebuilt after it.
- Why a tarball: this drive is exFAT, which has no symlinks (`clang` → `clang-20`) and no Unix
  permissions.
