#!/bin/sh
# Re-point a Fil-C tree's pizfix/os-include links at this machine's Linux kernel headers, by the
# same rule as Fil-C's own setup.sh (asm: /usr/include/x86_64-linux-gnu/asm if it exists, else
# /usr/include/asm; plus linux and asm-generic).
#
#   sh tools/filc/fix-os-include.sh <fil-c tree>      (the folder holding pizfix/)
#
# Why (found 2026-10-05 by Fil-C's own test suite, tools/filc/run-filc-tests.ts): setup.sh makes
# these links ONCE, when the prebuilt is unpacked. Here it ran before build-essential (and with it
# the kernel headers) was installed, so `asm` pointed at /usr/include/asm, which does not exist on
# Ubuntu. Every program including <linux/futex.h>, <linux/seccomp.h> or anything else reaching
# <asm/types.h> failed to compile ("'asm/types.h' file not found"): 9 of Fil-C's tests, and any
# Zig or C program through zilc that uses those headers. zilc's patched tree is a copy of the
# prebuilt, so it carried the same broken link, and so does the archive in toolchain/.
set -e
T=${1:?usage: fix-os-include.sh <fil-c tree>}
D=$T/pizfix/os-include
mkdir -p "$D"
if test -d /usr/include/x86_64-linux-gnu/asm; then A=/usr/include/x86_64-linux-gnu/asm; else A=/usr/include/asm; fi
ln -sfn "$A" "$D/asm"
ln -sfn /usr/include/linux "$D/linux"
ln -sfn /usr/include/asm-generic "$D/asm-generic"
for l in asm linux asm-generic; do
  if [ -e "$D/$l/." ]; then echo "  os-include/$l -> $(readlink "$D/$l")"; else echo "  os-include/$l -> $(readlink "$D/$l")  MISSING on this machine (install linux-libc-dev)"; fi
done
