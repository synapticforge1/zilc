#!/bin/sh
# KI-16: run the tests/basics corpus through zilc in every optimise mode and summarise.
# C inputs ignore -O (they go straight to Fil-C's clang), so only Zig differs by mode.
#   wsl.exe -e sh /mnt/d/…/zilc/tools/basics/all-modes.sh [modes…]
D=$(dirname "$0")
MODES=${*:-"Debug ReleaseSafe ReleaseFast ReleaseSmall"}
for m in $MODES; do
  MODE=$m JOBS=${JOBS:-8} bash "$D/zilc-check.sh" zig > "$HOME/zilc-work/all-modes-$m.txt" 2>&1 &
done
wait
for m in $MODES; do
  echo "################ $m"
  grep -v 'Trace/breakpoint\|^Aborted' "$HOME/zilc-work/all-modes-$m.txt" | tail -15
done
