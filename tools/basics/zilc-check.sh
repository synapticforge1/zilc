#!/bin/sh
# Build every tests/basics example with zilc (MODE=ReleaseSafe by default; Debug, ReleaseFast,
# ReleaseSmall: KI-16), run it, and classify the result:
# OK, BUILD-FAIL (with the first undefined symbol or error), TRAP (with Fil-C's fault), TIMEOUT, BUILD-TIMEOUT (zilc build over $TBUILD s, default 1800),
# or a plain exit code. The quick loop for fixing std-under-zilc problems (KI-7…KI-10).
#
#   wsl.exe -e sh /mnt/d/…/zilc/tools/basics/zilc-check.sh [c|zig]
# Output: $WORK/basics-zilc/results.txt, plus each program's .log (build) and .out (run).
WORK=${WORK:-$HOME/zilc-work}
REPO=$(cd "$(dirname "$0")/../.." && pwd)
export ZILC_ZIG=${ZILC_ZIG:-$WORK/tools/zig-0.15.2/zig}
# Default: the locally patched Fil-C clang (KI-22, tools/filc/build-patched-clang.sh); the prebuilt
# if it is not built. The prebuilt stays for comparison (tools/filc/compare-clangs.sh).
ZILC_FILC_DEFAULT=$WORK/tools/filc-0.685-zilc/build/bin/clang
[ -x "$ZILC_FILC_DEFAULT" ] || ZILC_FILC_DEFAULT=$WORK/tools/filc-0.685-linux-x86_64/build/bin/clang
export ZILC_FILC=${ZILC_FILC:-$ZILC_FILC_DEFAULT}
export ZIG_LOCAL_CACHE_DIR=${ZIG_LOCAL_CACHE_DIR:-$HOME/.cache/zilc-basics}
# Up to $JOBS builds run at once, and each big module splits its code generation into parallel
# parts (KI-22 lever a): cap the parts so 12 builds cannot start 12 x 16 clang processes.
export ZILC_JOBS=${ZILC_JOBS:-4}
# The corpus measures real compiles (its build times are recorded in cmem/testing.md), so zilc's
# object cache (KI-22 lever c) is off unless asked for: a second run would otherwise be all hits.
export ZILC_CACHE=${ZILC_CACHE:-0}
MODE=${MODE:-ReleaseSafe}
OUT=$WORK/basics-zilc${MODE:+-$MODE}
LANGS=${1:-"c zig"}
rm -rf "$OUT"; mkdir -p "$OUT"
"$ZILC_ZIG" build --build-file "$REPO/build.zig" --prefix "$OUT/zilc" -Doptimize=ReleaseSafe || exit 1
export ZILC=$OUT/zilc/bin/zilc
cp -r "$REPO/tests/basics" "$OUT/src"

one() {
  L=$1; f=$2; n=$(basename "$(dirname "$f")"); B=$OUT/bin/$L/$n
  mkdir -p "$B/cwd/tmp"; printf 'hello\nzig\n' > "$B/cwd/tmp/dat.txt"
  s=$(date +%s)
  timeout "${TBUILD:-1800}" "$ZILC" build -O "$MODE" -o "$B/prog" "$f" > "$B/build.log" 2>&1; brc=$?
  echo "build seconds: $(( $(date +%s) - s ))" >> "$B/build.log"
  if [ $brc -eq 124 ]; then echo "$L $n BUILD-TIMEOUT"; return; fi
  if [ $brc -ne 0 ]; then
    why=$(grep -o "undefined reference to \`[^']*'" "$B/build.log" | head -1)
    [ -z "$why" ] && why=$(grep -m1 -i 'error' "$B/build.log" | cut -c1-100)
    echo "$L $n BUILD-FAIL $why"; return
  fi
  # A fixed environment, the same as run-native.sh's, so outputs compare with native
  # (compare-output.ts): this script's own ZILC_* variables used to show up in 67's listing.
  (cd "$B/cwd" && printf 'hello\nfilter\n' | timeout 15 env -i HOME="$HOME" PATH="$PATH" USER="$USER" \
    LANG=C.UTF-8 TERM=dumb "$B/prog" > "$B/run.out" 2>&1); rc=$?
  if grep -q 'filc safety error\|filc panic' "$B/run.out"; then
    echo "$L $n TRAP $(grep -m1 'filc safety error\|filc panic' "$B/run.out" | sed 's/.*filc safety error: //' | cut -c1-110)"
  elif [ $rc -eq 124 ]; then echo "$L $n TIMEOUT"
  elif [ $rc -eq 0 ]; then echo "$L $n OK"
  else echo "$L $n exit=$rc"; fi
}
# No `export -f one`: it is bash-only, and dash (`sh`) exits with status 2 on it, silently,
# before any program runs (2026-10-02). The workers get `one` below, from `typeset -f` or `sed`.
for L in $LANGS; do
  D=$L; [ "$L" = zig ] && D=${ZIGDIR:-zig-0.15.2}
  for f in "$OUT"/src/$D/*/*.$L; do echo "$L $f"; done
done | xargs -P "${JOBS:-12}" -L 1 sh -c "OUT='$OUT' ZILC='$ZILC' MODE='$MODE'; $(typeset -f one 2>/dev/null || sed -n '/^one() {/,/^}/p' "$0"); one \"\$0\" \"\$1\"" | sort > "$OUT/results.txt"

for L in $LANGS; do
  echo "== $L [$MODE]: $(grep -c "^$L .* OK$" "$OUT/results.txt") OK / $(grep -c "^$L " "$OUT/results.txt")"
  grep "^$L " "$OUT/results.txt" | grep -v ' OK$' | awk '{ $1=""; $2=""; print }' | sed 's/^ *//' | sed -E 's/ [0-9a-fx]{8,}//g; s/[[0-9]+] //' | sort | uniq -c | sort -rn
done
