// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// The sarcasm port, stage by stage (cmem/sarcasm-port.md, S1): each stage of the Zig port
// (tools/sarcasm/stage-check.zig) against upstream's own Luau module, on the same inputs, both
// dumped in one canonical text. The Luau side requires upstream's modules from the release's
// pizfix/lib/sarcasm (copied beside a generated harness, run by the release's minilute).
//
//   bun tools/sarcasm/check-stages.ts [stage …]     stages: detect sig parse isa fplookup isasyn
//                                                   lift framecalls
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

// lift / ptrflow / regalloc / frame on the corpus. Each file's body is its parse with the
// instructions classify rejects left out (the same filter both sides), then:
//   lift      liftFunction with x86 classify, returnRegs {0, 2}, and a callInfo rule;
//   ptrflow   analyze with seeds chosen by rule (arg pointers rdi/rsi, load / call pointer defs,
//             save / restore pairs so both phases run), x86 baseMnemonic, widenSwaps;
//   regalloc  color with x86 ALLOCATABLE, with 5 registers (spills), and with rcx reserved, over
//             insns built from the lift (labels, defs / uses, targets, full / narrow moves); liveOut;
//   frame     preprocess with a small test policy (the same on both sides).
// Tables upstream iterates are dumped in iteration order; the rest sorted.
const LIFT_DUMP = [
  "local x86 = require('./sarcasm/x86_64_isa')",
  "local lift = require('./sarcasm/lift')",
  "local ptrflow = require('./sarcasm/ptrflow')",
  "local regalloc = require('./sarcasm/regalloc')",
  "local framem = require('./sarcasm/frame')",
  "local function L(t) local o = {} for _, x in t do table.insert(o, tostring(x)) end return '[' .. table.concat(o, ',') .. ']' end",
  "local function sortedNum(t, f) local ks = {} for k in t do table.insert(ks, k) end table.sort(ks) local o = {} for _, k in ks do table.insert(o, f(k, t[k])) end return '{' .. table.concat(o, ',') .. '}' end",
  "local function iterKV(t) local o = {} for k, v in t do table.insert(o, tostring(k) .. ':' .. tostring(v)) end return '{' .. table.concat(o, ',') .. '}' end",
  "local function callInfo(st)",
  "  local o = st.operands[1]",
  "  if o and o.kind == 'sym' then",
  "    local c = string.byte(o.text, 1) or 0",
  "    if c % 2 == 0 then return { argRegs = { 7, 6 }, resultReg = 0 } end",
  "    if c % 3 == 0 then return { argRegs = { 2 } } end",
  "  end",
  "  return nil",
  "end",
  "local function isRegRegMov(st)",
  "  local a, b = st.operands[1], st.operands[2]",
  "  return x86.baseMnemonic(st.mnemonic) == 'mov' and #st.operands == 2 and a.kind == 'reg' and a.rc == 'gpr' and b.kind == 'reg' and b.rc == 'gpr'",
  "end",
  "local function liftDump(out, r)",
  "  local body = {}",
  "  for _, st in r do if st.kind ~= 'insn' or pcall(x86.classify, st) then table.insert(body, st) end end",
  "  local ok, lf = pcall(lift.liftFunction, body, { classify = x86.classify, returnRegs = { 0, 2 }, callInfo = callInfo })",
  "  if not ok then table.insert(out, 'lift err ' .. tostring(lf)) return end",
  "  table.insert(out, 'L n=' .. #lf.flow .. ' next=' .. lf.nextTemp)",
  "  local tr = {} for _, t in lf.temps do table.insert(tr, tostring(t.reg)) end",
  "  table.insert(out, 'T ' .. table.concat(tr, ','))",
  "  table.insert(out, 'E ' .. sortedNum(lf.entryTemp, function(k, v) return tostring(k) .. ':' .. tostring(v) end))",
  "  for _, nd in lf.nodes do",
  "    if nd.kind == 'insn' then",
  "      local o = {}",
  "      for _, r in nd.c.defs do table.insert(o, tostring(nd.opTemp[r] or '-')) end",
  "      for _, r in nd.c.uses do table.insert(o, tostring(nd.opTemp[r] or '-')) end",
  "      table.insert(out, 'I ' .. nd.fi .. ' d=' .. L(nd.defTemps) .. ' u=' .. L(nd.useTemps) .. ' o=[' .. table.concat(o, ',') .. '] s=' .. L(lf.succ[nd.fi]))",
  "    elseif nd.kind == 'label' then table.insert(out, 'B ' .. qs(nd.name))",
  "    else table.insert(out, 'O') end",
  "  end",
  "  local lk = {} for k in lf.labelToFlow do table.insert(lk, k) end table.sort(lk)",
  "  local lo = {} for _, k in lk do table.insert(lo, qs(k) .. ':' .. lf.labelToFlow[k]) end",
  "  table.insert(out, 'F ' .. table.concat(lo, ','))",
  // ptrflow
  "  local seeds = { argPtrTemps = {}, loadPtrDefs = {}, callPtrDefs = {}, capSave = {}, capRestore = {} }",
  "  if lf.entryTemp[7] then table.insert(seeds.argPtrTemps, lf.entryTemp[7]) end",
  "  if lf.entryTemp[6] then table.insert(seeds.argPtrTemps, lf.entryTemp[6]) end",
  "  local lastSave = nil",
  "  for _, nd in lf.nodes do",
  "    if nd.kind == 'insn' then",
  "      local st = nd.stmt",
  "      local m = x86.baseMnemonic(st.mnemonic)",
  "      local a, b = st.operands[1], st.operands[2]",
  "      if m == 'mov' and a and b and a.kind == 'reg' and b.kind == 'mem' and nd.fi % 2 == 0 then seeds.loadPtrDefs[nd] = true end",
  "      if nd.c.control == 'call' and nd.fi % 3 == 0 then seeds.callPtrDefs[nd] = true end",
  "      if isRegRegMov(st) and nd.fi % 5 == 0 then seeds.capSave[nd] = 'v' .. nd.fi; lastSave = nd.fi",
  "      elseif isRegRegMov(st) and nd.fi % 7 == 0 and lastSave then seeds.capRestore[nd] = 'v' .. lastSave end",
  "    end",
  "  end",
  "  local nt, alloc = lf.nextTemp, {}",
  "  local function allocTemp(info) nt += 1; table.insert(alloc, tostring(nt) .. ':' .. tostring(info.forPtr) .. ':' .. tostring(info.dynamicLower or false)) return nt end",
  "  local okp, pf = pcall(ptrflow.analyze, lf, seeds, allocTemp, { baseMnemonic = x86.baseMnemonic, widenSwaps = true })",
  "  if not okp then table.insert(out, 'pf err ' .. tostring(pf)) else",
  "    table.insert(out, 'P ' .. iterKV(pf.isPtr) .. ' W ' .. iterKV(pf.lowerTemp) .. ' D ' .. iterKV(pf.dynamic))",
  "    local y = {}",
  "    for _, nd in lf.nodes do local dc = pf.dynCopy[nd] if dc then",
  "      local c = {} for _, x in dc.copies do table.insert(c, tostring(x.dst) .. '>' .. tostring(x.src)) end",
  "      table.insert(y, tostring(nd.fi) .. ':' .. tostring(dc.xchg or false) .. '/' .. tostring(dc.cmov or false) .. ':[' .. table.concat(c, ',') .. ']') end end",
  "    table.insert(out, 'Y ' .. table.concat(y, ' '))",
  "    local hk = {} for k in pf.capShot do table.insert(hk, k) end table.sort(hk)",
  "    local h = {} for _, k in hk do table.insert(h, k .. ':' .. tostring(pf.capShot[k].web) .. ',' .. tostring(pf.capShot[k].lo)) end",
  "    table.insert(out, 'H ' .. table.concat(h, ' ') .. ' N ' .. table.concat(alloc, ' '))",
  "  end",
  "  local okq, pq = pcall(ptrflow.analyze, lf, seeds, allocTemp, { baseMnemonic = x86.baseMnemonic, widenSwaps = false })",
  "  table.insert(out, okq and ('Q ' .. iterKV(pq.isPtr) .. ' W ' .. iterKV(pq.lowerTemp)) or ('Q err ' .. tostring(pq)))",
  // regalloc
  "  local insns = {}",
  "  for _, nd in lf.nodes do",
  "    if nd.kind == 'label' then table.insert(insns, { isLabelDef = nd.name })",
  "    elseif nd.kind == 'insn' then",
  "      local ins = { defs = nd.defTemps, uses = nd.useTemps, targets = nd.c.targets, fallsThrough = nd.c.fallsThrough }",
  "      if isRegRegMov(nd.stmt) and #nd.defTemps == 1 and #nd.useTemps == 1 then ins.move = { dst = nd.defTemps[1], src = nd.useTemps[1], wide = nd.stmt.operands[1].width == 64 } end",
  "      table.insert(insns, ins)",
  "    end",
  "  end",
  "  local function mkTemps(same)",
  "    local temps = {}",
  "    for t = 1, lf.nextTemp do temps[t] = { spillCost = 1 + (t % 3) } end",
  "    if lf.entryTemp[7] then temps[lf.entryTemp[7]].precolor = 'rdi' end",
  "    if lf.entryTemp[6] then temps[lf.entryTemp[6]].precolor = same and 'rdi' or 'rsi' end",
  "    return temps",
  "  end",
  "  local small = { 'rax', 'rcx', 'rdx', 'rbx', 'rbp' }",
  "  for vi, o in { { allocatable = x86.ALLOCATABLE }, { allocatable = small }, { allocatable = x86.ALLOCATABLE, reserved = { 'rcx' } }, { allocatable = x86.ALLOCATABLE } } do",
  "    local okc, cr = pcall(regalloc.color, insns, mkTemps(vi == 4), o)",
  "    if not okc then table.insert(out, 'R' .. vi .. ' err ' .. tostring(cr)) else",
  "      local b = {} for _, bl in cr.blocks do table.insert(b, bl.first .. '-' .. bl.last .. '>' .. table.concat(bl.succ, '.')) end",
  "      local al = {} for t = 1, lf.nextTemp do local a = cr.aliasOf(t) if a ~= t then table.insert(al, t .. '>' .. a) end end",
  "      table.insert(out, 'R' .. vi .. ' C ' .. iterKV(cr.color) .. ' S ' .. L(cr.spilled) .. ' K ' .. table.concat(b, ' ') .. ' A ' .. table.concat(al, ' '))",
  "    end",
  "  end",
  "  local lo2 = regalloc.liveOut(insns)",
  "  local v = {} for i = 1, #insns do local s = {} for t in lo2[i] do table.insert(s, tostring(t)) end table.insert(v, table.concat(s, '.')) end",
  "  table.insert(out, 'V ' .. table.concat(v, ' '))",
  "end",
  // frame
  "local policy = {",
  "  analyzeFrame = function(body, sigDesc, regions) return 96, 16, true, nil end,",
  "  rewrite = function(st, ctx)",
  "    for i, o in st.operands do",
  "      if o.kind == 'mem' and o.base and o.base.rc == 'sp' then",
  "        local off = o.dispVal or 0",
  "        if x86.baseMnemonic(st.mnemonic) == 'lea' then ctx.rejectEscape(st.raw, (off % 2 == 0) and st or nil) end",
  "        local r = ctx.regionOf(off, i == 1)",
  "        if r then ctx.emit({ kind = 'insn', mnemonic = 'region', operands = { ctx.slotReg(r.base) }, raw = st.raw }) return end",
  "        ctx.checkBounds(off, o.size or 8, i == 1, st.raw, -128, (off % 16 == 0) and st or nil)",
  "        ctx.emit({ kind = 'insn', mnemonic = 'slot', operands = { ctx.slotReg(off, (o.size or 8) * 8) }, raw = st.raw })",
  "        return",
  "      end",
  "      if o.kind == 'imm' and ctx.immVal(o) == 4096 then ctx.emit({ kind = 'insn', mnemonic = 'imm4096', operands = {}, raw = st.raw }) return end",
  "    end",
  "    ctx.emit(st)",
  "  end,",
  "}",
  "local regions = { { base = 32, size = 16, anchored = false }, { base = 0, size = 8, anchored = true } }",
  "local function frameDump(out, r)",
  "  local ok, o = pcall(framem.preprocess, r, regions, policy, nil)",
  "  if not ok then table.insert(out, 'frame err ' .. tostring(o)) return end",
  "  local p = {}",
  "  for _, st in o do",
  "    local s = st.kind .. ':' .. tostring(st.mnemonic)",
  "    if st.mnemonic == 'slot' or st.mnemonic == 'region' then s ..= ':' .. ser(st.operands[1]) end",
  "    table.insert(p, s)",
  "  end",
  "  table.insert(out, 'frame ' .. #o .. ' ' .. table.concat(p, ' '))",
  "end",
].join("\n");

