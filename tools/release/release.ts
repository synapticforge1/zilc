// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
/**
 * The release script (workspace release-process.md § 5 U4, letter H33): ONE command that runs
 * every check and gate, locally, then pushes `main` — and nothing else. **It makes and pushes NO
 * tag**: CI's `release.yml` only publishes — it verifies the version, tags the pushed commit and
 * makes the GitHub Release page (U5–U7; the final review standard, letter H37 (e): "every gate, the
 * test suites included, runs locally and is not repeated on GitHub"). Run it on the owner's word
 * "release", after `bun tools/release/bump.ts release` made the bump commit.
 *
 *   bun tools/release/release.ts            # the review gate, guards, the gates, then push + read back
 *   bun tools/release/release.ts --dry-run  # everything but the push
 *
 * In order, each refusing with exit 1:
 *   - FIRST, the review gate (`review-gate.ts HEAD`; H37 (d)): HEAD is the bump commit, exactly
 *     bump.ts's edits; cmem/review-process.md's one `- Review complete: <commit>` line names a
 *     commit after which only `cmem/` and RELEASE-NOTES.md changed; GitHub shows every place;
 *   - a clean tree (untracked files count), on `main`;
 *   - `origin/main` (fetched) is an ancestor of `main`: the push is a fast-forward;
 *   - the tag `v<version>` is absent locally and on origin (`git ls-remote`);
 *   - `bump.ts --check`: the five places agree;
 *   - the privacy gate: no private file tracked (`cmem/review-issues.md`, `cmem/local/`, `.claude/`,
 *     `CLAUDE.md`; H37 (b)), and the path scan (cmem/working-rules.md § Privacy) finds nothing;
 *   - the gates: `zig fmt --check`, Biome's Markdown check, `zig build test`, the release scripts'
 *     tests, and `bun tools/run-gate.ts` (the Fil-C safety gate, 10/10).
 * Then `git push origin main` (no tags, no force) and a read-back of `refs/heads/main`.
 */
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { ARGS, REPO, ZIG, linuxOnly, must, run } from "../lib/tool.ts";
import { gitIn, privateFilesTracked, tagsDifferFrom, zonVersion } from "./guards.ts";

await linuxOnly(import.meta);

function fail(msg: string): never {
  console.error(`release: ${msg}`);
  process.exit(1);
}
const dryRun = ARGS.includes("--dry-run");
for (const a of ARGS) if (a !== "--dry-run") fail(`unknown argument "${a}" — use --dry-run or nothing`);

// A time limit on every git call (KI-31): a hung remote is a refusal, never a wait forever.
const git = (...a: string[]) => must(["git", "-C", REPO, ...a], { timeout: 120 }).then((s) => s.trim());

const version = (zonVersion(readFileSync(join(REPO, "build.zig.zon"), "utf8")) ?? fail("cannot read build.zig.zon's .version")).full;
const tag = `v${version}`;

// ---- FIRST: the review gate (workspace review standard § 9, letter H37 (d)). It also refuses a
// HEAD that is not the bump commit (run bun tools/release/bump.ts release).
const rev = await run(["bun", join(REPO, "tools/release/review-gate.ts"), "HEAD"], { cwd: REPO });
if (rev.code !== 0) fail(`the review gate — run "review" first (H37):\n${rev.out.trimEnd()}`);
console.log(`release: ${rev.out.trim()}`);

// ---- guards
if (await git("status", "--porcelain", "--untracked-files=all")) fail("the tree is not clean (untracked files count)");
if ((await git("rev-parse", "--abbrev-ref", "HEAD")) !== "main") fail("not on main");
await git("fetch", "-q", "--tags", "origin");
// The release tags here and on origin agree, so the tag CI makes is the one checked here (KI-30).
const tagDiff = await tagsDifferFrom(gitIn(REPO));
if (tagDiff.length) fail(`the release tags here and on origin differ:\n  ${tagDiff.join("\n  ")}`);
if ((await run(["git", "-C", REPO, "merge-base", "--is-ancestor", "origin/main", "main"])).code !== 0) fail("origin/main is not an ancestor of main: the push would not be a fast-forward");
if ((await run(["git", "-C", REPO, "rev-parse", "-q", "--verify", `refs/tags/${tag}`])).code === 0) fail(`tag ${tag} exists locally — a release never reuses a tag (CI makes the tag)`);
if (await git("ls-remote", "--tags", "origin", `refs/tags/${tag}`)) fail(`tag ${tag} exists on origin — this version was released before`);
console.log(`release: ${tag} — guards pass; main ${(await git("rev-parse", "--short", "main"))}, origin/main ${(await git("rev-parse", "--short", "origin/main"))}`);

