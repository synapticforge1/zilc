F=$HOME/zilc-work/tools/filc-0.685-linux-x86_64
CC=$F/build/bin/clang
I=$F/pizfix/stdfil-include
S=$(dirname "$0")
T=$(mktemp -d)
$CC -O1 -S -emit-llvm -o $T/w.ll $S/write1.c 2>/dev/null
echo "== types"; grep -nE '^%(filc|pizlonated)' $T/w.ll
echo "== IR, main through the write wrapper"; sed -n '36,200p' $T/w.ll | grep -v '^!' | grep -v '^$' | head -150
echo "== runtime header"; cat $I/pizlonated_runtime.h | grep -v '^ *$' | head -100
echo "== stdfil.h: object / capability / function-object vocabulary"
grep -n -iE 'struct filc_|filc_object|flight|lower|upper|aux|function.?object|zgetlower|zgetupper' $I/stdfil.h | head -40
rm -rf $T
