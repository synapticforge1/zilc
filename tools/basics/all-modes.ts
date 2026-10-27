// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// KI-16: run the tests/basics corpus through zilc in every optimize mode at once, and summarise.
// C inputs ignore -O (they go straight to Fil-C's clang), so only Zig differs by mode.
//
//   bun tools/basics/all-modes.ts [modes…]      (default: all four)
//   env: LANGS (default "zig"; "c zig" adds the C half, which the output comparison wants),
//        JOBS (parallel builds PER MODE, default 8), and everything zilc-check.ts takes
// Output: $WORK/all-modes-<mode>.txt, plus zilc-check.ts's folders.
import { readFile } from "node:fs/promises";
import { ARGS, env, linuxOnly, pool, REPO, run, WORK } from "../lib/tool.ts";

await linuxOnly(import.meta);
const modes = ARGS.length ? ARGS : ["Debug", "ReleaseSafe", "ReleaseFast", "ReleaseSmall"];
const check = `${REPO}/tools/basics/zilc-check.ts`;

await pool(modes, modes.length, (mode) =>
  run([process.execPath, check, env("LANGS", "zig")], {
    env: { MODE: mode, JOBS: env("JOBS", "8") },
    outFile: `${WORK}/all-modes-${mode}.txt`,
  }));

for (const mode of modes) {
  console.log(`################ ${mode}`);
  const text = await readFile(`${WORK}/all-modes-${mode}.txt`, "utf8");
  const lines = text.split("\n").filter((l) => !/Trace\/breakpoint|^Aborted/.test(l));
  console.log(lines.slice(-31).join("\n").trimEnd());
}
