#!/bin/sh
# The GC protocol, observed (filc-abi.md §5b): where pass-compiled code polls for GC work,
# and how the runtime exits/enters around a blocking system call.
#   wsl.exe -e sh /mnt/d/…/zilc/tools/p3/gc-probe.sh
F=$HOME/zilc-work/tools/filc-0.685-linux-x86_64
CC=$F/build/bin/clang
L=$F/pizfix/lib
S=$(dirname "$0")
T=$(mktemp -d)
$CC -O1 -S -emit-llvm -o $T/g.ll $S/gc-probe.c || exit 1

echo "== 1. pollcheck in spin(): runtime calls and thread-relative loads inside the loop"
awk '/^define .*pizlonatedFIP[0-9]*_spin/,/^}/' $T/g.ll | grep -nE 'call .*@filc_|getelementptr i8, ptr %0, i64|load .*%filc_thread|pollcheck|br i1' | head -20
echo "-- runtime functions the module declares:"
grep -oE '^declare [^@]*@filc_[a-z_]+' $T/g.ll | sed 's/.*@//' | sort -u

echo "== 2. runtime exports about safepoints"
nm -D --defined-only $L/libpizlo.so | awk '{print $3}' | grep -iE 'pollcheck|handshake|safepoint|^filc_(enter|exit)|_enter$|_exit$|stop_the_world|soft' | sort | head -30

echo "== 3. does the runtime's read() wrapper exit/enter? calls made by filc_native_zsys_read"
objdump -d --no-show-raw-insn $L/libpizlo.so --disassemble=filc_native_zsys_read 2>/dev/null | grep -E 'call' | sed 's/.*call *//' | head -20

echo "== 4. thread offsets: what filc_pollcheck-ish exports read from the thread"
for s in $(nm -D --defined-only $L/libpizlo.so | awk '{print $3}' | grep -iE '^filc_pollcheck' | head -3); do
  echo "-- $s"; objdump -d --no-show-raw-insn $L/libpizlo.so --disassemble=$s 2>/dev/null | sed -n '7,22p'
done
rm -rf $T
