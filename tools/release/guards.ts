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
 *   - the two required reviews are a RECORD in a fixed form, one line each, and the record is
 *     checked against the repository: the range it names starts at the previous release's tag and
 *     ends at a commit after which only memory and the release notes changed.
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

/** A GFM table row's cell count: split on every `|` not escaped as `\|` — in code spans too, as GFM
 *  does — with one leading and one trailing pipe optional (KI-35). */
export function cells(row: string): number {
  // GFM trims only ASCII space, tab, VT and FF (KI-37) — never `trim()`, which also eats NBSP & co.
  let s = row.replaceAll("\\|", "x").replace(/^[ \t\v\f]+|[ \t\v\f]+$/g, "");
  if (s.startsWith("|")) s = s.slice(1);
  if (s.endsWith("|")) s = s.slice(0, -1);
  return s.split("|").length;
}

/** How many times `v` appears as a whole version (not as the start of `…1` in `…10`). */
export const mentions = (text: string, v: string) => (text.match(new RegExp(`(?<![\\d.])${esc(v)}(?![\\d])`, "g")) ?? []).length;

/** Lines of `text` that match `re` (anchored by the caller). */
const lines = (text: string, re: RegExp) => text.split("\n").filter((l) => re.test(l));

/** Each place's disagreement with `v`, or [] when the four files agree with build.zig.zon. */
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
  // The three Markdown places are read as a reader sees them, and only from files the guard can
  // read without guessing at a renderer (KI-31): see `unreadable`.
  const md = (name: string, text: string) => {
    for (const u of unreadable(text)) bad.push(`${name}: ${u}`);
    return visibleLines(text).join("\n");
  };
  // Before the version, plain characters only (KI-33, KI-34): no `<` (a tag's attribute), backtick,
  // backslash, `~`, `$` (math), `!` / `[` / `]` (an image's alt text, a link), `*` / `_` past the
  // fixed bold opener.
  const readme = md("README.md", p.readme);
  one(readme, /^> \*\*Status:/, new RegExp(`^> \\*\\*Status: [A-Za-z0-9 ,.:;/+'—-]*\\(v${esc(v.full)}: zilc release ${v.n} for Zig ${esc(v.zig)} and Fil-C ${esc(v.filc)}\\)`), `README.md's status line does not name v${v.full} (zilc release ${v.n}) as "(v${v.full}: zilc release ${v.n} for Zig ${v.zig} and Fil-C ${v.filc})", with only letters, digits, spaces and , . : ; / + ' — - before it`);
  // The status line OPENS its paragraph (KI-34): a line before it in the same quote paragraph could
  // open an attribute that runs over it. So the line before it is blank.
  const rl = readme.split("\n");
  const si = rl.findIndex((l) => /^> \*\*Status:/.test(l));
  if (si > 0 && rl[si - 1] !== "") bad.push(`README.md's status line must follow a blank line (it opens its own paragraph)`);
  one(md("RELEASE-NOTES.md", p.notes), new RegExp(`^## ${esc(v.full)}$`), /./, `RELEASE-NOTES.md has no "## ${v.full}" section`);
  const ow = md("cmem/open-work.md", p.openWork);
  one(ow, /^\| version \|/, new RegExp(`^\\| version \\| \\*\\*\`${esc(v.full)}\`\\*\\*`), `cmem/open-work.md's State row "| version |" does not begin with **\`${v.full}\`**`);
  // The State row is a ROW of a real table (KI-34): a header, a delimiter row, then rows — a table
  // cell cannot be reached by an attribute opened outside it, while a paragraph line can.
  // On the RAW lines (KI-36): a fence between the table and the row splits the table on GitHub, and
  // visible lines would hide that fence. The row is the first one outside a fence.
  const ol = p.openWork.split("\n");
  const owFence = fenceLines(p.openWork);
  const ri = ol.findIndex((l, i) => !owFence[i] && /^\| version \|/.test(l));
  if (ri >= 0) {
    let s = ri;
    while (s > 0 && ol[s - 1].startsWith("|")) s--;
    if (!(ri >= s + 2 && /^\|(?:[ \t]*:?-+:?[ \t]*\|)+[ \t]*$/.test(ol[s + 1]))) bad.push(`cmem/open-work.md's State row is not a row of a table (a header and a delimiter row above it)`);
    // The table starts a block of its own (KI-37): a quote or list line just above the header would
    // take the header as its lazy continuation, and the "table" would be that paragraph.
    else if (s > 0 && ol[s - 1] !== "" && !/^#{1,6}[ \t]/.test(ol[s - 1])) bad.push(`cmem/open-work.md's State table must follow a blank line or a heading`);
    // GFM makes it a table only when the header and the delimiter row have the SAME number of
    // cells, and drops a row's cells past that number (KI-35). The header may hold no `<`.
    else {
      const [h, d, r] = [cells(ol[s]), cells(ol[s + 1]), cells(ol[ri])];
      if (h !== d || h < 2) bad.push(`cmem/open-work.md's State table has ${h} header cells and ${d} delimiter cells (GFM needs the same number, at least 2)`);
      else if (r !== h) bad.push(`cmem/open-work.md's State row has ${r} cells in a ${h}-column table`);
      // No `<` from the header down to the row (KI-35, KI-37): nothing above it can open an attribute.
      if (ol.slice(s, ri).some((l) => l.includes("<"))) bad.push(`cmem/open-work.md's State table holds a "<" above the State row`);
    }
  }
  // The bump files name the version ONLY in their place (KI-30): a second mention is one the bump
  // would leave behind, stale, in the release.
  for (const [f, text] of [["src/root.zig", p.root], ["README.md", p.readme], ["build.zig.zon", p.zon]] as const) {
    const n = mentions(text, v.full);
    if (n !== 1) bad.push(`${f} names ${v.full} ${n} times; only its version place may (a second mention would go stale at the bump)`);
  }
  return bad;
}

