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
 * name the new version, or a `cmem/release.md` entry for it that does not record BOTH required
 * reviews (security, hardening — workspace review-process.md § 0, letter H35). Writes the
 * mechanical places (build.zig.zon, src/root.zig's `release` and its test literals, the README
 * status line), runs `zig build test` (and puts every file back if it fails), then commits.
 */
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { ARGS, REPO, ZIG, linuxOnly, must, run } from "../lib/tool.ts";

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
const read = (f: string) => readFileSync(P(f), "utf8");

/** The version every place must agree on, read from build.zig.zon. */
function zonVersion(): { full: string; zig: string; filc: string; n: number } {
  const m = read("build.zig.zon").match(/^\s*\.version = "(\d+\.\d+\.\d+)-(\d+\.\d+)\.(\d+)",$/m);
  if (!m) fail("cannot read build.zig.zon's .version as <Zig>-<Fil-C>.<N>");
  return { full: `${m[1]}-${m[2]}.${m[3]}`, zig: m[1], filc: m[2], n: Number(m[3]) };
}

/** Each place's disagreement with `v`, or [] when all five agree. */
function disagreements(v: string, zig: string, filc: string, n: number): string[] {
  const bad: string[] = [];
  const root = read("src/root.zig");
  const zl = root.match(/^pub const zig_line = std\.SemanticVersion\{ \.major = (\d+), \.minor = (\d+), \.patch = (\d+) \};$/m);
  if (!zl || `${zl[1]}.${zl[2]}.${zl[3]}` !== zig) bad.push(`src/root.zig zig_line is not ${zig}`);
  if (!new RegExp(`^pub const filc_release = "${filc.replace(".", "\\.")}";$`, "m").test(root)) bad.push(`src/root.zig filc_release is not "${filc}"`);
  if (!new RegExp(`^pub const release = ${n};$`, "m").test(root)) bad.push(`src/root.zig release is not ${n}`);
  if (!root.includes(`expectEqualStrings("${v}", version_string)`)) bad.push(`src/root.zig's version test does not pin "${v}"`);
  const status = read("README.md").split("\n").find((l) => l.startsWith("> **Status:"));
  if (!status?.includes(`v${v}: zilc release ${n} for Zig ${zig} and Fil-C ${filc}`)) bad.push(`README.md's status line does not name v${v} (zilc release ${n})`);
  if (!new RegExp(`^## ${v.replaceAll(".", "\\.")}$`, "m").test(read("RELEASE-NOTES.md"))) bad.push(`RELEASE-NOTES.md has no "## ${v}" section`);
  const state = read("cmem/open-work.md").split("\n").find((l) => l.startsWith("| version |"));
  if (!state?.includes(`\`${v}\``)) bad.push(`cmem/open-work.md's State row "| version |" does not name \`${v}\``);
  return bad;
}

const cur = zonVersion();

if (kind === "--check") {
  const bad = disagreements(cur.full, cur.zig, cur.filc, cur.n);
  if (bad.length) fail(`the five places disagree on ${cur.full}:\n  ${bad.join("\n  ")}`);
  console.log(`bump --check: build.zig.zon, src/root.zig, README.md, RELEASE-NOTES.md and cmem/open-work.md agree on ${cur.full}`);
  process.exit(0);
}

// ---- kind === "release"
const porcelain = await must(["git", "-C", REPO, "status", "--porcelain", "--untracked-files=all"]);
if (porcelain.trim()) fail(`the tree is not clean (untracked files count):\n${porcelain.trimEnd()}`);
const before = disagreements(cur.full, cur.zig, cur.filc, cur.n).filter((b) => !b.startsWith("RELEASE-NOTES") && !b.startsWith("cmem/open-work"));
if (before.length) fail(`the current version ${cur.full} is not consistent before the bump:\n  ${before.join("\n  ")}`);

const n2 = cur.n + 1;
const next = `${cur.zig}-${cur.filc}.${n2}`;
const after = `${cur.zig}-${cur.filc}.${n2 + 1}`;

// The prose places a person writes BEFORE the bump (U2: the notes are merged first).
const pre: string[] = [];
if (!new RegExp(`^## ${next.replaceAll(".", "\\.")}$`, "m").test(read("RELEASE-NOTES.md"))) pre.push(`RELEASE-NOTES.md has no "## ${next}" section — write the release notes first`);
const stateRow = read("cmem/open-work.md").split("\n").find((l) => l.startsWith("| version |"));
if (!stateRow?.includes(`\`${next}\``)) pre.push(`cmem/open-work.md's State row "| version |" does not name \`${next}\``);
const rel = read("cmem/release.md");
const entry = rel.split(/^### /m).find((s) => s.startsWith(`v${next}`) || s.startsWith(next));
if (!entry) pre.push(`cmem/release.md § "Release History" has no "### v${next}" entry`);
else {
  if (!/security review/i.test(entry)) pre.push(`cmem/release.md's v${next} entry records no security review (required before every release — H35)`);
  if (!/hardening review/i.test(entry)) pre.push(`cmem/release.md's v${next} entry records no hardening review (required before every release — H35)`);
}
if (pre.length) fail(`not ready to bump to ${next}:\n  ${pre.join("\n  ")}`);

/** Replace `from` with `to` in `file`, asserting exactly one match. */
const edits = new Map<string, string>();
function replaceOnce(file: string, from: string, to: string) {
  const text = edits.get(file) ?? read(file);
  const count = text.split(from).length - 1;
  if (count !== 1) fail(`${file}: expected exactly one "${from}", found ${count}`);
  edits.set(file, text.replace(from, to));
}
replaceOnce("build.zig.zon", `.version = "${cur.full}",`, `.version = "${next}",`);
replaceOnce("src/root.zig", `pub const release = ${cur.n};`, `pub const release = ${n2};`);
replaceOnce("src/root.zig", `expectEqualStrings("${cur.full}", version_string)`, `expectEqualStrings("${next}", version_string)`);
replaceOnce("src/root.zig", `version_string)); // the release before`, `version_string)); // the release before`); // asserts the line exists
{
  const root = edits.get("src/root.zig")!;
  const m = root.match(/order\("([^"]+)", version_string\)\); \/\/ the release before/);
  const m2 = root.match(/order\(version_string, "([^"]+)"\)\); \/\/ next zilc release/);
  if (!m || !m2) fail("src/root.zig: the ordering test's 'the release before' / 'next zilc release' lines are missing");
  replaceOnce("src/root.zig", `order("${m[1]}", version_string)); // the release before`, `order("${cur.full}", version_string)); // the release before`);
  replaceOnce("src/root.zig", `order(version_string, "${m2[1]}")); // next zilc release`, `order(version_string, "${after}")); // next zilc release`);
}
replaceOnce("README.md", `v${cur.full}: zilc release ${cur.n} for Zig`, `v${next}: zilc release ${n2} for Zig`);

const originals = new Map<string, string>();
for (const [f, t] of edits) {
  originals.set(f, read(f));
  writeFileSync(P(f), t);
}
for (const f of edits.keys()) console.log(`  wrote ${f}`);

const putBack = () => {
  for (const [f, t] of originals) writeFileSync(P(f), t);
};
const left = disagreements(next, cur.zig, cur.filc, n2);
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
writeFileSync(msgFile, `bump to v${next}\n`);
await must(["git", "-C", REPO, "add", "--", ...edits.keys()]);
await must(["git", "-C", REPO, "commit", "-q", "-F", msgFile]);
console.log(`bump: committed "bump to v${next}" (${(await must(["git", "-C", REPO, "rev-parse", "--short", "HEAD"])).trim()}). Next: bun tools/release/release.ts`);
