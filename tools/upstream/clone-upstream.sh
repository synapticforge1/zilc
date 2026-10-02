#!/bin/sh
# Create upstream/fil-c: a gitignored, read-only reference clone of Fil-C's `deluge` branch
# (cmem/upstream.md "The upstream/ reference folder"; the pattern of binaryen-ts's upstream/).
# Partial (no file contents beyond the checked-out paths), shallow (history from v0.684 on) and
# sparse (only what zilc references), so it stays small. Run from Git Bash on Windows.
#
#   sh tools/upstream/clone-upstream.sh
#
# ⚠️ Every git command names its repo with -C and an absolute path. A partial-clone fetch run in
# the wrong directory once rewrote zilc's own .git/config (2026-10-01).
set -e
REPO=$(cd "$(dirname "$0")/../.." && pwd)
U=$REPO/upstream/fil-c
URL=https://github.com/pizlonator/fil-c.git
# filc/tests (15,603 small files) is left out: on exFAT each file takes a whole cluster (3.9 GB).
# llvm/tools/llvm-split: zilc patches it (KI-22 lever a), and check-upstream.sh checks that patch.
PATHS="llvm/lib/Transforms/Instrumentation llvm/include/llvm/Transforms/Instrumentation llvm/lib/CodeGen llvm/tools/llvm-split libpas filc/include filc/src filc/main filc/benchmarks filc/manualtests"

if [ -e "$U" ]; then echo "$U exists; delete it first to re-clone"; exit 1; fi
mkdir -p "$REPO/upstream"
# core.autocrlf=false: keep upstream's exact bytes (LF). The global Windows setting (true) checked
# files out with CRLF, which broke patch-pass.ts's exact-match check and any diff against the
# WSL build tree (2026-10-01).
git -c core.longpaths=true -c core.autocrlf=false clone --no-checkout --filter=blob:none \
  --sparse --branch deluge --shallow-exclude=v0.684 "$URL" "$U"
git -C "$U" config core.autocrlf false
git -C "$U" config core.longpaths true
# Fil-C's tree bundles projects (Linux headers, systemd tests) with paths Windows forbids
# (`aux.h`, `:` and `\` in names). Git for Windows refuses to INDEX them; they are all outside the
# sparse paths, so nothing illegal is ever written. Local to this clone only.
git -C "$U" config core.protectNTFS false
git -C "$U" sparse-checkout set $PATHS
git -C "$U" checkout -q deluge
git -C "$U" fetch -q origin "+refs/tags/v0.685:refs/tags/v0.685"
echo "upstream/fil-c at $(git -C "$U" log -1 --format='%h %ad %s' --date=short)"
echo "v0.685 = $(git -C "$U" rev-parse --short v0.685)"
echo "⚠️ exFAT drive: also run once:"
echo "   git config --global --add safe.directory $U"
