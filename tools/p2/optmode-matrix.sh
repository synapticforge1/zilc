#!/bin/sh
# Shrink Zig's IR until it is small enough to inspect, and see if the crash follows.
WORK="$HOME/zilc-work"
ZIG="$WORK/tools/zig-0.15.2/zig"
FILC="$WORK/tools/filc-0.685-linux-x86_64/build/bin/clang"
OUT="$WORK/p2"
cd "$OUT"
cp "$WORK/p1/tiny.zig" . 2>/dev/null

BEFORE='e-m:e-ni:0-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128'
AFTER='e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128'
patch_dl() {
  awk -v b="$BEFORE" -v a="$AFTER" '
    /^target datalayout = / && !d { print "target datalayout = \"" b "\""; print "target datalayout_after_filc = \"" a "\""; d=1; next }
    /^target datalayout_after_filc = / { next }
    { print }' "$1" > "$2"
}

for mode in Debug ReleaseSafe ReleaseSmall ReleaseFast; do
  ll="tiny-$mode.ll"
  "$ZIG" build-obj tiny.zig -target x86_64-linux-gnu -O "$mode" -fno-emit-bin -femit-llvm-ir="$ll" 2>/dev/null
  patch_dl "$ll" "tiny-$mode-ni.ll"
  lines=$(wc -l < "$ll")
  defs=$(grep -c '^define' "$ll")
  asm=$(grep -c 'asm ' "$ll")
  if "$FILC" -O1 -c -o "tiny-$mode.o" "tiny-$mode-ni.ll" 2>"$mode.log"; then
    verdict="PASS OK"
  else
    verdict="CRASH ($(grep -m1 -oE 'exit code [0-9]+|Assertion' "$mode.log"))"
  fi
  printf '%-14s %7s lines  %4s defines  %3s asm   %s\n' "$mode" "$lines" "$defs" "$asm" "$verdict"
done
