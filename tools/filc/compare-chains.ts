// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Are the Zig-only chain and the GCC chain FUNCTIONALLY THE SAME? (owner, 2026-10-30: "before we
// fully remove the gcc, we should make sure that the resulting compilations are functionally the
// same from gcc or the zig only compilation chain"; GCC is maintainer-only, kept for this check on
// every Fil-C move — cmem/design-decisions.md.) Compares the two trees
// tools/filc/build-filc-from-source.ts makes (MODE=zig and MODE=upstream), and the release:
//
//   exports   every library in pizfix/lib*: the zig chain defines exactly the release's global
//             symbols (the GCC chain is shown beside it, for information), and no zig-chain
//             library carries a `GCC:` .comment
//   relocs    each shared library's self-binding relocations (JUMP_SLOT / GLOB_DAT / 64), by type
//             and symbol NAME (the Info column holds a per-link dynsym index): every name that
//             differs between the chains must be defined in that library or be a weak undefined,
//             so a call still reaches the same function
//   suite     Fil-C's suite on each tree: 0 differences zig vs stock and zig vs the GCC chain
//   gate      `zig build gate` with each tree's clang: 8/8 both, the same lines
//   corpus    tests/basics, C and Zig, all four modes, per chain; the output comparison against
//             native per chain (0 unexplained each); then chain against chain: the same verdicts
//             (the PID in Fil-C's panic prefix masked) and the same comparison report
//
//   bun tools/filc/compare-chains.ts     env: PARTS (comma list, default all five), ZIG_TREE,
//                                          GCC_TREE (defaults: build-filc-from-source.ts's OUT for
//                                          each mode), OUT (default ~/zilc-work/equiv), JOBS
//                                          (suite, default 24), REUSE=1 (keep existing suite
//                                          results, native runs, and each chain's corpus and
//                                          report: re-analysis without rebuilding)
//
// Fil-C's tests: ~/zilc-work/filc-tests-<release> with results-stock.json (cmem/testing.md). The
// suite writes results-from-source-zig.json and results-from-source-upstream.json there. Exit 0 =
// every part passed. First run 2026-11-04 (cmem/testing.md "THE ZIG-ONLY CHAIN").

import { readdir, readFile, writeFile } from "node:fs/promises";
import { env, exists, FILC_PREBUILT_TREE, FILC_VERSION, mkdirp, must, REPO, rmrf, run, WORK, ZIG } from "../lib/tool.ts";

const zigTree = env("ZIG_TREE", `${WORK}/filc-from-source-${FILC_VERSION}`);
const gccTree = env("GCC_TREE", `${WORK}/filc-from-source-${FILC_VERSION}-upstream`);
const out = env("OUT", `${WORK}/equiv`);
const tests = `${WORK}/filc-tests-${FILC_VERSION}`;
const parts = env("PARTS", "exports,relocs,suite,gate,corpus").split(",").map((p) => p.trim()).filter(Boolean);
const reuse = env("REUSE") === "1";
const bun = process.execPath;
for (const p of [zigTree, gccTree, FILC_PREBUILT_TREE]) if (!(await exists(`${p}/pizfix/lib`))) throw new Error(`missing ${p}/pizfix/lib`);
await mkdirp(out);

const verdicts: string[] = [];
const verdict = (part: string, ok: boolean, what: string) => {
  const line = `${ok ? "PASS" : "FAIL"} ${part}: ${what}`;
  verdicts.push(line);
  console.log(line);
};
const libDirs = ["lib", "lib_test", "lib_gcverify", "lib_test_gcverify"];
async function libraries(tree: string): Promise<string[]> {
  const found: string[] = [];
  for (const d of libDirs) {
    if (!(await exists(`${tree}/pizfix/${d}`))) continue;
    for (const e of await readdir(`${tree}/pizfix/${d}`, { withFileTypes: true })) {
      if (e.isFile() && /\.(so(\.[0-9.]+)?|a|o)$/.test(e.name) && (await isBinary(`${tree}/pizfix/${d}/${e.name}`))) found.push(`${d}/${e.name}`);
    }
  }
  return found.sort();
}
/** ELF and ar files only: libc++.so is a linker script (`INPUT(libc++.so.1 -lc++abi)`). */
async function isBinary(file: string): Promise<boolean> {
  const head = new Uint8Array(await Bun.file(file).slice(0, 8).arrayBuffer());
  const text = new TextDecoder().decode(head);
  return text.startsWith("\x7fELF") || text.startsWith("!<arch>");
}
async function defined(file: string): Promise<string> {
  if (!(await exists(file))) return "(missing)";
  const r = await run(["nm", "-g", "--defined-only", file]);
  return [...new Set(r.out.split("\n").map((l) => l.trim().split(/\s+/)).filter((f) => f.length >= 3).map((f) => f[2]))].sort().join("\n");
}

