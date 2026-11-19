// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
/**
 * The release guards as pure functions (review round 1, class 1 — "a guard that passes on text,
 * not on fact", 2026-11-15). bump.ts, release.ts and CI's `checks` all call these; the tests are
 * guards.test.ts. Nothing here reads a file or runs a process: the callers hand in the text and a
 * `git` function, so every refusal can be tested.
 *
 * What changed against the first version (cmem/known-issues.md, the review's rows):
 *   - each version place is matched as the WHOLE line that carries it, so a comment, a second
 *     mention or a longer version (`…687.10` for `…687.1`) cannot satisfy it;
 *   - a release entry is found by its exact `### v<version>` heading and ends at the next heading;
 *   - the review is a RECORD, checked against the repository (since 2026-11-19, the final review
 *     standard, letter H37 (d)): ONE line `- Review complete: <commit>` in cmem/review-process.md
 *     § Last review, naming a commit in the released history after which only memory and the
 *     release notes changed. (Until then: two records, security and hardening, in the release entry
 *     — letter H35, retired.)
 */

export const esc = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

export type Version = { full: string; zig: string; filc: string; n: number };

/** build.zig.zon's `.version`, or null when it is not `<Zig>-<Fil-C>.<N>` on a line of its own. */
export function zonVersion(zon: string): Version | null {
  const all = [...zon.matchAll(/^[ \t]*\.version = "(\d+\.\d+\.\d+)-(\d+\.\d+)\.(\d+)",$/gm)];
  if (all.length !== 1) return null;
  const m = all[0];
  return { full: `${m[1]}-${m[2]}.${m[3]}`, zig: m[1], filc: m[2], n: Number(m[3]) };
}

export type Places = { root: string; readme: string; notes: string; openWork: string; zon: string };

/** How many times `v` appears as a whole version (not as the start of `…1` in `…10`). */
export const mentions = (text: string, v: string) => (text.match(new RegExp(`(?<![\\d.])${esc(v)}(?![\\d])`, "g")) ?? []).length;

/** Lines of `text` that match `re` (anchored by the caller). */
const lines = (text: string, re: RegExp) => text.split("\n").filter((l) => re.test(l));

/** LF only (owner, 2026-10-01, `.gitattributes`; again 2026-11-15: "we should be using LF as the
 *  standard not CRLF"): a CR is refused, never normalised away. */
export const crProblems = (name: string, md: string) => (md.includes("\r") ? [`${name} holds a CR byte (the file must be LF only)`] : []);

/**
 * Each place's disagreement with `v`, or [] when the four files agree with build.zig.zon — as TEXT
 * facts: the one line that carries each place, matched whole. Whether a reader of the GitHub page
 * SEES the Markdown places is not decided here: `renderedProblems` asks GitHub's own renderer
 * (KI-38; owner, 2026-11-15: valid Markdown is not forbidden; "a markdown record that is not
 * rendered is an error"). Formatting is Biome's (`biome.jsonc`).
 */
