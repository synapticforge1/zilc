// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Proves src/sarcasm/lua_pattern.zig against Luau itself (cmem/sarcasm-port.md, foundation 3):
// every literal pattern sarcasm's own sources pass to string.find / match / gmatch / gsub (and
// method-call forms), plus hand-written ones for each construct, run over real lines and tokens
// of Fil-C's .s test corpus — in Luau under the release's minilute and in Zig. Per pattern, both
// print the length and a checksum of the canonical encoding of every result (find's positions and
// captures, match's captures, every gmatch step, gsub with "<%0>" and its count); a pattern that
// raises an error prints E. Checksum: h = (h*31 + byte) mod 2^32, exact in Luau's doubles.
//
//   bun tools/sarcasm/check-lua-pattern.ts     env SUBJECTS (600), MINILUTE

import { readdirSync, readFileSync, statSync } from "node:fs";
import { mkdir, writeFile } from "node:fs/promises";
import { env, envInt, filcPackageDir, FILC_PREBUILT_TREE, linuxOnly, must, REPO, WORK, ZIG, zigCacheArgs } from "../lib/tool.ts";

await linuxOnly(import.meta);

const minilute = env("MINILUTE", `${FILC_PREBUILT_TREE}/pizfix/bin/minilute`);
const pkg = await filcPackageDir();
const dir = `${WORK}/sarcasm/lua-pattern-check`;
await mkdir(dir, { recursive: true });

// ---- the patterns: literals in sarcasm's sources
const unescape = (lit: string): string => {
  // a Luau double-quoted string body: \\ \" \' \n \t \r \a \b \f \v \0 \ddd \xXX
  return lit.replace(/\\(x[0-9a-fA-F]{2}|\d{1,3}|.)/g, (_, e: string) => {
    if (e[0] === "x") return String.fromCharCode(parseInt(e.slice(1), 16));
    if (/^\d/.test(e)) return String.fromCharCode(parseInt(e, 10));
    return ({ n: "\n", t: "\t", r: "\r", a: "\x07", b: "\b", f: "\f", v: "\v" } as Record<string, string>)[e] ?? e;
  });
};
const found = new Set<string>();
const srcDir = `${pkg}/projects/sarcasm/sarcasm`;
for (const f of readdirSync(srcDir).filter((n) => n.endsWith(".luau") && !n.startsWith("arm64"))) {
  const text = readFileSync(`${srcDir}/${f}`, "utf8");
  const re = /(?:string\.(?:find|match|gmatch|gsub)\(\s*[^,()]*(?:\([^()]*\))?[^,()]*,\s*|:(?:find|match|gmatch|gsub)\(\s*)"((?:[^"\\\n]|\\.)*)"/g;
  for (const m of text.matchAll(re)) found.add(unescape(m[1]));
}
const extra = [
  "^%s*(.-)%s*$", "%f[%w]%w+", "%f[%W]", "%b()", "%b{}", "(%d+)%.(%d+)", "()%a+()", "^(%$?)(-?%d+)$", "[^,]+", "[%w_%.%$]+",
  "%%(%a+)", "(.)%1", "a-b", "x*", "[a-c-]", "[]]", "[^]]", "%x+$", "^$", "", ".-", "[%z]",
];
const patterns = [...found, ...extra];

// ---- the subjects: corpus lines and tokens
const files: string[] = [];
const walk = (d: string) => {
  for (const n of readdirSync(d)) {
    const p = `${d}/${n}`;
    if (statSync(p).isDirectory()) walk(p);
    else if (p.endsWith(".s")) files.push(p);
  }
};
walk(`${pkg}/filc/tests`);
files.sort();
let seed = 1;
const rnd = (m: number) => ((seed = (Math.imul(seed, 1103515245) + 12345) >>> 0) >>> 8) % m;
const subjects = new Set<string>(["", " ", "%", "()", "{a{b}c}", "a,b,,c", "  x  ", "0x10", "-12", "$7", "%rax", "8(%rsp)", "aab", "xyz]"]);
const want = envInt("SUBJECTS", 600);
while (subjects.size < want) {
  const lines = readFileSync(files[rnd(files.length)], "utf8").split("\n");
  const line = lines[rnd(lines.length)];
  subjects.add(line);
  const toks = line.split(/[\s,]+/).filter(Boolean);
  if (toks.length) subjects.add(toks[rnd(toks.length)]);
}
const subs = [...subjects];
const hex = (s: string) => Buffer.from(s, "latin1").toString("hex");
await writeFile(`${dir}/patterns.hex`, patterns.map(hex).join("\n") + "\n");
await writeFile(`${dir}/subjects.hex`, subs.map(hex).join("\n") + "\n");