// ---- exports ---------------------------------------------------------------------------------
if (parts.includes("exports")) {
  const libs = await libraries(zigTree);
  const lines: string[] = [];
  let zigOff = 0, gccOff = 0, gccStrings = 0;
  for (const l of libs) {
    const [z, g, r] = await Promise.all([defined(`${zigTree}/pizfix/${l}`), defined(`${gccTree}/pizfix/${l}`), defined(`${FILC_PREBUILT_TREE}/pizfix/${l}`)]);
    const comment = (await run(["readelf", "-p", ".comment", `${zigTree}/pizfix/${l}`])).out;
    const gcc = comment.includes("GCC:");
    if (z !== r) zigOff++;
    if (g !== r) gccOff++;
    if (gcc) gccStrings++;
    lines.push(`${l} zig=${z === r ? "release" : "DIFF"} gcc-chain=${g === r ? "release" : "DIFF"}${gcc ? " GCC-in-zig-build" : ""}`);
  }
  await writeFile(`${out}/exports.txt`, lines.join("\n") + "\n");
  for (const l of lines) if (l.includes("DIFF") || l.includes("GCC-in")) console.log(`  ${l}`);
  verdict("exports", zigOff === 0 && gccStrings === 0,
    `${libs.length} libraries; zig chain = release on ${libs.length - zigOff}, GCC chain on ${libs.length - gccOff} (information); ${gccStrings} zig-chain libraries with a GCC .comment`);
}

// ---- relocs ----------------------------------------------------------------------------------
if (parts.includes("relocs")) {
  type Sym = { bind: string; ndx: string };
  const dynsyms = async (file: string) => {
    const m = new Map<string, Sym>();
    for (const l of (await must(["readelf", "-sW", "--dyn-syms", file])).split("\n")) {
      const f = l.trim().split(/\s+/); // Num: Value Size Type Bind Vis Ndx Name
      if (f.length >= 8 && /^\d+:$/.test(f[0])) m.set(f[7].replace(/@.*$/, ""), { bind: f[4], ndx: f[6] });
    }
    return m;
  };
  const relocs = async (file: string) => (await must(["readelf", "-rW", file])).split("\n")
    .map((l) => l.trim().split(/\s+/)).filter((f) => /^R_X86_64_(JUMP_SLOT|GLOB_DAT|64)$/.test(f[2] ?? "") && f[4])
    .map((f) => `${f[2]} ${f[4].replace(/@.*$/, "")}`);
  const count = (xs: string[]) => xs.reduce((m, x) => m.set(x, (m.get(x) ?? 0) + 1), new Map<string, number>());
  const shared = (await libraries(zigTree)).filter((l) => /\.so(\.[0-9.]+)?$/.test(l));
  let bad = 0;
  const report: string[] = [];
  for (const l of shared) {
    const [z, g] = [await relocs(`${zigTree}/pizfix/${l}`), await relocs(`${gccTree}/pizfix/${l}`)];
    const r = await relocs(`${FILC_PREBUILT_TREE}/pizfix/${l}`).catch(() => [] as string[]);
    const zc = count(z), gc = count(g);
    const keys = [...new Set([...zc.keys(), ...gc.keys()])].sort().filter((k) => zc.get(k) !== gc.get(k));
    const syms = await dynsyms(`${zigTree}/pizfix/${l}`);
    const unexplained = keys.filter((k) => {
      const s = syms.get(k.split(" ")[1]);
      return !(s && (s.ndx !== "UND" || s.bind === "WEAK")); // defined here, or a weak undefined
    });
    bad += unexplained.length;
    report.push(`${l}: zig ${z.length}, GCC chain ${g.length}, release ${r.length}; ${keys.length} differing (type, name)${keys.length ? ": " + keys.map((k) => `${k} ${zc.get(k) ?? 0}/${gc.get(k) ?? 0}`).join(", ") : ""}${unexplained.length ? `; UNEXPLAINED: ${unexplained.join(", ")}` : ""}`);
  }
  await writeFile(`${out}/relocs.txt`, report.join("\n") + "\n");
  for (const l of report) console.log(`  ${l}`);
  verdict("relocs", bad === 0, `${shared.length} shared libraries; every differing relocation names a symbol defined in that library or a weak undefined (${bad} not)`);
}

