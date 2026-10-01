#!/bin/sh
# Build and run every tests/basics example natively on Linux with PLAIN Zig 0.15.2
# (no Fil-C): the "does it behave" check after conversion, and the baseline that
# zilc's output will be compared against later.
#
# From Windows:  wsl.exe -e sh /mnt/d/…/zilc/tools/basics/run-native.sh [c|zig]
# Output: zig-out/basics-run/<lang>/<example>.out (stdout+stderr) and a summary line per
# example: exit code, or TIMEOUT for examples that wait forever (servers, signals).
ZIG=${ZIG:-$HOME/zilc-work/tools/zig-0.15.2/zig}
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
T=$ROOT/tests/basics
export ZIG_LOCAL_CACHE_DIR=${ZIG_LOCAL_CACHE_DIR:-$HOME/.cache/zilc-basics}
LANGS=${1:-"c zig"}
for L in $LANGS; do
  OUT=$ROOT/zig-out/basics-run/$L
  rm -rf "$OUT"; mkdir -p "$OUT/bin" "$OUT/cwd/tmp"
  # 58_reading-files reads ./tmp/dat.txt
  printf 'hello\nzig\n' > "$OUT/cwd/tmp/dat.txt"
  : > "$OUT/summary.txt"
  D=$L; [ "$L" = zig ] && D=${ZIGDIR:-zig-0.15.2}
  for f in "$T"/$D/*/*.$L; do
    n=$(basename "$(dirname "$f")")
    if [ "$L" = zig ]; then
      "$ZIG" build-exe -lc -target x86_64-linux-musl -femit-bin="$OUT/bin/$n" "$f" > "$OUT/$n.build" 2>&1
    else
      "$ZIG" cc -lc -target x86_64-linux-musl -o "$OUT/bin/$n" "$f" > "$OUT/$n.build" 2>&1
    fi
    if [ $? -ne 0 ]; then echo "$n BUILD-FAIL" >> "$OUT/summary.txt"; continue; fi
    # 60_line-filters reads stdin; everything else gets the same two lines, harmlessly.
    (cd "$OUT/cwd" && printf 'hello\nfilter\n' | timeout 15 "$OUT/bin/$n" > "$OUT/$n.out" 2>&1)
    rc=$?
    if [ $rc -eq 124 ]; then echo "$n TIMEOUT" >> "$OUT/summary.txt"; else echo "$n exit=$rc" >> "$OUT/summary.txt"; fi
  done
  echo "== $L: $(grep -c 'exit=0' "$OUT/summary.txt") exit 0 / $(wc -l < "$OUT/summary.txt")"
  grep -v 'exit=0' "$OUT/summary.txt"
done
