// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Restore the patched Fil-C clang from the project's toolchain/ folder into Linux, where zilc's tools
// expect it (~/zilc-work/tools/filc-0.685-zilc). The alternative is a ~1 h rebuild with
// tools/filc/build-patched-clang.ts. Linux; from Windows it runs inside WSL.
//
//   deno run -A tools/filc/restore-patched-clang.ts [--with-debug-info]
//   env DEST=/some/dir: restore there instead (used to test the archive without touching the install)
import { fixOsInclude } from "./fix-os-include.ts";
import { env, linuxOnly, mkdirp, must, REPO, rmrf, sh, show, WORK } from "../lib/tool.ts";

await linuxOnly(import.meta);
const input = `${REPO}/toolchain`;
const name = "filc-0.685-zilc";
const dest = env("DEST", `${WORK}/tools`);

// The checksums first: SHA256SUMS lists both files, its comment lines start with '#'.
const sums = (await Deno.readTextFile(`${input}/SHA256SUMS`)).split("\n").filter((l) => l && !l.startsWith("#")).join("\n") + "\n";
if ((await sh("sha256sum -c -", { cwd: input, stdin: sums, inherit: true })).code !== 0) throw new Error("toolchain/ checksums do not match");

await mkdirp(dest);
await rmrf(`${dest}/${name}`);
// xz and tar: a .tar.xz is unpacked by the system tools (symlinks such as clang -> clang-20 are
// kept, which is why the archive is a tarball at all: exFAT has no symlinks).
await must(["sh", "-c", 'xz -dc "$0" | tar -C "$1" -xf -', `${input}/${name}-linux-x86_64.tar.xz`, dest]);
if (Deno.args.includes("--with-debug-info")) {
  // gdb finds it next to the binary through the .gnu_debuglink section.
  await must(["sh", "-c", 'xz -dc "$0" > "$1"', `${input}/${name}-clang-20.debug.xz`, `${dest}/${name}/build/bin/clang-20.debug`]);
}
// The archive's kernel-header links point wherever they pointed on the machine that made it.
await fixOsInclude(`${dest}/${name}`);
await show(["sh", "-c", '"$0" --version | head -1', `${dest}/${name}/build/bin/clang`]);
console.log(`restored: ${dest}/${name}/build/bin/clang`);