// ---- suite -----------------------------------------------------------------------------------
if (parts.includes("suite")) {
  const runner = `${REPO}/tools/filc/run-filc-tests.ts`;
  for (const [tree, label] of [[zigTree, "from-source-zig"], [gccTree, "from-source-upstream"]] as const) {
    if (reuse && (await exists(`${tests}/results-${label}.json`))) continue;
    const r = await run([bun, runner, "run", "--pizfix", `${tree}/pizfix`, "--label", label, "--jobs", env("JOBS", "24")], { cwd: tests, outFile: `${out}/suite-${label}.log` });
    if (r.code !== 0) verdict("suite", false, `the run on ${tree} exited ${r.code} (${out}/suite-${label}.log)`);
  }
  for (const base of ["stock", "from-source-upstream"]) {
    const r = await run([bun, runner, "compare", `results-${base}.json`, "results-from-source-zig.json"], { cwd: tests });
    verdict("suite", r.code === 0, `zig chain vs ${base}: ${r.out.trim().split("\n").pop()}`);
  }
}

// ---- gate ------------------------------------------------------------------------------------
if (parts.includes("gate")) {
  const outs: string[] = [];
  for (const tree of [gccTree, zigTree]) {
    const r = await run([bun, `${REPO}/tools/run-gate.ts`], { cwd: REPO, env: { ZILC_FILC: `${tree}/build/bin/clang`, ZILC_ZIG: ZIG } });
    await writeFile(`${out}/gate-${tree.split("/").pop()}.log`, r.out);
    outs.push(r.out.split("\n").filter((l) => !l.startsWith("gate:")).join("\n"));
    verdict("gate", r.code === 0 && /gate: (\d+)\/\1 cases passed/.test(r.out), `${tree}: ${r.out.split("\n").find((l) => l.startsWith("gate:")) ?? "no summary"}`);
  }
  verdict("gate", outs[0] === outs[1], "the two chains' gate output, line for line");
}

