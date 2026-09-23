#!/bin/sh
# P1 step 2: record Fil-C's reference behavior on the zilc bug examples.
WORK="$HOME/zilc-work"
FILC="$WORK/tools/filc-0.685-linux-x86_64/build/bin/clang"
REPO="<repo-root>"
OUT="$WORK/p1"
mkdir -p "$OUT"

echo "== filcc version"
"$FILC" --version | head -2

echo
echo "== sanity: hello world"
printf '#include <stdio.h>\nint main(void){printf("hello from Fil-C\\n");return 0;}\n' > "$OUT/hello.c"
"$FILC" -O2 -g -o "$OUT/hello" "$OUT/hello.c" && "$OUT/hello"
echo "exit=$?"

for name in oob_write use_after_free; do
  echo
  echo "======================================================================"
  echo "== $name"
  echo "======================================================================"
  if "$FILC" -O2 -g -o "$OUT/$name" "$REPO/examples/$name.c" 2>"$OUT/$name.build.log"; then
    echo "-- compiled"
  else
    echo "-- COMPILE FAILED"
    cat "$OUT/$name.build.log"
    continue
  fi
  "$OUT/$name" > "$OUT/$name.out" 2>&1
  code=$?
  echo "-- exit=$code"
  echo "-- output:"
  cat "$OUT/$name.out"
done
