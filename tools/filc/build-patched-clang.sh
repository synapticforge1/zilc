#!/bin/sh
# Build Fil-C's clang from source WITH zilc's local pass fixes, for local use only
# (cmem/workarounds.md KI-22; ledger `filc-pass-fixes` in third_party/LICENSES.md).
#
#   wsl.exe -e sh /mnt/d/…/zilc/tools/filc/build-patched-clang.sh
#
# Needs: build-essential + cmake (apt, `main`), Ninja in ~/zilc-work/tools/ninja (official
# release binary), Deno. The source is Fil-C's LLVM fork at the commit the 0.685 prebuilt names
# in `clang --version`, so the only difference from the prebuilt is the patch.
#
# Configuration mirrors Fil-C's own configure_llvm.sh at that commit, except LLVM_ENABLE_LLD
# (lld is not in Ubuntu's `main`); the linker changes build speed, not the compiler's output.
#
# Result: ~/zilc-work/tools/filc-0.685-zilc/  = a copy of the prebuilt tree with build/bin/clang-20
# replaced and build/bin/llvm-split added. Point zilc at it with
# ZILC_FILC=…/filc-0.685-zilc/build/bin/clang.
set -e
W=$HOME/zilc-work
SHA=bb0d0a64eed297ab8e171002033208fb08ad9941
SRC=$W/filc-src/repo
REPO=$(cd "$(dirname "$0")/../.." && pwd)
PREBUILT=$W/tools/filc-0.685-linux-x86_64
OUT=$W/tools/filc-0.685-zilc
export PATH=$W/tools/ninja:$PATH

for t in cc c++ cmake ninja; do command -v $t >/dev/null || { echo "missing: $t"; exit 1; }; done
test "$(git -C "$SRC" rev-parse HEAD)" = "$SHA" || { echo "source is not at $SHA"; exit 1; }

# The patches (idempotent; fail loudly if the original text differs). The pass fixes (KI-4,
# KI-22), and zilc's splitting mode of llvm-split for parallel code generation (KI-22 lever a).
~/.deno/bin/deno run --allow-read --allow-write "$REPO/tools/filc/patch-pass.ts" \
  "$SRC/llvm/lib/Transforms/Instrumentation/FilPizlonator.cpp"
~/.deno/bin/deno run --allow-read --allow-write "$REPO/tools/filc/patch-split.ts" \
  "$SRC/llvm/tools/llvm-split/llvm-split.cpp"

mkdir -p "$SRC/build" && cd "$SRC/build"
if [ ! -f build.ninja ]; then
  cmake -S ../llvm -B . -G Ninja -DLLVM_ENABLE_PROJECTS=clang \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo -DLLVM_ENABLE_ASSERTIONS=ON \
    -DLLVM_TARGETS_TO_BUILD=X86 \
    -DLLVM_ENABLE_LIBXML2=OFF -DLLVM_ENABLE_LIBEDIT=OFF \
    -DLLVM_ENABLE_LIBPFM=OFF -DLLVM_ENABLE_ZLIB=OFF -DLLVM_ENABLE_ZSTD=OFF \
    -DLLVM_ENABLE_CURL=OFF -DLLVM_ENABLE_HTTPLIB=OFF \
    -DLLVM_STATIC_LINK_CXX_STDLIB=ON -DCMAKE_EXE_LINKER_FLAGS=-static-libgcc
fi
# ⚠️ Not ninja's default (one job per core): 32 parallel RelWithDebInfo compiles of clang's largest
# files exhausted the 31 GB WSL VM and crashed the WSL service twice (2026-10-01,
# Wsl/Service/E_UNEXPECTED). The job count changes build speed only, never the result.
ninja -j "${JOBS:-12}" clang llvm-split

# Install: the prebuilt tree (headers, runtime, libc) with our clang binary in place, plus
# llvm-split beside it, where zilc finds it through clang's -print-prog-name. Stripped: it is
# ~1 GB of debug info otherwise, and debug info does not change what it writes.
rm -rf "$OUT"
cp -a "$PREBUILT" "$OUT"
cp bin/clang-20 "$OUT/build/bin/clang-20"
strip --strip-debug -o "$OUT/build/bin/llvm-split" bin/llvm-split
"$OUT/build/bin/clang" --version | head -1
echo "installed: $OUT/build/bin/clang"
