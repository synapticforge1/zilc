#!/bin/sh
# Binary-size comparison over tests/basics: Zig ReleaseSmall, Zig ReleaseSafe, and zilc,
# for the C examples and the Zig 0.15.2 examples. Also records whether each zilc binary
# runs with the same exit code as the plain ReleaseSafe build.
#
# From Windows:  wsl.exe -e sh /mnt/d/…/zilc/tools/basics/size-compare.sh
# Output: $WORK/basics-size/sizes.csv (and the binaries, under $WORK/basics-size/bin).
#
# ⚠️ Fairness: Zig's musl binaries are STATIC. zilc's are DYNAMIC and load Fil-C's
# libc.so, libpizlo.so and libyoloc.so at run time, so the shared runtime is reported
# separately. zilc also passes -g, so stripped sizes are reported alongside raw ones.
WORK=${WORK:-$HOME/zilc-work}
REPO=$(cd "$(dirname "$0")/../.." && pwd)
export ZILC_ZIG=${ZILC_ZIG:-$WORK/tools/zig-0.15.2/zig}
# Default: the locally patched Fil-C clang (KI-22, tools/filc/build-patched-clang.sh); the prebuilt
# if it is not built. The prebuilt stays for comparison (tools/filc/compare-clangs.sh).
ZILC_FILC_DEFAULT=$WORK/tools/filc-0.685-zilc/build/bin/clang
[ -x "$ZILC_FILC_DEFAULT" ] || ZILC_FILC_DEFAULT=$WORK/tools/filc-0.685-linux-x86_64/build/bin/clang
export ZILC_FILC=${ZILC_FILC:-$ZILC_FILC_DEFAULT}
export ZIG_LOCAL_CACHE_DIR=${ZIG_LOCAL_CACHE_DIR:-$HOME/.cache/zilc-basics}
OUT=$WORK/basics-size
rm -rf "$OUT"; mkdir -p "$OUT"

# Build zilc itself for Linux, outside the repo's zig-out.
"$ZILC_ZIG" build --build-file "$REPO/build.zig" --prefix "$OUT/zilc" -Doptimize=ReleaseSafe || exit 1
export ZILC=$OUT/zilc/bin/zilc

# Work on WSL's own disk: /mnt/d is slow and exFAT.
cp -r "$REPO/tests/basics" "$OUT/src"

echo "lang,example,zig_small,zig_safe,zilc_safe,zilc_small,zig_small_stripped,zig_safe_stripped,zilc_safe_stripped,zilc_small_stripped,run_zig_safe,run_zilc" > "$OUT/sizes.csv"
{ for f in "$OUT"/src/c/*/*.c; do echo "c $f"; done
  for f in "$OUT"/src/${ZIGDIR:-zig-0.15.2}/*/*.zig; do echo "zig $f"; done; } |
  xargs -P "${JOBS:-12}" -L 1 sh -c 'sh "$0" "$1" "$2" "'"$OUT"'"' "$REPO/tools/basics/size-one.sh" >> "$OUT/sizes.csv"

L=$WORK/tools/filc-0.685-linux-x86_64/pizfix/lib
echo "shared runtime every zilc binary loads (bytes): libc.so=$(stat -c %s $L/libc.so) libpizlo.so=$(stat -c %s $L/libpizlo.so) libyoloc.so=$(stat -c %s $L/libyoloc.so) ld-fil1=$(stat -c %s $L/ld-fil1-x86_64.so)" | tee "$OUT/runtime.txt"
echo "done: $(($(wc -l < "$OUT/sizes.csv") - 1)) rows in $OUT/sizes.csv"
