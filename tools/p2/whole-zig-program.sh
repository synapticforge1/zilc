#!/bin/sh
# Test 2 retry: Fil-C's libc IS musl, so Zig must target musl symbol names.
WORK="$HOME/zilc-work"
ZIG="$WORK/tools/zig-0.15.2/zig"
FILC="$WORK/tools/filc-0.685-linux-x86_64/build/bin/clang"
OUT="$WORK/p2"
cd "$OUT"

BEFORE='e-m:e-ni:0-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128'
AFTER='e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128'
patch_dl() {
  awk -v b="$BEFORE" -v a="$AFTER" '
    /^target datalayout = / && !d { print "target datalayout = \"" b "\""; print "target datalayout_after_filc = \"" a "\""; d=1; next }
    /^target datalayout_after_filc = / { next }
    { print }' "$1" > "$2"
}

for mode in ReleaseSmall ReleaseFast ReleaseSafe; do
  echo "-- $mode, target x86_64-linux-musl"
  ll="m-$mode.ll"
  if ! "$ZIG" build-exe zig_oob.zig -target x86_64-linux-musl -lc -O "$mode" -fno-emit-bin -femit-llvm-ir="$ll" 2>"m-$mode.emit.log"; then
    echo "   emit failed"; head -3 "m-$mode.emit.log" | sed 's/^/      /'; continue
  fi
  patch_dl "$ll" "m-$mode-ni.ll"
  printf '   %s lines, %s defines, %s asm  ' "$(wc -l < "$ll")" "$(grep -c '^define' "$ll")" "$(grep -c 'asm ' "$ll")"
  if "$FILC" -O1 -g -o "mprog-$mode" "m-$mode-ni.ll" 2>"m-$mode.log"; then
    echo "LINKED"
    "./mprog-$mode" > "m-$mode.run" 2>&1
    echo "   exit=$?"
    sed 's/^/      /' "m-$mode.run"
  else
    echo "FAILED"
    grep -m5 -E "error:|Assertion|Segmentation|undefined reference" "m-$mode.log" | sed 's/^/      /'
  fi
  echo
done
