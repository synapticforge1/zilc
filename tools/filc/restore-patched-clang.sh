#!/bin/sh
# Restore the patched Fil-C clang from the project's toolchain/ folder into WSL, where zilc's
# scripts expect it (~/zilc-work/tools/filc-0.685-zilc). The alternative is a ~1 h rebuild with
# tools/filc/build-patched-clang.sh.
#
#   wsl.exe -e sh /mnt/d/…/zilc/tools/filc/restore-patched-clang.sh [--with-debug-info]
#   DEST=/some/dir …   restores there instead (used to test the archive without touching the install)
set -e
REPO=$(cd "$(dirname "$0")/../.." && pwd)
IN=$REPO/toolchain
NAME=filc-0.685-zilc
DEST=${DEST:-$HOME/zilc-work/tools}
cd "$IN"
grep -v '^#' SHA256SUMS | sha256sum -c -
mkdir -p "$DEST"
rm -rf "$DEST/$NAME"
xz -dc "$NAME-linux-x86_64.tar.xz" | tar -C "$DEST" -xf -
if [ "$1" = "--with-debug-info" ]; then
  # gdb finds it next to the binary through the .gnu_debuglink section.
  xz -dc "$NAME-clang-20.debug.xz" > "$DEST/$NAME/build/bin/clang-20.debug"
fi
# The archive's kernel-header links point wherever they pointed on the machine that made it.
sh "$REPO/tools/filc/fix-os-include.sh" "$DEST/$NAME"
"$DEST/$NAME/build/bin/clang" --version | head -1
echo "restored: $DEST/$NAME/build/bin/clang"
