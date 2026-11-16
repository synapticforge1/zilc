// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
// Tests for tools/release/guards.ts and check-reviews.ts (`bun test tools/release/`, run by CI's
// `checks`). Review round 1, class 1 (2026-11-15): each case below is a way the first version of the
// guards passed on text, not on fact; the cases were run against that version first (inverted).
import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { chmodSync, cpSync, mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { BUMP_FILES, bumpEdits, cells, disagreements, findEntry, gitIn, mentions, tagsDifferFrom, reviewRecords, reviewsCoverRelease, unreadable, zonVersion, type Git, type Places } from "./guards.ts";
import { run } from "../lib/tool.ts";

const REPO = join(import.meta.dir, "..", "..");
const read = (f: string) => readFileSync(join(REPO, f), "utf8");
const real = (): Places => ({ root: read("src/root.zig"), readme: read("README.md"), notes: read("RELEASE-NOTES.md"), openWork: read("cmem/open-work.md"), zon: read("build.zig.zon") });
const cur = zonVersion(read("build.zig.zon"))!;

describe("the five places", () => {
  test("the repository agrees with itself", () => {
    expect(cur).not.toBeNull();
    expect(disagreements(real(), cur)).toEqual([]);
  });

  test("the repository's own cmem/release.md is readable by the guard (KI-33: a record of the rule once broke it)", () => {
    expect(unreadable(read("cmem/release.md"))).toEqual([]);
    expect(() => findEntry(read("cmem/release.md"), cur.full)).not.toThrow();
  });

  test("the version test pinning another version, the right one only in a comment, is refused", () => {
    const p = real();
    const line = `expectEqualStrings("${cur.full}", version_string);`;
    expect(p.root.split(line).length - 1).toBe(1);
    p.root = p.root.replace(line, `expectEqualStrings("0.0.0-0.0.0", version_string); // expectEqualStrings("${cur.full}", version_string)`);
    expect(disagreements(p, cur).join("\n")).toContain("version test does not pin");
  });

  test("a second version test line is refused", () => {
    const p = real();
    p.root += `\n    try std.testing.expectEqualStrings("${cur.full}", version_string);\n`;
    expect(disagreements(p, cur).join("\n")).toContain("found 2");
  });

  test("a State row naming the version only as 'previous' is refused", () => {
    const p = real();
    p.openWork = p.openWork.replace(/^\| version \|.*$/m, `| version | **\`9.9.9-9.9.9\`** (previous: \`${cur.full}\`) |`);
    expect(disagreements(p, cur).join("\n")).toContain("State row");
  });

  test("a README status line naming the version outside its own place is refused", () => {
    const p = real();
    p.readme = p.readme.replace(/^> \*\*Status:.*$/m, `> **Status: (v9.9.9-9.9.9: zilc release 9 for Zig 9.9.9 and Fil-C 9.9) — was v${cur.full}: zilc release ${cur.n} for Zig ${cur.zig} and Fil-C ${cur.filc}`);
    expect(disagreements(p, cur).join("\n")).toContain("README.md");
  });

  test("a version that only begins with the right one is refused (…1 vs …10)", () => {
    const p = real();
    const v10 = { ...cur, full: `${cur.full}0`, n: cur.n * 10 };
    expect(disagreements(p, v10).length).toBeGreaterThan(0);
  });

  test("a second mention of the version in a bump file is refused (retest 3, KI-30)", () => {
    for (const [k, extra] of [["readme", `\nInstall zilc ${cur.full}.\n`], ["root", `\n// built for ${cur.full}\n`], ["zon", `\n// ${cur.full}\n`]] as const) {
      const p = real();
      p[k] += extra;
      expect(disagreements(p, cur).join("\n")).toContain(`names ${cur.full} 2 times`);
    }
  });

  // Retest 4 (KI-31): a place a reader cannot see is not the place.
  test("a RELEASE-NOTES heading inside a comment is refused", () => {
    const p = real();
    p.notes = p.notes.replace(`## ${cur.full}\n`, `<!--\n## ${cur.full}\n-->\n`);
    expect(disagreements(p, cur).join("\n")).toContain("RELEASE-NOTES.md: line");
  });
  test("a RELEASE-NOTES heading inside a fence is not the section", () => {
    const p = real();
    p.notes = p.notes.replace(`## ${cur.full}\n`, `~~~\n## ${cur.full}\n~~~\n`);
    expect(disagreements(p, cur).join("\n")).toContain(`RELEASE-NOTES.md has no "## ${cur.full}" section`);
  });
  test("a State row inside a fence is not the row", () => {
    const p = real();
    p.openWork = p.openWork.replace(/^(\| version \|.*)$/m, "```\n$1\n```");
    expect(disagreements(p, cur).join("\n")).toContain("State row");
  });
  test("a comment INSIDE a fence is code, not markup: the notes stay readable", () => {
    const p = real();
    p.notes = p.notes.replace(`## ${cur.full}\n`, `## ${cur.full}\n\n\`\`\`html\n<!-- an example -->\n<pre>x</pre>\n\`\`\`\n`);
    expect(disagreements(p, cur)).toEqual([]);
  });
  test("a notes heading after a shorter fence line inside a longer fence is still code", () => {
    const p = real();
    p.notes = p.notes.replace(`## ${cur.full}\n`, `\`\`\`\`\n\`\`\`\n## ${cur.full}\n\`\`\`\`\n`);
    expect(disagreements(p, cur).join("\n")).toContain(`RELEASE-NOTES.md has no "## ${cur.full}" section`);
  });
  test("the list-item fence trap that split the README status line is refused (retest 5, KI-32)", () => {
    const p = real();
    p.readme = p.readme.replace(/^(> \*\*Status:.*)$/m, "- x\n  ```\n> **Status: stale\n<!--\n```\n$1\n-->");
    expect(disagreements(p, cur).join("\n")).toContain("fence inside a list, quote or indent");
  });
  for (const [name, wrap] of [
    ["in a tag attribute", (s: string) => s.replace("(v", '<a title="(v').replace(/\)/, ')">')],
    ["struck through", (s: string) => s.replace("(v", "~~(v").replace(/\)/, ")~~")],
    ["inside a code span", (s: string) => s.replace("(v", "`(v").replace(/\)/, ")`")],
  ] as const) {
    test(`a README status version ${name} is not the status (retest 6, KI-33)`, () => {
      const p = real();
      p.readme = p.readme.replace(/^> \*\*Status:.*$/m, (l) => wrap(l));
      expect(disagreements(p, cur).join("\n")).toContain("README.md's status line does not name");
    });
  }
  // Retest 7 (KI-34), each rendered by the reviewer with Bun.markdown.
  test("a README status version inside an image's alt text is not the status", () => {
    const p = real();
    p.readme = p.readme.replace(/^> \*\*Status: ([^(]*)\((v[^)]*)\)/m, "> **Status: $1![logo ($2)](docs/logo.svg)");
    expect(disagreements(p, cur).join("\n")).toContain("README.md's status line does not name");
  });
  for (const ch of ["[", "]", "!", "$", "*", "_"]) {
    test(`a README status line with ${ch} before the version is not the status`, () => {
      const p = real();
      p.readme = p.readme.replace(/^> \*\*Status: /m, `> **Status: x${ch} `);
      expect(disagreements(p, cur).join("\n")).toContain("README.md's status line does not name");
    });
  }
  test("a README status line continuing a quote paragraph is refused", () => {
    const p = real();
    p.readme = p.readme.replace(/^(> \*\*Status:.*)$/m, '> see <span title="\n$1');
    expect(disagreements(p, cur).join("\n")).toContain("must follow a blank line");
  });
  test("a State row that is not in a table is refused", () => {
    const p = real();
    p.openWork = p.openWork.replace(/^\| what \| value \|\n\| --- \| --- \|\n/m, 'text <a title="\n');
    expect(disagreements(p, cur).join("\n")).toContain("not a row of a table");
  });
  test("a State row under a header with no delimiter row is refused", () => {
    const p = real();
    p.openWork = p.openWork.replace(/^\| --- \| --- \|\n/m, "");
    expect(disagreements(p, cur).join("\n")).toContain("not a row of a table");
  });
  // Retest 8 (KI-35): GFM's table rules — the same cell count in header and delimiter, excess dropped.
  test("the reviewer's shape A, header and delimiter of different widths (not a table), is refused", () => {
    const p = real();
    p.openWork = p.openWork.replace(/^\| what \| value \|\n\| --- \| --- \|$/m, '| what <a title=" | value |\n| --- | --- | --- |');
    const d = disagreements(p, cur).join("\n");
    expect(d).toContain("2 header cells and 3 delimiter cells");
    expect(d).toContain('holds a "<" above the State row');
  });
  test("the reviewer's shape B, a one-column table that drops the version cell, is refused", () => {
    const p = real();
    p.openWork = p.openWork.replace(/^\| what \| value \|\n\| --- \| --- \|$/m, "| what |\n| --- |");
    expect(disagreements(p, cur).join("\n")).toContain("1 header cells and 1 delimiter cells");
  });
  test("a State row with more cells than its table is refused", () => {
    const p = real();
    p.openWork = p.openWork.replace(/^(\| version \|)/m, "$1 extra |");
    expect(disagreements(p, cur).join("\n")).toContain("cells in a 2-column table");
  });
  test("cells are split on every unescaped pipe, in code spans too (GFM)", () => {
    expect(cells("| a | `b | c` |")).toBe(3);
    expect(cells("| a | b \\| c |")).toBe(2);
    expect(cells("a | b")).toBe(2);
  });
  test("front matter at the top of a counted file is refused", () => {
    const p = real();
    p.readme = `---\nk: v\n---\n${p.readme}`;
    expect(disagreements(p, cur).join("\n")).toContain("front matter");
  });
  test("an em dash or an apostrophe before the status version is allowed", () => {
    const p = real();
    p.readme = p.readme.replace(/^> \*\*Status: /m, "> **Status: zilc's prototype — ");
    expect(disagreements(p, cur)).toEqual([]);
  });
  // Retest 9 (KI-36).
  for (const [where, re] of [
    ["between the table and the State row", /^(\| version \|)/m],
    ["between the header and the delimiter", /^(\| --- \| --- \|)$/m],
  ] as const) {
    test(`a fence ${where} splits the table and is refused`, () => {
      const p = real();
      p.openWork = p.openWork.replace(re, "```\nx\n```\n$1");
      expect(disagreements(p, cur).join("\n")).toMatch(/not a row of a table|header cells/);
    });
  }
  test("$$ is refused at a line start, in a quote, in a list and mid-line (KI-36, KI-37)", () => {
    for (const l of ["$$", "> $$", "- $$", "a $$ b"]) expect(unreadable(`text\n\n${l}\n`).join("\n")).toContain("$$");
  });

  // Retest 10 (KI-37).
  for (const lead of ["> <a title=\"", "- <a title=\"", "1. <a title=\"", "some text"]) {
    test(`a State table right after "${lead}" (a lazy continuation) is refused`, () => {
      const p = real();
      p.openWork = p.openWork.replace(/^(\| what \| value \|)$/m, `${lead}\n$1`);
      expect(disagreements(p, cur).join("\n")).toContain("must follow a blank line or a heading");
    });
  }
  for (const cp of [0xa0, 0xfeff, 0x3000, 0x2003]) {
    test(`U+${cp.toString(16).toUpperCase().padStart(4, "0")} in a counted file is refused`, () => {
      const p = real();
      p.openWork = p.openWork.replace(/^(\| what \| value \|)$/m, `$1${String.fromCodePoint(cp)}`);
      expect(disagreements(p, cur).join("\n")).toContain("a BOM or non-ASCII whitespace");
    });
  }
  test("cells() trims ASCII whitespace only, as GFM does", () => {
    expect(cells(`| a | b |${String.fromCodePoint(0xa0)}`)).toBe(3);
    expect(cells("\t| a | b | \f")).toBe(2);
  });
  test("a leading BOM before front matter is refused", () => {
    const p = real();
    p.readme = `${String.fromCodePoint(0xfeff)}---\na: b\n---\n${p.readme}`;
    expect(disagreements(p, cur).join("\n")).toContain("U+FEFF");
  });
  test("a < in a State table row above the State row is refused", () => {
    const p = real();
    p.openWork = p.openWork.replace(/^(\| --- \| --- \|)$/m, '$1\n| note | <a title=" |');
    expect(disagreements(p, cur).join("\n")).toContain('holds a "<" above the State row');
  });
  test("a one-dash delimiter row is a delimiter (GFM accepts it)", () => {
    const p = real();
    p.openWork = p.openWork.replace(/^\| --- \| --- \|$/m, "|-|-|");
    expect(disagreements(p, cur)).toEqual([]);
  });
  test("an autolink at a line start is a link, not an HTML block", () => {
    expect(unreadable("<https://example.com/x>\n")).toEqual([]);
    expect(unreadable("<div>\n").join("\n")).toContain("HTML block");
  });
  test("a README with a CR byte is refused (LF only)", () => {
    const p = real();
    p.readme = p.readme.replace("\n", "\r\n");
    expect(disagreements(p, cur).join("\n")).toContain("README.md: holds a CR byte");
  });

  test("a longer version is not a mention (…1 in …10)", () => {
    expect(mentions("0.15.2-0.687.10 x0.15.2-0.687.1 0.15.2-0.687.1", "0.15.2-0.687.1")).toBe(2);
    expect(mentions("10.15.2-0.687.1", "0.15.2-0.687.1")).toBe(0);
  });

  test("build.zig.zon with two .version lines is not read", () => {
    expect(zonVersion(`.{\n    .version = "0.15.2-0.687.1",\n    .version = "0.15.2-0.687.2",\n}`)).toBeNull();
  });
});

