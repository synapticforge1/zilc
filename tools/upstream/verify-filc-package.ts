// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Proves that the Fil-C sources `zig build` fetches (build.zig.zon, lazy dependency `filc`: GitHub's
// archive of the fork at the compiler commit) are the commit as a checkout of it has them: the same
// paths, nothing extra or missing; every file's bytes the commit's blob, or for the files the
// commit's OWN .gitattributes mark `eol=crlf`, that blob with LF turned into CRLF; every symlink's
// target. Zig's package hash then pins those bytes for every later fetch. Re-run on every Fil-C
// move, after bumping the URL and hash (cmem/releasing.md).
//
//   bun tools/upstream/verify-filc-package.ts [<package dir>]     env: JOBS (default 16),
//                                                                  REPORT=<file> (every difference)
//
// <package dir> defaults to Zig's global cache entry for the hash in build.zig.zon
// ($ZIG_GLOBAL_CACHE_DIR or ~/.cache/zig, then p/<hash>); fetch it first with `zig build
// patched-clang` (or `zig fetch <url>`). The reference tree is read from the Fil-C clone
// (ZILC_FILC_SRC, default ~/zilc-work/filc-src/repo): a blob:none partial clone has every tree, so
// `ls-tree` and `check-attr --source` need no download.
//
// What the archive and Zig change, and how each is checked (measured on 0.687, 2026-10-30):
//  - Line endings: GitHub builds the archive with `git archive`, which writes text files as a
//    checkout would, so upstream's `text eol=crlf` fixtures arrive CRLF (110 files on 0.687: tcl,
//    zstd, cosmo, LLVM and lld test inputs). Upstream's own attributes decide, read with
//    `git check-attr --source=<commit>` (workspace rule: line endings are checked with check-attr
//    and a positive control, never by eye; zilc's own `* text=auto eol=lf` never applies here,
//    so no git command that reads zilc's attributes, such as `git hash-object` in the repo, is used).
//  - Executable bits: Zig's fetcher IGNORES the archive's modes and marks a file executable when it
//    starts with `#!`, an ELF or a Mach-O header (ziglang/zig#17463; src/Package/Fetch.zig
//    FileHeader), and its hash records no executable bit. So the bit is checked against THAT rule,
//    and the files where it differs from git's mode are counted, for the record.
//  - `export-ignore` / `export-subst` would show as a missing path or a blob that matches neither
//    form. Submodule links (gitlinks) are empty in any archive and are listed, not compared.
// Ends with an inversion: the same comparison must catch a one-byte change.

import { createHash } from "node:crypto";
import { lstat, readFile, readdir, readlink, writeFile } from "node:fs/promises";
import { env, envInt, FILC_SHA, filcPackageDir, must, pool, REPO } from "../lib/tool.ts";

const NO_FETCH = { env: { GIT_NO_LAZY_FETCH: "1" } }; // a partial clone must never wait on ssh
// The reference clone, always: ZILC_FILC_SRC may name the package itself (tools/lib/tool.ts).
const FILC_SRC = `${env("WORK", `${env("HOME")}/zilc-work`)}/filc-src/repo`;
const zon = await readFile(`${REPO}/build.zig.zon`, "utf8");
const url = zon.match(/\.url = "([^"]+)"/)?.[1] ?? "";
if (!url.includes(FILC_SHA)) throw new Error(`build.zig.zon's filc url (${url || "none"}) does not name ${FILC_SHA}`);
const pkg = process.argv[2] ?? await filcPackageDir();
console.log(`package: ${pkg}\nurl:     ${url}\ncommit:  ${FILC_SHA}`);

type Entry = { mode: string; type: string; id: string };
const tree = new Map<string, Entry>();
const listing = await must(["git", "-C", FILC_SRC, "ls-tree", "-r", "-z", "--full-tree", FILC_SHA], NO_FETCH);
for (const rec of listing.split("\0").filter(Boolean)) {
  const tab = rec.indexOf("\t");
  const [mode, type, id] = rec.slice(0, tab).split(" ");
  tree.set(rec.slice(tab + 1), { mode, type, id });
}

