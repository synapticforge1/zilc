#!/bin/sh
# Summarise size-compare.sh's CSV: medians and totals per language and flavour, build
# failures, and how zilc's runs compare with the plain ReleaseSafe runs.
#   wsl.exe -e sh /mnt/d/…/zilc/tools/basics/size-report.sh
CSV=${1:-$HOME/zilc-work/basics-size/sizes.csv}
for L in c zig; do
  echo "== $L"
  # columns: 3 zig_small 4 zig_safe 5 zilc_safe 6 zilc_small 7..10 stripped, 11 run_zig_safe 12 run_zilc
  for col in 3:zig_small 4:zig_safe 5:zilc_safe 6:zilc_small 7:zig_small_stripped 8:zig_safe_stripped 9:zilc_safe_stripped 10:zilc_small_stripped; do
    c=${col%%:*}; name=${col#*:}
    awk -F, -v L="$L" -v c="$c" '$1==L && $c!="NA" {print $c}' "$CSV" | sort -n > /tmp/col.$$
    n=$(wc -l < /tmp/col.$$)
    [ "$n" -eq 0 ] && { printf '  %-22s (none built)\n' "$name"; continue; }
    med=$(awk -v n="$n" 'NR==int((n+1)/2){print}' /tmp/col.$$)
    min=$(head -1 /tmp/col.$$); max=$(tail -1 /tmp/col.$$)
    sum=$(awk '{s+=$1} END{print s}' /tmp/col.$$)
    printf '  %-22s built %3d  median %9d  min %9d  max %9d  total %11d\n' "$name" "$n" "$med" "$min" "$max" "$sum"
  done
  echo "  -- runs: plain ReleaseSafe vs zilc (exit code, 133 = Fil-C trap, NA = zilc build failed)"
  awk -F, -v L="$L" '$1==L {k=($11==$12)?"same":"DIFF"; print k}' "$CSV" | sort | uniq -c | sed 's/^/    /'
  awk -F, -v L="$L" '$1==L && $11!=$12 {printf "    %-40s zig=%-8s zilc=%s\n", $2, $11, $12}' "$CSV"
done
rm -f /tmp/col.$$