describe("the release entry", () => {
  const md = ["# r", "", "## Release History", "", "### v0.15.2-0.687.10 — x", "security review hardening review", "", "### v0.15.2-0.687.1 — y", "body", "", "## Later section", "security review and hardening review"].join("\n");

  test("…687.1 does not find …687.10's entry", () => {
    const e = findEntry(md, "0.15.2-0.687.1")!;
    expect(e).toContain("body");
    expect(e).not.toContain("687.10");
  });

  test("the last entry ends at the next heading, not at the end of the file", () => {
    expect(findEntry(md, "0.15.2-0.687.1")).not.toContain("Later section");
  });

  test("an entry without the v is not the entry", () => {
    expect(findEntry("## Release History\n\n### 0.15.2-0.687.2\nx", "0.15.2-0.687.2")).toBeNull();
  });

  test("an entry outside the Release History section is not the entry", () => {
    expect(findEntry("## Notes\n\n### v1.2.3-4.5.6 — x\n\n## Release History\n", "1.2.3-4.5.6")).toBeNull();
  });

  test("no Release History section, or two, is an error", () => {
    expect(() => findEntry("### v1.2.3-4.5.6\n", "1.2.3-4.5.6")).toThrow("0");
    expect(() => findEntry("## Release History\n## Release History\n", "1.2.3-4.5.6")).toThrow("2");
  });

  // Retests 3–4 (KI-30, KI-31): what could hide an entry heading is refused, not interpreted.
  for (const [name, md] of [
    ["inside a ~~~ fence", "## Release History\n~~~\n### v1.2.3-4.5.6 — x\nbody\n~~~\n"],
    ["inside an HTML comment", "## Release History\n<!--\n### v1.2.3-4.5.6 — x\nbody\n-->\n"],
    ["inside a <pre> block", "## Release History\n<pre>\n### v1.2.3-4.5.6 — x\n</pre>\n"],
    ["after a CR byte", "## Release History\r\n### v1.2.3-4.5.6 — x\r\n"],
    ["after a processing instruction", "## Release History\n<?x\n### v1.2.3-4.5.6 — x\n?>\n"],
    ["after CDATA", "## Release History\n<![CDATA[\n### v1.2.3-4.5.6 — x\n]]>\n"],
  ] as const) {
    test(`a file with an entry heading ${name} is refused`, () => {
      expect(() => findEntry(md, "1.2.3-4.5.6")).toThrow();
    });
  }

  // Retest 5 (KI-32): a fence inside a container, which ends with the container on GitHub.
  const trap = "- item\n  ```\n  x\n<!-- the rest of the file\n```\n";
  test("the reviewer's list-item fence trap above the section is refused", () => {
    expect(() => findEntry(`# r\n\n${trap}\n## Release History\n\n### v1.2.3-4.5.6 — x\nbody\n`, "1.2.3-4.5.6")).toThrow("fence inside a list, quote or indent");
  });
  for (const [name, l] of [
    ["indented one space", " ```"],
    ["indented three spaces", "   ~~~"],
    ["in a blockquote", "> ```"],
    ["in a nested quote", "> > ~~~"],
    ["after a list marker", "- ```"],
    ["after a numbered marker", "1. ```"],
    ["after a tab", "\t```"],
  ] as const) {
    test(`a fence ${name} is refused`, () => {
      expect(unreadable(`text\n${l}\ncode\n\`\`\`\n`).join("\n")).toContain("fence inside a list, quote or indent");
    });
  }
  test("an indented closer of a column-0 fence is still a closer (CommonMark allows three spaces)", () => {
    expect(unreadable("```\ncode\n   ```\nafter\n")).toEqual([]);
  });

  test("the entry ends at a one-dash setext underline (retest 5, KI-32)", () => {
    const e = findEntry("## Release History\n\n### v1.2.3-4.5.6 — x\nNote\n-\nlater\n", "1.2.3-4.5.6")!;
    expect(e).not.toContain("later");
  });

  test("an escaped backtick never opens a code span (retest 5, KI-32)", () => {
    expect(unreadable("text \\`<!-- x \\` more\n").join("\n")).toContain("HTML comment");
  });
  test("backtick runs of different lengths are not a code span (retest 5, KI-32)", () => {
    expect(unreadable("text `<!-- x `` more\n").join("\n")).toContain("HTML comment");
  });

  test("a placeholder tag mid-line is allowed; `<!--` is refused even in backticks (KI-33)", () => {
    expect(findEntry("## Release History\n\n### v1.2.3-4.5.6 — x\nuse `<Zig>-<Fil-C>.<N>` and <n> here\n", "1.2.3-4.5.6")).toContain("<Zig>");
    expect(() => findEntry("## Release History\n\n### v1.2.3-4.5.6 — x\nuse `<!--` here\n", "1.2.3-4.5.6")).toThrow("HTML comment");
  });

  // Retest 6 (KI-33): which backticks pair is the renderer's call — the guard no longer guesses.
  for (const [name, l] of [
    ["a backtick in a tag attribute before a comment", '> **Status: ok <b title="`"> <!-- (v1) ` -->'],
    ["a backslash inside a span before a comment", "> **Status: ok `a\\` <!-- (v1) `"],
    ["<details> mid-line", "text <details>"],
    ["<details> indented", "para\n    <details>"],
    ["<details> in a quote", "> <details>"],
    ["<details> in a list", "- <details>"],
    ["</summary> anywhere", "a </summary> b"],
  ] as const) {
    test(`${name} is refused`, () => {
      expect(unreadable(`${l}\n`).length).toBeGreaterThan(0);
    });
  }

  test("a fence ABOVE the section is allowed (the review form's own example lives there)", () => {
    expect(findEntry("# r\n```\nexample\n```\n## Release History\n\n### v1.2.3-4.5.6 — x\nbody\n", "1.2.3-4.5.6")).toContain("body");
  });

  for (const [name, after] of [
    ["a setext heading", "Other\n====="],
    ["an indented heading", "  ## Other"],
    ["a bare ###", "###"],
    ["a heading after a tab", "#\tOther"],
  ] as const) {
    test(`the entry ends at ${name} (retest 4, KI-31)`, () => {
      const e = findEntry(`## Release History\n\n### v1.2.3-4.5.6 — x\nbody\n${after}\nlater\n`, "1.2.3-4.5.6")!;
      expect(e).toContain("body");
      expect(e).not.toContain("later");
    });
  }

  test("an entry under a later section is not the entry (retest 9, KI-36)", () => {
    expect(findEntry("## Release History\n\n### v1.0.0-1.0.1 — x\nold\n\n## Scratch\n\n### v1.2.3-4.5.6 — x\nbody\n", "1.2.3-4.5.6")).toBeNull();
    expect(findEntry("## Release History\n\n# Other\n\n### v1.2.3-4.5.6 — x\nbody\n", "1.2.3-4.5.6")).toBeNull();
  });
  test("the last entry of the section ends at the next section", () => {
    const e = findEntry("## Release History\n\n### v1.2.3-4.5.6 — x\nbody\n## Next\nlater\n", "1.2.3-4.5.6")!;
    expect(e).not.toContain("later");
  });

  test("two entries for one version is an error", () => {
    expect(() => findEntry("## Release History\n### v1.2.3-4.5.6\n### v1.2.3-4.5.6\n", "1.2.3-4.5.6")).toThrow();
  });
});

