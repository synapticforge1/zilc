#!/bin/sh
# Run syscall-probe.c under Fil-C, one case per process so a trap names its case.
#   wsl.exe -e sh /mnt/d/…/zilc/tools/p3/syscall-probe.sh
F=$HOME/zilc-work/tools/filc-0.685-linux-x86_64
S=$(dirname "$0")
T=$(mktemp -d)
echo "== who exports syscall"
nm -D --defined-only $F/pizfix/lib/libc.so | grep -wE 'syscall|gettid'
nm -D --defined-only $F/pizfix/lib/libpizlo.so | grep -iE 'zsys_(syscall|gettid|clock_nanosleep|futex[a-z_]*)$|^[0-9a-f]+ T pizlonated_zsys_[a-z_]*futex'
$F/build/bin/clang -O1 -g -o $T/probe $S/syscall-probe.c || exit 1
for c in gettid futex-ptr futex-err nanosleep futex-int; do
  echo "== $c"; $T/probe $c 2>&1 | grep -v '^    ' | head -4; echo "   exit $?"
done
rm -rf $T
