#!/bin/sh
# Group why zilc-built tests/basics programs fail: runtime traps by the Fil-C fault and the
# source location it names, and build failures by their first error line.
#   wsl.exe -e sh /mnt/d/…/zilc/tools/basics/zilc-failures.sh
B=${1:-$HOME/zilc-work/basics-size/bin}
echo "== runtime traps (zilcSafe): fault + semantic origin"
for o in "$B"/*/*/zilcSafe.out; do
  grep -q 'filc safety error\|filc panic' "$o" 2>/dev/null || continue
  n=$(basename "$(dirname "$o")")
  fault=$(grep -m1 'filc safety error\|filc panic' "$o" | sed 's/.*filc safety error: //; s/^\[[0-9]*\] //')
  origin=$(grep -A1 -m1 'semantic origin' "$o" | tail -1 | sed 's/^ *//; s/([^)]*) //')
  echo "$fault | $origin | $n"
done | sort | awk -F' \\| ' '{k=$1" | "$2; c[k]++; ex[k]=ex[k]" "$3} END{for(k in c) printf "%3d  %s\n       e.g.%s\n", c[k], k, substr(ex[k],1,120)}' | sort -rn
echo
echo "== build failures (zilcSafe): first error"
for g in "$B"/zig/*/zilcSafe.log; do
  d=$(dirname "$g"); [ -f "$d/zilcSafe" ] && continue
  n=$(basename "$d")
  e=$(grep -m1 -iE 'error|undefined|assert|segmentation|stack dump' "$g" | sed 's/^.*error: //' | cut -c1-110)
  echo "$e | $n"
done | awk -F' \\| ' '{c[$1]++; ex[$1]=ex[$1]" "$2} END{for(k in c) printf "%3d  %s\n       e.g.%s\n", c[k], k, substr(ex[k],1,120)}' | sort -rn
echo
echo "== the one zilcSmall build failure"
for g in "$B"/zig/*/zilcSmall.log; do d=$(dirname "$g"); [ -f "$d/zilcSmall" ] || { echo "$(basename "$d"): $(grep -m1 -iE 'error|undefined|assert' "$g" | cut -c1-140)"; }; done
