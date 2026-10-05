// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Is the project's toolchain/ archive up to date with the patched Fil-C clang in Linux, and is the
// installed tree healthy? Run on every "update the project memory" (cmem/INDEX.md policy, owner
// 2026-10-01). Linux; from Windows it runs inside WSL.
//
//   deno run -A tools/filc/check-toolchain.ts
//
// Exit 0 = up to date. Exit 1 = stale or broken; the message names the step to run.
import { exists, FILC_PATCHED_TREE, linuxOnly, REPO, run, WORK } from "../lib/tool.ts";

await linuxOnly(import.meta);
const src = `${WORK}/filc-src/repo`;
const patch = `${REPO}/third_party/filc-patches/zilc-filc-pass.patch`;
const sums = `${REPO}/toolchain/SHA256SUMS`;
const tar = `${REPO}/toolchain/filc-0.685-zilc-linux-x86_64.tar.xz`;
const bin = `${FILC_PATCHED_TREE}/build/bin/clang-20`;
let stale = false;

// 1. Edits in the Linux Fil-C source that are not saved into the repo's patch file.
if (await exists(`${src}/.git`)) {
  const diff = (await run(["git", "-C", src, "diff"])).out;
  const saved = await Deno.readTextFile(patch).catch(() => "");
  if (diff !== saved) {
    console.log(`STALE: the Linux Fil-C source differs from ${patch}.`);
    console.log("       Put the change in tools/filc/patch-pass.ts or patch-split.ts (the edit scripts are the");
    console.log("       source of truth), rebuild (build-patched-clang.ts), then save the diff:");
    console.log(`       git -C ${src} diff > third_party/filc-patches/zilc-filc-pass.patch`);
    stale = true;
  }
} else {
  console.log(`note: no Linux Fil-C source at ${src} (restored-only machine); skipping check 1`);
}

// 2. The repo's patch is not the one the archive was built from.
const sha256 = async (p: string) => {
  const digest = await crypto.subtle.digest("SHA-256", await Deno.readFile(p));
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
};
const want = await sha256(patch);
const have = (await Deno.readTextFile(sums).catch(() => "")).match(/zilc-filc-pass\.patch sha256 ([0-9a-f]+)/)?.[1];
if (want !== have) {
  console.log(`STALE: toolchain/ was archived from a different patch (${have ?? "none"} vs ${want}).`);
  console.log("       Run tools/filc/archive-patched-clang.ts.");
  stale = true;
}

// 3. The installed compiler was rebuilt after the archive was made.
const [b, t] = await Promise.all([Deno.stat(bin).catch(() => null), Deno.stat(tar).catch(() => null)]);
if (b?.mtime && t?.mtime && b.mtime > t.mtime) {
  console.log(`STALE: ${bin} is newer than the archive. Run tools/filc/archive-patched-clang.ts.`);
  stale = true;
}

// 4. The installed tree's kernel-header links must resolve, or programs that include
//    <linux/futex.h> and friends do not compile (fix-os-include.ts says why).
const osi = `${FILC_PATCHED_TREE}/pizfix/os-include`;
if (await exists(osi)) {
  for (const l of ["asm", "linux", "asm-generic"]) {
    if (!(await exists(`${osi}/${l}/.`))) {
      console.log(`BROKEN: ${osi}/${l} -> ${await Deno.readLink(`${osi}/${l}`).catch(() => "?")} does not exist.`);
      console.log(`        Run: deno run -A tools/filc/fix-os-include.ts ${FILC_PATCHED_TREE}`);
      stale = true;
    }
  }
}

if (!stale) console.log(`toolchain/ is up to date (patch sha256 ${want}).`);
Deno.exit(stale ? 1 : 0);
