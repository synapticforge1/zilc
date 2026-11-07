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

// ---- tonumber(s): corpus tokens and edge cases, compared as the result's exact bits (or nil)
import { readdirSync, readFileSync, statSync } from "node:fs";
import { filcPackageDir } from "../lib/tool.ts";
const strs = new Set<string>([
  "", " ", "0", "-0", "+1", " 12 ", "\t7\n", "1e3", "1E+3", "1e", "1e+", ".5", "5.", ".", "-.5e-2", "0x", "0X1F", "0x1p4", "0x1.8p1", "0x.8", "0x1p", "0xg",
  "0x10 ", " 0x10", "-0x10", "0x8000000000000000", "0xffffffffffffffff", "0x10000000000000000", "0x7fffffffffffffffff", "inf", "-inf", "Infinity", "INF", "infinit",
  "nan", "-nan", "NaN", "nan(123)", "nan(", "1,2", "1 2", "12abc", "1_000", "0b101", "1e400", "-1e400", "4.9e-324", "2e-324", "9007199254740993", "123456789012345678901234567890",
  "0x1fffffffffffff", "0x20000000000001", "00012", "0e0", "+", "-", "++1", "1.2.3", "$1", "%rax", "1f", "2b",
]);
{
  const pkg = await filcPackageDir();
  const walk = (d: string, out: string[]) => { for (const n of readdirSync(d)) { const p = `${d}/${n}`; if (statSync(p).isDirectory()) walk(p, out); else if (p.endsWith(".s")) out.push(p); } return out; };
  for (const f of walk(`${pkg}/filc/tests`, []).sort()) for (const tok of readFileSync(f, "latin1").split(/[\s,()$*%[\]{}:;!#]+/)) if (tok && tok.length < 40) strs.add(tok);
}
// hex rounding: long hex integers, and hex floats across the whole exponent range (subnormals too)
for (let i = 0; i < 4000; i++) {
  const len = 14 + Number(rnd64() % 10n);
  let h = "";
  for (let k = 0; k < len; k++) h += "0123456789abcdef"[Number(rnd64() % 16n)];
  strs.add(`0x${h}`);
  const e = Number(rnd64() % 2200n) - 1150;
  strs.add(`0x${h.slice(0, 1)}.${h.slice(1)}p${e}`);
}
for (const t of ["0x1p-1074", "0x1p-1075", "0x1.0000000000001p-1075", "0x0.8p-1074", "0x1.fffffffffffff8p1023", "0x1.fffffffffffff7p1023", "0x8.000000000000400p0", "0x8.000000000000c00p0", "0x8.0000000000004001p0"]) strs.add(t);
const list = [...strs];
await writeFile(`${dir}/strings.hex`, list.map((s) => Buffer.from(s, "latin1").toString("hex")).join("\n") + "\n");
const lua2 = [
  "local fs = require('@lute/fs')",
  `local h = fs.open(${JSON.stringify(`${dir}/strings.hex`)}, 'r'); local text = fs.read(h); fs.close(h)`,
  "local out = {}",
  "for line in string.gmatch(text, '[^\\n]*\\n') do",
  "  local s = string.gsub(string.sub(line, 1, -2), '%x%x', function(x) return string.char(tonumber(x, 16)) end)",
  "  local n = tonumber(s)",
  "  if n == nil then table.insert(out, 'nil') else",
  "    local b = string.pack('<d', n); local o = {} for i = 8, 1, -1 do table.insert(o, string.format('%02x', string.byte(b, i))) end",
  "    table.insert(out, table.concat(o)) end",
  "end",
  "print(table.concat(out, '\\n'))",
].join("\n");
await writeFile(`${dir}/tonumber.luau`, lua2 + "\n");
const [l2, z2] = await Promise.all([must([minilute, `${dir}/tonumber.luau`]), must([exe, "--tonumber", `${dir}/strings.hex`])]);
const a2 = l2.trimEnd().split("\n"), b2 = z2.trimEnd().split("\n");
const bad2 = list.map((s, i) => ({ s, a: a2[i], b: b2[i] })).filter((x) => x.a !== x.b);
console.log(`tonumber: ${list.length} strings (${a2.filter((x) => x !== "nil").length} numbers in Luau)`);
for (const x of bad2.slice(0, 10)) console.log(`  DIFFER ${JSON.stringify(x.s)}: luau ${x.a} / zig ${x.b}`);
console.log(bad2.length ? `FAILED: ${bad2.length} differ` : "OK: tonumber equal to Luau's for every string");
process.exit(bad.length || bad2.length ? 1 : 0);