describe("the review records' form", () => {
  const ok = "- **Security review:** 3 rounds, empty round 2026-11-20, reviewed `v0.15.2-0.687.1..0123abc`\n- **Hardening review:** 1 round, empty round 2026-11-21, reviewed `v0.15.2-0.687.1..0123abc`";

  test("the form is accepted", () => {
    expect(reviewRecords(ok).bad).toEqual([]);
  });

  test("a fence in an entry is refused even when properly closed: an entry is plain text (KI-31)", () => {
    expect(reviewRecords(`\`\`\`\ncode\n\`\`\`\n${ok}`).bad.join("\n")).toContain("code fence");
    expect(reviewRecords(`~~~~\ncode\n~~~~~\n${ok}`).bad.join("\n")).toContain("code fence");
  });

  test("placeholders and tags mid-line are allowed beside records (only hiding forms are refused)", () => {
    expect(reviewRecords(`${ok}\nnote: \`<pre>\`, <n> and \`<commit>\` are text here`).bad).toEqual([]);
  });

  for (const [name, text] of [
    ["a negation", "security review: not run. hardening review: skipped."],
    ["placeholders", "- **Security review:** TODO\n- **Hardening review:** TODO"],
    ["a heading", "#### Security review and hardening review"],
    ["only one kind", "- **Security review:** 3 rounds, empty round 2026-11-20, reviewed `v0.15.2-0.687.1..0123abc`"],
    ["zero rounds", ok.replace("3 rounds", "0 rounds")],
    ["a date that is not one", ok.replace("2026-11-20", "2026-02-31")],
    ["one kind twice", `${ok}\n- **Security review:** 4 rounds, empty round 2026-11-22, reviewed \`v0.15.2-0.687.1..0123abc\``],
    ["records inside an HTML comment (retest 2, KI-29)", `<!--\n${ok}\n-->`],
    ["one record inside an unclosed HTML comment (retest 2, KI-29)", ok.replace("\n", "\n<!-- \n")],
    ["records inside a ``` fence (retest 2, KI-29)", `\`\`\`\n${ok}\n\`\`\``],
    ["records inside a ~~~ fence (retest 2, KI-29)", `~~~\n${ok}\n~~~`],
    ["records after a shorter, non-closing ``` inside a ```` fence (retest 3, KI-30)", `\`\`\`\`\ncode\n\`\`\`\n${ok}\n\`\`\`\``],
    ["records after a ``` x line, which does not close (retest 3, KI-30)", `\`\`\`\ncode\n\`\`\` x\n${ok}\n\`\`\``],
    ["records after a ~~~ line inside a ``` fence (retest 3, KI-30)", `\`\`\`\ncode\n~~~\n${ok}\n\`\`\``],
    ["records inside an unclosed fence (retest 3, KI-30)", `\`\`\`\n${ok}`],
    ["records inside a <script> block (retest 3, KI-30)", `<script>\n${ok}\n</script>`],
    ["records inside a <style> block (retest 3, KI-30)", `<style type="x">\n${ok}\n</style>`],
    ["records inside a <pre> block (retest 3, KI-30)", `<pre>\n${ok}\n</pre>`],
    ["records inside a <textarea> block (retest 3, KI-30)", `<textarea>\n${ok}\n</textarea>`],
    ["records after a comment that makes a fence line look closed (retest 4, KI-31)", `\`\`\`\n<!-- -->\`\`\`\n${ok}\n\`\`\``],
    ["records inside a processing instruction (retest 4, KI-31)", `<?x\n${ok}\n?>`],
    ["records inside CDATA (retest 4, KI-31)", `<![CDATA[\n${ok}\n]]>`],
    ["records after a heading-like line (retest 4, KI-31)", `x\n=====\n${ok}`],
    ["records with a CR byte (LF only)", ok.replaceAll("\n", "\r\n")],
  ] as const) {
    test(`${name} is not a record`, () => {
      expect(reviewRecords(text).bad.length).toBeGreaterThan(0);
    });
  }
});

