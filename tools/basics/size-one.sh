#!/bin/sh
# One example, every build flavour: prints a CSV row. Called by size-compare.sh.
#   $1 = lang (c|zig)   $2 = source file   $3 = output dir
L=$1; f=$2; OUT=$3
n=$(basename "$(dirname "$f")")
B=$OUT/bin/$L/$n
mkdir -p "$B"

size() { if [ -f "$1" ]; then stat -c %s "$1"; else echo NA; fi; }
stripped() { if [ -f "$1" ]; then strip -o "$1.s" "$1" 2>/dev/null && stat -c %s "$1.s" || echo NA; else echo NA; fi; }
runrc() {
  [ -f "$1" ] || { echo NA; return; }
  mkdir -p "$B/cwd/tmp"; printf 'hello\nzig\n' > "$B/cwd/tmp/dat.txt"
  (cd "$B/cwd" && printf 'hello\nfilter\n' | timeout 15 "$1" > "$1.out" 2>&1)
  rc=$?; [ $rc -eq 124 ] && echo TIMEOUT || echo $rc
}

# Plain Zig: build-exe handles .c and .zig alike, so C gets the same optimize modes.
for m in ReleaseSmall ReleaseSafe; do
  "$ZILC_ZIG" build-exe -O $m -lc -target x86_64-linux-musl -femit-bin="$B/$m" "$f" > "$B/$m.log" 2>&1
done
# zilc (Fil-C runtime). Zig inputs take -O; C inputs go straight to Fil-C's clang (-O1 -g).
if [ "$L" = zig ]; then
  "$ZILC" build -O ReleaseSafe  -o "$B/zilcSafe"  "$f" > "$B/zilcSafe.log" 2>&1
  "$ZILC" build -O ReleaseSmall -o "$B/zilcSmall" "$f" > "$B/zilcSmall.log" 2>&1
else
  "$ZILC" build -o "$B/zilcSafe" "$f" > "$B/zilcSafe.log" 2>&1
fi

echo "$L,$n,$(size "$B/ReleaseSmall"),$(size "$B/ReleaseSafe"),$(size "$B/zilcSafe"),$(size "$B/zilcSmall"),$(stripped "$B/ReleaseSmall"),$(stripped "$B/ReleaseSafe"),$(stripped "$B/zilcSafe"),$(stripped "$B/zilcSmall"),$(runrc "$B/ReleaseSafe"),$(runrc "$B/zilcSafe")"
