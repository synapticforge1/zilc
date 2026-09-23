#!/bin/sh
# Debug mode through the zilc driver: it should apply the -O0 + -fno-stack-check
# concessions itself and still trap correctly (cmem/known-issues.md KI-4).
WORK="$HOME/zilc-work"
REPO=<repo-root>
ZILC="$REPO/zig-out/bin/zilc"

export ZILC_ZIG="$WORK/tools/zig-0.15.2/zig"
export ZILC_FILC="$WORK/tools/filc-0.685-linux-x86_64/build/bin/clang"

mkdir -p "$WORK/drive-debug"
cd "$WORK/drive-debug"
cp "$REPO/examples/interop/c_caller.c" "$REPO/examples/interop/bounds.zig" .

for mode in Debug ReleaseSafe; do
  echo "=================================================================="
  echo "== -O $mode"
  echo "=================================================================="
  "$ZILC" build c_caller.c bounds.zig -O "$mode" -o "interop-$mode"
  echo "build exit=$?"
  # Capture first, THEN print: `prog | sed` would report sed's status, not the
  # program's, and the exit code is half of what this test asserts.
  "./interop-$mode" > "run-$mode.log" 2>&1
  echo "   run exit=$?  (expect 133)"
  sed 's/^/   /' "run-$mode.log"
  ls -l "interop-$mode" | awk '{print "   binary:", $5, "bytes"}'
  echo
done
