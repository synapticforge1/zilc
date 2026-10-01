#!/bin/sh
# Is the project's toolchain/ archive up to date with the patched Fil-C clang in WSL?
# Run on every "update the project memory" (cmem/INDEX.md policy, owner 2026-10-01).
#
#   wsl.exe -e sh /mnt/d/…/zilc/tools/filc/check-toolchain.sh
#
# Exit 0 = up to date. Exit 1 = stale; the message names the step to run.
W=$HOME/zilc-work
REPO=$(cd "$(dirname "$0")/../.." && pwd)
SRC=$W/filc-src/repo
PATCH=$REPO/third_party/filc-patches/zilc-filc-pass.patch
SUMS=$REPO/toolchain/SHA256SUMS
TAR=$REPO/toolchain/filc-0.685-zilc-linux-x86_64.tar.xz
BIN=$W/tools/filc-0.685-zilc/build/bin/clang-20
stale=0

# 1. Edits in the WSL source that are not saved into the repo's patch file.
if [ -d "$SRC/.git" ]; then
  if ! git -C "$SRC" diff | cmp -s - "$PATCH"; then
    echo "STALE: the WSL Fil-C source differs from $PATCH."
    echo "       Put the change in tools/filc/patch-pass.ts (the edit script is the source of truth),"
    echo "       rebuild (build-patched-clang.sh), then save the diff:"
    echo "       git -C $SRC diff > third_party/filc-patches/zilc-filc-pass.patch"
    stale=1
  fi
else
  echo "note: no WSL Fil-C source at $SRC (restored-only machine); skipping check 1"
fi

# 2. The repo's patch is not the one the archive was built from.
want=$(sha256sum "$PATCH" | cut -d' ' -f1)
have=$(grep -oE 'zilc-filc-pass.patch sha256 [0-9a-f]+' "$SUMS" 2>/dev/null | awk '{print $3}')
if [ "$want" != "$have" ]; then
  echo "STALE: toolchain/ was archived from a different patch (${have:-none} vs $want)."
  echo "       Run tools/filc/archive-patched-clang.sh."
  stale=1
fi

# 3. The installed compiler was rebuilt after the archive was made.
if [ -f "$BIN" ] && [ -f "$TAR" ] && [ "$BIN" -nt "$TAR" ]; then
  echo "STALE: $BIN is newer than the archive. Run tools/filc/archive-patched-clang.sh."
  stale=1
fi

[ $stale = 0 ] && echo "toolchain/ is up to date (patch sha256 $want)."
exit $stale
