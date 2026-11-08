// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// The sarcasm port, stage by stage (cmem/sarcasm-port.md, S1): each stage of the Zig port
// (tools/sarcasm/stage-check.zig) against upstream's own Luau module, on the same inputs, both
// dumped in one canonical text. The Luau side requires upstream's modules from the release's
// pizfix/lib/sarcasm (copied beside a generated harness, run by the release's minilute).
//
//   bun tools/sarcasm/check-stages.ts [stage …]     stages: detect sig parse isa fplookup isasyn
//                                                   (default: all); both outputs are kept in
//                                                   $WORK/sarcasm/stages/<stage>.{luau,zig}.out
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

// A hex input line is "x" + the hex of the input, so an EMPTY input is still a line (both sides
// split on non-empty lines, which would otherwise skip it).
const hex = (s: string) => "x" + Buffer.from(s, "latin1").toString("hex");
const unhexTs = (h: string) => Buffer.from(h.slice(1), "hex").toString("latin1");
const luaHexDecode = "local function unhex(h) return (string.gsub(string.sub(h, 2), '%x%x', function(x) return string.char(tonumber(x, 16)) end)) end";
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

// The canonical serializer (ser: fields sorted by key repr, "#n" for array indices; strings quoted
// with \ddd escapes; tostring numbers), shared by the stages below.
const SER = [
  "local function qs(v) return '\"' .. (string.gsub(v, '[%c\"\\\\\\128-\\255]', function(c) return '\\\\' .. tostring(string.byte(c)) end)) .. '\"' end",
  "local ser",
  "ser = function(v)",
  "  local t = type(v)",
  "  if t == 'string' then return qs(v) end",
  "  if t == 'number' or t == 'boolean' then return tostring(v) end",
  "  local keys = {}",
  "  for k in v do local r = type(k) == 'string' and k or ('#' .. tostring(k)); table.insert(keys, { r = r, k = k }) end",
  "  table.sort(keys, function(a, b) return a.r < b.r end)",
  "  local parts = {}",
  "  for _, e in keys do table.insert(parts, e.r .. '=' .. ser(v[e.k])) end",
  "  return '{' .. table.concat(parts, ',') .. '}'",
  "end",
].join("\n");

// parse: x86parse.parseString (+ numlabel) on every corpus file, as main runs it with --x86_64
// (the detected syntax, else AT&T), each statement serialized canonically.
stages.push({
  name: "parse",
  inputs: files,
  zigArg: "files",
  lua: [
    "local detect = require('./sarcasm/detect')",
    "local x86parse = require('./sarcasm/x86_64_parse')",
    SER,
    "local out = {}",
    "for line in string.gmatch(INPUT, '[^\\n]+') do",
    "  local text = FS.readfile(line)",
    "  local _, syn = detect.detect(text)",
    "  local ok, r = pcall(x86parse.parseString, text, syn or 'att', '<in>')",
    "  if ok then",
    "    table.insert(out, 'file ' .. tostring(#r))",
    "    for _, st in r do table.insert(out, ser(st)) end",
    "  else",
    "    table.insert(out, 'file err ' .. tostring(r))",
    "  end",
    "end",
    "print(table.concat(out, '\\n'))",
  ].join("\n"),
});