// ---- corpus ----------------------------------------------------------------------------------
if (parts.includes("corpus")) {
  const native = [`${out}/outcmp/native1`, `${out}/outcmp/native2`];
  await mkdirp(`${out}/outcmp`);
  // ALL OR NOTHING: some programs print the date and time of day (07_switch "It's after noon",
  // 52_time-formatting-parsing), so the native runs and both chains' corpora must come from the same
  // sitting. Reusing day-old native runs against a fresh corpus failed both on 2026-11-05.
  const chainDone = async (t: string) => (await exists(`${out}/${t.split("/").pop()}/compare-output.log`)) && (await exists(`${out}/${t.split("/").pop()}/basics-zilc-Debug/results.txt`));
  const reuseCorpus = reuse && (await exists(native[0])) && (await exists(native[1])) && (await chainDone(gccTree)) && (await chainDone(zigTree));
  for (const n of native) {
    if (reuseCorpus) continue;
    await rmrf(n);
    await run([bun, `${REPO}/tools/basics/run-native.ts`], { cwd: REPO, env: { OUTROOT: n }, outFile: `${n}.log` });
  }
  const modes = ["Debug", "ReleaseSafe", "ReleaseFast", "ReleaseSmall"];
  const reports: string[] = [];
  for (const tree of [gccTree, zigTree]) {
    const work = `${out}/${tree.split("/").pop()}`;
    await mkdirp(work);
    // WORK moves zilc-check's output; ZILC_ZIG pins the Zig that WORK would otherwise move too.
    const e = { WORK: work, ZILC_FILC: `${tree}/build/bin/clang`, ZILC_ZIG: ZIG, LANGS: "c zig" };
    // REUSE=1 keeps the corpus and reports only when ALL of it exists (above: re-analysis, and the
    // inversion); otherwise both chains run again beside fresh native runs.
    const have = reuseCorpus;
    if (!have) await run([bun, `${REPO}/tools/basics/all-modes.ts`], { cwd: REPO, env: e, outFile: `${work}/all-modes.log` });
    if (!have) await run([bun, `${REPO}/tools/basics/compare-output.ts`, ...native, work], { cwd: REPO, outFile: `${work}/compare-output.log` });
    const report = await readFile(`${work}/compare-output.log`, "utf8");
    reports.push(report);
    const total = report.trim().split("\n").pop() ?? "";
    verdict("corpus", /"variesBad":0,"differs":0,"missing":0/.test(total), `${tree}: output comparison ${total}`);
  }
  const mask = (s: string) => s.replace(/\[\d+\]/g, "[pid]").split("\n").sort().join("\n");
  for (const m of modes) {
    const [g, z] = await Promise.all([gccTree, zigTree].map((t) => readFile(`${out}/${t.split("/").pop()}/basics-zilc-${m}/results.txt`, "utf8").catch(() => "(missing)")));
    verdict("corpus", mask(g) === mask(z) && g !== "(missing)", `${m}: verdicts chain against chain (${z.trim().split("\n").length} programs)`);
  }
  // Chain against chain, per program and mode. Not byte-identical reports: the thread-order programs
  // flip between SAME and an allowed verdict run to run (2026-11-04: 36_worker-pools SAME in one
  // chain's run and EXPECTED in the other's, 35_waitgroups SAME vs NATIVE-VARIES shape ok — while
  // the 2026-10-30 run happened to match). What must hold: the same programs fail in both chains
  // (DIFFERS, SHAPE DIFFERS, missing), and a flip only between SAME and EXPECTED / shape ok.
  const verdictsOf = (report: string) => {
    const m = new Map<string, string>();
    let section = "";
    for (const l of report.split("\n")) {
      const h = l.match(/^== (\S+) \[(\w+)\]/);
      if (h) { section = `${h[1]} ${h[2]}`; continue; }
      // `  NATIVE-VARIES  35_waitgroups: shape ok` (a program name never holds a colon; a lazy \S+?
      // matched one character and hid every flip, 2026-11-04).
      const v = l.match(/^\s+(SAME|EXPECTED|NATIVE-VARIES|DIFFERS|MISSING)\s+([^\s:]+):?\s*(.*)$/);
      if (v && section) m.set(`${section} ${v[2]}`, v[1] === "NATIVE-VARIES" ? (/shape ok/.test(v[3]) ? "shape ok" : "SHAPE DIFFERS") : v[1]);
    }
    return m;
  };
  const allowed = new Set(["SAME", "EXPECTED", "shape ok"]);
  const [gv, zv] = reports.map(verdictsOf);
  const failing = (m: Map<string, string>) => [...m].filter(([, v]) => !allowed.has(v)).map(([k, v]) => `${k} ${v}`).sort().join("; ");
  const flips = [...new Set([...gv.keys(), ...zv.keys()])].filter((k) => (gv.get(k) ?? "SAME") !== (zv.get(k) ?? "SAME"))
    .map((k) => `${k}: ${gv.get(k) ?? "SAME"} → ${zv.get(k) ?? "SAME"}`);
  for (const f of flips) console.log(`  flip (GCC chain → zig chain): ${f}`);
  verdict("corpus", failing(gv) === failing(zv) && flips.every((f) => [...f.matchAll(/(SAME|EXPECTED|shape ok)/g)].length === 2),
    `output comparison chain against chain: failing programs — GCC chain: ${failing(gv) || "none"}; zig chain: ${failing(zv) || "none"}; ${flips.length} verdict flip(s), allowed only between SAME / EXPECTED / shape ok (thread order)`);
}

const failed = verdicts.filter((v) => v.startsWith("FAIL")).length;
await writeFile(`${out}/verdicts.txt`, verdicts.join("\n") + "\n");
console.log(failed ? `\nFAILED: ${failed} of ${verdicts.length} checks (${out}/verdicts.txt)` : `\nOK: the chains are functionally the same (${verdicts.length} checks; ${out}/verdicts.txt)`);
process.exit(failed ? 1 : 0);
