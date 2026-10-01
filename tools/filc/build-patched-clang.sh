#!/bin/sh
# Build Fil-C's clang from source WITH zilc's local pass fixes, for local use only
# (cmem/workarounds.md KI-22; ledger `filc-pass-colouring-fix` in third_party/LICENSES.md).
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
# replaced. Point zilc at it with ZILC_FILC=…/filc-0.685-zilc/build/bin/clang.
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

# The patch (idempotent; fails loudly if the original text differs).
~/.deno/bin/deno run --allow-read --allow-write "$REPO/tools/filc/patch-pass.ts" \
  "$SRC/llvm/lib/Transforms/Instrumentation/FilPizlonator.cpp"

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
ninja clang

# Install: the prebuilt tree (headers, runtime, libc) with our clang binary in place.
rm -rf "$OUT"
cp -a "$PREBUILT" "$OUT"
cp bin/clang-20 "$OUT/build/bin/clang-20"
"$OUT/build/bin/clang" --version | head -1
echo "installed: $OUT/build/bin/clang"