/** A BOM and the non-ASCII whitespace code points (KI-37), by number: no literal in this source. */
const ODD_SPACE = new Set([0xa0, 0xfeff, 0x1680, 0x2028, 0x2029, 0x202f, 0x205f, 0x3000, ...Array.from({ length: 12 }, (_, k) => 0x2000 + k)]);

/** A fence-like line that is NOT at column 0 — indented, or after a list marker or `>` (KI-32):
 *  inside a container a fence ends with the container, which the guard does not read. */
const containerFence = (l: string) => /^(?:[ \t]|[>*+-]|\d{1,9}[.)])[ \t>*+\-\d.)]*?(`{3,}|~{3,})/.test(l);

/**
 * What makes a Markdown file one the guard will not read (KI-31). Four retests found four more ways
 * an emulation of GitHub's renderer could be made to disagree with it (comments that close fences,
 * processing instructions, CDATA, setext and indented headings …), so the guard stops emulating:
 * a file holding any construct whose rendering it would have to guess is REFUSED, by name. None
 * of zilc's three Markdown places holds one (measured 2026-11-15). Returns the reasons, or [].
 */
export function unreadable(md: string): string[] {
  const out: string[] = [];
  // LF only (owner, 2026-10-01, `.gitattributes`; again 2026-11-15: "we should be using LF as the
  // standard not CRLF"): a CR is refused, never normalised away.
  if (md.includes("\r")) out.push("holds a CR byte (the file must be LF only)");
  // A BOM or non-ASCII whitespace (KI-37): GFM treats them as text where `trim()` would not, and a
  // leading BOM would hide front matter from the check below.
  for (const ch of md) if (ODD_SPACE.has(ch.codePointAt(0)!)) {
    out.push(`holds U+${ch.codePointAt(0)!.toString(16).toUpperCase().padStart(4, "0")} (a BOM or non-ASCII whitespace)`);
    break;
  }
  // YAML front matter: GitHub renders it as a table, not as Markdown (KI-35).
  if (/^---[ \t]*(?:\n|$)/.test(md)) out.push("starts with a --- line (front matter, which GitHub renders as a table)");
  const inFence = fenceLines(md);
  md.split("\n").forEach((l, i) => {
    if (inFence[i]) return; // inside a fence nothing is markup — the SAME fence reading as visibleLines
    if (containerFence(l)) {
      out.push(`line ${i + 1} is a fence inside a list, quote or indent; a fence must start at column 0`);
      return;
    }
    // The RAW line (KI-33): no code span is subtracted first, because which backticks pair is the
    // renderer's call (a tag's attribute, or a backslash inside a span, decides it — retest 6).
    // `<!--` even inside backticks is refused: zilc's files hold none (measured 2026-11-15).
    if (/<!--|<\?|<!\[|<![A-Za-z]/.test(l)) out.push(`line ${i + 1} holds an HTML comment, declaration or processing instruction`);
    // An autolink (`<https://…>`) at a line start is a link, not an HTML block (KI-37).
    else if (/^ {0,3}<\/?[A-Za-z]/.test(l) && !/^ {0,3}<[A-Za-z][A-Za-z0-9+.-]{1,31}:[^\s<>]*>/.test(l)) out.push(`line ${i + 1} starts an HTML block`);
    // A `$$` math block (KI-36): GitHub renders its content as math, not Markdown.
    // Anywhere on the line (KI-37): `> $$` or `- $$` opens one inside a container too.
    else if (/\$\$/.test(l)) out.push(`line ${i + 1} holds $$ (math)`);
    // Elements that collapse what follows them on GitHub (an unclosed one, everything after it).
    else if (/<\/?(?:details|summary)(?:[\s/>]|$)/i.test(l)) out.push(`line ${i + 1} holds a <details>/<summary> tag, which can collapse what follows`);
  });
  return out;
}

