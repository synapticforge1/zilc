// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Archive the locally built, patched Fil-C clang (KI-4, KI-22) into the project's toolchain/ folder,
// so the project folder alone can restore it (owner, 2026-10-01). LOCAL ONLY: toolchain/ is
// gitignored. Pushing these files would be a DISTRIBUTION of Fil-C (Apache-2.0 + LLVM exception,
// BSD-2-Clause runtime, MIT musl); see the ledger entry `filc-pass-fixes`. Linux; from Windows it
// runs inside WSL.
//
//   deno run -A tools/filc/archive-patched-clang.ts
//
// Why two files: D: is exFAT (no symlinks, no Unix permissions), so the tree goes in a tarball.
// And clang-20 built RelWithDebInfo is 3.6 GB, almost all debug info. The tree gets a STRIPPED
// clang-20 (debug info does not change what it compiles); the debug info goes to its own file,
// linked by .gnu_debuglink, for profiling with gdb (as KI-22 was diagnosed).
import { FILC_PATCHED_TREE, linuxOnly, mkdirp, must, REPO, rmrf, run, show, WORK } from "../lib/tool.ts";

await linuxOnly(import.meta);
const out = `${REPO}/toolchain`;
const name = "filc-0.685-zilc";
const tmp = `${WORK}/archive-tmp`;
await rmrf(tmp);
await mkdirp(tmp);
await mkdirp(out);

// cp -a keeps the tree's symlinks (clang -> clang-20, os-include/*).
await must(["cp", "-a", FILC_PATCHED_TREE, `${tmp}/${name}`]);
await rmrf(`${tmp}/${name}/build/bin/clang-prebuilt`); // comparison copy, not part of the toolchain
const b = `${tmp}/${name}/build/bin/clang-20`;
await must(["objcopy", "--only-keep-debug", b, `${tmp}/clang-20.debug`]);
await must(["strip", "--strip-debug", b]);
await must(["objcopy", `--add-gnu-debuglink=${tmp}/clang-20.debug`, "clang-20"], { cwd: `${tmp}/${name}/build/bin` });
const du = async (p: string) => (await must(["du", "-h", p])).split("\t")[0];
console.log(`stripped clang-20: ${await du(b)}; debug info: ${await du(`${tmp}/clang-20.debug`)}`);

// Stripping must not change what the compiler emits: compare against the unstripped binary.
const f = `${REPO}/tools/p2/repro/filc-0.685-O1-crash.ll`;
await must(["setarch", "-R", `${FILC_PATCHED_TREE}/build/bin/clang-20`, "-O1", "-Wno-override-module", "-c", "-o", `${tmp}/a.o`, f]);
await must(["setarch", "-R", b, "-O1", "-Wno-override-module", "-c", "-o", `${tmp}/b.o`, f]);
if ((await run(["cmp", `${tmp}/a.o`, `${tmp}/b.o`])).code !== 0) throw new Error("the stripped clang emits a different object: not archiving");
console.log("stripped clang emits identical objects (KI-4 repro, -O1)");

await must(["sh", "-c", 'tar -C "$0" -cf - "$1" | xz -T0 -6 > "$2"', tmp, name, `${out}/${name}-linux-x86_64.tar.xz`]);
await must(["sh", "-c", 'xz -T0 -6 -c "$0" > "$1"', `${tmp}/clang-20.debug`, `${out}/${name}-clang-20.debug.xz`]);

const patchSum = (await must(["sha256sum", `${REPO}/third_party/filc-patches/zilc-filc-pass.patch`])).split(" ")[0];
const fileSums = await must(["sha256sum", `${name}-linux-x86_64.tar.xz`, `${name}-clang-20.debug.xz`], { cwd: out });
const stamp = new Date().toISOString().slice(0, 16) + "Z";
await Deno.writeTextFile(`${out}/SHA256SUMS`, [
  `# ${name}: Fil-C 0.685 clang built from llvm-project-deluge bb0d0a64 with zilc's pass fixes`,
  `# patch: third_party/filc-patches/zilc-filc-pass.patch sha256 ${patchSum}`,
  `# archived ${stamp} by tools/filc/archive-patched-clang.ts`,
  fileSums.trimEnd(),
].join("\n") + "\n");
await rmrf(tmp);
await show(["ls", "-la", out]);
console.log(await Deno.readTextFile(`${out}/SHA256SUMS`));
