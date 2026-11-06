// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// The benchmark suite (cmem/testing.md planned gate 4; upgrade stage C, cmem/upstream.md). Owner,
// 2026-11-05, on what it runs: "upstream's plus our zig only ports of upstreams plus new ones that
// we write to test the zig only version specifically". Three groups:
//   upstream   Fil-C's own filc/benchmarks, read from the fetched Fil-C package (nothing of
//              Fil-C's is copied into zilc), built as upstream's Makefile builds them: Fil-C's
//              clang/clang++ -O3 -g with each program's flags, against plain `zig cc`/`zig c++`
//              with the same flags (the native baseline). pcre_benchmark is left out: it needs a
//              libpcre2 built by Fil-C.
//   zig-port   tests/bench/zig/{nbody,spectralnorm,fannkuch,binarytrees}.zig: upstream's
//              algorithms in Zig, through `zilc build -O <mode>` against `zig build-exe -O <mode>`.
//   zig        tests/bench/zig/*: zilc's own programs for its Zig path (containers on the C
//              allocator, strings and sorting, dispatch, slices), and tests/bench/interop (Zig ⇄ C).
// Every program prints a result; the plain and zilc builds must print the same one (masked for the
// two upstream programs that print timings). Runs alternate plain/zilc after one warm-up each, so
// drift hits both; per binary: median, min, and the noise (median absolute deviation / median).
// A slowdown is reported as "within noise" when it is inside twice the larger noise.
//
//   bun tools/bench/bench.ts [run]          env: REPEATS (5), MODES ("ReleaseSafe ReleaseFast"),
//                                            ONLY (regex over names), LABEL (default: zilc's
//                                            version), OUT (default $WORK/bench/<LABEL>), JOBS
//                                            (parallel builds, default 1: build times stay honest)
//   bun tools/bench/bench.ts compare <old.json> <new.json>   version against version
// Output: <OUT>/results.json, <OUT>/summary.md (also printed). Linux only, like every tool.

import { createHash } from "node:crypto";
import { readFile, writeFile } from "node:fs/promises";
import { cpus, loadavg } from "node:os";
import {
  ARGS, env, envInt, exists, filc, filcPackageDir, FILC_VERSION, HOME, linuxOnly, mkdirp, must, pool, REPO, rmrf, run, size, WORK, ZIG,
} from "../lib/tool.ts";

await linuxOnly(import.meta);

type Group = "upstream" | "zig-port" | "zig";
interface Prog {
  name: string;
  group: Group;
  lang: "c" | "c++" | "zig";
  files: string[];
  args: string[];
  cflags?: string[];
  /** Only for the plain (native) build. */
  plainCflags?: string[];
  /** Printed beside the figure: what the number does and does not mean. */
  note?: string;
  stdinFile?: string;
  entry?: string;
  /** How the two outputs are compared: exactly, after a mask, or not at all (timings only). */
  check: "exact" | "mask" | "none";
  mask?: RegExp;
}
interface Entry {
  program: string;
  group: Group;
  mode: string;
  variant: "plain" | "zilc";
  /** The program's arguments: a version comparison is only meaningful on the same input. */
  args: string[];
  buildSeconds: number | null;
  size: number | null;
  strippedSize: number | null;
  runs: number[];
  median: number | null;
  min: number | null;
  noise: number | null;
  exit: number | null;
  outputHash: string | null;
}

const median = (xs: number[]) => {
  const s = [...xs].sort((a, b) => a - b);
  return s.length ? (s.length % 2 ? s[(s.length - 1) / 2] : (s[s.length / 2 - 1] + s[s.length / 2]) / 2) : NaN;
};
const noiseOf = (xs: number[]) => {
  const m = median(xs);
  return m > 0 ? median(xs.map((x) => Math.abs(x - m))) / m : NaN;
};
const f = (x: number | null, d = 3) => (x === null || Number.isNaN(x) ? "—" : x.toFixed(d));

