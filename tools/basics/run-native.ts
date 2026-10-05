// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Build and run every tests/basics example natively with PLAIN Zig 0.15.2 (no Fil-C): the "does it
// behave" check after conversion, and the baseline zilc's output is compared against
// (compare-output.ts). Linux; from Windows it runs inside WSL.
//
//   deno run -A tools/basics/run-native.ts [c|zig|"c zig"]      (default: both)
//   env: OUTROOT (default: zig-out/basics-run in the repo; the WSL home is much faster, the repo
//        is on exFAT), JOBS (default 8), ZIGDIR, ZIG_LOCAL_CACHE_DIR, ZILC_ZIG
// Output: $OUTROOT/<lang>/<example>.out (stdout+stderr), and summary.txt: per example its exit
// code, or TIMEOUT for examples that wait forever (servers, signals), or BUILD-FAIL.
//
// Kept from the shell version: examples build and run in parallel (one at a time the Zig half
// alone took over 30 minutes, 2026-10-02); each gets its own working directory with the same
// ./tmp/dat.txt (58_reading-files reads it) and the same stdin (60_line-filters reads it); and
// programs run in the same FIXED environment as zilc-check.ts, so outputs compare.
import { basename, env, envInt, glob, HOME, linuxOnly, mkdirp, pool, REPO, rmrf, run, ZIG } from "../lib/tool.ts";

await linuxOnly(import.meta);
const outRoot = env("OUTROOT", `${REPO}/zig-out/basics-run`);
const langs = (Deno.args[0] ?? "c zig").split(/\s+/).filter(Boolean);
const cacheEnv = { ZIG_LOCAL_CACHE_DIR: env("ZIG_LOCAL_CACHE_DIR", `${HOME}/.cache/zilc-basics`) };

for (const lang of langs) {
  const out = `${outRoot}/${lang}`;
  await rmrf(out);
  await mkdirp(`${out}/bin`);
  const dir = lang === "zig" ? env("ZIGDIR", "zig-0.15.2") : lang;
  const files = await glob(`${REPO}/tests/basics/${dir}/*/*.${lang}`);
  const summary = await pool(files, envInt("JOBS", 8), async (file) => {
    const name = basename(file.slice(0, file.lastIndexOf("/")));
    const build = lang === "zig"
      ? [ZIG, "build-exe", "-lc", "-target", "x86_64-linux-musl", `-femit-bin=${out}/bin/${name}`, file]
      : [ZIG, "cc", "-lc", "-target", "x86_64-linux-musl", "-o", `${out}/bin/${name}`, file];
    if ((await run(build, { env: cacheEnv, outFile: `${out}/${name}.build` })).code !== 0) return `${name} BUILD-FAIL`;
    const cwd = `${out}/cwd/${name}`;
    await mkdirp(`${cwd}/tmp`);
    await Deno.writeTextFile(`${cwd}/tmp/dat.txt`, "hello\nzig\n");
    const r = await run([`${out}/bin/${name}`], {
      cwd, stdin: "hello\nfilter\n", timeout: 15, outFile: `${out}/${name}.out`, cleanEnv: true,
      env: { HOME, PATH: env("PATH"), USER: env("USER"), LANG: "C.UTF-8", TERM: "dumb" },
    });
    return r.timedOut ? `${name} TIMEOUT` : `${name} exit=${r.code}`;
  });
  summary.sort();
  await Deno.writeTextFile(`${out}/summary.txt`, summary.join("\n") + "\n");
  console.log(`== ${lang}: ${summary.filter((l) => l.endsWith(" exit=0")).length} exit 0 / ${summary.length}`);
  for (const l of summary.filter((l) => !l.endsWith(" exit=0"))) console.log(l);
}