// ---- the Luau side
const luaStr = (s: string) => '"' + [...Buffer.from(s, "latin1")].map((b) => `\\${b}`).join("") + '"';
const lua = [
  `local pats = {${patterns.map(luaStr).join(",\n")}}`,
  `local subs = {${subs.map(luaStr).join(",\n")}}`,
  "local len, h = 0, 0",
  "local function add(x) for i = 1, #x do h = (h * 31 + string.byte(x, i)) % 4294967296; len += 1 end end",
  "local function caps(...) local n = select('#', ...) for i = 1, n do local c = select(i, ...) if type(c) == 'number' then add('p' .. tostring(c)) else add('s' .. tostring(#c) .. ':'); add(c) end end end",
  "local out = {}",
  "for _, p in pats do",
  "  len, h = 0, 0",
  "  local ok = pcall(function()",
  "    for _, s in subs do",
  "      local r = table.pack(string.find(s, p))",
  "      if r[1] then add('F' .. tostring(r[1]) .. ',' .. tostring(r[2])); caps(table.unpack(r, 3, r.n)) else add('F-') end",
  "      local m = table.pack(string.match(s, p))",
  "      if m[1] ~= nil then add('M'); caps(table.unpack(m, 1, m.n)) else add('M-') end",
  "      add('G')",
  // the iterator called directly, its results packed: exactly the values each step returns
  "      local it = string.gmatch(s, p)",
  "      while true do local g = table.pack(it()) if g[1] == nil then break end caps(table.unpack(g, 1, g.n)); add(';') end",
  "      local t, n = string.gsub(s, p, '<%0>')",
  "      add('S' .. tostring(n) .. ':'); add(t)",
  "    end",
  "  end)",
  "  table.insert(out, ok and (tostring(len) .. ' ' .. tostring(h)) or 'E')",
  "end",
  "print(table.concat(out, '\\n'))",
].join("\n");
await writeFile(`${dir}/check.luau`, lua + "\n");

const exe = `${dir}/lua-pattern-check`;
await must([ZIG, "build-exe", "-OReleaseSafe", "--dep", "lua_pattern", `-Mroot=${REPO}/tools/sarcasm/lua-pattern-check.zig`,
  `-Mlua_pattern=${REPO}/src/sarcasm/lua_pattern.zig`, `-femit-bin=${exe}`, ...zigCacheArgs()]);
const [luauOut, zigOut] = await Promise.all([must([minilute, `${dir}/check.luau`]), must([exe, `${dir}/patterns.hex`, `${dir}/subjects.hex`])]);
const a = luauOut.trimEnd().split("\n"), b = zigOut.trimEnd().split("\n");
const bad = patterns.map((p, i) => ({ p, a: a[i], b: b[i] })).filter((x) => x.a !== x.b);
console.log(`${patterns.length} patterns (${found.size} from sarcasm's sources), ${subs.length} subjects; ${a.filter((l) => l === "E").length} raise errors in Luau`);
for (const x of bad.slice(0, 12)) console.log(`  DIFFER ${JSON.stringify(x.p)}: luau ${x.a} / zig ${x.b}`);
console.log(bad.length ? `FAILED: ${bad.length} patterns differ` : "OK: every pattern gives Luau's results on every subject (find, match, gmatch, gsub)");
process.exit(bad.length ? 1 : 0);
