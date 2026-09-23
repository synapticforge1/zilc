#!/bin/sh
# KI-5: a whole Zig program through the zilc driver, with no C file.
WORK="$HOME/zilc-work"
REPO=<repo-root>
ZILC="$REPO/zig-out/bin/zilc"

export ZILC_ZIG="$WORK/tools/zig-0.15.2/zig"
export ZILC_FILC="$WORK/tools/filc-0.685-linux-x86_64/build/bin/clang"

mkdir -p "$WORK/drive-whole"
cd "$WORK/drive-whole"
cp "$REPO/examples/whole_program/hello.zig" .

echo "== zilc build hello.zig   (entry shim chosen automatically)"
"$ZILC" build hello.zig -o hello -v 2>&1 | grep -E "^\+|error" | sed 's/^/   /'
echo "   build exit=$?"

echo
echo "== run"
./hello > run.log 2>&1
echo "   exit=$?  (expect 133)"
sed 's/^/   /' run.log

echo
echo "== the entry shim zilc generated"
sed -n '1,12p' hello.zilc-tmp/zilc_entry.zig 2>/dev/null | sed 's/^/   /' || echo "   (temps removed; re-run with --keep-temps to see it)"