// isa / isasyn / fplookup: x86_64_isa and x86_64_fp. Every instruction is dumped through the same
// entry points (ISA_DUMP): classify (defs / uses as "@i" = the statement's own operand i, "@ib" /
// "@ix" = its memory base / index, "#n{…}" = a fresh table, numbered by first appearance so shared
// tables show), fp.lookup, accessWidth (lowercase and as-spelled mnemonic), vecEffects (in
// iteration order), maskedAccessInfo, the flag predicates and masks, lockAllows / isMemRmw /
// gprAccessRegWidth, narrowSuffix, unsafeReject, hasFpReg.
const ISA_DUMP = [
  "local fp = require('./sarcasm/x86_64_fp')",
  "local x86 = require('./sarcasm/x86_64_isa')",
  "local function lkSum(e)",
  "  if not e then return 'nil' end",
  "  return 'w=' .. (type(e.w) == 'function' and 'fn' or tostring(e.w)) .. ' a=' .. tostring(e.align) .. ' g=' .. (type(e.gpr) == 'function' and 'fn' or tostring(e.gpr))",
  "    .. ' m=' .. tostring(e.memOk) .. ' r=' .. tostring(e.reject ~= nil) .. ' n=' .. tostring(e.noCheck) .. ' c=' .. tostring(e.claim)",
  "end",
  "local function dumpClass(st, c)",
  "  local ids, n = {}, 0",
  "  local function ref(o)",
  "    for i, x in st.operands do",
  "      if x == o then return '@' .. i end",
  "      if x.kind == 'mem' then",
  "        if x.base == o then return '@' .. i .. 'b' end",
  "        if x.index == o then return '@' .. i .. 'x' end",
  "      end",
  "    end",
  "    if ids[o] then return '#' .. ids[o] end",
  "    n += 1; ids[o] = n",
  "    return '#' .. n .. ser(o)",
  "  end",
  "  local function refs(l) local o = {} for _, x in l do table.insert(o, ref(x)) end return '[' .. table.concat(o, ',') .. ']' end",
  "  local parts = { 'c=' .. c.control, 'f=' .. tostring(c.fallsThrough) }",
  "  table.insert(parts, 'd=' .. refs(c.defs))",
  "  table.insert(parts, 'u=' .. refs(c.uses))",
  "  local r = {} for _, x in c.rmw do table.insert(r, tostring(x)) end",
  "  table.insert(parts, 'r=[' .. table.concat(r, ',') .. ']')",
  "  if c.targets then local t = {} for _, x in c.targets do table.insert(t, qs(x)) end table.insert(parts, 't=[' .. table.concat(t, ',') .. ']') end",
  "  if c.pin then table.insert(parts, 'pu=' .. refs(c.pin.uses)); table.insert(parts, 'pd=' .. refs(c.pin.defs)) end",
  "  if c.rep then",
  "    local p = c.rep",
  "    local q = { 'rep=' .. p.kind, tostring(p.elem), tostring(p.repPrefix) }",
  "    table.insert(q, p.rsi and ref(p.rsi) or '-')",
  "    table.insert(q, p.rdi and ref(p.rdi) or '-')",
  "    table.insert(q, p.rax and ref(p.rax) or '-')",
  "    table.insert(q, ref(p.rcxUse))",
  "    table.insert(q, ref(p.rcxDef))",
  "    table.insert(parts, table.concat(q, '/'))",
  "  end",
  "  if c.flagsPush then table.insert(parts, 'fpush') end",
  "  if c.flagsPop then table.insert(parts, 'fpop') end",
  "  if c.unknown then table.insert(parts, 'unk') end",
  "  return table.concat(parts, ' ')",
  "end",
  "local function aw(m, st)",
  "  local ok, w, a = pcall(fp.accessWidth, m, st.operands, st.raw, st)",
  "  if not ok then return 'E ' .. tostring(w) end",
  "  return tostring(w) .. ',' .. tostring(a)",
  "end",
  "local function fx(t) local o = {} for k, v in t do table.insert(o, tostring(k) .. ':' .. tostring(v)) end return '{' .. table.concat(o, ',') .. '}' end",
  "local function isaDump(st)",
  "  local low = string.lower(st.mnemonic)",
  "  local p = { 'base=' .. x86.baseMnemonic(st.mnemonic) }",
  "  local ok, c = pcall(x86.classify, st)",
  "  table.insert(p, 'cls=' .. (ok and dumpClass(st, c) or ('E ' .. tostring(c))))",
  "  table.insert(p, 'lk=' .. lkSum(fp.lookup(low)))",
  "  table.insert(p, 'aw=' .. aw(low, st))",
  "  table.insert(p, 'aw2=' .. aw(st.mnemonic, st))",
  "  local vu, vd = fp.vecEffects(st)",
  "  table.insert(p, 've=u' .. fx(vu) .. ' d' .. fx(vd))",
  "  local mi = fp.maskedAccessInfo(low, st.operands)",
  "  table.insert(p, 'mi=' .. (mi and (tostring(mi.elem) .. ',' .. tostring(mi.lanes) .. ',' .. tostring(mi.vecsize) .. ',' .. tostring(mi.contiguous) .. ',' .. mi.extract .. ',' .. tostring(mi.movmskPd)) or 'nil'))",
  "  table.insert(p, 'fl=' .. tostring(x86.flagUse(st)) .. ',' .. tostring(x86.flagDef(st)) .. ',' .. tostring(x86.flagWriteNoDef(st)) .. ',' .. tostring(x86.flagUseMask(st)) .. ',' .. tostring(x86.flagDefMask(st)))",
  "  table.insert(p, 'lr=' .. tostring(x86.lockAllows(st)) .. ',' .. tostring(x86.isMemRmw(st)) .. ',' .. tostring(x86.gprAccessRegWidth(st)))",
  "  local mem = fp.memOperand(st.operands)",
  "  table.insert(p, 'ns=' .. tostring(fp.narrowSuffix(low, mem and mem.size)))",
  "  table.insert(p, 'ur=' .. tostring(fp.unsafeReject(low, st)))",
  "  table.insert(p, 'hf=' .. tostring(fp.hasFpReg(st)))",
  "  return table.concat(p, ' | ')",
  "end",
].join("\n");

