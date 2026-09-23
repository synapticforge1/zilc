#!/bin/sh
# Run `zig build gate` inside WSL, where Fil-C lives.
#
#   wsl.exe -e sh /mnt/d/.../zilc/tools/run-gate-wsl.sh
#
# The Zig cache goes to the WSL home on purpose: the repo is on an exFAT drive
# and a cache there is poisoned after one build (cmem/known-issues.md KI-2).
WORK="$HOME/zilc-work"
REPO=<repo-root>

export ZILC_ZIG="$WORK/tools/zig-0.15.2/zig"
export ZILC_FILC="$WORK/tools/filc-0.685-linux-x86_64/build/bin/clang"
export ZIG_LOCAL_CACHE_DIR="$HOME/.cache/zilc-zig"

exec "$ZILC_ZIG" build --build-file "$REPO/build.zig" gate "$@"
