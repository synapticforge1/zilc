// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
/**
 * The bump tool (workspace release-process.md § 5 U2–U3, letter H33): makes zilc's version bump
 * as its own commit, `bump to v<version>`, after the release notes are merged.
 *
 *   bun tools/release/bump.ts release   # 0.15.2-0.687.N -> 0.15.2-0.687.(N+1)
 *   bun tools/release/bump.ts --check   # the five places agree on the current version (CI runs it)
 *
 * The kind is an ARGUMENT, never a default (U1). zilc's version is `<Zig>-<Fil-C>.<N>`
 * (cmem/releasing.md): the one routine move is `release` (N + 1). A new Fil-C or Zig release is
 * zilc's upgrade procedure (releasing.md "Per-release checklist", upstream.md), which moves every
 * pin together and resets N to 1 — the tool refuses those kinds and points there. U3's floor (a
 * level computed from a surface diff) does not apply: the version deliberately encodes no
 * compatibility (releasing.md "No 1.0"; release-process.md § 7's zilc card) — so neither do the
 * previous release's tests, which pin the previous version string by design.
 *
 * Refuses: a dirty tree (untracked files count); places that disagree on the current version;
 * a missing `## <new>` section in RELEASE-NOTES.md, a State row in cmem/open-work.md that does not
 * begin with the new version, no `### v<new>` entry in `cmem/release.md`, or no completed review
 * covering HEAD: the one `- Review complete: <commit>` line in cmem/review-process.md (guards.ts
 * REVIEW_FORM; the workspace review standard, letter H37), naming a commit after which only `cmem/`
 * and RELEASE-NOTES.md changed. Writes the
 * mechanical places (build.zig.zon, src/root.zig's `release` and its test literals, the README
 * status line), runs `zig build test` (and puts every file back if it fails), then commits.
 */
import { lstatSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { ARGS, REPO, ZIG, linuxOnly, must, run } from "../lib/tool.ts";
import { BUMP_FILES, REVIEW_RECORD_FILE, bumpEdits, bumpSubject, findEntry, gitIn, githubRender, renderedProblems, tagsDifferFrom, disagreements as placeDisagreements, reviewCoversRelease, zonVersion, type Places, type Version } from "./guards.ts";

await linuxOnly(import.meta);

function fail(msg: string): never {
  console.error(`bump: ${msg}`);
  process.exit(1);
}

const kind = ARGS[0];
if (ARGS.length !== 1 || !["release", "--check", "filc", "zig"].includes(kind ?? "")) {
  fail("usage: bun tools/release/bump.ts release | --check   (the kind is required; nothing defaults)");
}
if (kind === "filc" || kind === "zig") {
  fail(`a ${kind === "filc" ? "Fil-C" : "Zig"} move is zilc's upgrade procedure, not a bump: cmem/releasing.md "Per-release checklist" and cmem/upstream.md (every pin moves together, N restarts at 1)`);
}

const P = (f: string) => join(REPO, f);
// A counted file that is a symlink is not what GitHub shows at that path (KI-36): refused.
const read = (f: string) => {
  if (lstatSync(P(f)).isSymbolicLink()) fail(`${f} is a symlink; GitHub shows the link, not the file it points to`);
  return readFileSync(P(f), "utf8");
};
const places = (): Places => ({ root: read("src/root.zig"), readme: read("README.md"), notes: read("RELEASE-NOTES.md"), openWork: read("cmem/open-work.md"), zon: read("build.zig.zon") });
const disagreements = (v: Version) => placeDisagreements(places(), v);

const cur = zonVersion(read("build.zig.zon")) ?? fail("cannot read build.zig.zon's .version as <Zig>-<Fil-C>.<N> (exactly one line)");

if (kind === "--check") {
  const bad = disagreements(cur);
  if (bad.length) fail(`the five places disagree on ${cur.full}:\n  ${bad.join("\n  ")}`);
  console.log(`bump --check: build.zig.zon, src/root.zig, README.md, RELEASE-NOTES.md and cmem/open-work.md agree on ${cur.full}`);
  process.exit(0);
}

// ---- kind === "release"
const porcelain = await must(["git", "-C", REPO, "status", "--porcelain", "--untracked-files=all"]);
if (porcelain.trim()) fail(`the tree is not clean (untracked files count):\n${porcelain.trimEnd()}`);
const before = disagreements(cur).filter((b) => !b.startsWith("RELEASE-NOTES") && !b.startsWith("cmem/open-work"));
if (before.length) fail(`the current version ${cur.full} is not consistent before the bump:\n  ${before.join("\n  ")}`);

const n2 = cur.n + 1;
const next = `${cur.zig}-${cur.filc}.${n2}`;
const nextV: Version = { full: next, zig: cur.zig, filc: cur.filc, n: n2 };

// The prose places a person writes BEFORE the bump (U2: the notes are merged first), and the
// completed review, recorded in the fixed form and checked against the history (guards.ts).
const pre = placeDisagreements(places(), nextV).filter((b) => b.startsWith("RELEASE-NOTES") || b.startsWith("cmem/open-work"));
let entry: string | null = null;
try {
  entry = findEntry(read("cmem/release.md"), next);
} catch (e) {
  pre.push((e as Error).message);
}
if (entry === null && !pre.some((p) => p.startsWith("cmem/release.md has"))) pre.push(`cmem/release.md § "Release History" has no "### v${next}" entry`);
if (entry !== null) {
  try {
    // The previous release is read from the tags; take origin's first, as CI will (KI-30).
    const f = await run(["git", "-C", REPO, "fetch", "-q", "--tags", "origin"], { timeout: 120 });
    if (f.code !== 0) fail(`git fetch --tags origin failed (exit ${f.code}): ${f.out.trim()}`);
    pre.push(...(await tagsDifferFrom(gitIn(REPO))));
    const head = (await must(["git", "-C", REPO, "rev-parse", "HEAD"])).trim();
    pre.push(...(await reviewCoversRelease(gitIn(REPO), read(REVIEW_RECORD_FILE), head, false)).map((b) => `${b} (required before every release — H37)`));
  } catch (e) {
    fail(`git failed while checking the review: ${(e as Error).message}`);
  }
  // The places a person wrote, as GitHub would show them (KI-38). The README's status line is the
  // bump's own edit, so review-gate.ts renders it after the bump.
  if (!pre.length) {
    try {
      pre.push(...(await renderedProblems(githubRender(), { release: read("cmem/release.md"), notes: read("RELEASE-NOTES.md"), openWork: read("cmem/open-work.md") }, nextV)));
    } catch (e) {
      fail(`GitHub's renderer could not be asked (a render that did not happen is never a pass): ${(e as Error).message}`);
    }
  }
}
if (pre.length) fail(`not ready to bump to ${next}:\n  ${pre.join("\n  ")}`);

// The edits themselves are guards.ts `bumpEdits`, so CI can recompute them and require the bump
// commit to be exactly these (KI-28).
// latin1 both ways: one character per byte, so every byte but the version text is kept exactly
// (a UTF-8 round trip would turn an invalid byte into U+FFFD — KI-29).
const readBytes = (f: string) => readFileSync(P(f), "latin1");
let edits: Map<string, string>;
try {
  edits = new Map(Object.entries(bumpEdits(Object.fromEntries(BUMP_FILES.map((f) => [f, readBytes(f)])), cur)));
} catch (e) {
  fail((e as Error).message);
}

const originals = new Map<string, string>();
for (const [f, t] of edits) {
  originals.set(f, readBytes(f));
  writeFileSync(P(f), t, "latin1");
}
for (const f of edits.keys()) console.log(`  wrote ${f}`);

const putBack = () => {
  for (const [f, t] of originals) writeFileSync(P(f), t, "latin1");
};
const left = disagreements(nextV);
if (left.length) {
  putBack();
  fail(`after the edits the places still disagree (every file put back):\n  ${left.join("\n  ")}`);
}
console.log(`bump: zig build test on ${next} …`);
const t = await run([ZIG, "build", "test", "--summary", "all"], { cwd: REPO });
if (t.code !== 0 || !/Build Summary: (\d+)\/\1 steps succeeded/.test(t.out)) {
  putBack();
  console.error(t.out.trimEnd());
  fail(`zig build test failed on ${next} (exit ${t.code}); every file put back`);
}
const msgFile = join(REPO, ".git", "BUMP_MSG");
writeFileSync(msgFile, `${bumpSubject(next)}\n`);
await must(["git", "-C", REPO, "add", "--", ...edits.keys()]);
await must(["git", "-C", REPO, "commit", "-q", "-F", msgFile]);
console.log(`bump: committed "bump to v${next}" (${(await must(["git", "-C", REPO, "rev-parse", "--short", "HEAD"])).trim()}). Next: bun tools/release/release.ts`);
