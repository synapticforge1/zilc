// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Summarise size-compare.ts's CSV: medians and totals per language and flavour, build failures, and
// how zilc's runs compare with the plain ReleaseSafe runs. Pure data: runs on any OS (from Windows
// give the CSV's path as WSL shares it, e.g. \\wsl.localhost\Ubuntu\home\…).
//
//   deno run -A tools/basics/size-report.ts [sizes.csv]      (default: $WORK/basics-size/sizes.csv)
import { WORK } from "../lib/tool.ts";

const csv = Deno.args[0] ?? `${WORK}/basics-size/sizes.csv`;
const rows = (await Deno.readTextFile(csv)).trim().split("\n").slice(1).map((l) => l.split(","));
// columns: 2 zig_small 3 zig_safe 4 zilc_safe 5 zilc_small 6..9 stripped, 10 run_zig_safe 11 run_zilc
const columns: [number, string][] = [
  [2, "zig_small"], [3, "zig_safe"], [4, "zilc_safe"], [5, "zilc_small"],
  [6, "zig_small_stripped"], [7, "zig_safe_stripped"], [8, "zilc_safe_stripped"], [9, "zilc_small_stripped"],
];
const pad = (n: number, w: number) => String(n).padStart(w);

for (const lang of ["c", "zig"]) {
  console.log(`== ${lang}`);
  const mine = rows.filter((r) => r[0] === lang);
  for (const [c, name] of columns) {
    const v = mine.map((r) => r[c]).filter((x) => x !== "NA").map(Number).sort((a, b) => a - b);
    if (!v.length) {
      console.log(`  ${name.padEnd(22)} (none built)`);
      continue;
    }
    const med = v[Math.floor((v.length + 1) / 2) - 1];
    const sum = v.reduce((a, b) => a + b, 0);
    console.log(`  ${name.padEnd(22)} built ${pad(v.length, 3)}  median ${pad(med, 9)}  min ${pad(v[0], 9)}  max ${pad(v[v.length - 1], 9)}  total ${pad(sum, 11)}`);
  }
  console.log("  -- runs: plain ReleaseSafe vs zilc (exit code, 133 = Fil-C trap, NA = zilc build failed)");
  const same = mine.filter((r) => r[10] === r[11]).length;
  if (same) console.log(`    ${pad(same, 6)} same`);
  if (mine.length - same) console.log(`    ${pad(mine.length - same, 6)} DIFF`);
  for (const r of mine.filter((r) => r[10] !== r[11])) console.log(`    ${r[1].padEnd(40)} zig=${r[10].padEnd(8)} zilc=${r[11]}`);
}