if (ARGS[0] === "compare") {
  const [a, b] = await Promise.all([ARGS[1], ARGS[2]].map(async (p) => JSON.parse(await readFile(p, "utf8"))));
  console.log(`old: ${a.label} (${a.date}) → new: ${b.label} (${b.date})\n`);
  console.log("| program | mode | variant | old s | new s | new/old | noise | build new/old | size new/old |");
  console.log("| --- | --- | --- | --- | --- | --- | --- | --- | --- |");
  for (const e of b.entries as Entry[]) {
    const o = (a.entries as Entry[]).find((x) => x.program === e.program && x.mode === e.mode && x.variant === e.variant);
    if (!o || !o.median || !e.median) continue;
    const r = e.median / o.median, nz = Math.max(o.noise ?? 0, e.noise ?? 0);
    const sameInput = JSON.stringify(o.args ?? null) === JSON.stringify(e.args ?? null);
    const flag = !sameInput ? " ⚠️ different input" : Math.abs(r - 1) <= 2 * nz ? " (within noise)" : "";
    const ratio = (x: number | null, y: number | null) => (x && y ? (x / y).toFixed(2) : "—");
    console.log(`| ${e.program} | ${e.mode} | ${e.variant} | ${f(o.median)} | ${f(e.median)} | ${r.toFixed(2)}${flag} | ${(nz * 100).toFixed(1)}% | ${ratio(e.buildSeconds, o.buildSeconds)} | ${ratio(e.strippedSize, o.strippedSize)} |`);
  }
  process.exit(0);
}

// ---- the programs ----
const up = `${await filcPackageDir()}/filc/benchmarks`;
if (!(await exists(`${up}/n-body.c`))) throw new Error(`no ${up}: fetch Fil-C's sources first (e.g. \`zig build pure-zig\`)`);
const tb = `${REPO}/tests/bench`;
const out = env("OUT", "");
const repeats = envInt("REPEATS", 5);
const modes = env("MODES", "ReleaseSafe ReleaseFast").split(/\s+/).filter(Boolean);
const only = new RegExp(env("ONLY", "."));

const programs: Prog[] = ([
  // upstream (filc/benchmarks/Makefile's flags; the sizes are zilc's, chosen to run ~0.2–1 s natively
  // on an idle machine, 2026-11-06; richards has no size argument: -Dbench100 is its largest)
  { name: "deltablue", group: "upstream", lang: "c", files: [`${up}/deltablue.c`], args: ["2000"], check: "mask", mask: /\t[0-9.e+-]+ms/g },
  // richards includes Fil-C's <stdfil.h> (zprintf, zgc_alloc); the plain build gets tests/bench/compat's.
  { name: "richards", group: "upstream", lang: "c", files: [`${up}/richards.c`], cflags: ["-Dbench100"], plainCflags: ["-I", `${tb}/compat`], args: [], check: "exact" },
  { name: "fannkuch-redux", group: "upstream", lang: "c", files: [`${up}/fannkuch-redux.c`], args: ["-t", "1", "11"], check: "exact" },
  // n-body prints a pointer (`r = 0x…`), different on every run; the energies are compared.
  { name: "n-body", group: "upstream", lang: "c", files: [`${up}/n-body.c`], cflags: ["-march=ivybridge"], args: ["10000000"], check: "mask", mask: /r = 0x[0-9a-f]+/g },
  { name: "n-body-2", group: "upstream", lang: "c", files: [`${up}/n-body-2.c`], cflags: ["-lm"], args: ["5000000"], check: "exact" },
  { name: "spectralnorm", group: "upstream", lang: "c", files: [`${up}/spectralnorm.c`], cflags: ["-mavx"], args: ["4000"], check: "exact" },
  { name: "reversecomplement", group: "upstream", lang: "c", files: [`${up}/reversecomplement.c`], args: [], stdinFile: "fasta", check: "exact" },
  { name: "binarytrees", group: "upstream", lang: "c++", files: [`${up}/binarytrees.cpp`], args: ["16"], check: "exact",
    note: "upstream's version never frees a tree (written for Fil-C's GC) and runs one thread per hardware thread: under Fil-C the GC reclaims them; plain musl leaks every tree and serializes all threads on its malloc lock. A real result for this program, not a measure of Fil-C's cost (zig-binarytrees frees, single-threaded)" },
  { name: "fannkuch-redux-2", group: "upstream", lang: "c++", files: [`${up}/fannkuch-redux-2.cpp`], args: ["10"], check: "exact" },
  { name: "stepanov_container", group: "upstream", lang: "c++", files: [`${up}/stepanov_container.cpp`], args: [], check: "none" },
  // upstream's algorithms in Zig
  ...["nbody", "spectralnorm", "fannkuch", "binarytrees"].map((n) => ({ name: `zig-${n}`, group: "zig-port" as Group, lang: "zig" as const, files: [`${tb}/zig/${n}.zig`], args: [], check: "exact" as const })),
  // zilc's own
  ...([["hashmap_churn", ["120"]], ["sort_format", ["600000"]], ["dispatch", ["100000000"]], ["slices", ["100000000", "400"]]] as const)
    .map(([n, args]) => ({ name: n, group: "zig" as Group, lang: "zig" as const, files: [`${tb}/zig/${n}.zig`], args: [...args], check: "exact" as const })),
  { name: "interop", group: "zig", lang: "zig", files: [`${tb}/interop/interop.zig`, `${tb}/interop/kernel.c`], entry: "zig", args: [], check: "exact" },
] as Prog[]).filter((p) => only.test(p.name));

