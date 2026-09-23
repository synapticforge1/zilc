#!/bin/sh
# P2 experiment 1: what does the pass need beyond the two datalayout lines?
WORK="$HOME/zilc-work"
FILC="$WORK/tools/filc-0.685-linux-x86_64/build/bin/clang"
SRCDIR="<scratchpad>"
OUT="$WORK/p2"
mkdir -p "$OUT"
cd "$OUT"
cp "$SRCDIR/p2-minimal.ll" .

echo "=================================================================="
echo "A. HAND-WRITTEN module in Fil-C's dialect (not from their frontend)"
echo "=================================================================="
if "$FILC" -O1 -c -o minimal.o p2-minimal.ll 2>a.log; then
  echo "ACCEPTED -- the dialect is reproducible by hand; frontend origin does NOT matter"
else
  echo "REJECTED:"
  grep -m4 -E "Assertion|error:|Segmentation" a.log | sed 's/^/   /'
fi

echo
echo "=================================================================="
echo "B. Same, at -O0 (does the pass care about the optimization level?)"
echo "=================================================================="
"$FILC" -O0 -c -o minimal0.o p2-minimal.ll 2>b.log && echo "ACCEPTED" || grep -m3 -E "Assertion|error:|Segmentation" b.log | sed 's/^/   /'

echo
echo "=================================================================="
echo "C. Zig's tiny module, patched layout, with the pass being verbose"
echo "=================================================================="
cp "$WORK/p1/tiny-ni2.ll" . 2>/dev/null
"$FILC" -O1 -c -o tiny.o tiny-ni2.ll -mllvm -filc-light-verbose > c.stdout 2>c.log
echo "exit=$?"
echo "-- last verbose lines before the crash:"
tail -12 c.stdout 2>/dev/null | sed 's/^/   /'
echo "-- crash summary:"
grep -m3 -E "Assertion|Segmentation|error:" c.log | sed 's/^/   /'
