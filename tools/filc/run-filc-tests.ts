#!/usr/bin/env -S deno run --allow-read --allow-write --allow-run --allow-env --allow-net=jsr.io
// SPDX-License-Identifier: BSD-2-Clause
//
// Copyright (c) 2023-2025 Epic Games, Inc. All Rights Reserved.
// Copyright (c) 2026 Filip Pizlo. All Rights Reserved.
// Copyright (c) 2026 the zilc authors (this port).
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY FILIP PIZLO ``AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL FILIP PIZLO OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
// OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------------------------------------------
// Fil-C's own test suite, run without Ruby. A port of Fil-C's `filc/run-tests` (Ruby) as of commit
// 163fae5 = tag v0.686 (it was read from upstream's newest commit on 2026-10-05, which was 0.686's;
// it also ran 0.685's tests correctly); ledger entry `filc-test-runner-port` in
// third_party/LICENSES.md. Purpose (owner, 2026-10-05): run upstream's tests (7,003 at 0.685,
// 7,205 at 0.686) against zilc's PATCHED Fil-C clang and
// against the stock one, and compare, "to make sure we are not missing anything that upstream
// has already identified".
//
// What it reproduces, rule by rule (each marked `// run-tests:` below): the skips (CPU features,
// platform, glibc/cosmo builds, `skip`), the compile of every .c/.cpp/.ll/.s in a test folder
// with `<pizfix>/../build/bin/clang[++]` (`-O2` unless `optFlags`, `-g`, `-Ifilc/tests`,
// `-std=c++20` for C++), the libraries, the link with `filc/tests/utils.o`, and the four runs
// (FUGC_RAGE_MODE; scribble+verify; stop-the-world; release), each with FILC_EXIT_ON_PANIC=1
// (a Fil-C stop exits 42) and checked for the expected return and `output-includes/-excludes`.
// The per-test shell scripts are generated as run-tests generates them.
//
// Where it differs, on purpose: (1) Deno runs the per-test `run.sh` scripts in its own worker
// pool instead of `make -k -j`, with a per-test TIMEOUT (one hung test cannot stall the run), and
// records each test's result; (2) CPU features come from /proc/cpuinfo, not from compiling the
// `has_*.c` probes with a system clang (this machine has none; on x86_64 only AVX-512 and SHA-NI
// can be present); (3) `slow` tests start first, as run-tests orders them.
//
// Usage (in WSL, cwd = the folder holding Fil-C's `filc/tests`):
//   deno run -A run-filc-tests.ts run --pizfix <toolchain>/pizfix --label stock [--jobs 24]
//        [--filter REGEX] [--timeout 900]
//   deno run -A run-filc-tests.ts compare results-stock.json results-patched.json
// `run` leaves filc/test-output-<label>/ (per-test scripts and outputs) and results-<label>.json.
// ⚠️ The cwd must be Fil-C's REPO ROOT checkout, and it must also contain
// projects/openssl-3.6.4/crypto/aes/asm: test `sarcasm-mb-pl-sink-att` (since v0.686) reads
// aesni-mb-x86_64.pl from there and fails "BAD cannot open" without it (cmem/testing.md).

import { parse as parseYaml } from "jsr:@std/yaml@1";

type Manifest = Record<string, unknown>;
type Status = "PASS" | "FAIL" | "TIMEOUT" | `SKIP: ${string}`;

const args = Deno.args;
const mode = args[0];
const opt = (name: string, def?: string) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : def;
};

