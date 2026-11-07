// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// The sarcasm port, stage by stage (cmem/sarcasm-port.md, S1): each stage of the Zig port
// (tools/sarcasm/stage-check.zig) against upstream's own Luau module, on the same inputs, both
// dumped in one canonical text. The Luau side requires upstream's modules from the release's
// pizfix/lib/sarcasm (copied beside a generated harness, run by the release's minilute).
//
//   bun tools/sarcasm/check-stages.ts [stage …]     stages: detect sig (default: all)
//
//   detect   detect.detect on every .s file of Fil-C's tests: "arch syntax|nil"
//   sig      sig.parseSignature + checkSupportedClasses on every `;!` / `#!` annotation body in
//            the corpus and synthetic ones: "ok <signature> {ret}{args} aw rw void retptr" or
//            "err <message>"

import { readdirSync, readFileSync, statSync } from "node:fs";
import { cp, mkdir, rm, writeFile } from "node:fs/promises";
import { ARGS, env, filcPackageDir, FILC_PREBUILT_TREE, linuxOnly, must, REPO, WORK, ZIG, zigCacheArgs } from "../lib/tool.ts";

await linuxOnly(import.meta);
const minilute = env("MINILUTE", `${FILC_PREBUILT_TREE}/pizfix/bin/minilute`);
const dir = `${WORK}/sarcasm/stages`;
await rm(dir, { recursive: true, force: true });
await mkdir(dir, { recursive: true });
await cp(`${FILC_PREBUILT_TREE}/pizfix/lib/sarcasm`, `${dir}/sarcasm`, { recursive: true });

const pkg = await filcPackageDir();
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

const exe = `${dir}/stage-check`;
await must([ZIG, "build-exe", "-OReleaseSafe", "--dep", "sarcasm", `-Mroot=${REPO}/tools/sarcasm/stage-check.zig`,
  `-Msarcasm=${REPO}/src/sarcasm/sarcasm.zig`, `-femit-bin=${exe}`, ...zigCacheArgs()]);

const hex = (s: string) => Buffer.from(s, "latin1").toString("hex");
const luaHexDecode = "local function unhex(h) return (string.gsub(h, '%x%x', function(x) return string.char(tonumber(x, 16)) end)) end";
const listOf = (xs: string) => `local function list(t) local o = {} for _, x in t do table.insert(o, tostring(x)) end return '{' .. table.concat(o, ',') .. '}' end`;

interface Stage { name: string; inputs: string[]; lua: string; zigArg: string }
const stages: Stage[] = [];

// detect
stages.push({
  name: "detect",
  inputs: files,
  zigArg: "files",
  lua: [
    "local detect = require('./sarcasm/detect')",
    "local out = {}",
    "for line in string.gmatch(INPUT, '[^\\n]+') do",
    "  local text = FS.readfile(line)",
    "  local a, s = detect.detect(text)",
    "  table.insert(out, a .. ' ' .. (s or 'nil'))",
    "end",
    "print(table.concat(out, '\\n'))",
  ].join("\n"),
});

// sig: the annotation bodies of the corpus, and synthetic ones
{
  const anns = new Set<string>(["int(ptr)", "void()", "void(void)", "  unsigned long ( ptr , size_t )  ", "double(float, double)", "long double(int)", "vec4(int)",
    "int(__m128)", "ptr(ptr,ptr,ptr,ptr,ptr,ptr,ptr,ptr,ptr,ptr,ptr,ptr,ptr,ptr)", "int", "int(int (*)(int), char *)", "", "uint64_t(int8_t, Bool)", "enum x(signed char)"]);
  for (const f of files) for (const line of readFileSync(f, "latin1").split("\n")) {
    const m = line.match(/(?:;!|#!)(.*)$/);
    if (m) anns.add(m[1]);
  }
  stages.push({
    name: "sig",
    inputs: [...anns].map(hex),
    zigArg: "hex",
    lua: [
      "local sig = require('./sarcasm/sig')",
      luaHexDecode,
      listOf(""),
      "local out = {}",
      "local st = { file = '<in>', line = 7 }",
      "for line in string.gmatch(INPUT, '[^\\n]+') do",
      "  local ann = unhex(line)",
      "  local ok, r = pcall(function()",
      "    local d = sig.parseSignature(ann, st)",
      "    sig.checkSupportedClasses(d, \"call to 'f'\", { arch = 'x86_64' }, st)",
      "    return d",
      "  end)",
      "  if ok then",
      "    table.insert(out, 'ok ' .. tostring(r.signature) .. ' ' .. list(r.retTypes) .. list(r.argTypes) .. ' ' .. tostring(r.argWords) .. ' ' .. tostring(r.retWords) .. ' ' .. tostring(r.isVoid) .. ' ' .. tostring(r.retIsPtr))",
      "  else",
      "    table.insert(out, 'err ' .. tostring(r))",
      "  end",
      "end",
      "print(table.concat(out, '\\n'))",
    ].join("\n"),
  });
}

const want = ARGS.filter((a) => !a.startsWith("-"));
let failed = 0;
for (const st of stages.filter((s) => !want.length || want.includes(s.name))) {
  const inFile = `${dir}/${st.name}.in`;
  await writeFile(inFile, st.inputs.join("\n") + "\n");
  // The harness reads its input list and files through @lute/fs.
  const lua = [
    "local fs = require('@lute/fs')",
    "local FS = { readfile = function(p) local h = fs.open(p, 'r'); local t = fs.read(h); fs.close(h); return t end }",
    `local INPUT = FS.readfile(${JSON.stringify(inFile)})`,
    st.lua.replace(/\bFS\.readfile\b/g, "FS.readfile"),
  ].join("\n");
  await writeFile(`${dir}/${st.name}.luau`, lua + "\n");
  const [luauOut, zigOut] = await Promise.all([must([minilute, `${dir}/${st.name}.luau`]), must([exe, st.name, inFile])]);
  const a = luauOut.trimEnd().split("\n"), b = zigOut.trimEnd().split("\n");
  const bad: number[] = [];
  for (let i = 0; i < Math.max(a.length, b.length); i++) if (a[i] !== b[i]) bad.push(i);
  console.log(`${st.name}: ${st.inputs.length} inputs, ${bad.length} differ`);
  for (const i of bad.slice(0, 6)) console.log(`  input ${JSON.stringify((st.zigArg === "hex" ? Buffer.from(st.inputs[i] ?? "", "hex").toString("latin1") : st.inputs[i] ?? "").slice(0, 90))}\n    luau: ${a[i]?.slice(0, 160)}\n    zig:  ${b[i]?.slice(0, 160)}`);
  if (bad.length) failed++;
}
console.log(failed ? `FAILED: ${failed} stage(s) differ` : "OK: every stage equal to upstream's");
process.exit(failed ? 1 : 0);