// ---- zilc itself, and the versions ----
const tmp = `${WORK}/bench/.build`;
await rmrf(tmp);
await mkdirp(tmp);
const toolEnv = { ZILC_ZIG: ZIG, ZILC_FILC: filc(), ZIG_LOCAL_CACHE_DIR: env("ZIG_LOCAL_CACHE_DIR", `${HOME}/.cache/zilc-bench`) };
await must([ZIG, "build", "--build-file", `${REPO}/build.zig`, "--prefix", `${tmp}/zilc`, "-Doptimize=ReleaseSafe"], { env: toolEnv });
const zilc = `${tmp}/zilc/bin/zilc`;
const zilcVersion = (await must([zilc, "--version"])).trim().split("\n")[0];
const label = env("LABEL", zilcVersion.replace(/^zilc\s+/, "").split(/\s/)[0]);
const outDir = out || `${WORK}/bench/${label}`;
await rmrf(outDir);
await mkdirp(`${outDir}/bin`);
const filcClang = filc();
const filcClangxx = filcClang.replace(/clang$/, "clang++");

// reversecomplement's input: a FASTA file (three sequences, ~60 MB), from a fixed LCG.
const fasta = `${outDir}/input.fasta`;
{
  let seed = 42;
  const acgt = "ACGTacgtNRYKMS";
  const lines: string[] = [];
  for (const [title, n] of [[">ONE Homo sapiens alu", 12_000_000], [">TWO IUB ambiguity codes", 18_000_000], [">THREE Homo sapiens frequency", 30_000_000]] as const) {
    lines.push(title);
    let line = "";
    for (let i = 0; i < n; i++) {
      seed = (seed * 3877 + 29573) % 139968;
      line += acgt[seed % (seed % 7 === 0 ? 14 : 4)];
      if (line.length === 60) (lines.push(line), (line = ""));
    }
    if (line) lines.push(line);
  }
  await writeFile(fasta, lines.join("\n") + "\n");
}

// `zig cc` reads -march with -mcpu's syntax (cmem/toolchain-quirks.md Z-cc-4).
const zigFlags = (fl: string[]) => fl.map((x) => (x.startsWith("-march=") ? `-mcpu=${x.slice(7).replaceAll("-", "_")}` : x));

interface Job { p: Prog; mode: string; variant: "plain" | "zilc"; bin: string; argv: string[] }
const jobs: Job[] = [];
for (const p of programs) {
  for (const mode of p.lang === "zig" ? modes : ["O3"]) {
    for (const variant of ["plain", "zilc"] as const) {
      const bin = `${outDir}/bin/${p.name}-${mode}-${variant}`;
      let argv: string[];
      if (p.lang !== "zig") {
        const cc = variant === "zilc" ? [p.lang === "c" ? filcClang : filcClangxx] : [ZIG, p.lang === "c" ? "cc" : "c++", "-target", "x86_64-linux-musl"];
        // Fil-C's clang targets x86-64-v2 by default; `zig cc -target …` targets baseline x86-64.
        // The plain build gets Fil-C's default CPU unless the program names one, so both sides
        // compile for the same machine (upstream's fannkuch-redux needs SSSE3/SSE4.1).
        const named = (p.cflags ?? []).some((x) => x.startsWith("-march="));
        const flags = variant === "zilc" ? p.cflags ?? [] : [...(named ? [] : ["-mcpu=x86_64_v2"]), ...zigFlags(p.cflags ?? []), ...(p.plainCflags ?? [])];
        argv = [...cc, "-O3", "-g", "-o", bin, ...p.files, ...flags, ...(variant === "plain" ? ["-lpthread"] : [])];
      } else if (variant === "plain") {
        argv = [ZIG, "build-exe", "-O", mode, "-lc", "-target", "x86_64-linux-musl", `-femit-bin=${bin}`, ...p.files];
      } else {
        // --no-cache: zilc's object cache (KI-22 lever c) would turn a rebuild into a lookup.
        argv = [zilc, "build", "--no-cache", "-O", mode, ...(p.entry ? ["--entry", p.entry] : []), "-o", bin, ...p.files];
      }
      jobs.push({ p, mode, variant, bin, argv });
    }
  }
}

