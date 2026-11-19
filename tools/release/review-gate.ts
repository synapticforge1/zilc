// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
/**
 * The review gate: the release tooling's FIRST step (workspace review standard § 9, letter H37 (d);
 * it replaced check-reviews.ts and its two record lines, letter H35, on 2026-11-19). A review is run
 * by agents, not by a script; what a script can check is that one was completed on the code being
 * released. `release.ts` runs it before anything else. CI no longer runs it: every gate runs
 * locally, and CI only publishes (H37 (e)).
 *
 *   bun tools/release/review-gate.ts <commit>
 *
 * Exit 0 only when ALL hold for build.zig.zon's version at <commit>:
 *   - <commit>'s subject is the bump commit's, `bump to v<version>`, and it is exactly bump.ts's
 *     edits of its parent (guards.ts BUMP_FILES, bumpEdits);
 *   - cmem/release.md (at <commit>) has exactly one `### v<version>` entry;
 *   - cmem/review-process.md (at <commit>) holds exactly ONE line `- Review complete: <reviewed>`
 *     (guards.ts REVIEW_FORM), and <reviewed> is in the released history with only `cmem/` and
 *     RELEASE-NOTES.md changed after it;
 *   - GitHub's own renderer (`POST /markdown`, KI-38) shows every counted version place: the entry
 *     heading, the notes heading, the README status line, the State row. `GITHUB_TOKEN` lifts the
 *     unauthenticated rate limit; `ZILC_GITHUB_API` points the renderer elsewhere (the tests).
 * Exit 1 with the reasons otherwise; exit 2 when git itself fails (a failure is never a pass).
 */
import { REVIEW_RECORD_FILE, bumpSubject, findEntry, gitIn, githubRender, renderedProblems, reviewCoversRelease, zonVersion } from "./guards.ts";
import { join } from "node:path";

const REPO = join(import.meta.dir, "..", "..");
const git = gitIn(REPO);

function fail(code: number, msg: string): never {
  console.error(`review-gate: ${msg}`);
  process.exit(code);
}

const args = process.argv.slice(2);
if (args.length !== 1) fail(2, "usage: bun tools/release/review-gate.ts <commit>");

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
  if (!findEntry(await show("cmem/release.md"), v.full)) fail(1, `cmem/release.md has no "### v${v.full}" entry`);
  const bad = await reviewCoversRelease(git, await show(REVIEW_RECORD_FILE), sha, true);
  if (bad.length) fail(1, `v${v.full} is not reviewed:\n  ${bad.join("\n  ")}`);
  // What a reader of the GitHub page sees (KI-38): every counted place, rendered by GitHub itself.
  // A render that fails throws, and is exit 2 below — never a pass.
  const files = { release: await show("cmem/release.md"), notes: await show("RELEASE-NOTES.md"), readme: await show("README.md"), openWork: await show("cmem/open-work.md") };
  const unseen = await renderedProblems(githubRender(), files, v);
  if (unseen.length) fail(1, `v${v.full} is not ready — GitHub would not show:\n  ${unseen.join("\n  ")}`);
  console.log(`review-gate: v${v.full} at ${sha.slice(0, 7)} — the bump commit, covered by the completed review, every counted place shown by GitHub's renderer`);
} catch (e) {
  fail(2, (e as Error).message);
}
