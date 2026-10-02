#!/bin/sh
# Monitor Fil-C upstream for changes that matter to zilc (cmem/upstream.md "The upstream/
# reference folder"). Fetches upstream/fil-c, then reports, relative to the last REVIEWED commit:
# new commits, new release tags, commits touching the files zilc patches or depends on, and
# whether zilc's patches still apply to upstream's newest FilPizlonator.cpp and llvm-split.cpp.
# Run from Git Bash on Windows.
#
#   sh tools/upstream/check-upstream.sh                 report only
#   sh tools/upstream/check-upstream.sh --mark-reviewed after reviewing: record upstream HEAD
#
# ⚠️ Every git command names its repo with -C and an absolute path (see clone-upstream.sh).
set -e
REPO=$(cd "$(dirname "$0")/../.." && pwd)
U=$REPO/upstream/fil-c
REV_FILE=$REPO/tools/upstream/REVIEWED
[ -d "$U/.git" ] || { echo "no upstream clone; run tools/upstream/clone-upstream.sh"; exit 1; }

# Files whose changes zilc must look at, and why.
WATCH="
llvm/lib/Transforms/Instrumentation/FilPizlonator.cpp   zilc patches it (KI-4, KI-22) and works around it (KI-18)
llvm/include/llvm/Transforms/Instrumentation            the pass's interface
llvm/lib/CodeGen/IndirectBrExpandPass.cpp               the code KI-4's broken lowering was copied from
llvm/tools/llvm-split/llvm-split.cpp                    zilc patches it (KI-22 lever a, parallel code generation)
llvm/lib/Transforms/Utils/SplitModule.cpp               the stock split zilc's mode replaces (use-list order)
configure_llvm.sh                                       tools/filc/build-patched-clang.sh mirrors it
libpas/common.sh                                        the build's architecture settings
filc/include                                            the runtime's public ABI (filc-abi.md)
invisicap.txt                                           design docs zilc's notes rely on
gimso_semantics.md
versioning-checklist.md                                 how releases are cut
"

git -C "$U" fetch -q origin deluge --tags
REVIEWED=$(cut -d' ' -f1 "$REV_FILE")
HEAD=$(git -C "$U" rev-parse origin/deluge)
git -C "$U" checkout -q --detach "$HEAD"

echo "upstream deluge: $(git -C "$U" log -1 --format='%h %ad %s' --date=short "$HEAD")"
echo "last reviewed:   $(git -C "$U" log -1 --format='%h %ad %s' --date=short "$REVIEWED") ($(cut -d' ' -f2- "$REV_FILE"))"
N=$(git -C "$U" rev-list --count "$REVIEWED..$HEAD")
echo "new commits since reviewed: $N"

echo "--- release tags newer than the reviewed commit"
git -C "$U" tag --contains "$REVIEWED" --sort=creatordate 'v*' | grep -v "^$(git -C "$U" describe --tags --exact-match "$REVIEWED" 2>/dev/null)$" || echo "  (none)"

echo "--- new commits touching watched files"
hit=0
echo "$WATCH" | while read -r path why; do
  [ -n "$path" ] || continue
  c=$(git -C "$U" rev-list --count "$REVIEWED..$HEAD" -- "$path")
  if [ "$c" != 0 ]; then
    echo "  $c  $path   ($why)"
    git -C "$U" log --format='       %h %ad %s' --date=short "$REVIEWED..$HEAD" -- "$path" | head -5
  fi
done

echo "--- does zilc's pass patch still apply to upstream's newest FilPizlonator.cpp?"
deno run --allow-read "$REPO/tools/filc/patch-pass.ts" --check \
  "$U/llvm/lib/Transforms/Instrumentation/FilPizlonator.cpp" && echo "  yes, every edit" || echo "  ⚠️ NO: re-derive the edits marked above before the next Fil-C upgrade"
echo "--- does zilc's llvm-split patch still apply to upstream's newest llvm-split.cpp?"
deno run --allow-read "$REPO/tools/filc/patch-split.ts" --check \
  "$U/llvm/tools/llvm-split/llvm-split.cpp" && echo "  yes, every edit" || echo "  ⚠️ NO: re-derive the edits marked above before the next Fil-C upgrade"

if [ "$1" = "--mark-reviewed" ]; then
  echo "$HEAD $(git -C "$U" describe --tags --always "$HEAD") $(date +%Y-%m-%d) reviewed" > "$REV_FILE"
  echo "recorded $HEAD as reviewed in tools/upstream/REVIEWED (commit it)"
fi