stages.push({
  name: "lift",
  inputs: files,
  zigArg: "files",
  lua: [
    "local detect = require('./sarcasm/detect')",
    "local x86parse = require('./sarcasm/x86_64_parse')",
    SER,
    LIFT_DUMP,
    "local out = {}",
    "table.insert(out, 'yolo ' .. ser(framem.yoloSlotReg(3, 32)) .. ' ' .. ser(framem.yoloSlotReg(0)) .. ' ' .. ser(framem.slotReg(-8)))",
    "for line in string.gmatch(INPUT, '[^\\n]+') do",
    "  local text = FS.readfile(line)",
    "  local _, syn = detect.detect(text)",
    "  local ok, r = pcall(x86parse.parseString, text, syn or 'att', '<in>')",
    "  if ok then",
    "    table.insert(out, 'file')",
    "    frameDump(out, r)",
    "    liftDump(out, r)",
    "  else",
    "    table.insert(out, 'file err')",
    "  end",
    "end",
    "print(table.concat(out, '\\n'))",
  ].join("\n"),
});

// framecalls: frame.zig's context against the REAL policy. Upstream's whole driver runs on every
// corpus file (sarcasm.main --x86_64 -S, as the S0 oracle runs it) with frame.preprocess wrapped
// so that every call x86_64_frame's policy makes into the frame context (regionOf, checkBounds,
// rejectEscape, slotReg) is logged with its arguments and upstream's result. The Zig side reads
// that log and REPLAYS each call into frame.zig's Ctx (the same frame size and regions, the same
// default file), printing its own result; the two must be equal line for line. Lines that only
// carry context (F file, P frame size + regions, O output count) are echoed.
// xframe: x86_64_frame, phase by phase. A patched COPY of upstream's module
// (sarcasm/x86_64_frame_cp.luau) stops analyzeFrame at a checkpoint line and hands its locals to
// the harness; the driver itself keeps the unpatched module (plus a state getter, appended). For
// every analyzeFrame call under the real driver the harness writes the call's full input
// ("A <iser>": statements with identity, sigDesc, regions, the stack-buffer table; the x86_*
// marks of a previous run are left out — analyzeFrame clears every one of them first, upstream
// 685–719) and the checkpoint state ("K ..."); the port reads each A, runs to the same
// checkpoint, and prints its K. Each checkpoint names its upstream line and the exact text there,
// so a moved line fails loudly instead of patching the wrong place.
interface Checkpoint { n: number; afterLine: number; anchor: string; next?: string; dump: string }
const XF_CHECKPOINTS: Checkpoint[] = [{
  n: 1,
  afterLine: 1189,
  anchor: "\t\tor (subBytes + spillBytes)",
  dump: "{ D0 = D0, rbpNorm = rbpNorm, frameSize = frameSize, prologueEnd = prologueEnd, usesRbp = usesRbp, fpDepth = fpDepth, depth = depth, subBytes = subBytes, spillBytes = spillBytes, pstack = pstack, frameAlignReq = frameAlignReq, frameAndDepth = frameAndDepth, frameAndIdx = frameAndIdx, frameAndSeen = frameAndSeen, cloneRetProofRan = cloneRetProofRan, yoloCount = yoloCount, yoloBase = yoloBase, sigHasFp = sigHasFp, bufRepRegs = bufRepRegs, bufProbeRanges = bufProbeRanges, bufProbeSuppress = bufProbeSuppress, bufB2DeclRaw = bufB2DeclRaw, targeted = targeted, labelAt = labelAt, nextInsn = nextInsn }",
}, {
  n: 2,
  afterLine: 3211,
  anchor: "\tend",
  next: "\t-- Verify epilogue teardown regions: from the instruction after a teardown starter to a",
  dump: "{ body = body, depthIn = depthIn, savesIn = savesIn, fpIn = fpIn, smapIn = smapIn, leaMemOnlyCache = leaMemOnlyCache }",
}];
const XF_STOP = Math.max(...XF_CHECKPOINTS.map((c) => c.n));
const XF_CLEARED = ["x86_prologue", "x86_depth", "x86_saves", "x86_unpairedPop", "x86_spillPop", "x86_flagsPop", "x86_teardownStart", "x86_teardown", "x86_fp", "x86_spRecover", "x86_saveStore", "x86_carrierLoad", "x86_leaSave", "x86_carrierCallArg", "x86_spSave", "x86_dropRestore", "x86_midSp", "x86_regionCarrier", "x86_aliasOff", "x86_aliasSaveIdx", "x86_midAnd", "x86_preAnd", "x86_postAnd", "x86_smap", "x86_b2band", "x86StackBufAccess", "x86StackBufIdx", "x86StackBufRep", "x86StackBufLea", "x86StackBufAddr", "x86StackBufLeaValue", "x86StackBufLeaValueComputed", "x86_alignKeyed", "x86_alignAndBase"];
{
  const src = readFileSync(`${dir}/sarcasm/x86_64_frame.luau`, "latin1").split("\n");
  for (const c of XF_CHECKPOINTS) {
    if (src[c.afterLine - 1] !== c.anchor) throw new Error(`xframe checkpoint ${c.n}: upstream line ${c.afterLine} is ${JSON.stringify(src[c.afterLine - 1])}, not ${JSON.stringify(c.anchor)}`);
    if (c.next !== undefined && src[c.afterLine + 1] !== c.next) throw new Error(`xframe checkpoint ${c.n}: upstream line ${c.afterLine + 2} is ${JSON.stringify(src[c.afterLine + 1])}, not ${JSON.stringify(c.next)}`);
  }
  const ret = src.lastIndexOf("return x86_64_frame");
  if (ret < 0) throw new Error("xframe: no `return x86_64_frame` in upstream's module");
  const getter = "function x86_64_frame.__getSb() return sbCanon, sbResolving end";
  const setter = "function x86_64_frame.__setSb(c, r) sbCanon = c; sbResolving = r end";
  // written back BYTE FOR BYTE (latin1, as read): a default UTF-8 write would re-encode every
  // non-ASCII byte of upstream's source (its messages' em dashes among them)
  const orig = [...src];
  orig.splice(ret, 0, getter);
  await writeFile(`${dir}/sarcasm/x86_64_frame.luau`, orig.join("\n"), "latin1");
  const cp = [...src];
  cp.splice(ret, 0, setter);
  for (const c of [...XF_CHECKPOINTS].sort((x, y) => y.afterLine - x.afterLine)) {
    // the hook records every checkpoint it passes and stops the run at the last one
    cp.splice(c.afterLine, 0, `\tif x86_64_frame.__cp and x86_64_frame.__cp(${c.n}, ${c.dump}) then return 0 end`);
  }
  await writeFile(`${dir}/sarcasm/x86_64_frame_cp.luau`, cp.join("\n"), "latin1");
}

