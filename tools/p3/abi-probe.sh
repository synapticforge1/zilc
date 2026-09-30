F=$HOME/zilc-work/tools/filc-0.685-linux-x86_64
CC=$F/build/bin/clang
L=$F/pizfix/lib
I=$F/pizfix/stdfil-include
S=$(dirname "$0")
T=$(mktemp -d)

echo "== (a1) post-pass IR: how pass-compiled main is defined and how it calls write"
$CC -O1 -S -emit-llvm -o $T/w.ll $S/write1.c 2>&1 | head -3
grep -nE '^define|^declare' $T/w.ll | head -20
echo "-- call sites:"; grep -nE 'call .*@(pizlonated_|filc_)' $T/w.ll | head -12

echo "== (a2) how checked musl's write() reaches the runtime"
cd $T && ar x $L/libc.a write.o 2>/dev/null; ls write.o 2>/dev/null && nm write.o
objdump -d --no-show-raw-insn write.o 2>/dev/null | head -60

echo "== (a3) the header's view of zsys_write and the Fil-C calling-convention bits"
grep -n 'zsys_write\b\|zsys_write(' $I/pizlonated_syscalls.h
grep -n -i 'calling convention\|filc_cc\|cc_args\|cc_rets' $I/*.h | head -20

echo "== (a4) the runtime's own pizlonated_zsys_write: first instructions"
objdump -d --no-show-raw-insn $L/libpizlo.so --disassemble=pizlonated_zsys_write 2>/dev/null | sed -n '1,45p'

echo "== (b1) the link: what filc clang actually links, and how"
cd $T && $CC -O1 -o w $S/write1.c -v 2>&1 | grep -E 'ld(\.lld)?"? ' | tr ' ' '\n' | grep -E '\.(so|a|o)$|^-l|^-L|dynamic-linker|^-rpath|whole-archive|Bstatic|Bdynamic' | head -30
echo "-- NEEDED / interpreter:"; readelf -d w | grep -E 'NEEDED|RPATH|RUNPATH'; readelf -l w | grep -i interpreter
./w; echo "exit $?"

echo "== (b2) who defines pizlonated_zsys_write, and is it preemptible (default visibility, dynamic)?"
readelf -W --dyn-syms $L/libpizlo.so | grep -E ' pizlonated_zsys_write$'
readelf -W --dyn-syms $L/libc.so | grep -E ' pizlonated_zsys_write$'
echo "-- libpizlo DT_FLAGS (SYMBOLIC would defeat interposition):"; readelf -d $L/libpizlo.so | grep -E 'FLAGS|SYMBOLIC'
echo "-- libc.so DT_FLAGS:"; readelf -d $L/libc.so | grep -E 'FLAGS|SYMBOLIC|NEEDED'
rm -rf $T
