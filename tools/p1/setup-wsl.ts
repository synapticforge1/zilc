// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Install zilc's Linux toolchains into the home: Zig 0.15.2, Fil-C's prebuilt release, patchelf,
// and Fil-C's own setup.sh. Idempotent: skips what exists. Run inside Linux (WSL on a Windows host),
// AFTER Bun is installed — Bun cannot install itself, so that one step is documented in
// tools/README.md "First-time setup" (owner, 2026-10-27: Bun runs inside Linux only).
//
//   ~/.bun/bin/bun tools/p1/setup-wsl.ts        env: FILC_VERSION (default: the release zilc builds on)
//
// Ported from setup-wsl.sh (2026-10-27) and proved equivalent on a fresh home: same programs, same
// order, same messages and exit codes; the one declared difference is step 4, where the shell
// script installed Bun and this tool reports the Bun it runs under (cmem/open-work.md).
import { writeFile } from "node:fs/promises";
import { env, exists, FILC_VERSION as ZILC_FILC_VERSION, HOME, linuxOnly, mkdirp, run, show, WORK } from "../lib/tool.ts";

await linuxOnly(import.meta);

const DL = `${WORK}/dl`;
const TOOLS = `${WORK}/tools`;
await mkdirp(DL);
await mkdirp(TOOLS);

const ZIG_URL = "https://ziglang.org/download/0.15.2/zig-x86_64-linux-0.15.2.tar.xz";
const ZIG_SHA = "02aa270f183da276e5b5920b1dac44a63f1a49e55050ebde3aecc9eb82f93239";
// Fil-C: the release zilc builds on (tools/lib/tool.ts FILC_VERSION). Upstream publishes no
// checksum; these are the SHA-256s of the files as downloaded (0.686 on 2026-10-05, 0.687 on
// 2026-10-27), recorded so a later download can be checked against them. FILC_VERSION=0.685 still
// installs the release the phase experiments (tools/p1–p3) record (its SHA was only printed then,
// so it is not checked).
const FILC_VERSION = env("FILC_VERSION", ZILC_FILC_VERSION);
const FILC_URL = `https://github.com/pizlonator/fil-c/releases/download/v${FILC_VERSION}/filc-${FILC_VERSION}-linux-x86_64.tar.xz`;
const FILC_SHAS: Record<string, string> = {
  "0.686": "60bfbe8ee63d7e462394aa8d5e44fee675de892bcf800d9cc80d86378cad6b07",
  "0.687": "aab538401f78a47ab261ee79afed8c6b99e1d4848e263ae159a75b03c1288da1",
};
const FILC_SHA = FILC_SHAS[FILC_VERSION] ?? "";
const PATCHELF_URL = "https://github.com/NixOS/patchelf/releases/download/0.19.1/patchelf-0.19.1-x86_64.tar.gz";

/** Runs a step with its output on this terminal; a failure ends the tool with that exit code, as `set -e` did. */
async function step(argv: string[], o: { cwd?: string; env?: Record<string, string> } = {}): Promise<void> {
  const code = await show(argv, o);
  if (code !== 0) process.exit(code);
}
/** The SHA-256 of a file, from `sha256sum` as the shell script used it. */
async function sha256(path: string): Promise<string> {
  const r = await run(["sha256sum", path]);
  if (r.code !== 0) process.exit(r.code);
  return r.out.trimEnd();
}
/** The first `n` lines a program prints (as `| head -n`). */
async function head(argv: string[], n: number, o: { env?: Record<string, string> } = {}): Promise<void> {
  const r = await run(argv, o);
  const lines = r.out.split("\n");
  if (lines.at(-1) === "") lines.pop();
  for (const l of lines.slice(0, n)) console.log(l);
}

console.log("== 1/4 Zig 0.15.2");
const zig = `${TOOLS}/zig-0.15.2/zig`;
if (await exists(zig)) {
  console.log("already installed");
} else {
  if (!(await exists(`${DL}/zig.tar.xz`))) await step(["curl", "-fsSL", ZIG_URL, "-o", `${DL}/zig.tar.xz`]);
  const got = (await sha256(`${DL}/zig.tar.xz`)).split(" ")[0];
  if (got !== ZIG_SHA) {
    console.error(`SHA MISMATCH: got ${got} want ${ZIG_SHA}`);
    process.exit(1);
  }
  console.log("sha256 OK");
  await step(["tar", "-xJf", `${DL}/zig.tar.xz`, "-C", TOOLS]);
  await step(["mv", `${TOOLS}/zig-x86_64-linux-0.15.2`, `${TOOLS}/zig-0.15.2`]);
}
await step([zig, "version"]);
await head([zig, "cc", "--version"], 1);

console.log(`== 2/4 Fil-C ${FILC_VERSION}`);
const FILC = `${TOOLS}/filc-${FILC_VERSION}-linux-x86_64`;
if (await exists(FILC)) {
  console.log("already unpacked");
} else {
  const T = `${DL}/filc-${FILC_VERSION}.tar.xz`;
  if (!(await exists(T))) await step(["curl", "-fsSL", FILC_URL, "-o", T]);
  const line = await sha256(T);
  const got = line.split(" ")[0];
  console.log(`${got}  ${T}`);
  await writeFile(`${DL}/filc-${FILC_VERSION}.sha256`, `${got}  ${T}\n`);
  if (FILC_SHA && got !== FILC_SHA) {
    console.error(`SHA MISMATCH: got ${got} want ${FILC_SHA}`);
    process.exit(1);
  }
  await step(["tar", "-xJf", T, "-C", TOOLS]);
}
await head(["ls", FILC], 20);

console.log("== 2b/4 patchelf (needed by Fil-C setup.sh; installed WITHOUT root)");
const PBIN = `${TOOLS}/bin`;
await mkdirp(PBIN);
if (await exists(`${PBIN}/patchelf`)) {
  console.log("already installed");
} else {
  await step(["curl", "-fsSL", PATCHELF_URL, "-o", `${DL}/patchelf.tar.gz`]);
  const line = await sha256(`${DL}/patchelf.tar.gz`);
  console.log(line);
  await writeFile(`${DL}/patchelf.sha256`, `${line}\n`);
  await mkdirp(`${DL}/patchelf`);
  await step(["tar", "-xzf", `${DL}/patchelf.tar.gz`, "-C", `${DL}/patchelf`]);
  await step(["cp", `${DL}/patchelf/bin/patchelf`, `${PBIN}/patchelf`]);
  await step(["chmod", "+x", `${PBIN}/patchelf`]);
}
const PATH = `${PBIN}:${env("PATH")}`;
await step(["patchelf", "--version"], { env: { PATH } });

console.log("== 3/4 Fil-C setup.sh");
if (await exists(`${FILC}/.setup-done`)) {
  console.log("already run");
} else {
  await step(["./setup.sh"], { cwd: FILC, env: { PATH } });
  await writeFile(`${FILC}/.setup-done`, "");
}

console.log("== 4/4 Bun");
// Installed by the documented first-time step (tools/README.md), not here: this tool runs on it.
const bun = `${HOME}/.bun/bin/bun`;
console.log((await exists(bun)) ? "already installed" : `not at ${bun}; running under ${process.execPath}`);
await step([(await exists(bun)) ? bun : process.execPath, "--version"]);

console.log("== done");