// ---- build ----
// Build time means compiling THIS program: the parts every program shares (musl, compiler-rt,
// libc++ in Zig's global cache) are built once first by a warm-up, and every timed build gets an
// empty local cache of its own (else `zig cc` / `zig build-exe` return a cached binary in ~0 s).
// One at a time by default (JOBS=1), so no build competes with another for the CPU.
{
  const hz = `${tmp}/warm.zig`, hc = `${tmp}/warm.c`, hx = `${tmp}/warm.cpp`;
  await writeFile(hz, "pub fn main() void {}\n");
  await writeFile(hc, "int main(void) { return 0; }\n");
  await writeFile(hx, "#include <vector>\nint main() { std::vector<int> v(3); return (int)v.size() - 3; }\n");
  for (const mode of modes) {
    await run([ZIG, "build-exe", "-O", mode, "-lc", "-target", "x86_64-linux-musl", `-femit-bin=${tmp}/warm-${mode}`, hz], { env: toolEnv });
    await run([zilc, "build", "-O", mode, "-o", `${tmp}/warm-zilc-${mode}`, hz], { env: toolEnv });
  }
  for (const [lang, src] of [["cc", hc], ["c++", hx]]) {
    await run([ZIG, lang, "-target", "x86_64-linux-musl", "-mcpu=x86_64_v2", "-O3", "-o", `${tmp}/warm-${lang}`, src, "-lpthread"], { env: toolEnv });
  }
}
console.log(`building ${jobs.length} binaries (${programs.length} programs; modes ${modes.join(", ")})`);
const built = await pool(jobs, envInt("JOBS", 1), async (j) => {
  const t0 = performance.now();
  const r = await run(j.argv, { env: { ...toolEnv, ZIG_LOCAL_CACHE_DIR: `${j.bin}.cache` }, outFile: `${j.bin}.build.log` });
  await rmrf(`${j.bin}.cache`);
  const secs = (performance.now() - t0) / 1000;
  if (r.code !== 0) console.log(`  BUILD FAILED: ${j.p.name} ${j.mode} ${j.variant} (${j.bin}.build.log)`);
  let stripped: number | null = null;
  if (r.code === 0 && (await run(["strip", "-o", `${j.bin}.stripped`, j.bin])).code === 0) stripped = await size(`${j.bin}.stripped`);
  return { ok: r.code === 0, secs, size: r.code === 0 ? await size(j.bin) : null, stripped };
});

// ---- run: one warm-up each (its output is the one compared), then alternate plain/zilc ----
async function once(j: Job): Promise<{ secs: number; code: number; out: Uint8Array }> {
  const t0 = performance.now();
  const child = Bun.spawn([j.bin, ...j.p.args], { stdin: j.p.stdinFile ? Bun.file(fasta) : "ignore", stdout: "pipe", stderr: "pipe", env: { ...process.env } });
  // stdout and stderr both: Fil-C's zprintf (richards) writes to stderr where the plain build's
  // printf writes to stdout, so the compared output is stdout followed by stderr.
  const [o, e] = await Promise.all([new Response(child.stdout).arrayBuffer(), new Response(child.stderr).arrayBuffer()]);
  const code = await child.exited;
  const outBytes = new Uint8Array(o.byteLength + e.byteLength);
  outBytes.set(new Uint8Array(o), 0);
  outBytes.set(new Uint8Array(e), o.byteLength);
  return { secs: (performance.now() - t0) / 1000, code, out: outBytes };
}
const entries: Entry[] = [];
const notes: string[] = [];
for (let i = 0; i < jobs.length; i += 2) {
  const pair = [jobs[i], jobs[i + 1]], b = [built[i], built[i + 1]];
  const runs: number[][] = [[], []];
  const first: ({ code: number; out: Uint8Array } | null)[] = [null, null];
  if (b[0].ok && b[1].ok) {
    for (let k = 0; k < 2; k++) first[k] = await once(pair[k]);
    for (let r = 0; r < repeats; r++) for (let k = 0; k < 2; k++) runs[k].push((await once(pair[k])).secs);
    const p = pair[0].p;
    const text = (x: Uint8Array) => new TextDecoder().decode(x);
    const norm = (x: Uint8Array) => (p.check === "mask" && p.mask ? text(x).replace(p.mask, "<t>") : text(x));
    if (p.check !== "none" && (norm(first[0]!.out) !== norm(first[1]!.out) || first[0]!.code !== first[1]!.code)) {
      notes.push(`OUTPUT DIFFERS: ${p.name} ${pair[0].mode} (plain exit ${first[0]!.code}, zilc exit ${first[1]!.code})`);
    }
  }
  for (let k = 0; k < 2; k++) {
    const j = pair[k];
    entries.push({
      program: j.p.name, group: j.p.group, mode: j.mode, variant: j.variant, args: j.p.args,
      buildSeconds: b[k].ok ? b[k].secs : null, size: b[k].size, strippedSize: b[k].stripped,
      runs: runs[k], median: runs[k].length ? median(runs[k]) : null, min: runs[k].length ? Math.min(...runs[k]) : null,
      noise: runs[k].length ? noiseOf(runs[k]) : null, exit: first[k]?.code ?? null,
      outputHash: first[k] ? createHash("sha256").update(first[k]!.out).digest("hex").slice(0, 16) : null,
    });
  }
  const [pe, ze] = entries.slice(-2);
  console.log(`  ${pair[0].p.name} ${pair[0].mode}: plain ${f(pe.median)} s, zilc ${f(ze.median)} s`);
}

