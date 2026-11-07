// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Proves src/sarcasm/luau_number.zig against Luau itself (cmem/sarcasm-port.md, foundation 2):
// tostring(n) and string.format("%.0f", n) for random bit patterns, random integers and halves,
// powers of two and ten and their neighbours, and the specials — in Luau under the release's
// minilute and in Zig; every line must be equal.
//
//   bun tools/sarcasm/check-luau-number.ts     env COUNT (50000), MINILUTE

import { mkdir, writeFile } from "node:fs/promises";
import { env, envInt, FILC_PREBUILT_TREE, linuxOnly, must, REPO, WORK, ZIG, zigCacheArgs } from "../lib/tool.ts";

await linuxOnly(import.meta);
const minilute = env("MINILUTE", `${FILC_PREBUILT_TREE}/pizfix/bin/minilute`);
const dir = `${WORK}/sarcasm/luau-number-check`;
await mkdir(dir, { recursive: true });

const dv = new DataView(new ArrayBuffer(8));
const bitsOf = (x: number) => (dv.setFloat64(0, x, true), dv.getBigUint64(0, true));
const nums: bigint[] = [];
const add = (x: number) => nums.push(bitsOf(x));
for (const x of [0, -0, 1, -1, 0.5, 1.5, 2.5, -2.5, 0.1, 1 / 3, NaN, -NaN, Infinity, -Infinity, 5e-324, Number.MAX_VALUE, 1e21, 1e-5, 1e-6, 1e-7, 2 ** 53, 2 ** 62, 2 ** 63, 2 ** 64]) add(x);
for (let e = -330; e <= 310; e++) for (const m of [1, 2, 5, 9.999999999999999]) {
  const x = m * 10 ** e;
  if (Number.isFinite(x)) (add(x), add(-x));
}
for (let p = -1074; p <= 1023; p++) {
  const x = 2 ** p;
  add(x);
  dv.setFloat64(0, x, true);
  const b = dv.getBigUint64(0, true);
  nums.push(b + 1n, b - 1n);
}
let seed = 12345n;
const rnd64 = () => (seed = (seed * 6364136223846793005n + 1442695040888963407n) & 0xffffffffffffffffn);
const count = envInt("COUNT", 50000);
for (let i = 0; i < count; i++) {
  nums.push(rnd64()); // any bit pattern
  const r = Number(rnd64() >> 11n);
  add(r); // integers up to 2^53
  add(r / 2); // halves (the %.0f ties)
  add(Number(rnd64() >> 33n) / 1024);
}
const hex = nums.map((b) => b.toString(16)).join("\n") + "\n";
await writeFile(`${dir}/numbers.hex`, hex);
// Luau reads the same bits: the hex string → integer → double via string.unpack.
const lua = [
  "local out = {}",
  `for line in string.gmatch([[${hex}]], "%x+") do`,
  "  local hi = tonumber(string.sub(line, 1, -9), 16) or 0",
  "  local lo = tonumber(string.sub(line, -8), 16)",
  "  local n = string.unpack('<d', string.pack('<I4I4', lo, hi))",
  "  table.insert(out, tostring(n) .. '\\t' .. string.format('%.0f', n))",
  "end",
  "print(table.concat(out, '\\n'))",
].join("\n");
await writeFile(`${dir}/check.luau`, lua + "\n");
const exe = `${dir}/luau-number-check`;
await must([ZIG, "build-exe", "-OReleaseSafe", "--dep", "luau_number", `-Mroot=${REPO}/tools/sarcasm/luau-number-check.zig`,
  `-Mluau_number=${REPO}/src/sarcasm/luau_number.zig`, `-femit-bin=${exe}`, ...zigCacheArgs()]);
const [luauOut, zigOut] = await Promise.all([must([minilute, `${dir}/check.luau`]), must([exe, `${dir}/numbers.hex`])]);
const a = luauOut.trimEnd().split("\n"), b = zigOut.trimEnd().split("\n");
const bad: number[] = [];
for (let i = 0; i < Math.max(a.length, b.length); i++) if (a[i] !== b[i]) bad.push(i);
console.log(`${nums.length} doubles; Luau printed ${a.length} lines, Zig ${b.length}`);
for (const i of bad.slice(0, 10)) console.log(`  DIFFER bits ${nums[i]?.toString(16)}: luau ${JSON.stringify(a[i]?.slice(0, 80))} / zig ${JSON.stringify(b[i]?.slice(0, 80))}`);
console.log(bad.length ? `FAILED: ${bad.length} differ` : "OK: tostring and %.0f equal to Luau's for every double");
process.exit(bad.length ? 1 : 0);