// ---- the five places
const chk = await run(["bun", join(REPO, "tools/release/bump.ts"), "--check"], { cwd: REPO });
if (chk.code !== 0) fail(`bump.ts --check:\n${chk.out.trimEnd()}`);

// ---- the privacy gate (a gate STOPS a push; workspace review standard § 10)
const tracked = (await git("ls-files", "-z")).split("\0").filter(Boolean);
const privateOnes = privateFilesTracked(tracked);
if (privateOnes.length) fail(`private file(s) TRACKED — untrack them (git rm --cached): ${privateOnes.join(", ")}`);
const pattern = "[A-Za-z]:[\\\\/]+(Programs|Users|scoop|tools)[\\\\/]|/[a-z]/(Programs|Users)/";
for (const flag of ["-I", "-a"]) {
  const s = await run(["git", "-C", REPO, "grep", flag, "-l", "-i", "-E", pattern]);
  // The one permitted hit is the rule's own text: cmem/working-rules.md § Privacy names the path
  // shapes it forbids (measured 2026-11-12: the only file that hits).
  const hits = s.out.split("\n").filter((l) => l && l !== "cmem/working-rules.md");
  if (s.code === 0 && hits.length) fail(`the privacy scan (${flag}) found: ${hits.join(", ")}`);
}

// ---- the gates (all local: CI runs none of them, H37 (e))
// Each with a time limit (review 1, H12): a hung step is a refusal, never a wait forever. The
// limits are several times the runs measured here (zig build test ~40 s, the Fil-C gate minutes).
const steps: [string, string[], RegExp | null, number][] = [
  ["zig fmt --check", [ZIG, "fmt", "--check", "build.zig", "build", "tools", "tests", "src"], null, 300],
  ["Markdown formatting (Biome)", ["bun", "tools/md/biome.ts", "ci", "--colors=off", "."], null, 600],
  ["zig build test", [ZIG, "build", "test", "--summary", "all"], /Build Summary: (\d+)\/\1 steps succeeded/, 1800],
  ["the tools' tests", ["bun", "test", "tools/release/", "tools/lib/"], / 0 fail/, 1800],
  ["the Fil-C gate", ["bun", "tools/run-gate.ts"], /gate: (\d+)\/\1 cases passed/, 3600],
];
for (const [name, argv, want, timeout] of steps) {
  const r = await run(argv, { cwd: REPO, timeout });
  if (r.code !== 0 || (want && !want.test(r.out))) {
    console.error(r.out.trimEnd().split("\n").slice(-20).join("\n"));
    fail(r.timedOut ? `${name} took longer than ${timeout} s and was stopped` : `${name} failed (exit ${r.code})`);
  }
  console.log(`release: ${name} — ok`);
}

if (dryRun) {
  console.log(`release: dry run — would push main (${await git("rev-parse", "--short", "main")}) to origin; no tag (CI tags ${tag} after it verifies the version)`);
  process.exit(0);
}

// ---- push main only, read it back
await must(["git", "-C", REPO, "push", "origin", "main"], { timeout: 300 });
const local = await git("rev-parse", "main");
const remote = (await git("ls-remote", "origin", "refs/heads/main")).split(/\s+/)[0];
if (remote !== local) fail(`read-back: origin's main is ${remote}, local main is ${local}`);
console.log(`release: pushed main = ${local.slice(0, 7)} (read back with ls-remote). CI's release.yml now verifies the version, tags ${tag} and makes the Release page; record the run in cmem/release.md.`);
