// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Proves src/sarcasm/luau_table.zig against Luau itself (cmem/sarcasm-port.md, foundation 1):
// random operation sequences — number keys (dense small integers, 0, negatives, large, fractional,
// ±2^31, 2^53), short and long string keys, nil stores, table.insert / table.remove with and
// without a position, and `#t` (which caches a boundary in the lastfree union) — run in Luau under
// the release's minilute and replayed in Zig; every `#t` and every traversal order must be equal.
// Keys are printed as indices into the trace's key pool, so number formatting plays no part.
//
//   bun tools/sarcasm/check-luau-table.ts     env SCENARIOS (2000), SEED (1), MINILUTE

import { mkdir, writeFile } from "node:fs/promises";
import { env, envInt, FILC_PREBUILT_TREE, linuxOnly, must, REPO, WORK, ZIG, zigCacheArgs } from "../lib/tool.ts";

await linuxOnly(import.meta);

const minilute = env("MINILUTE", `${FILC_PREBUILT_TREE}/pizfix/bin/minilute`);
const dir = `${WORK}/sarcasm/luau-table-check`;
await mkdir(dir, { recursive: true });

// A fixed key pool.
const numKeys: number[] = [0, -1, -2, -100, 0.5, 1.5, 3.25, -0.5, 1e10, 2 ** 31 - 1, 2 ** 31, -(2 ** 31), 2 ** 53, 1e300, 100, 1000, 4096];
for (let i = 1; i <= 80; i++) numKeys.push(i);
const strKeys: string[] = ["", "a", "b", "x86_depth", "x86_smap", "rbp", "rsp", "%rax", "fil_x0", "kind", "name", "line"];
for (let i = 0; i < 20; i++) strKeys.push(`k${i}`);
for (let i = 0; i < 6; i++) strKeys.push(`a-long-string-key-of-more-than-32-bytes-number-${i}`);
const pool: ({ n: number } | { s: string })[] = [...numKeys.map((n) => ({ n })), ...strKeys.map((s) => ({ s }))];

let seed = envInt("SEED", 1) >>> 0;
const rnd = (m: number) => {
  seed = (Math.imul(seed, 1103515245) + 12345) >>> 0;
  return (seed >>> 8) % m;
};

const f64hex = (n: number) => {
  const b = new DataView(new ArrayBuffer(8));
  b.setFloat64(0, n, true);
  return b.getBigUint64(0, true).toString(16);
};
const trace: string[] = pool.map((k) => ("n" in k ? `K n ${f64hex(k.n)}` : `K s ${Buffer.from(k.s).toString("hex")}`));
const luaKey = (i: number) => {
  const k = pool[i];
  if ("s" in k) return JSON.stringify(k.s);
  if (Object.is(k.n, 2 ** 53)) return "2^53";
  return k.n.toString().includes("e") ? `(${k.n.toExponential().replace("e+", "e")})` : `(${k.n})`;
};
const lua: string[] = [
  "local pool = {}",
  "local idx = {}",
  ...pool.map((_, i) => `pool[${i}] = ${luaKey(i)}; idx[pool[${i}]] = ${i}`),
  "local out = {}",
  "local function dump(t) local s = {'dump'} for k in t do table.insert(s, tostring(idx[k])) end table.insert(out, table.concat(s, ' ')) end",
  "local t",
];

const scenarios = envInt("SCENARIOS", 2000);
let v = 1;
for (let s = 0; s < scenarios; s++) {
  trace.push("S");
  lua.push("t = {}");
  const ops = 5 + rnd(120);
  // Bias some scenarios to small dense integer keys (array part), some to strings, some mixed.
  const style = rnd(3);
  for (let o = 0; o < ops; o++) {
    const r = rnd(100);
    const pick = () => (style === 0 ? 17 + rnd(40) : style === 1 ? numKeys.length + rnd(strKeys.length) : rnd(pool.length));
    if (r < 55) {
      const k = pick();
      trace.push(`set ${k} ${v}`);
      lua.push(`t[pool[${k}]] = ${v}`);
      v++;
    } else if (r < 67) {
      // nil stores on NUMBER keys only: a nil-valued node with a collectable (string) key is
      // turned into a DEAD key whenever Luau's GC traverses the table (lgc removeentry), which then
      // changes where later keys go — GC timing, not the table algorithm. Numbers are never
      // collected, so number-keyed layouts are exact; sarcasm sorts string-keyed traversals that
      // reach its output (cmem/sarcasm-port.md).
      const k = style === 1 ? rnd(numKeys.length) : pick() % numKeys.length;
      trace.push(`nil ${k}`);
      lua.push(`t[pool[${k}]] = nil`);
    } else if (r < 77) {
      trace.push(`ins ${v}`);
      lua.push(`table.insert(t, ${v})`);
      v++;
    } else if (r < 82) {
      // Luau's tinsert takes any position (no bounds error, unlike Lua 5.3): pos <= n moves up.
      const p = 1 + rnd(8);
      trace.push(`insat ${p} ${v}`);
      lua.push(`table.insert(t, ${p}, ${v})`);
      v++;
    } else if (r < 88) {
      const p = rnd(4) === 0 ? "_" : String(1 + rnd(10));
      trace.push(`rem ${p}`);
      lua.push(p === "_" ? "table.remove(t)" : `table.remove(t, ${p})`);
    } else if (r < 93) {
      trace.push("len");
      lua.push("table.insert(out, 'len ' .. #t)");
    } else {
      trace.push("dump");
      lua.push("dump(t)");
    }
  }
  trace.push("dump");
  lua.push("dump(t)");
}
lua.push("print(table.concat(out, '\\n'))");
await writeFile(`${dir}/trace.txt`, trace.join("\n") + "\n");
await writeFile(`${dir}/check.luau`, lua.join("\n") + "\n");

const exe = `${dir}/luau-table-check`;
await must([ZIG, "build-exe", "-OReleaseSafe", "--dep", "luau_table", `-Mroot=${REPO}/tools/sarcasm/luau-table-check.zig`,
  `-Mluau_table=${REPO}/src/sarcasm/luau_table.zig`, `-femit-bin=${exe}`, ...zigCacheArgs()]);
const [luauOut, zigOut] = await Promise.all([must([minilute, `${dir}/check.luau`]), must([exe, `${dir}/trace.txt`])]);
const a = luauOut.trimEnd().split("\n"), b = zigOut.trimEnd().split("\n");
let first = -1;
for (let i = 0; i < Math.max(a.length, b.length); i++) if (a[i] !== b[i]) { first = i; break; }
console.log(`${scenarios} scenarios, ${trace.length} trace lines; Luau printed ${a.length} lines, Zig ${b.length}`);
if (first >= 0) {
  console.log(`FAILED: first difference at output line ${first + 1}\n  luau: ${a[first]?.slice(0, 200)}\n  zig:  ${b[first]?.slice(0, 200)}`);
  process.exit(1);
}
console.log(`OK: every #t and every traversal order equal to Luau's (${a.filter((l) => l.startsWith("dump")).length} traversals)`);
