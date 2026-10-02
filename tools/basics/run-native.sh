#!/bin/sh
# Build and run every tests/basics example natively on Linux with PLAIN Zig 0.15.2
# (no Fil-C): the "does it behave" check after conversion, and the baseline that
# zilc's output will be compared against later.
#
# From Windows:  wsl.exe -e sh /mnt/d/…/zilc/tools/basics/run-native.sh [c|zig]
# Output: $OUTROOT/<lang>/<example>.out (stdout+stderr) and a summary line per example: exit code,
# or TIMEOUT for examples that wait forever (servers, signals). OUTROOT defaults to
# zig-out/basics-run in the repo; put it in the WSL home for speed (the repo is on exFAT).
# JOBS examples build and run at once (default 8): one at a time, the Zig half alone took over
# 30 minutes (2026-10-02). Each example gets its own working directory, so parallel runs never
# share files; ./tmp/dat.txt is the same in each.
ZIG=${ZIG:-$HOME/zilc-work/tools/zig-0.15.2/zig}
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
T=$ROOT/tests/basics
OUTROOT=${OUTROOT:-$ROOT/zig-out/basics-run}
export ZIG_LOCAL_CACHE_DIR=${ZIG_LOCAL_CACHE_DIR:-$HOME/.cache/zilc-basics}
LANGS=${1:-"c zig"}

one() { # lang source out-dir
  L=$1; f=$2; OUT=$3; n=$(basename "$(dirname "$f")")
  if [ "$L" = zig ]; then
    "$ZIG" build-exe -lc -target x86_64-linux-musl -femit-bin="$OUT/bin/$n" "$f" > "$OUT/$n.build" 2>&1
  else
    "$ZIG" cc -lc -target x86_64-linux-musl -o "$OUT/bin/$n" "$f" > "$OUT/$n.build" 2>&1
  fi
  if [ $? -ne 0 ]; then echo "$n BUILD-FAIL"; return; fi
  # 58_reading-files reads ./tmp/dat.txt; 60_line-filters reads stdin, and everything else
  # gets the same two lines, harmlessly.
  C=$OUT/cwd/$n; mkdir -p "$C/tmp"; printf 'hello\nzig\n' > "$C/tmp/dat.txt"
  # The same fixed environment as zilc-check.sh, so outputs compare (67 lists the environment;
  # each harness's own variables used to show up in it).
  (cd "$C" && printf 'hello\nfilter\n' | timeout 15 env -i HOME="$HOME" PATH="$PATH" USER="$USER" \
    LANG=C.UTF-8 TERM=dumb "$OUT/bin/$n" > "$OUT/$n.out" 2>&1)
  rc=$?
  if [ $rc -eq 124 ]; then echo "$n TIMEOUT"; else echo "$n exit=$rc"; fi
}

for L in $LANGS; do
  OUT=$OUTROOT/$L
  rm -rf "$OUT"; mkdir -p "$OUT/bin" "$OUT/cwd"
  D=$L; [ "$L" = zig ] && D=${ZIGDIR:-zig-0.15.2}
  for f in "$T"/$D/*/*.$L; do echo "$f"; done |
    xargs -P "${JOBS:-8}" -I{} sh -c "ZIG='$ZIG'; $(sed -n '/^one() {/,/^}/p' "$0"); one '$L' \"\$1\" '$OUT'" _ {} |
    sort > "$OUT/summary.txt"
  echo "== $L: $(grep -c 'exit=0' "$OUT/summary.txt") exit 0 / $(wc -l < "$OUT/summary.txt")"
  grep -v 'exit=0' "$OUT/summary.txt"
done