// ---- results ----
const cpu = cpus()[0]?.model ?? "unknown";
const meta = {
  label, date: new Date().toISOString(), zilc: zilcVersion, zig: (await must([ZIG, "version"])).trim(), filc: FILC_VERSION,
  filcClang: (await must([filcClang, "--version"])).split("\n")[0], machine: { cpu, cores: cpus().length, loadavgAtEnd: loadavg() },
  repeats, modes,
};
await writeFile(`${outDir}/results.json`, JSON.stringify({ ...meta, notes, entries }, null, 1) + "\n");

const rows: string[] = [
  `# Benchmarks: ${label}`, "",
  `${meta.date} · ${meta.zilc} · Zig ${meta.zig} · Fil-C ${meta.filc} · ${cpu}, ${meta.machine.cores} threads · ${repeats} runs each after a warm-up`, "",
  "| group | program | mode | plain s | zilc s | slowdown | noise | build s plain / zilc | stripped KiB plain / zilc |",
  "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
];
const slow: Record<string, number[]> = {};
for (let i = 0; i < entries.length; i += 2) {
  const [pe, ze] = [entries[i], entries[i + 1]];
  const s = pe.median && ze.median ? ze.median / pe.median : null;
  const nz = Math.max(pe.noise ?? 0, ze.noise ?? 0);
  if (s && !programs.find((p) => p.name === pe.program)?.note) (slow[`${pe.group} ${pe.mode}`] ??= []).push(s);
  const kib = (x: number | null) => (x === null ? "—" : (x / 1024).toFixed(0));
  rows.push(`| ${pe.group} | ${pe.program} | ${pe.mode} | ${f(pe.median)} | ${f(ze.median)} | ${s ? `${s.toFixed(2)}×${Math.abs(s - 1) <= 2 * nz ? " (within noise)" : ""}` : "—"} | ${(nz * 100).toFixed(1)}% | ${f(pe.buildSeconds, 1)} / ${f(ze.buildSeconds, 1)} | ${kib(pe.strippedSize)} / ${kib(ze.strippedSize)} |`);
}
const geo = (xs: number[]) => Math.exp(xs.reduce((a, x) => a + Math.log(x), 0) / xs.length);
// (The geometric means leave out programs with a note: their figure is not a cost of Fil-C.)
rows.push("", "Geometric mean slowdown (zilc / plain):", "");
for (const [k, xs] of Object.entries(slow)) rows.push(`- ${k}: ${geo(xs).toFixed(2)}× over ${xs.length} programs`);
if (notes.length) rows.push("", ...notes.map((n) => `- ⚠️ ${n}`));
const progNotes = programs.filter((p) => p.note);
if (progNotes.length) rows.push("", "Notes:", "", ...progNotes.map((p) => `- **${p.name}**: ${p.note}`));
rows.push("", "zilc binaries are dynamic and load Fil-C's runtime (libc.so, libpizlo.so, libyoloc.so); plain ones are static musl.");
await writeFile(`${outDir}/summary.md`, rows.join("\n") + "\n");
console.log("\n" + rows.join("\n"));
console.log(`\n${outDir}/results.json`);
process.exit(notes.length ? 1 : 0);
