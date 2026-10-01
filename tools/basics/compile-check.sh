#!/bin/sh
# Compile-check every tests/basics example for zilc's target (x86_64-linux-musl)
# with PLAIN Zig 0.15.2 and -lc (libc linked, as zilc builds): no Fil-C involved. It tells "does this example build at all"
# apart from "does it survive zilc", which is a later question.
#
# Run from Git Bash on Windows (default paths) or anywhere with ZIG set:
#   sh tools/basics/compile-check.sh
# Writes one line per example to zig-out/basics-compile.txt and prints a summary.
Z=${ZIG:-/c/zig/0.15.2/zig.exe}
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
T=$ROOT/tests/basics
mkdir -p "$ROOT/zig-out"
OUT=$ROOT/zig-out/basics-compile.txt
BIN=$ROOT/zig-out/basics-check
: > "$OUT"
for f in "$T"/${ZIGDIR:-zig-0.15.2}/*/*.zig; do
  if err=$("$Z" build-exe -fno-emit-bin -lc -target x86_64-linux-musl "$f" 2>&1); then r=ok; else r="FAIL $(echo "$err" | grep -m1 'error:' | sed 's/.*error: //')"; fi
  echo "zig $(basename "$(dirname "$f")") $r" >> "$OUT"
done
# Full compile AND link with -lc, as the examples' own repo builds them (`zig cc -lc`). Default C
# dialect: -std=c99
# hides POSIX declarations under musl and fails for the wrong reason.
for f in "$T"/c/*/*.c; do
  if err=$("$Z" cc -lc -target x86_64-linux-musl -o "$BIN" "$f" 2>&1); then r=ok; else r="FAIL $(echo "$err" | grep -m1 'error:' | sed 's/.*error: //')"; fi
  echo "c $(basename "$(dirname "$f")") $r" >> "$OUT"
done
rm -f "$BIN"
echo "zig ok: $(grep -c '^zig .* ok$' "$OUT") / $(grep -c '^zig ' "$OUT")"
echo "c   ok: $(grep -c '^c .* ok$' "$OUT") / $(grep -c '^c ' "$OUT")"
echo "-- failure reasons:"; grep 'FAIL' "$OUT" | sed 's/^\([a-z]*\) [^ ]* FAIL /\1: /' | sort | uniq -c | sort -rn