// check-attr --source reads every .gitattributes on a path's way down, and in a partial, sparse clone
// a blob that was never fetched is SILENTLY treated as absent (2026-10-30: 105 of 110 CRLF files
// read "unspecified" until projects/*/.gitattributes were fetched). So every .gitattributes blob of
// the commit is made local first, over https for this command only (the origin is ssh, and a
// lazy fetch over ssh waits forever without keys), and the run stops if one is still missing.
const attrBlobs = [...tree].filter(([p]) => p === ".gitattributes" || p.endsWith("/.gitattributes")).map(([, e]) => e.id);
const HTTPS = ["-c", "url.https://github.com/.insteadOf=git@github.com:"];
const missing = async () => {
  const r = Bun.spawn(["git", "-C", FILC_SRC, "cat-file", "--batch-check=%(objectname) %(objecttype)"], {
    env: { ...process.env, ...NO_FETCH.env }, stdin: new TextEncoder().encode(attrBlobs.join("\n") + "\n"), stdout: "pipe",
  });
  return (await new Response(r.stdout).text()).split("\n").filter((l) => l.endsWith(" missing")).map((l) => l.split(" ")[0]);
};
let absent = await missing();
if (absent.length) {
  console.log(`fetching ${absent.length} .gitattributes blob(s) into the reference clone`);
  // git's own lazy fetch (a plain `fetch <blob id>` fails its connectivity check); the -c rewrite
  // reaches the fetch git starts for it.
  for (const id of new Set(absent)) await must(["git", ...HTTPS, "-C", FILC_SRC, "cat-file", "-t", id]);
  absent = await missing();
  if (absent.length) throw new Error(`.gitattributes blobs still missing: ${absent.join(" ")}`);
}
console.log(`${attrBlobs.length} .gitattributes blobs are local (check-attr sees them all)`);

// Upstream's eol attribute for every path, at the commit (not the working tree, not zilc's).
async function eolAttrs(paths: string[]): Promise<Map<string, string>> {
  const out = new Map<string, string>();
  for (let i = 0; i < paths.length; i += 2000) {
    const recs = (await must(["git", "-C", FILC_SRC, "check-attr", "-z", `--source=${FILC_SHA}`, "eol", "--", ...paths.slice(i, i + 2000)], NO_FETCH)).split("\0");
    for (let j = 0; j + 2 < recs.length; j += 3) out.set(recs[j], recs[j + 2]);
  }
  return out;
}

const onDisk: string[] = [];
async function walk(dir: string, rel: string) {
  for (const d of await readdir(dir, { withFileTypes: true })) {
    const r = rel ? `${rel}/${d.name}` : d.name;
    if (d.isDirectory()) await walk(`${dir}/${d.name}`, r);
    else onDisk.push(r);
  }
}
await walk(pkg, "");

const blobId = (bytes: Uint8Array) => createHash("sha1").update(`blob ${bytes.length}\0`).update(bytes).digest("hex");
const crlfToLf = (b: Uint8Array) => {
  const out: number[] = [];
  for (let i = 0; i < b.length; i++) if (!(b[i] === 0x0d && b[i + 1] === 0x0a)) out.push(b[i]);
  return new Uint8Array(out);
};
// Zig's rule (src/Package/Fetch.zig FileHeader.isExecutable, 0.15.2).
const MACHO = new Set([0xfeedface, 0xcefaedfe, 0xfeedfacf, 0xcffaedfe, 0xcafebabe, 0xbebafeca, 0xcafebabf, 0xbfbafeca]);
const zigExecutable = (b: Uint8Array) =>
  (b[0] === 0x23 && b[1] === 0x21) || (b[0] === 0x7f && b[1] === 0x45 && b[2] === 0x4c && b[3] === 0x46) ||
  (b.length >= 4 && MACHO.has(new DataView(b.buffer, b.byteOffset, 4).getUint32(0, true)));