// extra: zilc's own inputs run after the corpus, for branches no Fil-C test reaches
interface SeqStage { name: string; lua: string; keep?: (line: string) => boolean; extra?: string[] }
const frameBranches = readdirSync(`${REPO}/tests/sarcasm/frame-branches`).filter((n) => n.endsWith(".s")).sort()
  .map((n) => `${REPO}/tests/sarcasm/frame-branches/${n}`);
const seqStages: SeqStage[] = [{
  name: "framecalls",
  lua: [
    SER,
    "local framem = require('./sarcasm/frame')",
    "local sarcasm = require('./sarcasm/sarcasm')",
    "local function hx(s) if s == nil then return '-' end return 'x' .. (string.gsub(s, '.', function(c) return string.format('%02x', string.byte(c)) end)) end",
    "local function nv(x) if x == nil then return '-' end return tostring(x) end",
    "local function stOf(st) if not st then return '- -' end return hx(st.file) .. ' ' .. nv(st.line) end",
    "local out = {}",
    "local orig = framem.preprocess",
    "framem.preprocess = function(body, regions, policy, sigDesc)",
    "  local regs, rl = {}, {}",
    "  for i, r in (regions or {}) do table.insert(rl, nv(r.base) .. ',' .. nv(r.size) .. ',' .. tostring(r.anchored and true or false)); regs[r] = i end",
    "  local proxyOf = {}",
    "  local wrapped = {}",
    "  wrapped.analyzeFrame = function(...)",
    "    local a, b, c, d = policy.analyzeFrame(...)",
    "    table.insert(out, 'P ' .. nv(a) .. ' ' .. (#rl > 0 and table.concat(rl, ';') or '-'))",
    "    return a, b, c, d",
    "  end",
    "  wrapped.rewrite = function(st, ctx)",
    "    local p = proxyOf[ctx]",
    "    if not p then",
    "      p = {}",
    "      for k, v in ctx do p[k] = v end",
    "      p.regionOf = function(off, dyn)",
    "        local r = ctx.regionOf(off, dyn)",
    "        table.insert(out, 'R ' .. nv(off) .. ' ' .. tostring(dyn and true or false) .. '\\t' .. (r and tostring(regs[r]) or 'nil'))",
    "        return r",
    "      end",
    "      p.checkBounds = function(off, width, isWrite, raw, lowBound, st2)",
    "        local line = 'C ' .. nv(off) .. ' ' .. nv(width) .. ' ' .. tostring(isWrite and true or false) .. ' ' .. hx(raw) .. ' ' .. nv(lowBound) .. ' ' .. stOf(st2)",
    "        local ok, e = pcall(ctx.checkBounds, off, width, isWrite, raw, lowBound, st2)",
    "        table.insert(out, line .. '\\t' .. (ok and 'ok' or ('E ' .. tostring(e))))",
    "        if not ok then error(e, 0) end",
    "      end",
    "      p.rejectEscape = function(raw, st2)",
    "        local line = 'X ' .. hx(raw) .. ' ' .. stOf(st2)",
    "        local ok, e = pcall(ctx.rejectEscape, raw, st2)",
    "        table.insert(out, line .. '\\t' .. (ok and 'ok' or ('E ' .. tostring(e))))",
    "        if not ok then error(e, 0) end",
    "      end",
    "      p.slotReg = function(off, width)",
    "        local r = ctx.slotReg(off, width)",
    "        table.insert(out, 'S ' .. nv(off) .. ' ' .. nv(width) .. '\\t' .. ser(r))",
    "        return r",
    "      end",
    "      proxyOf[ctx] = p",
    "    end",
    "    return policy.rewrite(st, p)",
    "  end",
    "  local res = orig(body, regions, wrapped, sigDesc)",
    "  table.insert(out, 'O ' .. #res)",
    "  return res",
    "end",
    "for line in string.gmatch(INPUT, '[^\\n]+') do",
    "  table.insert(out, 'F ' .. hx(line))",
    "  sarcasm.main({ 'sarcasm', '--x86_64', '-S', '-o', '/dev/null', line })",
    "end",
    // The boundary sweep: the corpus never touches some edges (an access exactly at the lower
    // bound, for one), so a policy drives every context function over a grid of edges, through
    // the same wrapped preprocess (rejections caught so the sweep goes on).
    "do",
    "  local SW = 'sweep.s'",
    "  table.insert(out, 'F ' .. hx(SW))",
    "  local errm = require('./sarcasm/err')",
    "  errm.setDefaultFile(SW)",
    "  local sts = { { file = SW, line = 7 }, { line = 9 }, false }",
    "  local sweep = {",
    "    analyzeFrame = function() return 64, 0, false, nil end,",
    "    rewrite = function(st, ctx)",
    "      for off = -132, 100 do",
    "        for _, w in { 1, 8, 16 } do",
    "          for _, iw in { false, true } do",
    "            for _, lb in { false, -128, 0 } do",
    "              for _, s2 in sts do",
    "                pcall(ctx.checkBounds, off, w, iw, (off % 3 == 0) and nil or 'raw text', lb or nil, s2 or nil)",
    "              end",
    "            end",
    "          end",
    "        end",
    "      end",
    "      for _, off in { -0.5, 0.25, 63.5, 1e300 } do pcall(ctx.checkBounds, off, 8, true, 'frac', nil, nil) end",
    "      for off = -12, 60 do ctx.regionOf(off, false); ctx.regionOf(off, true) end",
    "      ctx.regionOf(15.5, true); ctx.regionOf(-0.0, true)",
    "      for _, off in { -136, -8, 0, 8, 1.5, 4096, 1e20 } do ctx.slotReg(off); ctx.slotReg(off, 32) end",
    "      for _, s2 in sts do pcall(ctx.rejectEscape, nil, s2 or nil); pcall(ctx.rejectEscape, 'lea 8(%rsp), %rax', s2 or nil) end",
    "      ctx.emit(st)",
    "    end,",
    "  }",
    "  framem.preprocess({ { kind = 'insn', mnemonic = 'nop', operands = {}, raw = 'nop' } },",
    "    { { base = 0, size = 16, anchored = true }, { base = 16, size = 8 }, { base = 40, size = 8, anchored = false } }, sweep, nil)",
    "end",
    // sarcasm.main prints its own diagnostics: the log goes to a file, not stdout
    "local h = fs.open(LOGFILE, 'w+'); fs.write(h, table.concat(out, '\\n') .. '\\n'); fs.close(h)",
  ].join("\n"),
}];