export function disagreements(p: Places, v: Version): string[] {
  const bad: string[] = [];
  const one = (text: string, anyRe: RegExp, wantRe: RegExp, what: string) => {
    const any = lines(text, anyRe);
    if (any.length !== 1) bad.push(`${what}: expected exactly one such line, found ${any.length}`);
    else if (!wantRe.test(any[0])) bad.push(what);
  };
  const [zmaj, zmin, zpat] = v.zig.split(".");
  one(p.root, /^pub const zig_line = /, new RegExp(`^pub const zig_line = std\\.SemanticVersion\\{ \\.major = ${zmaj}, \\.minor = ${zmin}, \\.patch = ${zpat} \\};$`), `src/root.zig zig_line is not ${v.zig}`);
  one(p.root, /^pub const filc_release = /, new RegExp(`^pub const filc_release = "${esc(v.filc)}";$`), `src/root.zig filc_release is not "${v.filc}"`);
  one(p.root, /^pub const release = /, new RegExp(`^pub const release = ${v.n};$`), `src/root.zig release is not ${v.n}`);
  // The test line itself, whole: code, not a comment beside other code.
  one(p.root, /^\s*try std\.testing\.expectEqualStrings\("[^"]*", version_string\)/, new RegExp(`^\\s*try std\\.testing\\.expectEqualStrings\\("${esc(v.full)}", version_string\\);$`), `src/root.zig's version test does not pin "${v.full}"`);
  for (const [name, text] of [["README.md", p.readme], ["RELEASE-NOTES.md", p.notes], ["cmem/open-work.md", p.openWork]] as const) bad.push(...crProblems(name, text));
  // Raw lines: whether each is SHOWN (not in a fence, a comment …) is `renderedProblems`'s question.
  one(p.readme, /^> \*\*Status:/, new RegExp(`^> \\*\\*Status: [^(]*\\(v${esc(v.full)}: zilc release ${v.n} for Zig ${esc(v.zig)} and Fil-C ${esc(v.filc)}\\)`), `README.md's status line does not name "(v${v.full}: zilc release ${v.n} for Zig ${v.zig} and Fil-C ${v.filc})"`);
  one(p.notes, new RegExp(`^## ${esc(v.full)}$`), /./, `RELEASE-NOTES.md has no "## ${v.full}" section`);
  // Biome pads table cells (KI-38), so the row is matched with any padding.
  one(p.openWork, /^\|\s*version\s*\|/, new RegExp(`^\\|\\s*version\\s*\\|\\s*\\*\\*\`${esc(v.full)}\`\\*\\*`), `cmem/open-work.md's State row "| version |" does not begin with **\`${v.full}\`**`);
  // The bump files name the version ONLY in their place (KI-30): a second mention is one the bump
  // would leave behind, stale, in the release.
  for (const [f, text] of [["src/root.zig", p.root], ["README.md", p.readme], ["build.zig.zon", p.zon]] as const) {
    const n = mentions(text, v.full);
    if (n !== 1) bad.push(`${f} names ${v.full} ${n} times; only its version place may (a second mention would go stale at the bump)`);
  }
  return bad;
}

/** An ATX heading line. The text side reads lines only; where GitHub ends an entry (a setext
 *  heading, a fence …) is the rendered check's to decide (KI-38): a record outside its entry on the
 *  page is not shown under the entry's heading, and is refused there. */
const headingLike = (l: string) => /^ {0,3}#{1,6}(?:[ \t]|$)/.test(l);

/**
 * The `### v<version>` entry of cmem/release.md, as text: from its heading to the next heading,
 * inside the file's one `## Release History` section. null when there is none; throws on a CR, no
 * or two such sections, or two entries for the version. That the entry and its records are SHOWN
 * is `renderedProblems`'s check.
 */
export function findEntry(releaseMd: string, version: string): string | null {
  const cr = crProblems("cmem/release.md", releaseMd);
  if (cr.length) throw new Error(cr[0]);
  const ls = releaseMd.split("\n");
  const sections = ls.flatMap((l, i) => (/^## Release History(?: |$)/.test(l) ? [i] : []));
  if (sections.length !== 1) throw new Error(`cmem/release.md has ${sections.length} "## Release History" sections`);
  // The section ends at the next heading of level 1 or 2 (KI-36): an entry below that is elsewhere.
  let sectionEnd = sections[0] + 1;
  while (sectionEnd < ls.length && !/^ {0,3}#{1,2}(?:[ \t]|$)/.test(ls[sectionEnd])) sectionEnd++;
  const head = new RegExp(`^### v${esc(version)}(?: |$)`);
  const starts = ls.flatMap((l, i) => (i > sections[0] && i < sectionEnd && head.test(l) ? [i] : []));
  if (starts.length === 0) return null;
  if (starts.length > 1) throw new Error(`cmem/release.md has ${starts.length} "### v${version}" entries`);
  let end = starts[0] + 1;
  while (end < sectionEnd && !headingLike(ls[end])) end++;
  return ls.slice(starts[0], end).join("\n");
}

/** Where the review record lives (the slot file's § Last review; workspace review standard § 9). */
export const REVIEW_RECORD_FILE = "cmem/review-process.md";
/** The record's form: written by the main session when the five required reviews end in an empty
 *  re-review and the full suite has passed (cmem/review-process.md § The loop, as zilc runs it). */
export const REVIEW_FORM = "- Review complete: <commit>";
const RECORD = /^- Review complete: `?([0-9a-f]{7,40})`?\s*$/;

/**
 * The commit named by the review record, or the reasons there is not exactly one. Text that only
 * mentions a review ("Review complete: none", a heading, a placeholder) is not a record.
 */
export function reviewedCommit(text: string): { commit: string | null; bad: string[] } {
  const bad = crProblems(REVIEW_RECORD_FILE, text);
  const found = text.split("\n").flatMap((l) => l.match(RECORD)?.[1] ?? []);
  if (found.length !== 1) bad.push(`${found.length === 0 ? "no" : found.length} review record${found.length > 1 ? "s" : ""} in ${REVIEW_RECORD_FILE} in the form "${REVIEW_FORM}" (exactly one: run "review" first — the five required reviews)`);
  return { commit: found.length === 1 && bad.length === 0 ? found[0] : null, bad };
}

/** Files that must never be tracked (H37 (b); cmem/working-rules.md § Privacy): the review issues,
 *  machine facts, the assistant's folder and the root CLAUDE.md. Each is gitignored, but
 *  `git add -f` still commits it — and an issues file on GitHub publishes every open finding. */
export function privateFilesTracked(tracked: readonly string[]): string[] {
  return tracked.filter((f) => f === "cmem/review-issues.md" || f === "CLAUDE.md" || f.startsWith("cmem/local/") || f.startsWith(".claude/"));
}

// ---- What a reader of the GitHub page sees (KI-38) -------------------------------------------

/** Markdown in, HTML out — GitHub's own renderer in use (`githubRender`); a stand-in in tests. */
export type Render = (markdown: string) => Promise<string>;

/**
 * GitHub's renderer: `POST /markdown`, mode `gfm` (the REST API; never `gh`, Tooling rule 9).
 * Measured 2026-11-15 on the reviewers' hiding cases: comments removed, attribute and alt text kept
 * out of the text, `<details>` kept (collapsed), a list item's fence ending with the item — the
 * repository page's reading. With `token` (CI's GITHUB_TOKEN) the rate limit is the authenticated
 * one; without, 60 an hour. Any failure throws: a render that did not happen is never a pass.
 */
export function githubRender(token = process.env.GITHUB_TOKEN, api = process.env.ZILC_GITHUB_API ?? "https://api.github.com"): Render {
  return async (markdown) => {
    const headers: Record<string, string> = { Accept: "application/vnd.github+json", "Content-Type": "application/json", "User-Agent": "zilc-release-guard", "X-GitHub-Api-Version": "2022-11-28" };
    if (token) headers.Authorization = `Bearer ${token}`;
    let r: Response;
    try {
      r = await fetch(`${api}/markdown`, { method: "POST", headers, body: JSON.stringify({ text: markdown, mode: "gfm" }), signal: AbortSignal.timeout(30_000) });
    } catch (e) {
      throw new Error(`GitHub's Markdown renderer did not answer: ${(e as Error).message}`);
    }
    if (r.status !== 200) throw new Error(`GitHub's Markdown renderer answered HTTP ${r.status}: ${(await r.text()).slice(0, 200)}`);
    return await r.text();
  };
}

/** One block of rendered text: a heading, paragraph, list item or table cell, with what holds it. */
export type Block = { tag: string; text: string; hidden: boolean; quoted: boolean; row: number | null };

const VOID = new Set(["area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"]);
const BLOCKS = new Set(["h1", "h2", "h3", "h4", "h5", "h6", "p", "li", "td", "th", "pre", "summary"]);
const NAMED: Record<string, string> = { lt: "<", gt: ">", quot: '"', apos: "'", nbsp: " ", amp: "&" };
/** HTML character references: the named few GitHub's output carries, and every numeric one. */
const decode = (s: string) =>
  s.replace(/&(?:#(\d+)|#[xX]([0-9a-fA-F]+)|([a-zA-Z]+));/g, (m, d, h, n) => (d ? String.fromCodePoint(Number(d)) : h ? String.fromCodePoint(parseInt(h, 16)) : (NAMED[n] ?? m)));
const norm = (s: string) => s.replace(/\s+/g, " ").trim();
/** Struck-through text is not the text a reader is meant to take (KI-39). */
const STRUCK = new Set(["del", "s", "strike"]);

/**
 * The visible text of rendered HTML, block by block, in document order. Only TEXT nodes count —
 * an attribute (`title`, `alt`) is never text, and a comment is no node at all. Text is NOT shown
 * (KI-39) when any element holding it is: inside a collapsed `<details>` (one without `open`) other
 * than through that details' own `<summary>` — at any depth, inside a list item or paragraph too —
 * or inside `<del>`, `<s>` or `<strike>`. Such text never joins its block; a block that opens there
 * is `hidden`.
 */
export async function renderedBlocks(html: string): Promise<Block[]> {
  // `hide`: this element is not shown. `hideKids`: a collapsed <details> — its children are not
  // shown, except its <summary>.
  type Open = { tag: string; block: Block | null; row: number | null; hide: boolean; hideKids: boolean };
  const stack: Open[] = [];
  const blocks: Block[] = [];
  let rows = 0;
  const rw = new HTMLRewriter()
    .on("*", {
      element(el) {
        const tag = el.tagName.toLowerCase();
        if (VOID.has(tag) || el.selfClosing) return;
        const parent = stack[stack.length - 1];
        const row = tag === "tr" ? ++rows : (parent?.row ?? null);
        const hide = (parent?.hide ?? false) || ((parent?.hideKids ?? false) && tag !== "summary") || STRUCK.has(tag);
        const hideKids = tag === "details" && !el.hasAttribute("open");
        let block: Block | null = parent?.block ?? null;
        if (BLOCKS.has(tag)) {
          block = { tag, text: "", hidden: hide, quoted: stack.some((o) => o.tag === "blockquote"), row };
          blocks.push(block);
        }
        const open: Open = { tag, block, row, hide, hideKids };
        stack.push(open);
        el.onEndTag(() => {
          const i = stack.lastIndexOf(open);
          if (i >= 0) stack.length = i;
        });
      },
    })
    .onDocument({
      text(t) {
        const top = stack[stack.length - 1];
        // Text directly in a collapsed <details> (outside its summary) is collapsed too.
        if (top?.block && !top.hide && !top.hideKids) top.block.text += t.text;
      },
    });
  await rw.transform(new Response(html)).text();
  for (const b of blocks) b.text = norm(decode(b.text));
  return blocks;
}

export type Rendered = { release?: string; notes?: string; readme?: string; openWork?: string };

/**
 * What a reader of the GitHub page does NOT see of the counted places (KI-38): each given file is
 * rendered by `render`, and its place must be visible text there — the entry's `v<version>` heading,
 * the notes' `## <version>` heading, the README's status version in a quote, the State row as a
 * table row. Returns the problems, or [].
 */
export async function renderedProblems(render: Render, files: Rendered, v: Version): Promise<string[]> {
  const out: string[] = [];
  const blocksOf = async (name: string, md: string) => {
    try {
      return await renderedBlocks(await render(md));
    } catch (e) {
      throw new Error(`${name}: ${(e as Error).message}`);
    }
  };
  // A hidden block (collapsed, struck through) has no text: hidden text never joins a block (KI-39),
  // so matching the text is the whole test of being shown.
  if (files.release !== undefined) {
    const bs = await blocksOf("cmem/release.md", files.release);
    const heads = bs.filter((b) => b.tag === "h3" && (b.text === `v${v.full}` || b.text.startsWith(`v${v.full} `)));
    if (heads.length !== 1) out.push(`cmem/release.md: GitHub shows ${heads.length} "v${v.full}" entry headings (one is required)`);
  }
  if (files.notes !== undefined) {
    const bs = await blocksOf("RELEASE-NOTES.md", files.notes);
    if (!bs.some((b) => b.tag === "h2" && b.text === v.full)) out.push(`RELEASE-NOTES.md: GitHub does not show a "${v.full}" heading`);
  }
  if (files.readme !== undefined) {
    const bs = await blocksOf("README.md", files.readme);
    const want = `(v${v.full}: zilc release ${v.n} for Zig ${v.zig} and Fil-C ${v.filc})`;
    if (!bs.some((b) => b.tag === "p" && b.quoted && b.text.startsWith("Status:") && b.text.includes(want))) out.push(`README.md: GitHub does not show the status line naming ${want}`);
  }
  if (files.openWork !== undefined) {
    const bs = await blocksOf("cmem/open-work.md", files.openWork);
    const byRow = new Map<number, Block[]>();
    for (const b of bs) if ((b.tag === "td" || b.tag === "th") && b.row !== null) byRow.set(b.row, [...(byRow.get(b.row) ?? []), b]);
    const ok = [...byRow.values()].some((cs) => cs.length >= 2 && cs[0].tag === "td" && cs[0].text === "version" && (cs[1].text === v.full || cs[1].text.startsWith(`${v.full} `)));
    if (!ok) out.push(`cmem/open-work.md: GitHub does not show the State row "version | ${v.full} …" as a table row`);
  }
  return out;
}

/** What may change after the reviewed commit and before the bump: memory and the release notes. */
export const AFTER_REVIEW_OK = (path: string) => path.startsWith("cmem/") || path === "RELEASE-NOTES.md";
/** The Markdown files the guard counts places in (KI-36: each must be an ordinary file). */
export const MD_PLACES = ["README.md", "RELEASE-NOTES.md", "cmem/open-work.md", "cmem/release.md"];
/** What the bump commit itself changes (bump.ts's three mechanical places). */
export const BUMP_FILES = ["README.md", "build.zig.zon", "src/root.zig"];

/**
 * The bump's edits: the three files as they must be after `bump to v<cur with N + 1>`, from their
 * text before it. bump.ts writes exactly this; the review check recomputes it from the bump
 * commit's parent and requires the bump commit to equal it byte for byte (KI-28), so the one
 * commit made after the review can carry nothing else. Throws when an anchor is not there once.
 */
export function bumpEdits(before: Record<string, string>, cur: Version): Record<string, string> {
  const n2 = cur.n + 1;
  const next = `${cur.zig}-${cur.filc}.${n2}`;
  const after = `${cur.zig}-${cur.filc}.${n2 + 1}`;
  const out: Record<string, string> = {};
  for (const f of BUMP_FILES) {
    if (typeof before[f] !== "string") throw new Error(`the bump needs ${f}`);
    out[f] = before[f];
  }
  const once = (file: string, from: string | RegExp, to: string) => {
    const text = out[file];
    const count = typeof from === "string" ? text.split(from).length - 1 : (text.match(new RegExp(from.source, "gm")) ?? []).length;
    if (count !== 1) throw new Error(`${file}: expected exactly one ${typeof from === "string" ? `"${from}"` : from}, found ${count}`);
    out[file] = typeof from === "string" ? text.replace(from, () => to) : text.replace(new RegExp(from.source, "m"), () => to);
  };
  once("build.zig.zon", `.version = "${cur.full}",`, `.version = "${next}",`);
  once("src/root.zig", `pub const release = ${cur.n};`, `pub const release = ${n2};`);
  once("src/root.zig", `expectEqualStrings("${cur.full}", version_string)`, `expectEqualStrings("${next}", version_string)`);
  once("src/root.zig", /order\("[^"]+", version_string\)\); \/\/ the release before/, `order("${cur.full}", version_string)); // the release before`);
  once("src/root.zig", /order\(version_string, "[^"]+"\)\); \/\/ next zilc release/, `order(version_string, "${after}")); // next zilc release`);
  once("README.md", `v${cur.full}: zilc release ${cur.n} for Zig`, `v${next}: zilc release ${n2} for Zig`);
  return out;
}

/** The paths a diff touches: every side of every change, renames split into delete + add (so a
 *  file moved into `cmem/` shows its old path too), NUL-separated so no name is ever quoted. */
export async function changedPaths(git: Git, from: string, to: string): Promise<string[]> {
  // --ignore-submodules=none: a `.gitmodules` `ignore = all` must not hide a gitlink move (KI-29).
  const r = await git("diff", "--no-renames", "--no-ext-diff", "--no-textconv", "--ignore-submodules=none", "-z", "--name-only", from, to);
  if (r.code !== 0) throw new Error(`git diff ${from} ${to} failed (exit ${r.code}): ${r.out.trim()}`);
  return r.out.split("\0").filter(Boolean);
}

/** Runs git in the repository; resolves to its exit code, its stdout as text and as the exact
 *  bytes (`raw`). Never throws on non-zero. */
export type Git = (...args: string[]) => Promise<{ code: number; out: string; raw: Uint8Array }>;

/** A `Git` for the repository at `dir`: stdout alone on success (stderr kept apart, so a warning
 *  never reads as a file name), stderr in `out` on failure. Replace refs are never followed
 *  (`--no-replace-objects`), so the history checked is the one that is pushed. */
export function gitIn(dir: string, timeoutSeconds = 120): Git {
  return async (...args) => {
    const p = Bun.spawn(["git", "--no-replace-objects", "-C", dir, ...args], { stdin: "ignore", stdout: "pipe", stderr: "pipe", env: { ...process.env, GIT_TERMINAL_PROMPT: "0" } });
    // A time limit on every call (KI-31): a hung remote is a refusal (exit 124), never a wait
    // forever. The limit RETURNS when it fires: killing git does not close the pipes while a child
    // it started (a remote helper) still holds them, so waiting for them would wait for that child.
    let timer: ReturnType<typeof setTimeout> | undefined;
    const limit = new Promise<null>((resolve) => {
      timer = setTimeout(() => {
        try {
          p.kill("SIGKILL");
        } catch {
          /* gone */
        }
        resolve(null);
      }, timeoutSeconds * 1000);
    });
    const done = Promise.all([new Response(p.stdout).bytes(), new Response(p.stderr).text(), p.exited]);
    const r = await Promise.race([done, limit]);
    clearTimeout(timer);
    if (r === null) return { code: 124, out: `git ${args[0]}: no answer in ${timeoutSeconds} s`, raw: new Uint8Array() };
    const [raw, err, code] = r;
    const out = new TextDecoder().decode(raw);
    return { code, out: code === 0 ? out : `${out}${err}`, raw };
  };
}

/** Text ⇄ bytes one for one (latin1), so an edit of ASCII anchors never changes any other byte —
 *  invalid UTF-8 and a BOM survive exactly (KI-29). */
const bytesToText = (b: Uint8Array) => Buffer.from(b).toString("latin1");
const textToBytes = (s: string) => Buffer.from(s, "latin1");

/**
 * The release tags (`v*`) here and on `remote`, compared by name and object (KI-30): `git describe`
 * picks the previous release from the LOCAL tags, and CI sees origin's, so a tag missing locally
 * (CI made it, nothing fetched it) or a local-only tag makes the owner's machine and CI disagree
 * about the previous release. Returns the differences, or [].
 */
export async function tagsDifferFrom(git: Git, remote = "origin"): Promise<string[]> {
  const r = await git("ls-remote", "--tags", remote, "refs/tags/v*");
  if (r.code !== 0) throw new Error(`git ls-remote ${remote} failed (exit ${r.code}): ${r.out.trim()}`);
  const there = new Map<string, string>();
  for (const l of r.out.split("\n").filter(Boolean)) {
    const [sha, ref] = l.split("\t");
    if (!ref.endsWith("^{}")) there.set(ref.slice("refs/tags/".length), sha);
  }
  const l = await git("for-each-ref", "--format=%(objectname) %(refname:strip=2)", "refs/tags/v*");
  if (l.code !== 0) throw new Error(`git for-each-ref failed (exit ${l.code}): ${l.out.trim()}`);
  const here = new Map<string, string>();
  for (const line of l.out.split("\n").filter(Boolean)) {
    const [sha, name] = line.split(" ");
    here.set(name, sha);
  }
  const out: string[] = [];
  for (const [name, sha] of there) if (!here.has(name)) out.push(`tag ${name} is on ${remote} but not here (git fetch --tags ${remote})`);
  else if (here.get(name) !== sha) out.push(`tag ${name} differs here (${here.get(name)!.slice(0, 10)}) and on ${remote} (${sha.slice(0, 10)})`);
  for (const name of here.keys()) if (!there.has(name)) out.push(`tag ${name} is here but not on ${remote} (a release tag is only ever made by CI)`);
  return out;
}

/** The subject line of the bump commit for `version` (bump.ts writes it; release.ts and CI require it). */
export const bumpSubject = (version: string) => `bump to v${version}`;

/**
 * Checks the review record (`recordText`, cmem/review-process.md at `head`) against the repository.
 * `head` is the commit the release is made from; with `bumped`, `head` is the bump commit and the
 * reviewed code is what `head^` held. Returns the reasons the release is not reviewed, or [].
 */
export async function reviewCoversRelease(git: Git, recordText: string, head: string, bumped: boolean): Promise<string[]> {
  const { commit: reviewed, bad } = reviewedCommit(recordText);
  if (!reviewed) return bad;
  const out: string[] = [];
  // The counted Markdown files are ordinary files at the commit (KI-36): GitHub shows a symlink's
  // target path, not the Markdown the guard read through it.
  for (const f of MD_PLACES) {
    const r = await git("ls-tree", "-z", head, "--", f);
    if (r.code !== 0) throw new Error(`git ls-tree ${head} ${f} failed (exit ${r.code}): ${r.out.trim()}`);
    const mode = r.out.match(/^(\d{6}) /)?.[1];
    if (mode !== "100644") out.push(`${f} is not an ordinary file (mode 100644) at ${head}: ${mode ?? "absent"}`);
  }
  // GitHub shows `.github/README*` in place of the root README (KI-37): the status line counted
  // there would not be the one on the page.
  const gh = await git("ls-tree", "-z", "--name-only", head, "--", ".github/");
  if (gh.code !== 0) throw new Error(`git ls-tree ${head} .github failed (exit ${gh.code}): ${gh.out.trim()}`);
  for (const p of gh.out.split("\0").filter(Boolean)) if (/^\.github\/readme(?:\.|$)/i.test(p)) out.push(`${p} exists at ${head}; GitHub would show it instead of README.md`);
  let tip = head;
  if (bumped) {
    tip = `${head}^`;
    const changed = await changedPaths(git, tip, head);
    const extra = changed.filter((f) => !BUMP_FILES.includes(f));
    if (extra.length || changed.length === 0) out.push(`the bump commit changes ${changed.length ? extra.join(", ") : "nothing"}: it may change only ${BUMP_FILES.join(", ")}`);
    else {
      // Not only WHICH files: the bump commit must be exactly bump.ts's edits of its parent (KI-28),
      // compared as git objects — the exact bytes (KI-29: not decoded text, where an invalid byte
      // or a BOM is lost) and the entry's mode and type (a chmod or a symlink is a change too).
      const entry = async (rev: string, f: string) => {
        const r = await git("ls-tree", "-z", rev, "--", f);
        if (r.code !== 0) throw new Error(`git ls-tree ${rev} ${f} failed (exit ${r.code}): ${r.out.trim()}`);
        const m = r.out.match(/^(\d{6}) (\w+) ([0-9a-f]+)\t/);
        return m ? { mode: m[1], type: m[2] } : null;
      };
      const blob = async (rev: string, f: string) => {
        const r = await git("cat-file", "blob", `${rev}:${f}`);
        if (r.code !== 0) throw new Error(`git cat-file ${rev}:${f} failed (exit ${r.code}): ${r.out.trim()}`);
        return r.raw;
      };
      const before: Record<string, string> = {};
      for (const f of BUMP_FILES) {
        const e0 = await entry(tip, f);
        const e1 = await entry(head, f);
        // Mode 100644 is an ordinary file: a symlink (120000), a gitlink (160000) or an executable
        // (100755) is refused by the mode alone, so no separate type test is needed.
        if (!e0 || !e1 || e0.mode !== "100644" || e1.mode !== "100644") out.push(`the bump commit's ${f} is not an ordinary file (mode 100644) on both sides: ${e0 ? `${e0.mode} ${e0.type}` : "absent"} → ${e1 ? `${e1.mode} ${e1.type}` : "absent"}`);
        else before[f] = bytesToText(await blob(tip, f));
      }
      const cur = Object.keys(before).length === BUMP_FILES.length ? zonVersion(before["build.zig.zon"]) : null;
      if (Object.keys(before).length === BUMP_FILES.length && !cur) out.push(`the bump commit's parent has no readable build.zig.zon .version`);
      if (cur) {
        let want: Record<string, string> | null = null;
        try {
          want = bumpEdits(before, cur);
        } catch (e) {
          out.push(`the bump commit's parent cannot be bumped: ${(e as Error).message}`);
        }
        if (want) for (const f of BUMP_FILES) if (!Buffer.from(await blob(head, f)).equals(textToBytes(want[f]))) out.push(`the bump commit's ${f} is not exactly the bump of its parent's (only bump.ts's edits may follow the review)`);
      }
    }
  }
  const what = "the review";
  const sha = await git("rev-parse", "-q", "--verify", `${reviewed}^{commit}`);
  if (sha.code !== 0) return [...out, `${what} names ${reviewed}, which is not a commit here`];
  const anc = await git("merge-base", "--is-ancestor", reviewed, tip);
  if (anc.code === 1) return [...out, `${what} names ${reviewed}, which is not in the history being released`];
  if (anc.code !== 0) throw new Error(`git merge-base failed (exit ${anc.code}): ${anc.out.trim()}`);
  // A commit from before the previous release needs no check of its own: everything since it, the
  // previous release included, shows up in the diff below.
  const later = (await changedPaths(git, reviewed, tip)).filter((f) => !AFTER_REVIEW_OK(f));
  if (later.length) out.push(`${what} ended at ${reviewed}, but these changed after it and were not reviewed: ${later.join(", ")}`);
  return out;
}
