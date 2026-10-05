// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Create upstream/fil-c: a gitignored, read-only reference clone of Fil-C's `deluge` branch
// (cmem/upstream.md "The upstream/ reference folder"; the pattern of binaryen-ts's upstream/).
// Partial (no file contents beyond the checked-out paths), shallow (history from v0.684 on) and
// sparse (only what zilc references), so it stays small. Needs only git: runs on any OS (made on
// Windows, where the repo lives).
//
//   deno run -A tools/upstream/clone-upstream.ts
//
// ⚠️ Every git command names its repo with -C and an absolute path. A partial-clone fetch run in the
// wrong directory once rewrote zilc's own .git/config (2026-10-01).
import { exists, mkdirp, must, REPO, show } from "../lib/tool.ts";

const u = `${REPO}/upstream/fil-c`;
const url = "https://github.com/pizlonator/fil-c.git";
// filc/tests (15,603 small files) is left out: on exFAT each file takes a whole cluster (3.9 GB).
// (Fil-C's tests are run from their own clone in the Linux home: tools/filc/run-filc-tests.ts.)
// llvm/tools/llvm-split: zilc patches it (KI-22 lever a), and check-upstream.ts checks that patch.
const paths = [
  "llvm/lib/Transforms/Instrumentation", "llvm/include/llvm/Transforms/Instrumentation", "llvm/lib/CodeGen",
  "llvm/tools/llvm-split", "libpas", "filc/include", "filc/src", "filc/main", "filc/benchmarks", "filc/manualtests",
];

if (await exists(u)) {
  console.log(`${u} exists; delete it first to re-clone`);
  Deno.exit(1);
}
await mkdirp(`${REPO}/upstream`);
// core.autocrlf=false: keep upstream's exact bytes (LF). The global Windows setting (true) checked
// files out with CRLF, which broke patch-pass.ts's exact-match check and any diff against the Linux
// build tree (2026-10-01).
await must(["git", "-c", "core.longpaths=true", "-c", "core.autocrlf=false", "clone", "--no-checkout", "--filter=blob:none",
  "--sparse", "--branch", "deluge", "--shallow-exclude=v0.684", url, u], { inherit: true });
await must(["git", "-C", u, "config", "core.autocrlf", "false"]);
await must(["git", "-C", u, "config", "core.longpaths", "true"]);
// Fil-C's tree bundles projects (Linux headers, systemd tests) with paths Windows forbids (`aux.h`,
// `:` and `\` in names). Git for Windows refuses to INDEX them; they are all outside the sparse
// paths, so nothing illegal is ever written. Local to this clone only.
await must(["git", "-C", u, "config", "core.protectNTFS", "false"]);
await must(["git", "-C", u, "sparse-checkout", "set", ...paths]);
await must(["git", "-C", u, "checkout", "-q", "deluge"]);
await must(["git", "-C", u, "fetch", "-q", "origin", "+refs/tags/v0.685:refs/tags/v0.685"]);
await show(["git", "-C", u, "log", "-1", "--format=upstream/fil-c at %h %ad %s", "--date=short"]);
console.log(`v0.685 = ${(await must(["git", "-C", u, "rev-parse", "--short", "v0.685"])).trim()}`);
console.log("⚠️ exFAT drive: also run once:");
console.log(`   git config --global --add safe.directory ${u}`);