// Ruby's Shellwords.shellescape, for the commands written into the scripts.
const sq = (s: string) => (/^[A-Za-z0-9_\-.,:\/@+=%]+$/.test(s) ? s : `'${s.replaceAll("'", `'\\''`)}'`);
const arr = (x: unknown): string[] => (x === undefined || x === null ? [] : Array.isArray(x) ? x.map(String) : [String(x)]);
const isSource = (e: string) => /\.(c|ll|cpp|s)$/.test(e); // run-tests: isSourceEntry
const isCpp = (e: string) => e.endsWith(".cpp"); // run-tests: isCppEntry

async function exists(p: string) {
  return (await Deno.stat(p).catch(() => null)) !== null;
}
async function sh(cmd: string, timeoutSec?: number): Promise<number | "timeout"> {
  const argv = timeoutSec ? ["timeout", "-k", "10", String(timeoutSec), "sh", "-c", cmd] : ["sh", "-c", cmd];
  const { code } = await new Deno.Command(argv[0], { args: argv.slice(1), stdout: "null", stderr: "null" }).output();
  return timeoutSec && code === 124 ? "timeout" : code;
}

async function runAll() {
  const pizfix = opt("pizfix");
  const label = opt("label");
  if (!pizfix || !label) throw new Error("run needs --pizfix and --label");
  const jobs = Number(opt("jobs", "24"));
  const timeout = Number(opt("timeout", "900"));
  const filter = new RegExp(opt("filter", ".")!);
  const bin = `${pizfix}/../build/bin`;

  // run-tests: CPU feature checks. x86_64: only AVX-512 and SHA-NI can be present; the ARM ones
  // are absent by construction.
  const cpu = await Deno.readTextFile("/proc/cpuinfo");
  const has: Record<string, boolean> = {
    needsAVX512: /\bavx512f\b/.test(cpu),
    needsSHANI: /\bsha_ni\b/.test(cpu),
    needsGLIBC: await exists(`${pizfix}/lib/libc.so.6666`),
    needsCOSMO: await exists(`${pizfix}/lib/libyolocosmo.a`),
  };
  for (const arm of ["needsARMCrypto", "needsLSE", "needsJSCVT", "needsFP16", "needsASIMDHP", "needsBF16", "needsI8MM", "needsCRC32", "needsFLAGM", "needsFLAGM2", "needsSHA3", "needsSHA512", "needsPACA", "needsSVE", "needsRNG", "needsFRINTTS"]) has[arm] = false;
  const platform = "x86_64-linux"; // run-tests: RUBY_PLATFORM, for only-on-platform

  // run-tests: utils.o, compiled once with the toolchain under test.
  if (await sh(`${sq(bin)}/clang -O3 -c -o filc/tests/utils.o filc/tests/utils.c -g`) !== 0) throw new Error("cannot compile filc/tests/utils.c");

  const outRoot = "filc/test-output";
  await Deno.remove(outRoot, { recursive: true }).catch(() => {});
  await Deno.mkdir(outRoot, { recursive: true });

  const results: Record<string, Status> = {};
  const queue: { name: string; slow: boolean }[] = [];
  const names: string[] = [];
  for await (const e of Deno.readDir("filc/tests")) if (e.isDirectory) names.push(e.name);
  names.sort();

  for (const name of names) {
    if (!filter.test(name)) continue;
    const full = `filc/tests/${name}`;
    if (!(await exists(`${full}/manifest`))) continue; // run-tests: "no manifest"
    // Ruby's YAML takes a repeated key, the last one winning; six 0.685 manifests repeat
    // `only-on-platform` (same value), and Deno's parser rejects that unless told.
    const m = (parseYaml(await Deno.readTextFile(`${full}/manifest`), { allowDuplicateKeys: true }) ?? {}) as Manifest;
    // run-tests: the skips, in its order.
    if (m["only-on-platform"] && !new RegExp(String(m["only-on-platform"])).test(platform)) { results[name] = `SKIP: only on ${m["only-on-platform"]}`; continue; }
    const missing = Object.keys(has).find((k) => m[k] && !has[k]);
    if (missing) { results[name] = `SKIP: ${missing}`; continue; }
    if (m["unsupportedOnCOSMO"] && has.needsCOSMO) { results[name] = "SKIP: unsupported on cosmo"; continue; }
    if (m["skip"]) { results[name] = "SKIP: skip"; continue; }

    const expected = String(m["return"]);
    if (!["success", "failure", "crash", "compileFailure", "dontCrash", "exit13", "compileOnly", "linkFailure"].includes(expected)) throw new Error(`${name}: unknown return '${expected}'`);
    const includes = arr(m["output-includes"]);
    const excludes = arr(m["output-excludes"]);
    const optFlags = m["optFlags"] ? String(m["optFlags"]) : "-O2";
    const out = `${outRoot}/${name}`;
    await Deno.mkdir(out, { recursive: true });
    for (const d of arr(m["mkdirs"])) await Deno.mkdir(`${out}/${d}`, { recursive: true });

    const entries: string[] = [];
    for await (const e of Deno.readDir(full)) if (e.isFile && isSource(e.name)) entries.push(e.name);
    entries.sort();
    const compilerOutput = `${out}/compilerOutput.txt`;
    const binary = `${out}/${name}`;
    const runScript = `${out}/run.sh`;

    // run-tests: compile.sh
    const c: string[] = ["#!/bin/sh", `rm -f ${sq(compilerOutput)}`, `touch ${sq(compilerOutput)}`];
    for (const e of entries) {
      const clang = isCpp(e) ? "clang++" : "clang";
      const extra = isCpp(e) ? "-std=c++20" : "";
      c.push(`${sq(bin)}/${clang} -c -o ${sq(`${out}/${e}`)}.o ${sq(`${full}/${e}`)} -Ifilc/tests ${optFlags} -g ${extra} >> ${sq(compilerOutput)} 2>&1`);
      if (expected === "compileFailure") c.push("if [ $? -eq 0 ]", "then", `    echo ${sq(`${runScript}: FAIL: compiled ${e} but shouldn't have`)}`, `    cat ${sq(compilerOutput)}`, "    exit 1", "fi");
      else c.push("if [ $? -ne 0 ]", "then", `    echo ${sq(`${runScript}: FAIL: couldn't compile ${e}`)}`, `    cat ${sq(compilerOutput)}`, "    exit 1", "fi");
    }
    if (expected === "compileFailure") {
      for (const x of includes) c.push(`grep -F -- ${sq(x)} ${sq(compilerOutput)} > /dev/null || {`, `    echo ${sq(`FAIL: expected compiler output to contain ${x}`)}`, `    cat ${sq(compilerOutput)}`, "    exit 1", "}");
      for (const x of excludes) c.push(`grep -F -- ${sq(x)} ${sq(compilerOutput)} > /dev/null && {`, `    echo ${sq(`FAIL: expected compiler output to NOT contain ${x}`)}`, `    cat ${sq(compilerOutput)}`, "    exit 1", "}");
      c.push(":");
    }
    if (expected !== "compileFailure" && expected !== "compileOnly") {
      const libraryFiles = new Set<string>();
      const libraries = (m["libraries"] ?? {}) as Record<string, Record<string, unknown>>;
      for (const [libname0, data] of Object.entries(libraries)) {
        let libname = libname0;
        let line: string;
        const files = arr(data["files"]);
        if (data["isStatic"]) {
          libname += ".a";
          line = `ar cr ${sq(`${out}/${libname}`)}`;
        } else {
          const libOpt = "-shared"; // run-tests: $bundleOpt and $dylibOpt are both -shared
          if (!data["isBundle"]) libname += ".so";
          const linker = files.some(isCpp) ? "clang++" : "clang";
          line = `${sq(bin)}/${linker} ${libOpt} -o ${sq(`${out}/${libname}`)}`;
        }
        for (const f of files) { libraryFiles.add(f); line += ` ${sq(`${out}/${f}`)}.o`; }
        if (data["extraLinkerArgs"]) line += ` ${data["extraLinkerArgs"]}`;
        c.push(`${line} >> ${sq(compilerOutput)} 2>&1`, "if [ $? -ne 0 ]", "then", `    echo ${sq(`${runScript}: FAIL: couldn't link ${libname}`)}`, `    cat ${sq(compilerOutput)}`, "    exit 1", "fi");
      }
      const mainEntries = entries.filter((e) => !libraryFiles.has(e));
      const linker = mainEntries.some(isCpp) ? "clang++" : "clang";
      let link = `${sq(bin)}/${linker} -o ${sq(binary)}`;
      for (const e of mainEntries) link += ` ${sq(`${out}/${e}`)}.o`;
      if (m["extraLinkerArgs"]) link += ` ${m["extraLinkerArgs"]}`;
      if (has.needsGLIBC) link += " -lm";
      c.push(`${link} filc/tests/utils.o >> ${sq(compilerOutput)} 2>&1`);
      if (expected === "linkFailure") c.push("if [ $? -eq 0 ]", "then", `    echo ${sq(`${runScript}: FAIL: linked but shouldn't have`)}`, `    cat ${sq(compilerOutput)}`, "    exit 1", "fi");
      else c.push("if [ $? -ne 0 ]", "then", `    echo ${sq(`${runScript}: FAIL: couldn't link`)}`, `    cat ${sq(compilerOutput)}`, "    exit 1", "fi");
    }
    await Deno.writeTextFile(`${out}/compile.sh`, c.join("\n") + "\n", { mode: 0o755 });

    // run-tests: justRun.sh / justRunRelease.sh and the four sub-runs.
    const runs = expected !== "compileFailure" && expected !== "compileOnly" && expected !== "linkFailure";
    const subScripts: string[] = [];
    if (runs) {
      const extraArgs = arr(m["extraArgs"]).map(sq).join(" ");
      const env = arr(m["extra-env"]).map((e) => `${e} `).join("");
      const ld = m["extraLDPath"] ? `:${m["extraLDPath"]}` : "";
      await Deno.writeTextFile(`${out}/justRun.sh`, `#!/bin/sh\nset -e\nLD_LIBRARY_PATH=${pizfix}/lib_test${ld} ${env}${sq(binary)} ${extraArgs}\n`, { mode: 0o755 });
      const ldRel = m["extraLDPath"] ? `LD_LIBRARY_PATH=${m["extraLDPath"]} ` : "";
      await Deno.writeTextFile(`${out}/justRunRelease.sh`, `#!/bin/sh\nset -e\n${ldRel}${env}${sq(binary)} ${extraArgs}\n`, { mode: 0o755 });
      const subRuns = m["subRuns"] as Record<string, unknown> | undefined;
      const kinds = [
        { key: "default", file: "subRun.sh", prefix: "FUGC_RAGE_MODE=1", just: "justRun.sh", output: "output.txt" },
        { key: "scribble", file: "subRunScribble.sh", prefix: "FUGC_RAGE_MODE=1 FUGC_SCRIBBLE=1 FUGC_VERIFY=1", just: "justRun.sh", output: "outputScribble.txt" },
        { key: "stw", file: "subRunSTW.sh", prefix: "FUGC_MIN_THRESHOLD=0 FUGC_STW=1", just: "justRun.sh", output: "outputSTW.txt" },
        { key: "release", file: "subRunRelease.sh", prefix: "", just: "justRunRelease.sh", output: "outputRelease.txt" },
      ];
      const check: Record<string, [string, string]> = {
        failure: ["if [ $? -ne 42 ]", "expected program to return failure"],
        crash: ["if [ $? -eq 0 ]", "expected program to crash"],
        success: ["if [ $? -ne 0 ]", "expected program to return success"],
        exit13: ["if [ $? -ne 13 ]", "expected program to return 13"],
        dontCrash: ["if [ $? -ne 0 -a $? -ne 42 ]", "expected program to return success or failure, but not crash"],
      };
      for (const k of kinds) {
        const script = `${out}/${k.file}`;
        const output = `${out}/${k.output}`;
        const s: string[] = ["#!/bin/sh"];
        if (expected === "crash") s.push("ulimit -c 0");
        s.push(`${k.prefix} FILC_EXIT_ON_PANIC=1 FILC_DUMP_SETUP=1 ${sq(`${out}/${k.just}`)} > ${sq(output)} 2>&1`);
        s.push(check[expected][0], "then", `    echo ${sq(`${script}: FAIL: ${check[expected][1]}`)}`, `    cat ${sq(output)}`, "    exit 1", "fi");
        for (const x of includes) s.push(`grep -F -- ${sq(x)} ${sq(output)} > /dev/null || {`, `    echo ${sq(`${script}: FAIL: expected output to contain ${x}`)}`, `    cat ${sq(output)}`, "    exit 1", "}");
        for (const x of excludes) s.push(`grep -F -- ${sq(x)} ${sq(output)} > /dev/null && {`, `    echo ${sq(`${script}: FAIL: expected output to NOT contain ${x}`)}`, `    cat ${sq(output)}`, "    exit 1", "}");
        s.push(":");
        await Deno.writeTextFile(script, s.join("\n") + "\n", { mode: 0o755 });
        if (!subRuns || subRuns[k.key]) subScripts.push(script);
      }
    }
    // run-tests: run.sh
    await Deno.writeTextFile(runScript, ["#!/bin/sh", "set -e", sq(`${out}/compile.sh`), ...subScripts.map(sq)].join("\n") + "\n", { mode: 0o755 });
    queue.push({ name, slow: Boolean(m["slow"]) });
  }

  // run-tests: slow tests first.
  queue.sort((a, b) => Number(b.slow) - Number(a.slow));
  let next = 0, done = 0;
  const started = Date.now();
  const worker = async () => {
    while (next < queue.length) {
      const t = queue[next++];
      const out = `${outRoot}/${t.name}`;
      const r = await sh(`${sq(`${out}/run.sh`)} > ${sq(`${out}/result.txt`)} 2>&1`, timeout);
      results[t.name] = r === "timeout" ? "TIMEOUT" : r === 0 ? "PASS" : "FAIL";
      if (++done % 250 === 0) console.error(`  ${done}/${queue.length} (${Math.round((Date.now() - started) / 1000)} s)`);
    }
  };
  await Promise.all(Array.from({ length: jobs }, worker));

  const count = (p: (s: Status) => boolean) => Object.values(results).filter(p).length;
  console.log(`[${label}] ${queue.length} run, ${count((s) => s === "PASS")} pass, ${count((s) => s === "FAIL")} fail, ${count((s) => s === "TIMEOUT")} timeout, ${count((s) => s.startsWith("SKIP"))} skipped, ${Math.round((Date.now() - started) / 1000)} s`);
  await Deno.writeTextFile(`results-${label}.json`, JSON.stringify(results, null, 1));
  await Deno.remove(`filc/test-output-${label}`, { recursive: true }).catch(() => {});
  await Deno.rename(outRoot, `filc/test-output-${label}`);
}

async function compare() {
  const [a, b] = [args[1], args[2]];
  const ra = JSON.parse(await Deno.readTextFile(a)) as Record<string, Status>;
  const rb = JSON.parse(await Deno.readTextFile(b)) as Record<string, Status>;
  const names = [...new Set([...Object.keys(ra), ...Object.keys(rb)])].sort();
  const diff = names.filter((n) => ra[n] !== rb[n]);
  console.log(`${names.length} tests; ${diff.length} with a different result (${a} vs ${b})`);
  for (const n of diff) console.log(`  ${n}: ${ra[n] ?? "absent"} -> ${rb[n] ?? "absent"}`);
  Deno.exit(diff.length ? 1 : 0);
}

if (mode === "run") await runAll();
else if (mode === "compare") await compare();
else {
  console.error("usage: run-filc-tests.ts run --pizfix P --label L [--jobs N] [--filter RE] [--timeout S] | compare A.json B.json");
  Deno.exit(2);
}