seqStages.push({
  name: "xframe",
  keep: (l) => l.startsWith("F ") || l.startsWith("K"),
  extra: frameBranches,
  lua: [
    SER,
    "local xf = require('./sarcasm/x86_64_frame')",
    "local cp = require('./sarcasm/x86_64_frame_cp')",
    "local sarcasm = require('./sarcasm/sarcasm')",
    `local CLEARED = {} for _, k in { ${XF_CLEARED.map((k) => JSON.stringify(k)).join(", ")} } do CLEARED[k] = true end`,
    // the capture's strings are READ back, so their escapes are fixed-width (\ddd): qs's
    // unpadded ones are ambiguous before a digit (byte 25 then "6" would read as \256)
    "local function qsx(v) return '\"' .. (string.gsub(v, '[%c\"\\\\\\128-\\255]', function(c) return string.format('\\\\%03d', string.byte(c)) end)) .. '\"' end",
    "local function mkIser()",
    "  local ids, n = {}, 0",
    "  local function key(k) if type(k) == 'number' then return '#' .. tostring(k) end if string.match(k, '^[%a_][%w_]*$') then return k end return qsx(k) end",
    "  local iser",
    "  iser = function(v)",
    "    local t = type(v)",
    "    if t == 'nil' then return 'nil' end",
    "    if t == 'string' then return qsx(v) end",
    "    if t == 'number' or t == 'boolean' then return tostring(v) end",
    "    if t ~= 'table' then error('iser: cannot serialize a ' .. t) end",
    "    if ids[v] then return '*' .. ids[v] end",
    "    n += 1; ids[v] = n",
    "    local id = n",
    "    local keys = {}",
    "    for k in v do if not (type(k) == 'string' and CLEARED[k]) then table.insert(keys, { r = key(k), k = k }) end end",
    "    table.sort(keys, function(a, b) return a.r < b.r end)",
    "    local parts = {}",
    "    for _, e in keys do table.insert(parts, e.r .. '=' .. iser(v[e.k])) end",
    "    return '&' .. id .. '{' .. table.concat(parts, ',') .. '}'",
    "  end",
    "  return iser",
    "end",
    "local function nv(x) if x == nil then return 'nil' end if type(x) == 'string' then return qs(x) end return tostring(x) end",
    "local function numKeys(t) local ks = {} for k in (t or {}) do table.insert(ks, k) end table.sort(ks) return ks end",
    "local function strKeys(t) local ks = {} for k in (t or {}) do table.insert(ks, k) end table.sort(ks) return ks end",
    "local DUMP = {}",
    "DUMP[1] = function(K)",
    "  local p = { 'K1' }",
    "  for _, f in { 'D0', 'rbpNorm', 'frameSize', 'prologueEnd', 'usesRbp', 'fpDepth', 'depth', 'subBytes', 'spillBytes', 'frameAlignReq', 'frameAndDepth', 'frameAndIdx', 'frameAndSeen', 'cloneRetProofRan', 'yoloCount', 'yoloBase', 'sigHasFp', 'bufProbeSuppress' } do table.insert(p, f .. '=' .. nv(K[f])) end",
    "  local ps = {} for _, e in K.pstack do table.insert(ps, e.name .. '@' .. tostring(e.depth)) end",
    "  table.insert(p, 'pstack=[' .. table.concat(ps, ',') .. ']')",
    "  local rr = {} for _, k in numKeys(K.bufRepRegs) do table.insert(rr, tostring(k)) end",
    "  table.insert(p, 'rep=[' .. table.concat(rr, ',') .. ']')",
    "  if K.bufProbeRanges then local pr = {} for _, r in K.bufProbeRanges do table.insert(pr, tostring(r.lo) .. ',' .. tostring(r.hi) .. ',' .. qs(r.id)) end table.insert(p, 'probe=[' .. table.concat(pr, ';') .. ']') else table.insert(p, 'probe=nil') end",
    "  if K.bufB2DeclRaw then local b = {} for _, k in numKeys(K.bufB2DeclRaw) do local l = {} for _, sb in K.bufB2DeclRaw[k] do table.insert(l, qs(sb.id) .. ',' .. nv(sb.lo) .. ',' .. nv(sb.hi) .. ',' .. nv(sb.base)) end table.insert(b, tostring(k) .. ':[' .. table.concat(l, ';') .. ']') end table.insert(p, 'b2=[' .. table.concat(b, ' ') .. ']') else table.insert(p, 'b2=nil') end",
    "  local tg = {} for _, k in strKeys(K.targeted) do table.insert(tg, qs(k)) end",
    "  table.insert(p, 'targeted=[' .. table.concat(tg, ',') .. ']')",
    "  local la = {} for _, k in strKeys(K.labelAt) do table.insert(la, qs(k) .. ':' .. tostring(K.labelAt[k])) end",
    "  table.insert(p, 'labelAt=[' .. table.concat(la, ',') .. ']')",
    "  local ni = {} for i = 1, #K.nextInsn do table.insert(ni, tostring(K.nextInsn[i])) end",
    "  table.insert(p, 'nextInsn=[' .. table.concat(ni, ',') .. ']')",
    "  return table.concat(p, ' ')",
    "end",
    // checkpoint 2: per statement, the fixpoint's state and the marks it sets (smap in
    // iteration order — its order is upstream's output)
    "local function dDump(d) if d == nil then return 'nil' end return tostring(d) end",
    "local function svDump(sv) if sv == nil then return 'nil' end if sv == 'dyn' then return 'dyn' end local o = {} for _, e in sv do table.insert(o, qs(e.name) .. '/' .. nv(e.num) .. '/' .. nv(e.depth) .. '/' .. nv(e.spill) .. '/' .. nv(e.redefined)) end return '[' .. table.concat(o, ',') .. ']' end",
    "local SMF = { 'name', 'num', 'depth', 'saveIdx', 'redefined', 'form', 'slot', 'off', 'space', 'roff', 'rbase', 'rspace', 'conflict' }",
    "local function smDump(m) if m == nil then return 'nil' end local o = {} for k, e in m do local f = {} for _, x in SMF do table.insert(f, nv(e[x])) end table.insert(o, qs(k) .. ':' .. table.concat(f, ',')) end return '{' .. table.concat(o, ';') .. '}' end",
    "local function repDump(r) if r == nil then return 'nil' end local s = 'nil' for k, v in r do if k ~= 'lo' and k ~= 'hi' and k ~= 'id' then s = qs(k) .. ':' .. nv(v.K) .. ',' .. nv(v.num) .. ',' .. nv(v.isWrite) end end return nv(r.lo) .. ',' .. nv(r.hi) .. ',' .. qs(r.id) .. '|' .. s end",
    "DUMP[2] = function(K)",
    "  local lines = {}",
    "  for i, st in K.body do",
    "    local cca = st.x86_carrierCallArg and (qs(st.x86_carrierCallArg.name) .. '/' .. nv(st.x86_carrierCallArg.form)) or 'nil'",
    "    local lvc, rep, lmo = st.x86StackBufLeaValueComputed, st.x86StackBufRep, K.leaMemOnlyCache[st]",
    "    if K.depthIn[i] ~= nil or lvc ~= nil or st.x86_carrierCallArg or rep or lmo ~= nil then",
    "      table.insert(lines, 'K2 ' .. i .. ' d=' .. dDump(K.depthIn[i]) .. ' s=' .. svDump(K.savesIn[i]) .. ' f=' .. nv(K.fpIn[i]) .. ' m=' .. smDump(K.smapIn[i]) .. ' lvc=' .. nv(lvc) .. ' cca=' .. cca .. ' rep=' .. repDump(rep) .. ' lmo=' .. nv(lmo))",
    "    end",
    "  end",
    "  table.insert(lines, 'K2 end')",
    "  return table.concat(lines, '\\n')",
    "end",
    "local out = {}",
    "local origA = xf.analyzeFrame",
    "xf.analyzeFrame = function(body, sigDesc, regions)",
    "  local canon, resolving = xf.__getSb()",
    "  table.insert(out, 'A ' .. mkIser()({ body = body, sigDesc = sigDesc, regions = regions, canon = canon, resolving = resolving }))",
    "  cp.__setSb(canon, resolving)",
    "  local last = nil",
    `  cp.__cp = function(n, K) table.insert(out, DUMP[n](K)) last = n return n == ${XF_STOP} end`,
    "  local ok, e = pcall(cp.analyzeFrame, body, sigDesc, regions)",
    `  if last ~= ${XF_STOP} then table.insert(out, 'K err ' .. tostring(e)) end`,
    "  return origA(body, sigDesc, regions)",
    "end",
    "for line in string.gmatch(INPUT, '[^\\n]+') do",
    "  table.insert(out, 'F ' .. qsx(line))",
    "  sarcasm.main({ 'sarcasm', '--x86_64', '-S', '-o', '/dev/null', line })",
    "end",
    "local h = fs.open(LOGFILE, 'w+'); fs.write(h, table.concat(out, '\\n') .. '\\n'); fs.close(h)",
  ].join("\n"),
});

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
for (const st of seqStages.filter((s) => !want.length || want.includes(s.name))) {
  const inFile = `${dir}/${st.name}.in`;
  const logFile = `${dir}/${st.name}.luau.out`;
  const inputs = [...files, ...(st.extra ?? [])];
  await writeFile(inFile, inputs.join("\n") + "\n");
  const lua = [
    "local fs = require('@lute/fs')",
    "local FS = { readfile = function(p) local h = fs.open(p, 'r'); local t = fs.read(h); fs.close(h); return t end }",
    `local INPUT = FS.readfile(${JSON.stringify(inFile)})`,
    `local LOGFILE = ${JSON.stringify(logFile)}`,
    st.lua,
  ].join("\n");
  await writeFile(`${dir}/${st.name}.luau`, lua + "\n");
  await must([minilute, `${dir}/${st.name}.luau`]);
  const log = readFileSync(logFile, "latin1");
  const zigOut = await must([exe, st.name, logFile]);
  await writeFile(`${dir}/${st.name}.zig.out`, zigOut);
  // both sides compared as BYTES (latin1): the log is read that way, and stdout arrives
  // UTF-8-decoded, so a non-ASCII byte (a message's em dash) would never compare equal
  const zigBytes = readFileSync(`${dir}/${st.name}.zig.out`, "latin1");
  const a = log.trimEnd().split("\n").filter(st.keep ?? (() => true)), b = zigBytes.trimEnd().split("\n");
  const bad: number[] = [];
  for (let i = 0; i < Math.max(a.length, b.length); i++) if (a[i] !== b[i]) bad.push(i);
  const kinds = new Map<string, number>();
  for (const l of a) kinds.set(l[0], (kinds.get(l[0]) ?? 0) + 1);
  console.log(`${st.name}: ${files.length} files${st.extra?.length ? ` + ${st.extra.length} of zilc's` : ""}, ${a.length} log lines (${[...kinds].map(([k, n]) => `${k} ${n}`).join(", ")}), ${bad.length} differ`);
  for (const i of bad.slice(0, 6)) console.log(`  line ${i + 1}\n    luau: ${a[i]?.slice(0, 200)}\n    zig:  ${b[i]?.slice(0, 200)}`);
  if (bad.length) failed++;
}
console.log(failed ? `FAILED: ${failed} stage(s) differ` : "OK: every stage equal to upstream's");
process.exit(failed ? 1 : 0);
