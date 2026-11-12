// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
/**
 * The release script (workspace release-process.md § 5 U4, letter H33): ONE command that checks
 * everything the owner's machine can check, then pushes `main` — and nothing else. **It makes and
 * pushes NO tag**: CI's `release.yml` checks the pushed commit, tags it and makes the GitHub
 * Release page (U5–U7; owner, 2026-11-10: "the CI to check first, then push the tag, and then
 * create the release page from the tag"). Run it on the owner's word "release", after
 * `bun tools/release/bump.ts release` made the bump commit.
 *
 *   bun tools/release/release.ts            # guards, the cold gate, then push main + read back
 *   bun tools/release/release.ts --dry-run  # every guard and the gate, no push
 *
 * Guards, each refusing with exit 1:
 *   - a clean tree (untracked files count), on `main`, HEAD is the bump commit `bump to v<version>`;
 *   - `origin/main` (fetched) is an ancestor of `main`: the push is a fast-forward;
 *   - the tag `v<version>` is absent locally and on origin (`git ls-remote`);
 *   - `bump.ts --check`: the five places agree; cmem/release.md's entry records both required
 *     reviews (security, hardening — H35);
 *   - the privacy scan (cmem/working-rules.md § Privacy) finds nothing in the tree;
 *   - the cold gate: `zig fmt --check`, `zig build test`, the release scripts' tests, and
 *     `bun tools/run-gate.ts` (the Fil-C safety gate, 8/8 — the half CI cannot run: a runner has
 *     no Fil-C toolchain; cmem/release.md § "What runs where").
 * Then `git push origin main` (no tags, no force) and a read-back of `refs/heads/main`.
 */
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { ARGS, REPO, ZIG, linuxOnly, must, run } from "../lib/tool.ts";

await linuxOnly(import.meta);

function fail(msg: string): never {
  console.error(`release: ${msg}`);
  process.exit(1);
}
const dryRun = ARGS.includes("--dry-run");
for (const a of ARGS) if (a !== "--dry-run") fail(`unknown argument "${a}" — use --dry-run or nothing`);

const git = (...a: string[]) => must(["git", "-C", REPO, ...a]).then((s) => s.trim());

const m = readFileSync(join(REPO, "build.zig.zon"), "utf8").match(/^\s*\.version = "(\d+\.\d+\.\d+-\d+\.\d+\.\d+)",$/m);
if (!m) fail("cannot read build.zig.zon's .version");
const version = m[1];
const tag = `v${version}`;

// ---- guards
if (await git("status", "--porcelain", "--untracked-files=all")) fail("the tree is not clean (untracked files count)");
if ((await git("rev-parse", "--abbrev-ref", "HEAD")) !== "main") fail("not on main");
if ((await git("log", "-1", "--format=%s")) !== `bump to ${tag}`) fail(`HEAD is not the bump commit "bump to ${tag}" (run bun tools/release/bump.ts release)`);
await git("fetch", "-q", "origin");
if ((await run(["git", "-C", REPO, "merge-base", "--is-ancestor", "origin/main", "main"])).code !== 0) fail("origin/main is not an ancestor of main: the push would not be a fast-forward");
if ((await run(["git", "-C", REPO, "rev-parse", "-q", "--verify", `refs/tags/${tag}`])).code === 0) fail(`tag ${tag} exists locally — a release never reuses a tag (CI makes the tag)`);
if (await git("ls-remote", "--tags", "origin", `refs/tags/${tag}`)) fail(`tag ${tag} exists on origin — this version was released before`);
console.log(`release: ${tag} — guards pass; main ${(await git("rev-parse", "--short", "main"))}, origin/main ${(await git("rev-parse", "--short", "origin/main"))}`);

// ---- the five places and the reviews
const chk = await run(["bun", join(REPO, "tools/release/bump.ts"), "--check"], { cwd: REPO });
if (chk.code !== 0) fail(`bump.ts --check:\n${chk.out.trimEnd()}`);
const rel = readFileSync(join(REPO, "cmem/release.md"), "utf8");
const entry = rel.split(/^### /m).find((s) => s.startsWith(tag) || s.startsWith(version));
if (!entry || !/security review/i.test(entry) || !/hardening review/i.test(entry)) fail(`cmem/release.md has no ${tag} entry recording both required reviews (H35)`);

// ---- privacy (a scan STOPS a push — workspace review-process.md § 3.1 item 7)
const pattern = "[A-Za-z]:[\\\\/]+(Programs|Users|scoop|tools)[\\\\/]|/[a-z]/(Programs|Users)/";
for (const flag of ["-I", "-a"]) {
  const s = await run(["git", "-C", REPO, "grep", flag, "-l", "-i", "-E", pattern]);
  // The one permitted hit is the rule's own text: cmem/working-rules.md § Privacy names the path
  // shapes it forbids (measured 2026-11-12: the only file that hits).
  const hits = s.out.split("\n").filter((l) => l && l !== "cmem/working-rules.md");
  if (s.code === 0 && hits.length) fail(`the privacy scan (${flag}) found: ${hits.join(", ")}`);
}

// ---- the cold gate
const steps: [string, string[], RegExp | null][] = [
  ["zig fmt --check", [ZIG, "fmt", "--check", "build.zig", "build", "tools", "tests", "src"], null],
  ["zig build test", [ZIG, "build", "test", "--summary", "all"], /Build Summary: (\d+)\/\1 steps succeeded/],
  ["release scripts' tests", ["bun", "test", "tools/release/"], / 0 fail/],
  ["the Fil-C gate", ["bun", "tools/run-gate.ts"], /gate: (\d+)\/\1 cases passed/],
];
for (const [name, argv, want] of steps) {
  const r = await run(argv, { cwd: REPO });
  if (r.code !== 0 || (want && !want.test(r.out))) {
    console.error(r.out.trimEnd().split("\n").slice(-20).join("\n"));
    fail(`${name} failed (exit ${r.code})`);
  }
  console.log(`release: ${name} — ok`);
}

if (dryRun) {
  console.log(`release: dry run — would push main (${await git("rev-parse", "--short", "main")}) to origin; no tag (CI tags ${tag} after its checks)`);
  process.exit(0);
}

// ---- push main only, read it back
await must(["git", "-C", REPO, "push", "origin", "main"]);
const local = await git("rev-parse", "main");
const remote = (await git("ls-remote", "origin", "refs/heads/main")).split(/\s+/)[0];
if (remote !== local) fail(`read-back: origin's main is ${remote}, local main is ${local}`);
console.log(`release: pushed main = ${local.slice(0, 7)} (read back with ls-remote). CI's release.yml now checks it, tags ${tag} and makes the Release page; record the run in cmem/release.md.`);
