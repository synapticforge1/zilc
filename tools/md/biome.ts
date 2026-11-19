// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
/**
 * zilc's Markdown formatting check: Biome, pinned (owner, 2026-11-15: "biome. I know it works
 * correctly" — the tool the other projects chose; replacing the release guards' own Markdown
 * rules, review round 1 KI-38).
 *
 *   bun tools/md/biome.ts ci .              # check every tracked .md (CI's `checks`, release.ts)
 *   bun tools/md/biome.ts format --write .  # reformat them
 *
 * Any arguments are passed to Biome; the configuration is at the repository root
 * (`biome.jsonc`, Markdown only). Biome is fetched once from npm's `@biomejs/cli-linux-x64` package into
 * `$WORK/tools/biome-<version>/` and checked against the sha256 recorded here before it ever runs
 * (U9: tools pinned by version AND hash, like Zig and Bun). Biome 2.5.x ignores `.md` files
 * (measured 2026-11-15: "These paths were provided but ignored"); 2.6.0 (2026-10-21) is the first
 * line with Markdown. Move the pin by changing both lines below together.
 */
import { existsSync } from "node:fs";
import { chmod, mkdir, rename, rm, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { ARGS, REPO, WORK, linuxOnly, must, run, sha256 } from "../lib/tool.ts";

await linuxOnly(import.meta);

export const BIOME_VERSION = "2.6.4";
/** sha256 of `cli-linux-x64-2.6.4.tgz` as downloaded 2026-11-15; its sha512 equalled the registry's
 *  `dist.integrity` (sha512-tbFZMdL6dP/ws4edXxYG9WhvaVa1ZDzL4G5DzahnWW7Psib9H+VTdyU4XXVxpJk5j/nYZroSbvSNyYlpW3yCIw==). */
export const BIOME_SHA256 = "71d293b521e97daf9095710abcd361a212e81e8f53c939726e4263613a763bf8";

const dir = join(WORK, "tools", `biome-${BIOME_VERSION}`);
const bin = join(dir, "biome");

function fail(msg: string): never {
  console.error(`biome.ts: ${msg}`);
  process.exit(2);
}

if (!existsSync(bin)) {
  const url = `https://registry.npmjs.org/@biomejs/cli-linux-x64/-/cli-linux-x64-${BIOME_VERSION}.tgz`;
  const r = await fetch(url, { signal: AbortSignal.timeout(120_000) }).catch((e: Error) => fail(`cannot fetch ${url}: ${e.message}`));
  if (!r.ok) fail(`${url}: HTTP ${r.status}`);
  const bytes = new Uint8Array(await r.arrayBuffer());
  const got = await sha256(bytes);
  if (got !== BIOME_SHA256) fail(`SHA MISMATCH for ${url}: got ${got}, want ${BIOME_SHA256} — nothing installed`);
  const tmp = `${dir}.part`;
  await rm(tmp, { recursive: true, force: true });
  await mkdir(tmp, { recursive: true });
  await writeFile(join(tmp, "biome.tgz"), bytes);
  await must(["tar", "-xzf", join(tmp, "biome.tgz"), "-C", tmp, "package/biome"], { timeout: 120 });
  await chmod(join(tmp, "package", "biome"), 0o755);
  await mkdir(dir, { recursive: true });
  await rename(join(tmp, "package", "biome"), bin);
  await rm(tmp, { recursive: true, force: true });
}

// The binary is the pinned one: its own version line, not only the path's name.
const v = await run([bin, "--version"], { timeout: 30 });
if (v.code !== 0 || !v.out.includes(`Version: ${BIOME_VERSION}`)) fail(`${bin} is not Biome ${BIOME_VERSION} (${v.out.trim()}); delete ${dir} to fetch it again`);

const r = await run([bin, ...ARGS], { cwd: REPO, inherit: true, timeout: 600 });
process.exit(r.code);
