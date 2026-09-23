#!/usr/bin/env -S deno run --allow-read --allow-write --allow-run
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Delta-debug an LLVM IR module down to the smallest one that still crashes a
// compiler. Written for cmem/known-issues.md KI-4: Zig's Debug IR segfaults
// Fil-C's pass at -O1, and "189,740 lines" is not a bug report.
//
// Reduction unit: one function definition. Excluded definitions become
// `declare`s, so call sites stay valid and the module keeps parsing.
//
//   deno run --allow-read --allow-write --allow-run llreduce.ts \
//     --input dbg-ni.ll --out reduced.ll --filc /path/to/filc/bin/clang
//
// "Interesting" means the compiler died on a signal (segfault or assert),
// never an ordinary error exit — otherwise the reducer happily "reduces"
// towards modules that merely fail to parse.

interface Args {
  input: string;
  out: string;
  filc: string;
  opt: string;
}

function parseArgs(argv: string[]): Args {
  const a: Args = { input: "", out: "reduced.ll", filc: "clang", opt: "-O1" };
  for (let i = 0; i < argv.length; i += 2) {
    const v = argv[i + 1];
    switch (argv[i]) {
      case "--input": a.input = v; break;
      case "--out": a.out = v; break;
      case "--filc": a.filc = v; break;
      case "--opt": a.opt = v; break;
      default: throw new Error(`unknown argument: ${argv[i]}`);
    }
  }
  if (!a.input) throw new Error("--input is required");
  return a;
}

interface Func {
  start: number; // index of the `define` line
  end: number; // index of the closing `}` line
  decl: string; // the `declare` that replaces it when excluded
}

/** Turn a `define` line into a `declare`: drop the body, the linkage and any metadata. */
function defineToDeclare(defineLine: string): string {
  const open = defineLine.indexOf("(");
  const close = defineLine.lastIndexOf(")");
  if (open < 0 || close < 0 || close < open) return "";

  const head = defineLine.slice(0, open); // "define internal fastcc void @foo"
  const params = defineLine.slice(open + 1, close);

  // Keep the return type, calling convention and name; drop linkage keywords,
  // which are illegal on a declaration.
  const drop = new Set([
    "define", "internal", "private", "linkonce", "linkonce_odr", "weak",
    "weak_odr", "external", "available_externally", "appending", "common",
    "extern_weak", "dso_local", "dso_preemptable", "hidden", "protected",
    "default", "unnamed_addr", "local_unnamed_addr",
  ]);
  const headParts = head.trim().split(/\s+/).filter((t) => !drop.has(t));

  // Strip parameter names, keeping types and any parameter attributes.
  const types = splitTopLevel(params).map((p) => {
    const t = p.trim();
    if (t === "..." || t === "") return t;
    const pct = t.lastIndexOf("%");
    return pct > 0 ? t.slice(0, pct).trim() : t;
  }).filter((t) => t !== "");

  return `declare ${headParts.join(" ")}(${types.join(", ")})`;
}

/** Split a parameter list on commas that are not nested inside <>, [], {} or (). */
function splitTopLevel(s: string): string[] {
  const out: string[] = [];
  let depth = 0, start = 0;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if ("<[{(".includes(c)) depth++;
    else if (">]})".includes(c)) depth--;
    else if (c === "," && depth === 0) {
      out.push(s.slice(start, i));
      start = i + 1;
    }
  }
  out.push(s.slice(start));
  return out;
}

function findFunctions(lines: string[]): Func[] {
  const funcs: Func[] = [];
  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].startsWith("define ")) continue;
    let j = i;
    while (j < lines.length && lines[j] !== "}") j++;
    const decl = defineToDeclare(lines[i]);
    if (decl) funcs.push({ start: i, end: j, decl });
    i = j;
  }
  return funcs;
}

/** Render the module with only `keep` function bodies present. */
function render(lines: string[], funcs: Func[], keep: Set<number>): string {
  const skip = new Map<number, Func>();
  for (const [idx, f] of funcs.entries()) if (!keep.has(idx)) skip.set(f.start, f);

  const out: string[] = [];
  for (let i = 0; i < lines.length; i++) {
    const f = skip.get(i);
    if (f) {
      out.push(f.decl);
      i = f.end;
      continue;
    }
    out.push(lines[i]);
  }
  return out.join("\n");
}

// ⚠️ clang's DRIVER exits 1 when the frontend dies on a signal — the 139 never
// reaches us. So a crash has to be recognised from what it prints, not from the
// exit status. Getting this wrong makes the reducer declare "nothing to
// reduce" on an input that demonstrably crashes.
const crash_markers = [
  "Stack dump",
  "PLEASE submit a bug report",
  "failed due to signal",
  "exit code 139",
  "exit code 134",
  "Assertion",
  "Segmentation fault",
];

async function crashes(args: Args, path: string): Promise<boolean> {
  const cmd = new Deno.Command(args.filc, {
    args: [args.opt, "-c", "-o", "/dev/null", path],
    stdout: "null",
    stderr: "piped",
  });
  const { code, signal, stderr } = await cmd.output();
  if (signal !== null || code === 139 || code === 134) return true;
  if (code === 0) return false;
  const text = new TextDecoder().decode(stderr);
  // An ordinary "error:" exit means the module was merely invalid, which is
  // not interesting — unless the crash markers are there too.
  return crash_markers.some((m) => text.includes(m));
}

async function main() {
  const args = parseArgs(Deno.args.slice());
  const lines = (await Deno.readTextFile(args.input)).split("\n");
  const funcs = findFunctions(lines);
  console.log(`input: ${lines.length} lines, ${funcs.length} function definitions`);

  const tmp = await Deno.makeTempFile({ suffix: ".ll" });

  const test = async (keep: Set<number>): Promise<boolean> => {
    await Deno.writeTextFile(tmp, render(lines, funcs, keep));
    return await crashes(args, tmp);
  };

  let keep = new Set(funcs.keys());
  if (!await test(keep)) {
    console.error("the unmodified input does not crash: nothing to reduce");
    Deno.exit(1);
  }

  // ddmin: try ever-finer partitions, keeping any subset that still crashes.
  let granularity = 2;
  let runs = 1;
  while (keep.size > 1) {
    const items = [...keep];
    const chunk = Math.ceil(items.length / granularity);
    let reduced = false;

    for (let i = 0; i < items.length; i += chunk) {
      // Complement: everything except this chunk.
      const candidate = new Set(items);
      for (const idx of items.slice(i, i + chunk)) candidate.delete(idx);
      if (candidate.size === 0) continue;

      runs++;
      if (await test(candidate)) {
        keep = candidate;
        granularity = Math.max(granularity - 1, 2);
        reduced = true;
        console.log(`  ${keep.size} functions still crash (run ${runs})`);
        break;
      }
    }

    if (!reduced) {
      if (granularity >= items.length) break;
      granularity = Math.min(granularity * 2, items.length);
    }
  }

  const finalText = render(lines, funcs, keep);
  await Deno.writeTextFile(args.out, finalText);
  console.log(`\nreduced to ${finalText.split("\n").length} lines, ${keep.size} function bodies, in ${runs} runs`);
  console.log(`wrote ${args.out}`);
  for (const idx of keep) {
    console.log(`  kept: ${lines[funcs[idx].start].slice(0, 120)}`);
  }
}

if (import.meta.main) await main();