/** Is `l` a heading line, in any form CommonMark knows (ATX with up to three spaces, a bare
 *  `#`…, a tab after the hashes; or a setext underline)? Ends an entry; refused inside one. */
const headingLike = (l: string) => /^ {0,3}#{1,6}(?:[ \t]|$)/.test(l) || /^ {0,3}(?:=+|-+)[ \t]*$/.test(l);

/**
 * The lines of a Markdown text outside fenced code blocks, as CommonMark reads fences (a closer is
 * the opener's character, at least as long, nothing after it; an unclosed fence runs to the end).
 * Meant for text that `unreadable` passed: no comments or HTML blocks are left to hide anything.
 */
export function visibleLines(md: string): string[] {
  const inFence = fenceLines(md);
  return md.split("\n").filter((_, i) => !inFence[i]);
}

/** For each line: is it a fence line or inside a fenced code block? The one fence reader that
 *  `unreadable` and `visibleLines` share, so they can never disagree about what is code. */
function fenceLines(md: string): boolean[] {
  const out: boolean[] = [];
  let fence: { ch: string; len: number } | null = null;
  for (const l of md.split("\n")) {
    if (fence !== null) {
      const c = l.match(/^ {0,3}(`+|~+)[ \t]*$/);
      if (c && c[1][0] === fence.ch && c[1].length >= fence.len) fence = null;
      out.push(true);
      continue;
    }
    // Openers at column 0 only (KI-32): an indented one may belong to a list item, whose end the
    // guard does not read — `unreadable` refuses it instead (`containerFence`).
    const o = l.match(/^(`{3,}|~{3,})(.*)$/);
    if (o && !(o[1][0] === "`" && o[2].includes("`"))) {
      fence = { ch: o[1][0], len: o[1].length };
      out.push(true);
      continue;
    }
    out.push(false);
  }
  return out;
}

/**
 * The `### v<version>` entry of cmem/release.md: from its heading to the next heading-like line,
 * inside the file's one `## Release History` section. null when there is none; throws when the
 * file is unreadable (`unreadable`), has no or two such sections, two entries for the version, or
 * a fence anywhere in the section (an entry is plain text: nothing in it can be hidden).
 */
export function findEntry(releaseMd: string, version: string): string | null {
  const u = unreadable(releaseMd);
  if (u.length) throw new Error(`cmem/release.md cannot be read without guessing: ${u.join("; ")}`);
  const ls = visibleLines(releaseMd);
  const sections = ls.flatMap((l, i) => (/^## Release History(?: |$)/.test(l) ? [i] : []));
  if (sections.length !== 1) throw new Error(`cmem/release.md has ${sections.length} "## Release History" sections`);
  const raw = releaseMd.split("\n");
  const rawStart = raw.findIndex((l) => /^## Release History(?: |$)/.test(l));
  if (raw.slice(rawStart).some((l) => /^ {0,3}(`{3,}|~{3,})/.test(l))) throw new Error(`cmem/release.md's Release History section holds a code fence; an entry is plain text`);
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

export type ReviewRecord = { kind: "Security" | "Hardening"; rounds: number; date: string; base: string; reviewed: string };

/**
 * The form of a review record, one line each in the release's entry:
 *
 *   - **Security review:** 3 rounds, empty round 2026-11-20, reviewed `v1.2.3-4.5.6..0123abc`
 *   - **Hardening review:** 2 rounds, empty round 2026-11-21, reviewed `v1.2.3-4.5.6..0123abc`
 *
 * Text may follow on the line. Anything else that mentions a review ("security review: not run",
 * a heading, a placeholder) is not a record.
 */
export const REVIEW_FORM = "- **<Security|Hardening> review:** <n> rounds, empty round <YYYY-MM-DD>, reviewed `<previous tag>..<commit>`";
const RECORD = /^- \*\*(Security|Hardening) review:\*\* ([1-9]\d*) rounds?, empty round (\d{4}-\d{2}-\d{2}), reviewed `(v\d+\.\d+\.\d+-\d+\.\d+\.\d+)\.\.([0-9a-f]{7,40})`(?:[ ,.;:—-].*)?$/;

/** The two records of an entry, or the reasons there are not exactly one of each. */
export function reviewRecords(entry: string): { records: ReviewRecord[]; bad: string[] } {
  const records: ReviewRecord[] = [];
  const bad: string[] = [];
  // An entry is plain text (KI-31): nothing in it may hide a line from a reader, so a record can
  // never be one the page does not show. Refused, by name, rather than interpreted.
  for (const u of unreadable(entry)) bad.push(`the entry ${u}`);
  entry.split("\n").forEach((l, i) => {
    if (/^ {0,3}(`{3,}|~{3,})/.test(l)) bad.push(`the entry's line ${i + 1} is a code fence; an entry is plain text`);
    else if (i > 0 && headingLike(l)) bad.push(`the entry's line ${i + 1} is heading-like; an entry ends at its next heading`);
  });
  for (const l of entry.split("\n")) {
    const m = l.match(RECORD);
    if (m) records.push({ kind: m[1] as ReviewRecord["kind"], rounds: Number(m[2]), date: m[3], base: m[4], reviewed: m[5] });
  }
  for (const kind of ["Security", "Hardening"] as const) {
    const n = records.filter((r) => r.kind === kind).length;
    if (n !== 1) bad.push(`${n === 0 ? "no" : n} ${kind.toLowerCase()} review record${n > 1 ? "s" : ""} in the form: ${REVIEW_FORM}`);
  }
  for (const r of records) {
    const d = new Date(`${r.date}T00:00:00Z`);
    if (Number.isNaN(d.getTime()) || d.toISOString().slice(0, 10) !== r.date) bad.push(`the ${r.kind.toLowerCase()} review's date ${r.date} is not a date`);
  }
  return { records, bad };
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
 * Checks a release entry's review records against the repository. `head` is the commit the release
 * is made from; with `bumped`, `head` is the bump commit and the reviewed code is what `head^` held.
 * Returns the reasons the release is not reviewed, or [].
 */
export async function reviewsCoverRelease(git: Git, entry: string, head: string, bumped: boolean): Promise<string[]> {
  const { records, bad } = reviewRecords(entry);
  if (bad.length) return bad;
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
  // The previous release: the nearest tag below the code being released.
  const prev = await git("describe", "--tags", "--abbrev=0", "--match", "v*", tip);
  if (prev.code !== 0) return [...out, `no release tag is reachable from ${tip}: ${prev.out.trim()}`];
  const base = prev.out.trim();
  for (const r of records) {
    const what = `the ${r.kind.toLowerCase()} review`;
    if (r.base !== base) {
      out.push(`${what} starts at ${r.base}, but the previous release is ${base}`);
      continue;
    }
    const sha = await git("rev-parse", "-q", "--verify", `${r.reviewed}^{commit}`);
    if (sha.code !== 0) {
      out.push(`${what} names ${r.reviewed}, which is not a commit here`);
      continue;
    }
    const anc = await git("merge-base", "--is-ancestor", r.reviewed, tip);
    if (anc.code === 1) {
      out.push(`${what} names ${r.reviewed}, which is not in the history being released`);
      continue;
    }
    if (anc.code !== 0) throw new Error(`git merge-base failed (exit ${anc.code}): ${anc.out.trim()}`);
    // A commit from before `base` needs no check of its own: everything since it, the previous
    // release included, shows up in the diff below.
    const later = (await changedPaths(git, r.reviewed, tip)).filter((f) => !AFTER_REVIEW_OK(f));
    if (later.length) out.push(`${what} ended at ${r.reviewed}, but these changed after it and were not reviewed: ${later.join(", ")}`);
  }
  return out;
}
