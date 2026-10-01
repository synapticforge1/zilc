#!/bin/sh
# Archive the locally built, patched Fil-C clang (KI-4, KI-22) into the project's toolchain/
# folder, so the project folder alone can restore it (owner, 2026-10-01). LOCAL ONLY: toolchain/
# is gitignored. Pushing these files would be a DISTRIBUTION of Fil-C (Apache-2.0 + LLVM
# exception, BSD-2-Clause runtime, MIT musl); see the ledger entry `filc-pass-fixes`.
#
#   wsl.exe -e sh /mnt/d/…/zilc/tools/filc/archive-patched-clang.sh
#
# Why two files: D: is exFAT (no symlinks, no Unix permissions), so the tree goes in a tarball.
# And clang-20 built RelWithDebInfo is 3.6 GB, almost all debug info. The tree gets a STRIPPED
# clang-20 (debug info does not change what it compiles); the debug info goes to its own file,
# linked by .gnu_debuglink, for profiling with gdb (as KI-22 was diagnosed).
set -e
W=$HOME/zilc-work
REPO=$(cd "$(dirname "$0")/../.." && pwd)
SRC=$W/tools/filc-0.685-zilc
OUT=$REPO/toolchain
NAME=filc-0.685-zilc
TMP=$W/archive-tmp
rm -rf "$TMP"; mkdir -p "$TMP" "$OUT"

cp -a "$SRC" "$TMP/$NAME"
rm -f "$TMP/$NAME/build/bin/clang-prebuilt"   # comparison copy, not part of the toolchain
B=$TMP/$NAME/build/bin/clang-20
objcopy --only-keep-debug "$B" "$TMP/clang-20.debug"
strip --strip-debug "$B"
(cd "$(dirname "$B")" && objcopy --add-gnu-debuglink="$TMP/clang-20.debug" clang-20)
echo "stripped clang-20: $(du -h "$B" | cut -f1); debug info: $(du -h "$TMP/clang-20.debug" | cut -f1)"

# Stripping must not change what the compiler emits: compare against the unstripped binary.
F=$REPO/tools/p2/repro/filc-0.685-O1-crash.ll
setarch -R "$SRC/build/bin/clang-20" -O1 -Wno-override-module -c -o "$TMP/a.o" "$F"
setarch -R "$B" -O1 -Wno-override-module -c -o "$TMP/b.o" "$F"
cmp "$TMP/a.o" "$TMP/b.o" && echo "stripped clang emits identical objects (KI-4 repro, -O1)"
rm -f "$TMP/a.o" "$TMP/b.o"

tar -C "$TMP" -cf - "$NAME" | xz -T0 -6 > "$OUT/$NAME-linux-x86_64.tar.xz"
xz -T0 -6 -c "$TMP/clang-20.debug" > "$OUT/$NAME-clang-20.debug.xz"
{
  echo "# $NAME: Fil-C 0.685 clang built from llvm-project-deluge bb0d0a64 with zilc's pass fixes"
  echo "# patch: third_party/filc-patches/zilc-filc-pass.patch sha256 $(sha256sum "$REPO/third_party/filc-patches/zilc-filc-pass.patch" | cut -d' ' -f1)"
  echo "# archived $(date -u +%Y-%m-%dT%H:%MZ) by tools/filc/archive-patched-clang.sh"
  cd "$OUT" && sha256sum "$NAME-linux-x86_64.tar.xz" "$NAME-clang-20.debug.xz"
} > "$OUT/SHA256SUMS"
rm -rf "$TMP"
ls -la "$OUT"
cat "$OUT/SHA256SUMS"