// ---- against a real history: a throwaway repository
let dir = "";
const sh = (...a: string[]) => {
  const p = Bun.spawnSync(["git", "-C", dir, ...a], { stdout: "pipe", stderr: "pipe", env: { ...process.env, GIT_AUTHOR_NAME: "t", GIT_AUTHOR_EMAIL: "t@example.invalid", GIT_COMMITTER_NAME: "t", GIT_COMMITTER_EMAIL: "t@example.invalid", GIT_CONFIG_GLOBAL: "/dev/null", GIT_CONFIG_NOSYSTEM: "1" } });
  if (p.exitCode !== 0) throw new Error(`git ${a.join(" ")}: ${p.stderr.toString()}`);
  return p.stdout.toString().trim();
};
const put = (f: string, t: string) => {
  mkdirSync(join(dir, f, ".."), { recursive: true });
  writeFileSync(join(dir, f), t);
};
const commit = (msg: string) => {
  sh("add", "-A");
  sh("commit", "-q", "-m", msg);
  return sh("rev-parse", "HEAD");
};
const rec = (kind: string, base: string, at: string) => `- **${kind} review:** 2 rounds, empty round 2026-11-20, reviewed \`${base}..${at.slice(0, 10)}\``;
const entryFor = (base: string, at: string) => `### v0.15.2-0.687.2 — 2026-11-21\n\n${rec("Security", base, at)}\n${rec("Hardening", base, at)}\n`;

