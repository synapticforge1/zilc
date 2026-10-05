// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Build every tests/basics example with zilc (MODE=ReleaseSafe by default; Debug, ReleaseFast,
// ReleaseSmall: KI-16), run it, and classify the result: OK, BUILD-FAIL (with the first undefined
// symbol or error), TRAP (with Fil-C's fault), TIMEOUT, BUILD-TIMEOUT (a build over TBUILD s,
// default 1800), or a plain exit code. The quick loop for fixing std-under-zilc problems.
//
//   deno run -A tools/basics/zilc-check.ts [c|zig|"c zig"]      (default: both)
//   env: MODE, JOBS (parallel builds, default 12), TBUILD, ZIGDIR (default zig-0.15.2),
//        ZILC_JOBS (default 4), ZILC_CACHE (default 0), WORK, ZILC_ZIG, ZILC_FILC
// Output: $WORK/basics-zilc-<MODE>/results.txt, and per program bin/<lang>/<name>/{build.log,run.out}.
//
// Why each setting (kept from the shell version):
//  * ZILC_JOBS=4: up to JOBS builds run at once, and each big module splits its code generation
//    into parallel parts (KI-22 lever a); the cap stops 12 builds from starting 12 x 16 clangs.
//  * ZILC_CACHE=0: the corpus measures real compiles (its build times are recorded in
//    cmem/testing.md); with the object cache a second run would be all hits (KI-22 lever c).
//  * Programs run in a FIXED environment (the same as run-native.ts), so outputs compare with
//    native (compare-output.ts): this tool's own ZILC_* variables used to show up in 67's output.
//  * The output folder is cleared for the mode, so run both languages together when both matter.
import {
  basename, copyTree, env, envInt, filc, firstMatch, glob, HOME, linuxOnly, mkdirp, must, pool, REPO, rmrf, run, WORK, ZIG,
} from "../lib/tool.ts";

await linuxOnly(import.meta);

const mode = env("MODE", "ReleaseSafe");
const langs = (Deno.args[0] ?? "c zig").split(/\s+/).filter(Boolean);
const out = `${WORK}/basics-zilc-${mode}`;
const toolEnv = {
  ZILC_ZIG: ZIG,
  ZILC_FILC: filc(),
  ZIG_LOCAL_CACHE_DIR: env("ZIG_LOCAL_CACHE_DIR", `${HOME}/.cache/zilc-basics`),
  ZILC_JOBS: env("ZILC_JOBS", "4"),
  ZILC_CACHE: env("ZILC_CACHE", "0"),
};

await rmrf(out);
await mkdirp(out);
await must([ZIG, "build", "--build-file", `${REPO}/build.zig`, "--prefix", `${out}/zilc`, "-Doptimize=ReleaseSafe"], { env: toolEnv, inherit: true });
const zilc = `${out}/zilc/bin/zilc`;
await copyTree(`${REPO}/tests/basics`, `${out}/src`);

const work: { lang: string; file: string }[] = [];
for (const lang of langs) {
  const dir = lang === "zig" ? env("ZIGDIR", "zig-0.15.2") : lang;
  for (const file of await glob(`${out}/src/${dir}/*/*.${lang}`)) work.push({ lang, file });
}

const lines = await pool(work, envInt("JOBS", 12), async ({ lang, file }) => {
  const name = basename(file.slice(0, file.lastIndexOf("/")));
  const b = `${out}/bin/${lang}/${name}`;
  await mkdirp(`${b}/cwd/tmp`);
  await Deno.writeTextFile(`${b}/cwd/tmp/dat.txt`, "hello\nzig\n");
  const t0 = Date.now();
  const built = await run([zilc, "build", "-O", mode, "-o", `${b}/prog`, file], { env: toolEnv, outFile: `${b}/build.log`, timeout: envInt("TBUILD", 1800) });
  await Deno.writeTextFile(`${b}/build.log`, `build seconds: ${Math.floor((Date.now() - t0) / 1000)}\n`, { append: true });
  if (built.timedOut) return `${lang} ${name} BUILD-TIMEOUT`;
  if (built.code !== 0) {
    const log = await Deno.readTextFile(`${b}/build.log`);
    const why = log.match(/undefined reference to `[^']*'/)?.[0] ?? firstMatch(log, /error/i).slice(0, 100);
    return `${lang} ${name} BUILD-FAIL ${why}`;
  }
  const ran = await run([`${b}/prog`], {
    cwd: `${b}/cwd`, stdin: "hello\nfilter\n", timeout: 15, outFile: `${b}/run.out`, cleanEnv: true,
    env: { HOME, PATH: env("PATH"), USER: env("USER"), LANG: "C.UTF-8", TERM: "dumb" },
  });
  const output = await Deno.readTextFile(`${b}/run.out`);
  const trap = firstMatch(output, /filc safety error|filc panic/);
  if (trap) return `${lang} ${name} TRAP ${trap.replace(/.*filc safety error: /, "").slice(0, 110)}`;
  if (ran.timedOut) return `${lang} ${name} TIMEOUT`;
  if (ran.code === 0) return `${lang} ${name} OK`;
  return `${lang} ${name} exit=${ran.code}`;
});
lines.sort();
await Deno.writeTextFile(`${out}/results.txt`, lines.join("\n") + "\n");

for (const lang of langs) {
  const mine = lines.filter((l) => l.startsWith(`${lang} `));
  console.log(`== ${lang} [${mode}]: ${mine.filter((l) => l.endsWith(" OK")).length} OK / ${mine.length}`);
  // Group the rest by outcome, without the program name and addresses or pids.
  const counts = new Map<string, number>();
  for (const l of mine.filter((l) => !l.endsWith(" OK"))) {
    const k = l.split(" ").slice(2).join(" ").replace(/ [0-9a-fx]{8,}/g, "").replace(/\[[0-9]+\] /g, "");
    counts.set(k, (counts.get(k) ?? 0) + 1);
  }
  for (const [k, n] of [...counts].sort((a, b) => b[1] - a[1])) console.log(`${String(n).padStart(7)} ${k}`);
}
