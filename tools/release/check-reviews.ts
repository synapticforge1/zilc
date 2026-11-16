// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
/**
 * Is this commit a reviewed release commit? (review round 1, class 1, 2026-11-15.) CI's `checks`
 * runs it on every push to `main` whose version has no tag yet, BEFORE it decides to tag; release.ts
 * runs the same check before it pushes.
 *
 *   bun tools/release/check-reviews.ts <commit>
 *
 * Exit 0 only when ALL hold for build.zig.zon's version at <commit>:
 *   - <commit>'s subject is the bump commit's, `bump to v<version>`, and it changes only the bump's
 *     three files (guards.ts BUMP_FILES);
 *   - cmem/release.md (at <commit>) has exactly one `### v<version>` entry, and it holds exactly
 *     one Security and one Hardening review record in the fixed form (guards.ts REVIEW_FORM);
 *   - each record starts at the previous release's tag and names a commit in the released history
 *     after which only `cmem/` and RELEASE-NOTES.md changed;
 *   - GitHub's own renderer (`POST /markdown`, KI-38) shows every counted place: the entry heading
 *     and both records, the notes heading, the README status line, the State row. CI passes its
 *     GITHUB_TOKEN; `ZILC_GITHUB_API` points the renderer elsewhere (the tests' stand-in).
 * Exit 1 with the reasons otherwise; exit 2 when git itself fails (a failure is never a pass).
 */
import { bumpSubject, findEntry, gitIn, githubRender, renderedProblems, reviewRecords, reviewsCoverRelease, zonVersion } from "./guards.ts";
import { join } from "node:path";

const REPO = join(import.meta.dir, "..", "..");
const git = gitIn(REPO);

function fail(code: number, msg: string): never {
  console.error(`check-reviews: ${msg}`);
  process.exit(code);
}

const args = process.argv.slice(2);
if (args.length !== 1) fail(2, "usage: bun tools/release/check-reviews.ts <commit>");

try {
  const head = await git("rev-parse", "-q", "--verify", `${args[0]}^{commit}`);
  if (head.code !== 0) fail(2, `${args[0]} is not a commit`);
  const sha = head.out.trim();
  const show = async (path: string) => {
    const r = await git("show", `${sha}:${path}`);
    if (r.code !== 0) fail(2, `cannot read ${path} at ${sha}: ${r.out.trim()}`);
    return r.out;
  };
  const v = zonVersion(await show("build.zig.zon"));
  if (!v) fail(1, "cannot read build.zig.zon's .version as <Zig>-<Fil-C>.<N> (exactly one line)");
  const subject = await git("log", "-1", "--format=%s", sha);
  if (subject.code !== 0) fail(2, `git log failed: ${subject.out.trim()}`);
  if (subject.out.trim() !== bumpSubject(v.full)) fail(1, `${sha.slice(0, 7)} is not the bump commit "${bumpSubject(v.full)}" (its subject: "${subject.out.trim()}")`);
  const entry = findEntry(await show("cmem/release.md"), v.full);
  if (!entry) fail(1, `cmem/release.md has no "### v${v.full}" entry`);
  const bad = await reviewsCoverRelease(git, entry, sha, true);
  if (bad.length) fail(1, `v${v.full} is not ready:\n  ${bad.join("\n  ")}`);
  // What a reader of the GitHub page sees (KI-38): every counted place, rendered by GitHub itself.
  // A render that fails throws, and is exit 2 below — never a pass.
  const files = { release: await show("cmem/release.md"), notes: await show("RELEASE-NOTES.md"), readme: await show("README.md"), openWork: await show("cmem/open-work.md") };
  const unseen = await renderedProblems(githubRender(), files, v, reviewRecords(entry).records);
  if (unseen.length) fail(1, `v${v.full} is not ready — GitHub would not show:\n  ${unseen.join("\n  ")}`);
  console.log(`check-reviews: v${v.full} at ${sha.slice(0, 7)} — the bump commit, both required reviews recorded and covering everything since the previous release, every counted place shown by GitHub's renderer`);
} catch (e) {
  fail(2, (e as Error).message);
}