let before = "", reviewed = "", side = "";

beforeAll(() => {
  dir = mkdtempSync(join(tmpdir(), "zilc-guards-"));
  sh("init", "-q", "-b", "main");
  put("src/code.zig", "a\n");
  put("cmem/release.md", "# release\n\n## Release History\n");
  // The bump's three files are the real ones (version 0.15.2-0.687.1), so the bump commit can be
  // checked as exactly bumpEdits of its parent.
  for (const f of BUMP_FILES) put(f, readFileSync(join(REPO, f), "utf8"));
  // The other counted Markdown files, which must be ordinary files at the commit (KI-36).
  put("cmem/open-work.md", "# open work\n");
  put("RELEASE-NOTES.md", "# notes\n");
  for (const f of ["guards.ts", "check-reviews.ts"]) cpSync(join(import.meta.dir, f), join(dir, "tools/release", f));
  before = commit("start");
  sh("tag", "v0.15.2-0.687.1");
  put("src/code.zig", "b\n");
  reviewed = commit("work, then reviewed");
  sh("switch", "-q", "-c", "side");
  put("src/other.zig", "x\n");
  side = commit("never released");
  sh("switch", "-q", "main");
});
afterAll(() => {
  if (dir) rmSync(dir, { recursive: true, force: true });
});

/** On a fresh branch from `reviewed`: the entry, optional extra changes, then the bump commit. */
type Opts = { codeAfterReview?: boolean; bumpExtra?: boolean; bumpSmuggle?: string; afterReview?: () => void; bumpTamper?: () => void; from?: string };
/** A reviewed commit of its own: `reviewed` plus `fn`'s change, committed. */
function reviewedWith(fn: () => void) {
  sh("switch", "-q", "-C", `r${Math.random().toString(36).slice(2)}`, reviewed);
  fn();
  return commit("reviewed, with a twist");
}
const putBytes = (f: string, b: Uint8Array) => writeFileSync(join(dir, f), b);
const getBytes = (f: string) => readFileSync(join(dir, f));
function release(entry: string, opts: Opts = {}) {
  sh("switch", "-q", "-C", `t${Math.random().toString(36).slice(2)}`, opts.from ?? reviewed);
  if (opts.codeAfterReview) {
    put("src/code.zig", "c\n");
    commit("code after the review");
  }
  if (opts.afterReview) {
    opts.afterReview();
    commit("after the review");
  }
  put("cmem/release.md", `# release\n\n## Release History\n\n${entry}`);
  put("RELEASE-NOTES.md", "## 0.15.2-0.687.2\n");
  commit("notes and the entry");
  // As bump.ts writes it, byte for byte (latin1 is one character per byte).
  const now = Object.fromEntries(BUMP_FILES.map((f) => [f, getBytes(f).toString("latin1")]));
  const bumped = bumpEdits(now, zonVersion(now["build.zig.zon"])!);
  for (const f of BUMP_FILES) putBytes(f, Buffer.from(bumped[f], "latin1"));
  if (opts.bumpExtra) put("src/code.zig", "smuggled\n");
  if (opts.bumpSmuggle) put(opts.bumpSmuggle, `${bumped[opts.bumpSmuggle]}// smuggled\n`);
  opts.bumpTamper?.();
  return commit("bump to v0.15.2-0.687.2");
}
const check = async (head: string) => reviewsCoverRelease(gitIn(dir), findEntry(readFileSync(join(dir, "cmem/release.md"), "utf8"), "0.15.2-0.687.2")!, head, true);
const cli = (head: string) => {
  const p = Bun.spawnSync(["bun", join(dir, "tools/release/check-reviews.ts"), head], { stdout: "pipe", stderr: "pipe" });
  return { code: p.exitCode, out: p.stdout.toString() + p.stderr.toString() };
};

