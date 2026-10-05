// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Binary-size comparison over tests/basics: Zig ReleaseSmall, Zig ReleaseSafe, and zilc, for the C
// examples and the Zig 0.15.2 examples. Also records whether each zilc binary runs with the same exit
// code as the plain ReleaseSafe build. Linux; from Windows it runs inside WSL.
//
//   deno run -A tools/basics/size-compare.ts      env: JOBS (default 12), ZIGDIR, WORK, ZILC_ZIG, ZILC_FILC
// Output: $WORK/basics-size/sizes.csv (and the binaries, under $WORK/basics-size/bin), runtime.txt.
// Summarise with size-report.ts; group failures with zilc-failures.ts.
//
// ⚠️ Fairness: Zig's musl binaries are STATIC. zilc's are DYNAMIC and load Fil-C's libc.so,
// libpizlo.so and libyoloc.so at run time, so the shared runtime is reported separately. zilc also
// passes -g, so stripped sizes are reported alongside raw ones.
import {
  basename, copyTree, env, envInt, exists, filc, FILC_PREBUILT_TREE, glob, HOME, linuxOnly, mkdirp, must, pool, REPO, rmrf, run, size, WORK, ZIG,
} from "../lib/tool.ts";

await linuxOnly(import.meta);
const out = `${WORK}/basics-size`;
const toolEnv = { ZILC_ZIG: ZIG, ZILC_FILC: filc(), ZIG_LOCAL_CACHE_DIR: env("ZIG_LOCAL_CACHE_DIR", `${HOME}/.cache/zilc-basics`) };
await rmrf(out);
await mkdirp(out);

// zilc itself, built for Linux outside the repo's zig-out; the sources copied to Linux's own disk
// (/mnt/d is slow and exFAT).
await must([ZIG, "build", "--build-file", `${REPO}/build.zig`, "--prefix", `${out}/zilc`, "-Doptimize=ReleaseSafe"], { env: toolEnv, inherit: true });
const zilc = `${out}/zilc/bin/zilc`;
await copyTree(`${REPO}/tests/basics`, `${out}/src`);

const work = [
  ...(await glob(`${out}/src/c/*/*.c`)).map((file) => ({ lang: "c", file })),
  ...(await glob(`${out}/src/${env("ZIGDIR", "zig-0.15.2")}/*/*.zig`)).map((file) => ({ lang: "zig", file })),
];

const na = (n: number | null) => (n === null ? "NA" : String(n));
const stripped = async (p: string) => (await exists(p) && (await run(["strip", "-o", `${p}.s`, p])).code === 0 ? na(await size(`${p}.s`)) : "NA");

/** One example, every build flavour: a CSV row. */
const rows = await pool(work, envInt("JOBS", 12), async ({ lang, file }) => {
  const name = basename(file.slice(0, file.lastIndexOf("/")));
  const b = `${out}/bin/${lang}/${name}`;
  await mkdirp(b);
  const runrc = async (p: string) => {
    if (!(await exists(p))) return "NA";
    await mkdirp(`${b}/cwd/tmp`);
    await Deno.writeTextFile(`${b}/cwd/tmp/dat.txt`, "hello\nzig\n");
    const r = await run([p], { cwd: `${b}/cwd`, stdin: "hello\nfilter\n", timeout: 15, outFile: `${p}.out` });
    return r.timedOut ? "TIMEOUT" : String(r.code);
  };
  // Plain Zig: build-exe handles .c and .zig alike, so C gets the same optimize modes.
  for (const m of ["ReleaseSmall", "ReleaseSafe"]) {
    await run([ZIG, "build-exe", "-O", m, "-lc", "-target", "x86_64-linux-musl", `-femit-bin=${b}/${m}`, file], { env: toolEnv, outFile: `${b}/${m}.log` });
  }
  // zilc. Zig inputs take -O; C inputs go straight to Fil-C's clang (-O1 -g).
  if (lang === "zig") {
    await run([zilc, "build", "-O", "ReleaseSafe", "-o", `${b}/zilcSafe`, file], { env: toolEnv, outFile: `${b}/zilcSafe.log` });
    await run([zilc, "build", "-O", "ReleaseSmall", "-o", `${b}/zilcSmall`, file], { env: toolEnv, outFile: `${b}/zilcSmall.log` });
  } else {
    await run([zilc, "build", "-o", `${b}/zilcSafe`, file], { env: toolEnv, outFile: `${b}/zilcSafe.log` });
  }
  const f = ["ReleaseSmall", "ReleaseSafe", "zilcSafe", "zilcSmall"].map((x) => `${b}/${x}`);
  const sizes = await Promise.all(f.map(async (p) => na(await size(p))));
  const strips = await Promise.all(f.map(stripped));
  return [lang, name, ...sizes, ...strips, await runrc(`${b}/ReleaseSafe`), await runrc(`${b}/zilcSafe`)].join(",");
});

const header = "lang,example,zig_small,zig_safe,zilc_safe,zilc_small,zig_small_stripped,zig_safe_stripped,zilc_safe_stripped,zilc_small_stripped,run_zig_safe,run_zilc";
await Deno.writeTextFile(`${out}/sizes.csv`, [header, ...rows].join("\n") + "\n");

const lib = `${FILC_PREBUILT_TREE}/pizfix/lib`;
const rt = `shared runtime every zilc binary loads (bytes): libc.so=${await size(`${lib}/libc.so`)} libpizlo.so=${await size(`${lib}/libpizlo.so`)} libyoloc.so=${await size(`${lib}/libyoloc.so`)} ld-fil1=${await size(`${lib}/ld-fil1-x86_64.so`)}`;
console.log(rt);
await Deno.writeTextFile(`${out}/runtime.txt`, rt + "\n");
console.log(`done: ${rows.length} rows in ${out}/sizes.csv`);
