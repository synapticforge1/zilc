// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Re-point a Fil-C tree's pizfix/os-include links at this machine's Linux kernel headers, by the
// same rule as Fil-C's own setup.sh (asm: /usr/include/x86_64-linux-gnu/asm if it exists, else
// /usr/include/asm; plus linux and asm-generic). Linux; from Windows it runs inside WSL.
//
//   deno run -A tools/filc/fix-os-include.ts <fil-c tree>      (the folder holding pizfix/)
//
// Why (found 2026-10-05 by Fil-C's own test suite, tools/filc/run-filc-tests.ts): setup.sh makes
// these links ONCE, when the prebuilt is unpacked. Here it ran before build-essential (and with it
// the kernel headers) was installed, so `asm` pointed at /usr/include/asm, which does not exist on
// Ubuntu. Every program including <linux/futex.h>, <linux/seccomp.h> or anything else reaching
// <asm/types.h> failed to compile ("'asm/types.h' file not found"): 9 of Fil-C's tests, and any
// Zig or C program through zilc that uses those headers. zilc's patched tree is a copy of the
// prebuilt, so it carried the same broken link, and so does the archive in toolchain/.
import { exists, existsSync, linuxOnly, mkdirp } from "../lib/tool.ts";

/** Exported for build-patched-clang.ts and restore-patched-clang.ts. */
export async function fixOsInclude(tree: string): Promise<void> {
  const dir = `${tree}/pizfix/os-include`;
  await mkdirp(dir);
  const asm = existsSync("/usr/include/x86_64-linux-gnu/asm") ? "/usr/include/x86_64-linux-gnu/asm" : "/usr/include/asm";
  for (const [name, target] of [["asm", asm], ["linux", "/usr/include/linux"], ["asm-generic", "/usr/include/asm-generic"]]) {
    await Deno.remove(`${dir}/${name}`).catch(() => {}); // ln -sfn
    await Deno.symlink(target, `${dir}/${name}`);
    const ok = await exists(`${dir}/${name}/.`);
    console.log(`  os-include/${name} -> ${target}${ok ? "" : "  MISSING on this machine (install linux-libc-dev)"}`);
  }
}

// The bridge only when run directly: an importing tool has bridged already, and a top-level call
// here would run during the import, before the importer, and re-launch the wrong script.
if (import.meta.main) {
  await linuxOnly(import.meta);
  const tree = Deno.args[0];
  if (!tree) {
    console.error("usage: fix-os-include.ts <fil-c tree>");
    Deno.exit(2);
  }
  await fixOsInclude(tree);
}
