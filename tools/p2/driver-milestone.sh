#!/bin/sh
# Run the milestone through the zilc DRIVER instead of hand-run commands.
WORK="$HOME/zilc-work"
REPO=<repo-root>
ZILC="$REPO/zig-out/bin/zilc"

export ZILC_ZIG="$WORK/tools/zig-0.15.2/zig"
export ZILC_FILC="$WORK/tools/filc-0.685-linux-x86_64/build/bin/clang"

mkdir -p "$WORK/drive"
cd "$WORK/drive"
cp "$REPO/examples/interop/c_caller.c" "$REPO/examples/interop/bounds.zig" .

echo "== zilc --version"
"$ZILC" --version

echo
echo "== zilc build (the whole pipeline in one command)"
"$ZILC" build c_caller.c bounds.zig -o interop -v
echo "build exit=$?"

echo
echo "== run it"
./interop
echo "run exit=$?"

echo
echo "== guardrail: Debug must be refused, not crash the pass"
"$ZILC" build bounds.zig -O Debug -o dbg 2>&1 | head -5
