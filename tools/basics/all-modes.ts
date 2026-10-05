// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// KI-16: run the tests/basics corpus through zilc in every optimize mode at once, and summarise.
// C inputs ignore -O (they go straight to Fil-C's clang), so only Zig differs by mode.
//
//   deno run -A tools/basics/all-modes.ts [modes…]      (default: all four)
//   env: LANGS (default "zig"; "c zig" adds the C half, which the output comparison wants),
//        JOBS (parallel builds PER MODE, default 8), and everything zilc-check.ts takes
// Output: $WORK/all-modes-<mode>.txt, plus zilc-check.ts's folders.
import { env, linuxOnly, pool, REPO, run, WORK } from "../lib/tool.ts";

await linuxOnly(import.meta);
const modes = Deno.args.length ? Deno.args : ["Debug", "ReleaseSafe", "ReleaseFast", "ReleaseSmall"];
const check = `${REPO}/tools/basics/zilc-check.ts`;

await pool(modes, modes.length, (mode) =>
  run([Deno.execPath(), "run", "-A", check, env("LANGS", "zig")], {
    env: { MODE: mode, JOBS: env("JOBS", "8") },
    outFile: `${WORK}/all-modes-${mode}.txt`,
  }));

for (const mode of modes) {
  console.log(`################ ${mode}`);
  const text = await Deno.readTextFile(`${WORK}/all-modes-${mode}.txt`);
  const lines = text.split("\n").filter((l) => !/Trace\/breakpoint|^Aborted/.test(l));
  console.log(lines.slice(-31).join("\n").trimEnd());
}
