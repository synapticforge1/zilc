#!/bin/sh
# Stock-LLVM acceptance test, via Zig's bundled clang (stock LLVM 21).
WORK="$HOME/zilc-work"
ZIG="$WORK/tools/zig-0.15.2/zig"
OUT="$WORK/p1"
cd "$OUT"

try() {
  printf '%-58s' "$1"
  if "$ZIG" cc -c "$2" -o /tmp/t.o 2>"$2.stock.log"; then
    echo "ACCEPTED"
  else
    echo "REJECTED"
    grep -m2 -E "error" "$2.stock.log" | sed 's/^/      /'
  fi
}

try "1. Fil-C's emitted IR, unmodified"                dl.ll
try "2. ... with only the datalayout_after_filc line removed" dl-stripped.ll
try "3. a module whose datalayout has ni:0"            ni0.ll
try "4. control: same module, no ni"                   plain.ll
try "5. ni on a NON-zero address space (ni:1)"         ni1.ll

echo
echo "== does the stripped Fil-C module still behave like normal IR? (symbols)"
head -3 dl-stripped.ll
grep -c pizlonated_ dl-stripped.ll
