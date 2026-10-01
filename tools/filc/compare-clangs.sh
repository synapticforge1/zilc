#!/bin/sh
# Prove the patched Fil-C clang emits BYTE-IDENTICAL objects to the 0.685 prebuilt, and time both
# (KI-22, cmem/workarounds.md). Every input is compiled by both; objects are compared with cmp.
#
#   wsl.exe -e sh /mnt/d/…/zilc/tools/filc/compare-clangs.sh [extra .ll/.c files…]
#
# Default inputs: whatever IR is lying around from earlier measurements (KEEP the list explicit,
# so a reader can rerun it), the gate's C examples, and zilc's syscall helper.
#
# ⚠️ Two rules learned 2026-10-01, or the comparison means nothing:
#  1. ASLR OFF (`setarch -R`). Fil-C's pass iterates hash tables keyed by pointer addresses, so
#     the SAME prebuilt clang on the SAME input gives different objects run to run with ASLR on.
#  2. Both binaries run from the SAME directory. Clang finds its headers relative to itself, and
#     the include paths land in the debug info.
W=$HOME/zilc-work
REPO=$(cd "$(dirname "$0")/../.." && pwd)
T=$W/tools/filc-0.685-zilc/build/bin
cp -f $W/tools/filc-0.685-linux-x86_64/build/bin/clang-20 $T/clang-prebuilt
A=${A:-$T/clang-prebuilt}
B=${B:-$T/clang-20}
D=$W/perf/compare; rm -rf $D; mkdir -p $D

one() { # name file opt
  name=$1; f=$2; O=$3
  case $f in *.c) extra="" ;; *) extra="-Wno-override-module" ;; esac
  for side in A B; do
    cl=$A; [ $side = B ] && cl=$B
    s=$(date +%s.%N)
    setarch -R $cl $O -g $extra -c -o $D/$name.$side.o $f > $D/$name.$side.log 2>&1; echo $? > $D/$name.$side.rc
    e=$(date +%s.%N); echo "$e - $s" | bc > $D/$name.$side.t
  done
  ra=$(cat $D/$name.A.rc); rb=$(cat $D/$name.B.rc)
  if [ "$ra" != 0 ] || [ "$rb" != 0 ]; then
    if [ "$ra" = "$rb" ] && grep -q "Assertion" $D/$name.A.log && grep -q "Assertion" $D/$name.B.log; then verdict="both assert (same)"
    else verdict="EXIT DIFFERS ($ra vs $rb)"; fi
  elif cmp -s $D/$name.A.o $D/$name.B.o; then verdict="IDENTICAL ($(stat -c %s $D/$name.A.o) bytes)"
  else verdict="DIFFERENT"; fi
  printf '%-30s %-4s prebuilt %7.1fs  patched %7.1fs  %s\n' $name "$O" $(cat $D/$name.A.t) $(cat $D/$name.B.t) "$verdict"
}

P62=$W/perf/v2-62_directories-ReleaseSafe/prog.zilc-tmp/directories.filc.ll
P69=$(ls $W/perf/v2-69_http-client-ReleaseSafe/prog.zilc-tmp/http-client.filc.ll 2>/dev/null)
one ki18-repro $REPO/tools/p2/repro/filc-0.685-i21-global.ll -O1 &
for c in $REPO/examples/*.c; do one "c-$(basename $c .c)" $c -O1 & done
one zilc_syscall $W/perf/v2-62_directories-ReleaseSafe/prog.zilc-tmp/zilc_syscall.c -O1 &
one allocas2000-O1 $W/perf/scale2/allocas-2000-O1.ll -O1 &
one allocas2000-O0 $W/perf/scale2/allocas-2000-O0.ll -O0 &
one 62-O1 $P62 -O1 &
one 62-O0 $P62 -O0 &
[ -n "$P69" ] && one 69-O1 $P69 -O1 &
for f in "$@"; do one "x-$(basename $f)" $f -O1 & done
wait
