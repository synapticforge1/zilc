#!/bin/sh
# Retry with Fil-C's EXACT "before" datalayout (ni:0 right after m:e).
WORK="$HOME/zilc-work"
BIN="$WORK/tools/filc-0.685-linux-x86_64/build/bin"
FILC="$BIN/clang"
OUT="$WORK/p1"
cd "$OUT"

BEFORE='e-m:e-ni:0-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128'
AFTER='e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128'

patch_dl() {
  awk -v b="$BEFORE" -v a="$AFTER" '
    /^target datalayout = / && !done {
      print "target datalayout = \"" b "\"";
      print "target datalayout_after_filc = \"" a "\"";
      done=1; next
    }
    /^target datalayout_after_filc = / { next }
    { print }
  ' "$1" > "$2"
}

for base in tiny zig_oob-x86_64-linux-gnu; do
  echo "======================================================================"
  echo "== $base"
  echo "======================================================================"
  patch_dl "$base.ll" "$base-ni2.ll"
  head -4 "$base-ni2.ll" | tail -2
  if "$FILC" -O1 -c -o "$base-ni2.o" "$base-ni2.ll" 2>"$base-ni2.log"; then
    echo "-- PASS SURVIVED. pizlonated_ symbols in object: $("$BIN/llvm-nm" "$base-ni2.o" 2>/dev/null | grep -c pizlonated_)"
  else
    echo "-- FAILED:"
    grep -m4 -E "Assertion|error:|Segmentation|UNREACHABLE" "$base-ni2.log"
  fi
  echo
done

echo "== if zig_oob compiled, try linking and running it"
if [ -f zig_oob-x86_64-linux-gnu-ni2.o ]; then
  if "$FILC" -O1 -o prog-ni2 zig_oob-x86_64-linux-gnu-ni2.ll 2>link-ni2.log; then
    echo "-- LINKED"
    ./prog-ni2 > run-ni2.log 2>&1
    echo "-- exit=$?"
    cat run-ni2.log
  else
    echo "-- LINK FAILED:"
    grep -m6 -E "error:|undefined" link-ni2.log
  fi
fi