const problems: string[] = [];
const seen = new Set<string>();
const crlfCandidates: string[] = [];
let execDiffersFromGit = 0;
await pool(onDisk, envInt("JOBS", 16), async (p) => {
  const e = tree.get(p);
  if (!e) { problems.push(`extra: ${p}`); return; }
  seen.add(p);
  const st = await lstat(`${pkg}/${p}`);
  if (e.mode === "120000") {
    if (!st.isSymbolicLink()) problems.push(`not a symlink: ${p}`);
    else if (blobId(new TextEncoder().encode(await readlink(`${pkg}/${p}`))) !== e.id) problems.push(`symlink target differs: ${p}`);
    return;
  }
  const bytes = new Uint8Array(await readFile(`${pkg}/${p}`));
  if (blobId(bytes) !== e.id) {
    if (blobId(crlfToLf(bytes)) === e.id) crlfCandidates.push(p); // decided by upstream's attributes below
    else problems.push(`content differs: ${p}`);
  }
  const exec = (st.mode & 0o100) !== 0;
  if (exec !== zigExecutable(bytes)) problems.push(`executable bit is not Zig's rule: ${p}`);
  if (exec !== (e.mode === "100755")) execDiffersFromGit++;
});
const gitlinks: string[] = [];
for (const [p, e] of tree) {
  if (e.type === "commit") gitlinks.push(p);
  else if (!seen.has(p)) problems.push(`missing: ${p}`);
}
const entries = tree.size - gitlinks.length;
console.log(`compared ${onDisk.length} paths on disk with ${entries} tree entries${gitlinks.length ? ` (+${gitlinks.length} submodule links: ${gitlinks.join(", ")})` : ""}`);

// The CRLF files: each must be one upstream's attributes convert. Positive control: a fixture whose
// name says it is CRLF must read `crlf`; negative control: a plain source must not.
const POS = "llvm/test/MC/AsmParser/preserve-comments-crlf.s", NEG = "llvm/lib/Transforms/Instrumentation/FilPizlonator.cpp";
const attrs = await eolAttrs([...crlfCandidates, POS, NEG]);
if (attrs.get(POS) !== "crlf") problems.push(`control: check-attr says eol=${attrs.get(POS)} for ${POS}, expected crlf`);
if (attrs.get(NEG) === "crlf") problems.push(`control: check-attr says eol=crlf for ${NEG}`);
for (const p of crlfCandidates) if (attrs.get(p) !== "crlf") problems.push(`CRLF without upstream's eol=crlf: ${p}`);
console.log(`${crlfCandidates.length} files are CRLF as upstream's .gitattributes ask (eol=crlf at the commit; controls ${POS}: ${attrs.get(POS)}, ${NEG}: ${attrs.get(NEG)})`);
console.log(`${execDiffersFromGit} files have an executable bit that differs from git's mode, by Zig's content rule (expected; recorded)`);

// Inversion.
const probe = [...tree].find(([p, e]) => e.mode === "100644" && seen.has(p) && !crlfCandidates.includes(p))![0];
const changed = new Uint8Array([...(await readFile(`${pkg}/${probe}`)), 0x20]);
if (blobId(changed) === tree.get(probe)!.id || blobId(crlfToLf(changed)) === tree.get(probe)!.id) problems.push(`inversion: a changed ${probe} still matched`);
else console.log(`inversion: one byte added to ${probe} -> caught`);

const kinds = new Map<string, number>();
for (const p of problems) {
  const k = p.slice(0, p.indexOf(":"));
  kinds.set(k, (kinds.get(k) ?? 0) + 1);
}
for (const [k, n] of [...kinds].sort()) console.log(`  ${n}  ${k}`);
problems.sort();
const report = env("REPORT"); // every difference, one per line, when the 50 shown are not enough
if (report) await writeFile(report, problems.map((p) => `${p}\n`).join(""));
for (const p of problems.slice(0, 50)) console.log(`FAIL ${p}`);
if (problems.length > 50) console.log(`… ${problems.length - 50} more`);
console.log(problems.length ? `FAILED: ${problems.length} difference(s)` : `OK: the fetched package is ${FILC_SHA} as checked out (${entries} entries)`);
process.exit(problems.length ? 1 : 0);
