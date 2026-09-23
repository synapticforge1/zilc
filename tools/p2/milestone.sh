#!/bin/sh
# THE MILESTONE: Zig code + a C caller, both through Fil-C's pass, must trap.
WORK="$HOME/zilc-work"
ZIG="$WORK/tools/zig-0.15.2/zig"
FILC="$WORK/tools/filc-0.685-linux-x86_64/build/bin/clang"
SRCDIR="<scratchpad>"
OUT="$WORK/p2"
cd "$OUT"
cp "$SRCDIR/c_caller.c" .
cp "$WORK/p1/zig_oob.zig" . 2>/dev/null

BEFORE='e-m:e-ni:0-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128'
AFTER='e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128'
patch_dl() {
  awk -v b="$BEFORE" -v a="$AFTER" '
    /^target datalayout = / && !d { print "target datalayout = \"" b "\""; print "target datalayout_after_filc = \"" a "\""; d=1; next }
    /^target datalayout_after_filc = / { next }
    { print }' "$1" > "$2"
}

echo "=================================================================="
echo "TEST 1 — C main + Zig object (zig_add/zig_sum), ReleaseSafe"
echo "=================================================================="
"$ZIG" build-obj tiny.zig -target x86_64-linux-gnu -OReleaseSafe -fno-emit-bin -femit-llvm-ir=t1.ll 2>/dev/null
patch_dl t1.ll t1-ni.ll
if "$FILC" -O1 -c -o t1.o t1-ni.ll 2>t1c.log; then
  echo "-- Zig object compiled through the pass"
  if "$FILC" -O1 -g -o prog1 c_caller.c t1.o 2>t1l.log; then
    echo "-- linked C + Zig"
    ./prog1 > t1run.log 2>&1
    echo "-- exit=$?"
    cat t1run.log | sed 's/^/   /'
  else
    echo "-- LINK FAILED:"; grep -m6 -E "error|undefined" t1l.log | sed 's/^/   /'
  fi
else
  echo "-- COMPILE FAILED:"; grep -m3 -E "error|Assertion|Segmentation" t1c.log | sed 's/^/   /'
fi

echo
echo "=================================================================="
echo "TEST 2 — a whole Zig program (zig_oob.zig, libc malloc + printf)"
echo "=================================================================="
for mode in ReleaseSmall ReleaseSafe ReleaseFast; do
  echo "-- $mode"
  if "$ZIG" build-exe zig_oob.zig -target x86_64-linux-gnu -lc -O "$mode" -fno-emit-bin -femit-llvm-ir="z-$mode.ll" 2>"z-$mode.emit.log"; then
    patch_dl "z-$mode.ll" "z-$mode-ni.ll"
    printf '   %s lines, %s defines, %s asm  ' "$(wc -l < "z-$mode.ll")" "$(grep -c '^define' "z-$mode.ll")" "$(grep -c 'asm ' "z-$mode.ll")"
    if "$FILC" -O1 -g -o "zprog-$mode" "z-$mode-ni.ll" 2>"z-$mode.log"; then
      echo "LINKED"
      "./zprog-$mode" > "z-$mode.run" 2>&1
      echo "   exit=$?"
      sed 's/^/      /' "z-$mode.run"
    else
      echo "FAILED"
      grep -m4 -E "error:|Assertion|Segmentation|undefined" "z-$mode.log" | sed 's/^/      /'
    fi
  else
    echo "   emit failed"; head -3 "z-$mode.emit.log" | sed 's/^/      /'
  fi
done
