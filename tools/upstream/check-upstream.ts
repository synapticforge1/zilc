// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Monitor Fil-C upstream for changes that matter to zilc (cmem/upstream.md "The upstream/ reference
// folder"). Fetches upstream/fil-c, then reports, relative to the last REVIEWED commit: new commits,
// new release tags, commits touching the files zilc patches or depends on, and whether zilc's patches
// still apply to upstream's newest FilPizlonator.cpp and llvm-split.cpp. Needs git and Deno: runs on
// any OS (normally Windows, where the reference clone lives).
//
//   deno run -A tools/upstream/check-upstream.ts                  report only
//   deno run -A tools/upstream/check-upstream.ts --mark-reviewed  after reviewing: record upstream HEAD
//
// ⚠️ Every git command names its repo with -C and an absolute path (see clone-upstream.ts).
import { exists, must, REPO, run } from "../lib/tool.ts";

const u = `${REPO}/upstream/fil-c`;
const revFile = `${REPO}/tools/upstream/REVIEWED`;
if (!(await exists(`${u}/.git`))) {
  console.log("no upstream clone; run tools/upstream/clone-upstream.ts");
  Deno.exit(1);
}
const git = (...a: string[]) => must(["git", "-C", u, ...a]).then((s) => s.trim());

// Files whose changes zilc must look at, and why.
const watch: [string, string][] = [
  ["llvm/lib/Transforms/Instrumentation/FilPizlonator.cpp", "zilc patches it (KI-4, KI-22) and works around it (KI-18)"],
  ["llvm/include/llvm/Transforms/Instrumentation", "the pass's interface"],
  ["llvm/lib/CodeGen/IndirectBrExpandPass.cpp", "the code KI-4's broken lowering was copied from"],
  ["llvm/tools/llvm-split/llvm-split.cpp", "zilc patches it (KI-22 lever a, parallel code generation)"],
  ["llvm/lib/Transforms/Utils/SplitModule.cpp", "the stock split zilc's mode replaces (use-list order)"],
  ["configure_llvm.sh", "tools/filc/build-patched-clang.ts mirrors it"],
  ["libpas/common.sh", "the build's architecture settings"],
  ["filc/include", "the runtime's public ABI (filc-abi.md)"],
  ["invisicap.txt", "design docs zilc's notes rely on"],
  ["gimso_semantics.md", ""],
  ["versioning-checklist.md", "how releases are cut"],
  ["filc/tests", "Fil-C's own test suite, run against zilc's clang (run-filc-tests.ts)"],
];

await must(["git", "-C", u, "fetch", "-q", "origin", "deluge", "--tags"]);
const reviewedLine = (await Deno.readTextFile(revFile)).trim();
const reviewed = reviewedLine.split(" ")[0];
const head = await git("rev-parse", "origin/deluge");
await must(["git", "-C", u, "checkout", "-q", "--detach", head]);

console.log(`upstream deluge: ${await git("log", "-1", "--format=%h %ad %s", "--date=short", head)}`);
console.log(`last reviewed:   ${await git("log", "-1", "--format=%h %ad %s", "--date=short", reviewed)} (${reviewedLine.split(" ").slice(1).join(" ")})`);
console.log(`new commits since reviewed: ${await git("rev-list", "--count", `${reviewed}..${head}`)}`);

console.log("--- release tags newer than the reviewed commit");
const exact = (await run(["git", "-C", u, "describe", "--tags", "--exact-match", reviewed])).out.trim();
const tags = (await git("tag", "--contains", reviewed, "--sort=creatordate", "v*")).split("\n").filter((t) => t && t !== exact);
console.log(tags.length ? tags.join("\n") : "  (none)");

console.log("--- new commits touching watched files");
for (const [path, why] of watch) {
  const n = await git("rev-list", "--count", `${reviewed}..${head}`, "--", path);
  if (n === "0") continue;
  console.log(`  ${n}  ${path}   (${why})`);
  // Not through git(): its trim would eat the first line's indentation.
  const log = await must(["git", "-C", u, "log", "--format=       %h %ad %s", "--date=short", `${reviewed}..${head}`, "--", path]);
  console.log(log.trimEnd().split("\n").slice(0, 5).join("\n"));
}

// Each edit script's --check mode reports edit by edit and exits 1 if an original text is gone.
for (const [script, file, what] of [
  ["patch-pass.ts", "llvm/lib/Transforms/Instrumentation/FilPizlonator.cpp", "pass patch"],
  ["patch-split.ts", "llvm/tools/llvm-split/llvm-split.cpp", "llvm-split patch"],
]) {
  console.log(`--- does zilc's ${what} still apply to upstream's newest ${file.split("/").pop()}?`);
  const r = await run([Deno.execPath(), "run", "--allow-read", `${REPO}/tools/filc/${script}`, "--check", `${u}/${file}`], { inherit: true });
  console.log(r.code === 0 ? "  yes, every edit" : "  ⚠️ NO: re-derive the edits marked above before the next Fil-C upgrade");
}

if (Deno.args.includes("--mark-reviewed")) {
  const name = (await run(["git", "-C", u, "describe", "--tags", "--always", head])).out.trim();
  await Deno.writeTextFile(revFile, `${head} ${name} ${new Date().toISOString().slice(0, 10)} reviewed\n`);
  console.log("recorded HEAD as reviewed in tools/upstream/REVIEWED (commit it)");
}
