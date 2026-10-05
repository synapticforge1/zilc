// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Group why zilc-built tests/basics programs fail (from size-compare.ts's folders): runtime traps by
// the Fil-C fault and the source location it names, and build failures by their first error line.
// Pure data: runs on any OS (from Windows, give the folder as WSL shares it).
//
//   deno run -A tools/basics/zilc-failures.ts [bin dir]      (default: $WORK/basics-size/bin)
import { basename, exists, glob, WORK } from "../lib/tool.ts";

const bin = Deno.args[0] ?? `${WORK}/basics-size/bin`;
const dirOf = (p: string) => p.slice(0, p.lastIndexOf("/"));
const group = (items: [string, string][]) => {
  const g = new Map<string, string[]>();
  for (const [k, ex] of items) g.set(k, [...(g.get(k) ?? []), ex]);
  for (const [k, ex] of [...g].sort((a, b) => b[1].length - a[1].length)) {
    console.log(`${String(ex.length).padStart(3)}  ${k}\n       e.g. ${ex.join(" ").slice(0, 120)}`);
  }
};

console.log("== runtime traps (zilcSafe): fault + semantic origin");
const traps: [string, string][] = [];
for (const o of await glob(`${bin}/*/*/zilcSafe.out`)) {
  const lines = (await Deno.readTextFile(o)).split("\n");
  const at = lines.findIndex((l) => /filc safety error|filc panic/.test(l));
  if (at < 0) continue;
  const fault = lines[at].replace(/.*filc safety error: /, "").replace(/^\[[0-9]*\] /, "");
  const so = lines.findIndex((l) => l.includes("semantic origin"));
  const origin = so >= 0 ? (lines[so + 1] ?? "").trim().replace(/\([^)]*\) /, "") : "";
  traps.push([`${fault} | ${origin}`, basename(dirOf(o))]);
}
group(traps);

console.log("\n== build failures (zilcSafe): first error");
const fails: [string, string][] = [];
for (const g of await glob(`${bin}/zig/*/zilcSafe.log`)) {
  if (await exists(`${dirOf(g)}/zilcSafe`)) continue;
  const line = (await Deno.readTextFile(g)).split("\n").find((l) => /error|undefined|assert|segmentation|stack dump/i.test(l)) ?? "";
  fails.push([line.replace(/^.*error: /, "").slice(0, 110), basename(dirOf(g))]);
}
group(fails);

console.log("\n== zilcSmall build failures");
for (const g of await glob(`${bin}/zig/*/zilcSmall.log`)) {
  if (await exists(`${dirOf(g)}/zilcSmall`)) continue;
  const line = (await Deno.readTextFile(g)).split("\n").find((l) => /error|undefined|assert/i.test(l)) ?? "";
  console.log(`${basename(dirOf(g))}: ${line.slice(0, 140)}`);
}