stages.push({
  name: "isa",
  inputs: files,
  zigArg: "files",
  lua: [
    "local detect = require('./sarcasm/detect')",
    "local x86parse = require('./sarcasm/x86_64_parse')",
    SER,
    ISA_DUMP,
    "local out = {}",
    "for line in string.gmatch(INPUT, '[^\\n]+') do",
    "  local text = FS.readfile(line)",
    "  local _, syn = detect.detect(text)",
    "  local ok, r = pcall(x86parse.parseString, text, syn or 'att', '<in>')",
    "  if ok then",
    "    local n = 0",
    "    for _, st in r do if st.kind == 'insn' then n += 1 end end",
    "    table.insert(out, 'file ' .. tostring(n))",
    "    for _, st in r do if st.kind == 'insn' then table.insert(out, isaDump(st)) end end",
    "  else",
    "    table.insert(out, 'file err')",
    "  end",
    "end",
    "print(table.concat(out, '\\n'))",
  ].join("\n"),
});

// The mnemonic universe for the synthetic stages: every name token of upstream's fp / isa sources
// (table keys, quoted strings) and every corpus mnemonic.
const upSrc = ["x86_64_fp", "x86_64_isa"].map((m) => readFileSync(`${dir}/sarcasm/${m}.luau`, "latin1")).join("\n");
const tokens = new Set<string>();
for (const re of [/\b([a-z][a-z0-9]*)\s*=\s*[{"'\d]/g, /"([a-z][a-z0-9]*)"/g, /\["([a-z][a-z0-9]*)"\]/g]) for (const m of upSrc.matchAll(re)) tokens.add(m[1]);
for (const f of files) for (const line of readFileSync(f, "latin1").split("\n")) {
  const m = line.match(/^\s*(?:lock\s+|rep\w*\s+)?([a-zA-Z][a-zA-Z0-9]*)\s/);
  if (m && !line.trimStart().startsWith(".")) tokens.add(m[1].toLowerCase());
}
const lookupNames = new Set<string>();
for (const t of tokens) for (const v of [t, `v${t}`, `${t}b`, `${t}w`, `${t}l`, `${t}q`, `${t}x`, `${t}y`, `${t}z`, t.toUpperCase()]) lookupNames.add(v);

stages.push({
  name: "fplookup",
  inputs: [...lookupNames].sort(),
  zigArg: "lines",
  lua: [
    SER,
    ISA_DUMP,
    "local out = {}",
    "for m in string.gmatch(INPUT, '[^\\n]+') do",
    "  local st = { kind = 'insn', mnemonic = m, operands = {}, raw = m, syntax = 'att', file = '<in>', line = 1 }",
    "  local a, b, c = fp.narrowFamily(m)",
    "  table.insert(out, lkSum(fp.lookup(m)) .. ' | nf=' .. tostring(a) .. '/' .. tostring(b) .. '/' .. tostring(c) .. ' | ' .. isaDump(st))",
    "end",
    "print(table.concat(out, '\\n'))",
  ].join("\n"),
});

{
  const att = ["", "(%rdi)", "(%rdi), %xmm0", "(%rdi), %ymm1", "(%rdi), %zmm2", "%xmm3, (%rdi)", "%ymm3, (%rdi)", "%zmm3, (%rdi)",
    "(%rdi), %zmm2{%k1}", "(%rdi), %zmm2{%k1}{z}", "(%rdi), %zmm2{%k0}", "%zmm3, (%rdi){%k2}", "%ymm3, (%rdi){%k2}", "%xmm3, (%rdi){%k2}",
    "(%rdi){1to8}, %zmm1, %zmm2", "(%rdi){1to4}, %ymm1, %ymm2{%k3}", "(%rdi), %xmm1, %xmm2{%k1}", "(%rdi), %zmm1, %zmm2{%k1}",
    "(%rdi), %eax", "(%rdi), %rax", "(%rdi), %ax", "(%rdi), %al", "%eax, (%rdi)", "%rsi, (%rdi)", "%si, (%rdi)", "%sil, (%rdi)",
    "%xmm1, %xmm2", "%xmm1, %xmm1", "%ymm1, %ymm2", "%zmm1, %zmm2", "%xmm1, %ymm2", "%ymm1, %xmm2", "%xmm1, %xmm2, %xmm3", "%ymm1, %ymm2, %ymm3",
    "%zmm1, %zmm2, %zmm3{%k1}", "%zmm1, %zmm2, %zmm3{%k1}{z}", "(%rdi), %xmm1, %xmm2", "(%rdi), %ymm1, %ymm2", "(%rdi), %ymm1, %xmm2",
    "(%rdi), %zmm1, %ymm2", "%xmm0, %xmm1, %xmm2, %xmm3", "%eax, %xmm1", "%rax, %xmm1", "%xmm1, %eax", "%xmm1, %rax", "(%rdi), %xmm1, %eax",
    "$1, (%rdi), %xmm1", "$3, %xmm1, %eax", "$3, %xmm1, (%rdi)", "$1, %eax, %xmm1, %xmm2", "$1, (%rdi), %xmm1, %xmm2",
    "%rax, %rbx", "%eax, %ebx", "%ax, %bx", "%al, %bl", "(%rdi), %rax, %rbx", "%rcx, %rax, %rbx", "%ecx, %eax, %ebx",
    "%ah, %bl", "%bl, %ah", "%ah, %ch", "%ah, %sil", "%ah, %r8d", "%ah, %rax", "%ah", "%ah, %eax", "%ah, %ax", "$1, %ah", "%ah, (%rdi)",
    "%cl, %rax", "%dl, %rax", "$0, %rax", "$1, %rax", "%rcx, %rdx, %rax", "%cl, %rdx, %rax", "$3, %rdx, %rax", "$0, %rdx, %rax",
    "(%rdi), %mm0", "%mm1, %mm0", "%mm1, (%rdi)", "%k1, %k2", "%k1, %k2, %k3", "(%rdi), %k1", "%k1, (%rdi)", "%eax, %k1", "%k1, %eax",
    "myglobal, %rax", "%rax, myglobal", "myglobal(%rip), %rax", "%fs, %ax", "%ax, %fs", "%fs", "*%rax", "*(%rax)", "label", "*myglobal",
    "(,%rax,8), %rbx", "4096, %rax", "(4096), %rax", "(%rsp), %rax", "%rax, 8(%rsp)", "-8(%rbp), %rax", "%rax, -8(%rbp)",
    "$3", "$4", "$0x80", "%rax", "%eax", "%ax", "%al", "%r9d", "%xmm0", "%cr3, %rax", "%rax, %cr0", "%st(1), %st", "(%rdi), %st",
    "(%rdi,%rcx,4), %xmm1", "(%rdi,%xmm1,4), %xmm2", "(%rax,%rbx), %eax", "(%ah), %eax", "%fs:0x28, %rax"];
  const intel = ["xmm0, XMMWORD PTR [rdi]", "xmm0, DWORD PTR [rdi]", "xmm0, QWORD PTR [rdi]", "xmm0, WORD PTR [rdi]", "zmm0, ZMMWORD PTR [rdi]",
    "ymm0, QWORD PTR [rdi]", "ymm0, YMMWORD PTR [rdi]", "xmm0, YMMWORD PTR [rdi]", "xmm0, ZMMWORD PTR [rdi]", "ymm0, ZMMWORD PTR [rdi]",
    "ymm0, XMMWORD PTR [rdi]", "QWORD PTR [rdi], rax", "DWORD PTR [rdi], rax", "rax, BYTE PTR [rdi]", "eax, WORD PTR [rdi]", "rax, QWORD PTR [rdi]",
    "eax, DWORD PTR [rdi]", "TBYTE PTR [rdi]", "DWORD PTR [rdi]", "QWORD PTR [rdi]", "WORD PTR [rdi]", "BYTE PTR [rdi]", "XMMWORD PTR [rdi]",
    "xmm1, ymm2, YMMWORD PTR [rdi]", "xmm1, xmm2, DWORD PTR [rdi]", "ah, bl", "ah, sil", "eax, ah", "rax, myglobal", "rax, fs", "fs, ax",
    "XMMWORD PTR [rdi], xmm0", "DWORD PTR [rdi], xmm0", "xmm1, xmm2", "rax", "ecx", "rax, rbx", "eax, xmm1", "xmm1, rax"];
  const extra = ["lock xaddq %rax, (%rdi)", "lock addl $1, (%rdi)", "lock addl %eax, %ebx", "lock movq %rax, (%rdi)", "lock lock xadd %eax, (%rdi)",
    "lock cmpxchgq %rbx, (%rdi)", "lock cmpxchg16b (%rdi)", "lock incq (%rdi)", "lock xchg %rax, (%rdi)", "lock btsq $1, (%rdi)",
    "rep stosq", "rep movsb", "rep movsq", "repe movsb", "repne movsb", "repnz stosb", "rep movs", "rep stos", "movsd", "stosd", "movsl", "stosl",
    "movsq", "movsb %al, %bl", "rep ret", "rep nop", "rep addq %rax, %rbx", "rep lodsb", "lock rep movsb", "rep movsb #! stack buffer (x)", "rep movsb #! junk",
    "movsb #! junk", "int $3", "int $0x80", "int3", "int (%rax)", "hlt (%rax)", "ud2 (%rax)", "jrcxz label", "jecxz label", "jcxz label", "loop label",
    "loopl label", "loopq label", "loopw label", "loopb label", "loope label", "xbegin label", "jmp *myglobal", "call *myglobal",
    "cmpxchg8b (%rdi)", "cmpxchg16b %rax", "movbeb %al, (%rdi)", "movbew (%rdi), %ax", "movbeq %rax, (%rdi)", "movbeq %rax, %rbx", "movbe (%rdi)",
    "shldq %cl, %rax, %rbx", "shldq %dl, %rax, %rbx", "shldq $0, %rax, %rbx", "shrdq $3, %rax, (%rdi)", "shld %rax, %rbx",
    "pushfq", "popfq", "pushf", "popf", "pushfd", "pushfw", "pushfq %rax", "cld", "std", "std %rax", "cpuid", "cpuid %eax", "rdtsc", "rdtscp", "xgetbv",
    "rdpkru", "wrpkru", "monitor", "mwait", "lahf", "sahf", "lahf %ah", "mulx %rax, %rbx, %rcx", "mulxq (%rdi), %rax, %rbx", "divb %cl", "divw (%rdi)",
    "div (%rdi)", "idivq %rcx", "mulw %cx", "mull %ecx", "imul %rcx", "imulq %rcx, %rdx", "imulq $3, %rcx, %rdx", "cqo", "cwd", "cdq", "cltq", "cbw", "cwde",
    "xchg %ah, %bl", "xchg %ah, %sil", "xchgq %rax, %rbx", "xchg %rax, (%rdi)", "xchgb %ah, %al", "xchg %ah, %r9w", "xchg %eax, %xmm0",
    "setb %ah", "seta %al", "setb (%rdi)", "setb %sil", "cmovbq %rax, %rbx", "cmovbw %ax, %bx", "cmovll %eax, %ebx", "cmovxq %rax, %rbx",
    "movb %ah, %al", "movb %ah, %sil", "movb $1, %ah", "movb %ah, (%rdi)", "movzbl %ah, %eax", "movzbq %ah, %rax", "movzwl %ah, %eax", "movsbw %ah, %ax",
    "movzbl %ah, %ah", "movw %ax, %bx", "movb %al, %bl", "movl %eax, %ebx", "addb %ah, %al", "shlb %cl, %ah", "shlb %ah, %al", "incb %ah", "negb %ah",
    "cmpb %ah, %bl", "testb $1, %ah", "imulb %ah", "bswap %eax", "bswapw %ax", "bswap %rax, %rbx", "bswap (%rdi)", "bswapq %rax", "btq $3, %rax",
    "btsq %rcx, (%rdi)", "btrl %ecx, %eax", "btc $1, %ax", "nopw 0x0(%rax,%rax,1)", "nopl (%rax)", "ud2", "hlt", "syscall", "popw %ax", "popq %rax",
    "pushq %rax", "pushq (%rdi)", "push %fs", "pop %fs", "movw %ax, %fs", "movl %fs, %eax", "shlq %cl, %rdx", "shlq %rcx, %rdx", "shlq %dl, %rdx",
    "shlq $0, %rax", "shlq $4, %rax", "rolq $0, %rax", "rclq $1, %rax", "rcrq %cl, %rax", "adcq %rax, %rbx", "adcxq %rax, %rbx", "adoxl (%rdi), %eax",
    "crc32b %al, %eax", "crc32q (%rdi), %rax", "crc32l (%rdi), %rax", "crc32 (%rdi), %eax", "crc32w %ax, %rax", "xaddb %sil, (%rdi)",
    "popcntq %rax, %rbx", "tzcnt (%rdi), %eax", "lzcntw %ax, %bx", "stc", "clc", "cmc", "sahf", "salc", "daa", "arpl %ax, %bx", "notrack jmp *%rax",
    "movq %cr3, %rax", "mov %rax, %dr7", "leaq myglobal, %rax", "leaq (%rdi), %rax", "leal 4(%rdi,%rsi,2), %eax", "jmp *%rdi", "jmp *(%rax,%rcx,8)",
    "call *%rax", "call foo", "jmp foo", "je foo", "jne foo", "ret", "retq", "leave", "endbr64", "movabsq $1, %rax", "movq $1, %rax", "movq %rax, %xmm0",
    "movq %xmm0, %rax", "movq %xmm0, %xmm1", "movq (%rdi), %xmm0", "movd %eax, %xmm0", "vmovq %xmm0, %rax", "vmovd (%rdi), %xmm1", "kmovw %eax, %k1",
    "kmovw %k1, %eax", "kmovq (%rdi), %k1", "vpbroadcastd %eax, %zmm0", "vpbroadcastb (%rdi), %zmm0{%k1}", "vbroadcastss (%rdi), %ymm0{%k1}",
    "vmovdqu64 (%rdi), %zmm0{%k1}", "vmovdqu8 %zmm0, (%rdi){%k1}", "vpmovqb %zmm0, (%rdi){%k1}", "vpmovusdw %zmm0, (%rdi)", "vpmovsqd %ymm1, (%rdi){%k2}",
    "vpcompressd %zmm0, (%rdi){%k1}", "vexpandps (%rdi), %zmm0{%k1}", "vpsubq (%rip), %ymm3, %ymm3{%k1}", "vpsubq .Lmask(%rip), %ymm3, %ymm3{%k1}",
    "vaddps (%rdi), %zmm1, %zmm2{%k1}", "vaddps (%rdi){1to16}, %zmm1, %zmm2{%k1}", "vpermd (%rdi), %zmm1, %zmm2{%k1}", "vpermi2d (%rdi), %zmm1, %zmm2{%k1}",
    "vmaskmovps (%rdi), %ymm1, %ymm2", "vmaskmovps %ymm2, %ymm1, (%rdi)", "vmaskmovpd (%rdi), %ymm2", "vpmaskmovq (%rdi), %xmm1, %xmm2",
    "vcvtpd2ps (%rdi), %xmm0", "vcvtpd2psx (%rdi), %xmm0", "vcvtpd2psy (%rdi), %xmm0", "vcvtpd2psy (%rdi), %ymm0", "vcvtpd2ps (%rdi), %ymm0",
    "vcvtpd2phz (%rdi), %xmm0", "vcvtdq2ph (%rdi), %ymm0", "vcvtpd2ph (%rdi), %ymm0", "vcvtps2ph $0, %ymm0, (%rdi)", "vcvtps2pd (%rdi), %zmm0",
    "vcvtph2pd (%rdi), %zmm0", "vpmovzxbd (%rdi), %zmm0", "pmovsxwq (%rdi), %xmm0", "vpmovzxbq (%rdi), %ymm0", "vmovddup (%rdi), %ymm0", "movddup (%rdi), %xmm0",
    "vfmadd231sd (%rdi), %xmm1, %xmm2", "vfmadd231ps %zmm1, %zmm2, %zmm3", "vpternlogd $0, %zmm1, %zmm2, %zmm3", "vpdpwssd %zmm1, %zmm2, %zmm3",
    "vcvtsd2ss %xmm1, %xmm2, %xmm3", "vcvtss2sd (%rdi), %xmm2, %xmm3", "vaddsd %xmm1, %xmm2, %xmm3", "vcvttsd2si %xmm0, %eax", "cvtsi2sd %eax, %xmm0",
    "cvtsi2sdq (%rdi), %xmm0", "cvtsi2ss (%rdi), %xmm0", "cvtsd2ss %xmm1, %xmm0", "addsd %xmm1, %xmm0", "movsd %xmm1, %xmm0", "movsd (%rdi), %xmm0",
    "movsd %xmm0, (%rdi)", "pxor %xmm0, %xmm0", "pxor %xmm1, %xmm0", "xorps %xmm0, %xmm0", "movaps %xmm1, %xmm0", "movhps (%rdi), %xmm0", "pinsrd $1, %eax, %xmm0",
    "blendvps %xmm1, %xmm0", "sha256rnds2 %xmm1, %xmm2", "vzeroupper", "vzeroall", "fxsave (%rdi)", "fxrstor (%rdi)", "fxsave64 (%rsp)", "fnstsw %ax",
    "fstsw (%rdi)", "flds (%rdi)", "fldt (%rdi)", "fld (%rdi)", "fadd (%rdi)", "fsave (%rdi)", "xsave (%rdi)", "vgatherdps %ymm1, (%rdi,%ymm2,4), %ymm0",
    "tileloadd (%rdi,%rsi), %tmm0", "pcmpestri $0, (%rdi), %xmm0", "vpcmpistri $0, %xmm1, %xmm0", "prefetcht0 (%rdi)", "clflush (%rdi)", "maskmovdqu %xmm1, %xmm0",
    "ldmxcsr (%rdi)", "sgdt (%rdi)", "sldt %ax", "lss (%rdi), %eax", "lfs (%rdi), %rax", "movnti %esi, (%rdi)", "movnti %rsi, (%rdi)", "vaddsh (%rdi), %xmm1, %xmm2",
    "vcvtusi2sd %rax, %xmm1, %xmm2", "enqcmd (%rdi), %rax", "vmovups %ymm0, (%rdi)", "vmovaps (%rdi), %zmm0", "movdqa (%rdi), %xmm0", "vpaddd (%rdi), %zmm1, %zmm2",
    "vpabsd (%rdi), %zmm0", "vpopcntd (%rdi), %zmm0", "vexpandd (%rdi), %zmm0", "vpexpandd (%rdi), %zmm0", "vcompresspd %zmm0, (%rdi)", "kandw %k1, %k2, %k3",
    "kandw (%rdi), %k2, %k3", "aesimc (%rdi), %xmm0", "emms", "movmskps (%rdi), %eax", "movmskps %xmm0, %eax", "pextrw $1, %xmm0, %eax", "pextrw $1, %xmm0, (%rdi)",
    "extractps $1, %xmm0, %eax", "vpmovmskb %ymm0, %eax", "sm4rnds4 (%rdi), %xmm1, %xmm2", "vsm3rnds2 $1, (%rdi), %xmm1, %xmm2", "gf2p8affineqb $0, (%rdi), %xmm0",
    "vgf2p8affineqb $0, (%rdi), %zmm1, %zmm0", "vpmadd52luq (%rdi), %zmm1, %zmm2", "vp4dpwssd (%rdi), %zmm4, %zmm0", "v4fmaddps (%rdi), %zmm4, %zmm0",
    "vdbpsadbw $0, (%rdi), %zmm1, %zmm2", "vpclmulqdq $0, (%rdi), %zmm1, %zmm2", "vsha512msg2 (%rdi), %ymm0", "vsha512rnds2 %xmm0, %ymm1, %ymm2",
    "umwait %eax", "wrfsbase %rax", "swapgs", "rdmsr", "inb %dx, %al", "outb %al, %dx", "lodsb", "scasq", "cmpsb", "cmpsd", "xlatb", "clzero", "lcall *(%rax)",
    ".alloca $16, $8, %rax", ".alloca %rdi, $8, %rax", ".alloca %edi, $8, %rax", ".alloca %di, $8, %rax", ".alloca 8(%rsp), $8, %rax", ".alloca -8(%rbp), $8, %rax",
    ".alloca $16, $8, 8(%rsp)", ".alloca $16, $8, %eax", ".alloca $16, $8", ".alloca *%rdi, $8, %rax", ".alloca (%rdi), $8, %rax", ".alloca $16, $8, $1",
    ".alloca $16, $8, -8(%rbp)", ".alloca $16, *%rsi, %rax", ".alloca $16, $8, *%rax", ".alloca %xmm0, $8, %rax", ".alloca $16, $8, (%rdi)", "alloca $16, $8, %rax"];
  const intelExtra = ["mov rax, QWORD PTR [rdi]", "mov QWORD PTR [rdi], rax", "mov WORD PTR [rdi], rax", "movsd", "movsl", "stosd", "rep stosd", "rep movsd",
    "rep movsl", "xchg ah, bl", "movzx eax, ah", "movzx rax, ah", "mov ah, al", "mov al, ah", "setb ah", "vmovdqu64 DWORD PTR [rdi], zmm0", "movnti DWORD PTR [rdi], rsi",
    "cvtsi2sd xmm0, DWORD PTR [rdi]", "cvtsi2sd xmm0, QWORD PTR [rdi]", "vcvtpd2ps xmm0, XMMWORD PTR [rdi]", "vcvtpd2ps xmm0, YMMWORD PTR [rdi]",
    "vcvtpd2ps ymm0, ZMMWORD PTR [rdi]", "vcvtpd2ps xmm0, ZMMWORD PTR [rdi]", "vcvtpd2ps xmm0, DWORD PTR [rdi]", "vcvtpd2ph xmm0, ZMMWORD PTR [rdi]",
    "crc32 eax, BYTE PTR [rdi]", "crc32 eax, QWORD PTR [rdi]", "crc32 rax, WORD PTR [rdi]", "crc32 rax, BYTE PTR [rdi]", "fld TBYTE PTR [rdi]", "fadd DWORD PTR [rdi]",
    "lzcnt rax, DWORD PTR [rdi]", "xadd BYTE PTR [rdi], al", "div DWORD PTR [rdi]", "div QWORD PTR [rdi]", "mul BYTE PTR [rdi]", "push fs", "mov fs, ax", "mov ax, fs",
    "mov rax, gs", "jmp myglobal", "jmp QWORD PTR [rax]", "mov rax, 4096", "mov rax, [4096]", "vpbroadcastd zmm0{k1}, DWORD PTR [rdi]"];
  const lines: string[] = [];
  const add = (syn: string, t: string) => lines.push(hex(`${syn}\t${t}`));
  const synNames = [...tokens].sort();
  for (const m of synNames) {
    for (const v of [m, `v${m}`]) {
      for (const sh of att) add("att", sh ? `${v} ${sh}` : v);
      for (const sh of intel) add("intel", `${v} ${sh}`);
    }
  }
  for (const t of extra) add("att", t);
  for (const t of intelExtra) add("intel", t);
  stages.push({
    name: "isasyn",
    inputs: lines,
    zigArg: "hex",
    lua: [
      "local x86parse = require('./sarcasm/x86_64_parse')",
      SER,
      ISA_DUMP,
      luaHexDecode,
      "local out = {}",
      "for line in string.gmatch(INPUT, '[^\\n]+') do",
      "  local syn, text = string.match(unhex(line), '^([^\\t]*)\\t(.*)$')",
      "  local ok, r = pcall(x86parse.parseString, text, syn, '<in>')",
      "  if not ok then",
      "    table.insert(out, 'perr ' .. tostring(r))",
      "  else",
      "    local d = {}",
      "    for _, st in r do if st.kind == 'insn' then table.insert(d, isaDump(st)) end end",
      "    table.insert(out, #d > 0 and table.concat(d, ' || ') or 'none')",
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
  await writeFile(`${dir}/${st.name}.luau.out`, luauOut);
  await writeFile(`${dir}/${st.name}.zig.out`, zigOut);
  const a = luauOut.trimEnd().split("\n"), b = zigOut.trimEnd().split("\n");
  const bad: number[] = [];
  for (let i = 0; i < Math.max(a.length, b.length); i++) if (a[i] !== b[i]) bad.push(i);
  console.log(`${st.name}: ${st.inputs.length} inputs, ${a.length} lines (${luauOut.length} bytes), ${bad.length} differ`);
  for (const i of bad.slice(0, 6)) console.log(`  input ${JSON.stringify((st.zigArg === "hex" ? unhexTs(st.inputs[i] ?? "x") : st.inputs[i] ?? "").slice(0, 90))}\n    luau: ${a[i]?.slice(0, 160)}\n    zig:  ${b[i]?.slice(0, 160)}`);
  if (bad.length) failed++;
}
console.log(failed ? `FAILED: ${failed} stage(s) differ` : "OK: every stage equal to upstream's");
process.exit(failed ? 1 : 0);