describe("the review records against the history", () => {
  test("records covering everything since the previous release pass (library and CLI)", async () => {
    const h = release(entryFor("v0.15.2-0.687.1", reviewed));
    expect(await check(h)).toEqual([]);
    const r = cli(h);
    expect(r.out).toContain("both required reviews recorded");
    expect(r.code).toBe(0);
  });

  test("code changed after the reviewed commit is refused", async () => {
    const h = release(entryFor("v0.15.2-0.687.1", reviewed), { codeAfterReview: true });
    expect((await check(h)).join("\n")).toContain("src/code.zig");
    expect(cli(h).code).toBe(1);
  });

  test("a review that starts at the wrong release is refused", async () => {
    const h = release(entryFor("v0.15.2-0.686.1", reviewed));
    expect((await check(h)).join("\n")).toContain("previous release is v0.15.2-0.687.1");
  });

  test("a reviewed commit not in the released history is refused", async () => {
    const h = release(entryFor("v0.15.2-0.687.1", side));
    expect((await check(h)).join("\n")).toContain("not in the history being released");
  });

  test("a reviewed commit from before the previous release is refused", async () => {
    const h = release(entryFor("v0.15.2-0.687.1", before));
    expect((await check(h)).join("\n")).toContain("changed after it");
  });

  test("a bump commit that changes more than the bump's files is refused", async () => {
    const h = release(entryFor("v0.15.2-0.687.1", reviewed), { bumpExtra: true });
    expect((await check(h)).join("\n")).toContain("the bump commit changes src/code.zig");
  });

  for (const f of BUMP_FILES) {
    test(`a bump commit whose ${f} carries more than the bump is refused (retest 1, KI-28)`, async () => {
      const h = release(entryFor("v0.15.2-0.687.1", reviewed), { bumpSmuggle: f });
      expect((await check(h)).join("\n")).toContain(`the bump commit's ${f} is not exactly the bump`);
      expect(cli(h).code).toBe(1);
    });
  }

  test("reviewed code moved into cmem/ after the review is refused (a rename, retest 1, KI-28)", async () => {
    const h = release(entryFor("v0.15.2-0.687.1", reviewed), { afterReview: () => sh("mv", "src/code.zig", "cmem/code.zig.txt") });
    expect((await check(h)).join("\n")).toContain("src/code.zig");
    expect(cli(h).code).toBe(1);
  });

  test("a non-ASCII memory file after the review is allowed (retest 1, KI-28)", async () => {
    const h = release(entryFor("v0.15.2-0.687.1", reviewed), { afterReview: () => put("cmem/café.md", "x\n") });
    expect(await check(h)).toEqual([]);
    expect(cli(h).code).toBe(0);
  });

  // Retest 2 (KI-29): the bump commit compared as git objects, not decoded text.
  const withByte = () => reviewedWith(() => putBytes("src/root.zig", Buffer.concat([getBytes("src/root.zig"), Buffer.from([0x2f, 0x2f, 0x20, 0xff, 0x0a])])));
  test("a bump commit that changes one invalid UTF-8 byte is refused", async () => {
    const r = withByte();
    const h = release(entryFor("v0.15.2-0.687.1", r), { from: r, bumpTamper: () => {
      const b = getBytes("src/root.zig");
      b[b.lastIndexOf(0xff)] = 0xfe;
      putBytes("src/root.zig", b);
    } });
    expect((await check(h)).join("\n")).toContain("src/root.zig is not exactly the bump");
  });
  test("an exact bump of a file holding an invalid UTF-8 byte passes", async () => {
    const r = withByte();
    expect(await check(release(entryFor("v0.15.2-0.687.1", r), { from: r }))).toEqual([]);
  });
  test("a bump commit that adds a BOM is refused", async () => {
    const h = release(entryFor("v0.15.2-0.687.1", reviewed), { bumpTamper: () => putBytes("README.md", Buffer.concat([Buffer.from([0xef, 0xbb, 0xbf]), getBytes("README.md")])) });
    expect((await check(h)).join("\n")).toContain("README.md is not exactly the bump");
  });
  test("a bump commit that also changes a file's mode is refused", async () => {
    const h = release(entryFor("v0.15.2-0.687.1", reviewed), { bumpTamper: () => chmodSync(join(dir, "src/root.zig"), 0o755) });
    expect((await check(h)).join("\n")).toContain("src/root.zig is not an ordinary file");
  });
  test("a bump commit that turns a file into a symlink is refused", async () => {
    const h = release(entryFor("v0.15.2-0.687.1", reviewed), { bumpTamper: () => {
      rmSync(join(dir, "README.md"));
      symlinkSync("src/code.zig", join(dir, "README.md"));
    } });
    expect((await check(h)).join("\n")).toContain("README.md is not an ordinary file");
  });
  test("a submodule moved after the review is refused, even with ignore = all", async () => {
    const r = reviewedWith(() => {
      put(".gitmodules", '[submodule "vendor"]\n\tpath = vendor\n\turl = ./nowhere\n\tignore = all\n');
      mkdirSync(join(dir, "vendor"), { recursive: true }); // an unpopulated submodule: `add -A` leaves it be
      sh("update-index", "--add", "--cacheinfo", `160000,${"1".repeat(40)},vendor`);
    });
    const h = release(entryFor("v0.15.2-0.687.1", r), { from: r, afterReview: () => sh("update-index", "--cacheinfo", `160000,${"2".repeat(40)},vendor`) });
    expect((await check(h)).join("\n")).toContain("vendor");
  });

  test("a replace ref that shows a clean bump in place of a smuggling one changes nothing", async () => {
    const good = release(entryFor("v0.15.2-0.687.1", reviewed));
    const bad = release(entryFor("v0.15.2-0.687.1", reviewed), { bumpSmuggle: "src/root.zig" });
    sh("replace", bad, good);
    try {
      expect((await check(bad)).join("\n")).toContain("src/root.zig is not exactly the bump");
    } finally {
      sh("replace", "-d", bad);
    }
  });

  test("the current version is named only in its known places (retest 2, KI-29: Fil-C.md was a sixth)", () => {
    const p = Bun.spawnSync(["git", "-C", REPO, "grep", "-l", "-F", cur.full], { stdout: "pipe", stderr: "pipe" });
    expect(p.exitCode).toBe(0);
    const allowed = (f: string) => BUMP_FILES.includes(f) || f === "RELEASE-NOTES.md" || f.startsWith("cmem/") || /^tools\/release\/[^/]+\.test\.ts$/.test(f);
    expect(p.stdout.toString().split("\n").filter(Boolean).filter((f) => !allowed(f))).toEqual([]);
  });

  test("bumpEdits is what bump.ts writes: the real repository bumps cleanly, every anchor once", () => {
    const now = Object.fromEntries(BUMP_FILES.map((f) => [f, readFileSync(join(REPO, f), "utf8")]));
    const out = bumpEdits(now, cur);
    const next = `${cur.zig}-${cur.filc}.${cur.n + 1}`;
    expect(zonVersion(out["build.zig.zon"])!.full).toBe(next);
    const p = real();
    p.root = out["src/root.zig"];
    p.readme = out["README.md"];
    p.zon = out["build.zig.zon"];
    const bad = disagreements(p, { ...cur, full: next, n: cur.n + 1 }).filter((b) => !b.startsWith("RELEASE-NOTES") && !b.startsWith("cmem/open-work"));
    expect(bad).toEqual([]);
    expect(() => bumpEdits({ ...now, "src/root.zig": now["src/root.zig"].replace("// next zilc release", "") }, cur)).toThrow();
  });

  // bump.ts's own path: HEAD is the notes commit, BEFORE the bump (bumped = false; retest 3).
  test("before the bump: records covering the history pass, code after the review is refused", async () => {
    const g = gitIn(dir);
    const e = entryFor("v0.15.2-0.687.1", reviewed);
    const good = release(e);
    expect(await reviewsCoverRelease(g, findEntry(readFileSync(join(dir, "cmem/release.md"), "utf8"), "0.15.2-0.687.2")!, `${good}^`, false)).toEqual([]);
    const bad = release(e, { codeAfterReview: true });
    expect((await reviewsCoverRelease(g, findEntry(readFileSync(join(dir, "cmem/release.md"), "utf8"), "0.15.2-0.687.2")!, `${bad}^`, false)).join("\n")).toContain("src/code.zig");
  });

  // The tags here against origin's (retest 3, KI-30): a bare clone stands in for origin.
  test("release tags that differ from origin's are named, each way", async () => {
    const origin = mkdtempSync(join(tmpdir(), "zilc-origin-"));
    try {
      Bun.spawnSync(["git", "clone", "-q", "--bare", dir, origin]);
      sh("remote", "add", "origin", origin);
      const g = gitIn(dir);
      expect(await tagsDifferFrom(g)).toEqual([]);
      Bun.spawnSync(["git", "-C", origin, "tag", "v0.15.2-0.687.2", reviewed]);
      expect((await tagsDifferFrom(g)).join("\n")).toContain("v0.15.2-0.687.2 is on origin but not here");
      sh("tag", "v0.15.2-0.687.2", before);
      expect((await tagsDifferFrom(g)).join("\n")).toContain("v0.15.2-0.687.2 differs");
      sh("tag", "-d", "v0.15.2-0.687.2");
      Bun.spawnSync(["git", "-C", origin, "tag", "-d", "v0.15.2-0.687.2"]);
      sh("tag", "v9.9.9-9.9.9", reviewed);
      expect((await tagsDifferFrom(g)).join("\n")).toContain("v9.9.9-9.9.9 is here but not on origin");
      sh("tag", "-d", "v9.9.9-9.9.9");
      sh("remote", "remove", "origin");
      rmSync(origin, { recursive: true, force: true });
      const gone = await tagsDifferFrom(g).then(() => "no error", (e: Error) => e.message);
      expect(gone).toContain("ls-remote");
    } finally {
      Bun.spawnSync(["git", "-C", dir, "remote", "remove", "origin"]);
      rmSync(origin, { recursive: true, force: true });
    }
  });

  // CI's "Is this a release?" step, run as written in release.yml (retest 3: it had no test).
  test("the workflow's decide step releases only the bump commit, or a re-run on its tag", () => {
    const yml = readFileSync(join(REPO, ".github/workflows/release.yml"), "utf8").split("\n");
    const i = yml.findIndex((l) => l.trim() === "id: decide");
    expect(i).toBeGreaterThan(0);
    expect(yml[i + 1].trim()).toBe("run: |");
    const body: string[] = [];
    for (let j = i + 2; j < yml.length && (yml[j].startsWith("          ") || yml[j] === ""); j++) body.push(yml[j].slice(10));
    expect(body.join("\n")).toContain("GITHUB_OUTPUT");
    const decide = (sha: string) => {
      const out = join(dir, "..", `${Math.random().toString(36).slice(2)}.out`);
      writeFileSync(out, "");
      const p = Bun.spawnSync(["bash", "-c", body.join("\n").replaceAll("${{ github.sha }}", sha)], { cwd: dir, env: { ...process.env, GITHUB_OUTPUT: out }, stdout: "pipe", stderr: "pipe" });
      const r = `${p.exitCode} ${readFileSync(out, "utf8").trim().replaceAll("\n", " ")}`;
      rmSync(out);
      return r;
    };
    const bump = release(entryFor("v0.15.2-0.687.1", reviewed));
    expect(decide(bump)).toBe("0 release=true tag=v0.15.2-0.687.2");
    put("cmem/after.md", "x\n");
    const child = commit("memory: after the bump");
    expect(decide(child)).toBe("0 release=false tag=v0.15.2-0.687.2");
    sh("tag", "v0.15.2-0.687.2", bump);
    try {
      expect(decide(bump)).toBe("0 release=true tag=v0.15.2-0.687.2"); // a re-run
      expect(decide(child)).toBe("0 release=false tag=v0.15.2-0.687.2"); // released before
    } finally {
      sh("tag", "-d", "v0.15.2-0.687.2");
    }
  });

  for (const f of ["RELEASE-NOTES.md", "cmem/open-work.md"]) {
    test(`${f} as a symlink is refused at the commit (retest 9, KI-36)`, async () => {
      const h = release(entryFor("v0.15.2-0.687.1", reviewed), { bumpTamper: () => {
        writeFileSync(join(dir, "cmem/real.md"), readFileSync(join(dir, f)));
        rmSync(join(dir, f));
        symlinkSync(f.startsWith("cmem/") ? "real.md" : "cmem/real.md", join(dir, f));
      } });
      // A symlink in the bump commit is also an extra file; the mode is named either way.
      expect((await check(h)).join("\n")).toContain(`${f} is not an ordinary file (mode 100644)`);
    });
  }

  test("a .github/README.md, which GitHub shows instead of README.md, is refused (retest 10, KI-37)", async () => {
    const h = release(entryFor("v0.15.2-0.687.1", reviewed), { afterReview: () => put(".github/README.md", "# other\n") });
    expect((await check(h)).join("\n")).toContain(".github/README.md exists");
  });

  // CI's review step is present and gated as designed (retest 9: no test tied the YAML to it).
  test("release.yml runs check-reviews.ts on a release, and tag needs checks", () => {
    const yml = readFileSync(join(REPO, ".github/workflows/release.yml"), "utf8");
    const step = yml.match(/- name: The required reviews \(a release only\)\n {8}if: (.*)\n {8}run: (.*)\n/);
    expect(step).not.toBeNull();
    expect(step![1]).toBe("steps.decide.outputs.release == 'true'");
    expect(step![2]).toBe('bun tools/release/check-reviews.ts "$GITHUB_SHA"');
    expect(yml).toMatch(/\n {2}tag:\n {4}needs: checks\n {4}if: needs\.checks\.outputs\.release == 'true'\n/);
    expect(yml).toMatch(/\n {2}release:\n {4}needs: \[checks, tag\]\n/);
  });

  // Retest 4: the branches no test reached.
  test("an empty bump commit is refused", async () => {
    sh("switch", "-q", "-C", `e${Math.random().toString(36).slice(2)}`, reviewed);
    put("cmem/release.md", `# release\n\n## Release History\n\n${entryFor("v0.15.2-0.687.1", reviewed)}`);
    commit("the entry");
    sh("commit", "-q", "--allow-empty", "-m", "bump to v0.15.2-0.687.2");
    expect((await check(sh("rev-parse", "HEAD"))).join("\n")).toContain("the bump commit changes nothing");
  });
  test("a record naming something that is not a commit is refused", async () => {
    const h = release(entryFor("v0.15.2-0.687.1", "deadbeef00"));
    expect((await check(h)).join("\n")).toContain("deadbeef00, which is not a commit here");
  });
  test("a parent whose build.zig.zon has no version is refused", async () => {
    // By hand: release() cannot bump a parent without a version.
    sh("switch", "-q", "-C", `z${Math.random().toString(36).slice(2)}`, reviewed);
    put("build.zig.zon", ".{}\n");
    commit("the version gone");
    put("cmem/release.md", `# release\n\n## Release History\n\n${entryFor("v0.15.2-0.687.1", reviewed)}`);
    commit("the entry");
    put("build.zig.zon", '.{\n    .version = "0.15.2-0.687.2",\n}\n');
    const h = commit("bump to v0.15.2-0.687.2");
    expect((await check(h)).join("\n")).toContain("no readable build.zig.zon .version");
  });
  test("a parent that bumpEdits cannot bump is refused", async () => {
    // By hand: release() bumps through bumpEdits, which throws on this parent.
    sh("switch", "-q", "-C", `b${Math.random().toString(36).slice(2)}`, reviewed);
    put("src/root.zig", readFileSync(join(dir, "src/root.zig"), "utf8").replace("// next zilc release", ""));
    commit("an anchor gone");
    put("cmem/release.md", `# release\n\n## Release History\n\n${entryFor("v0.15.2-0.687.1", reviewed)}`);
    commit("the entry");
    put("build.zig.zon", readFileSync(join(dir, "build.zig.zon"), "utf8").replace('"0.15.2-0.687.1"', '"0.15.2-0.687.2"'));
    const h = commit("bump to v0.15.2-0.687.2");
    expect((await check(h)).join("\n")).toContain("cannot be bumped");
  });
  test("bump files executable on both sides are refused", async () => {
    const r = reviewedWith(() => chmodSync(join(dir, "src/root.zig"), 0o755));
    const h = release(entryFor("v0.15.2-0.687.1", r), { from: r });
    expect((await check(h)).join("\n")).toContain("src/root.zig is not an ordinary file (mode 100644) on both sides: 100755");
  });
  test("a git failure in describe or merge-base is never a pass", async () => {
    const h = release(entryFor("v0.15.2-0.687.1", reviewed));
    const entry = findEntry(readFileSync(join(dir, "cmem/release.md"), "utf8"), "0.15.2-0.687.2")!;
    const failing = (cmd: string): Git => async (...a) => (a[0] === cmd ? { code: 128, out: "fatal: injected", raw: new Uint8Array() } : gitIn(dir)(...a));
    expect((await reviewsCoverRelease(failing("describe"), entry, h, true)).join("\n")).toContain("no release tag is reachable");
    await expect(reviewsCoverRelease(failing("merge-base"), entry, h, true)).rejects.toThrow("merge-base");
  });
  test("a remote that never answers is a refusal within the time limit", async () => {
    const bin = mkdtempSync(join(tmpdir(), "zilc-hang-"));
    try {
      // git runs `git-remote-<scheme>` for an unknown URL scheme: this one never answers.
      writeFileSync(join(bin, "git-remote-hang"), "#!/bin/sh\nexec sleep 60\n", { mode: 0o755 });
      sh("remote", "add", "origin", "hang://nowhere");
      const old = process.env.PATH;
      process.env.PATH = `${bin}:${old}`;
      const t0 = Date.now();
      try {
        const e = await tagsDifferFrom(gitIn(dir, 2)).then(() => "no error", (x: Error) => x.message);
        expect(e).toContain("no answer in 2 s");
        expect(Date.now() - t0).toBeLessThan(15000);
        // The shared run() (release.ts's git helper, bump.ts's fetch) too (retest 5, KI-32).
        const t1 = Date.now();
        const r = await run(["git", "-C", dir, "ls-remote", "origin"], { timeout: 2 });
        expect(r.code).toBe(124);
        expect(r.timedOut).toBe(true);
        expect(Date.now() - t1).toBeLessThan(15000);
      } finally {
        process.env.PATH = old;
      }
    } finally {
      Bun.spawnSync(["git", "-C", dir, "remote", "remove", "origin"]);
      rmSync(bin, { recursive: true, force: true });
    }
  }, 30000); // two 2 s limits and run()'s 2 s grace: past bun's default 5 s per test

  test("the negation the first guard accepted is refused by the CLI", () => {
    const h = release("### v0.15.2-0.687.2 — x\n\nsecurity review: not run. hardening review: skipped.\n");
    const r = cli(h);
    expect(r.code).toBe(1);
    expect(r.out).toContain("no security review record");
  });

  test("a commit that is not the bump commit is refused by the CLI", () => {
    release(entryFor("v0.15.2-0.687.1", reviewed));
    put("cmem/x.md", "memory after the bump\n");
    const h = commit("memory: after the bump");
    const r = cli(h);
    expect(r.code).toBe(1);
    expect(r.out).toContain("is not the bump commit");
  });

  test("a git failure is exit 2, never a pass", () => {
    const r = cli("no-such-commit");
    expect(r.code).toBe(2);
  });
});
