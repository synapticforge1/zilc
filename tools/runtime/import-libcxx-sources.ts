// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// (The pure-Zig track, cmem/roadmap.md Z1 item 3, "libc++ / libc++abi"; 2026-11-06.)
// Derives src/runtime/libcxx_sources.zig from Fil-C's libc++ and libc++abi build (build_cxx.sh:
// CMake + Ninja over LLVM's runtimes/ with Fil-C's clang/clang++, then install-cxx-linux.sh), as
// import-compiler-rt-sources.ts does for compiler-rt: it runs upstream's CMake configure, with the
// options build_cxx.sh passes (each asserted against the script), from the fetched Fil-C sources
// into a SCRATCH build dir, and reads the build.ninja it generates:
//
//   compiles   every `CXX_COMPILER__<target>_unscanned_RelWithDebInfo` edge: source, and the
//              target's DEFINES / FLAGS / INCLUDES (one set per target, asserted);
//   archives   `CXX_STATIC_LIBRARY_LINKER__*`: libc++.a, libc++abi.a, libc++experimental.a,
//              their objects in order (CMake names members `<file>.cpp.o`);
//   links      `CXX_SHARED_LIBRARY_LINKER__*`: libc++abi.so.1.0, libc++.so.1.0 — and, since the
//              build links without Fil-C's driver, the LINKER line that driver makes of each
//              (`clang++ -###`), tokenized;
//   headers    the header targets alone are built (copies, no compiler), and each file of the
//              tree is classified: a copy of a file in the sources (by content), or generated
//              (`__config_site`), whose content is kept.
// The Fil-C tree is never written (CMake's -S is read-only). Needs cmake and ninja (env CMAKE,
// NINJA; default from PATH). Re-run when the pin moves.
//
//   bun tools/runtime/import-libcxx-sources.ts      (env ZILC_FILC: the Fil-C clang to configure with)

import { createHash } from "node:crypto";
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { env, filc, filcPackageDir, FILC_SHA, FILC_VERSION, REPO, WORK, linuxOnly, must, requireFilcSrc, rmrf, ZIG } from "../lib/tool.ts";

await linuxOnly(import.meta);

// The FETCHED package, the tree `zig build` compiles from, not FILC_SRC: that is a sparse checkout
// without libc/, and libc++'s CMake changes with it (FindLibcCommonUtils.cmake makes the
// llvm-libc-common-utilities target only when ../../../libc exists; without it the link gets
// `-lllvm-libc-common-utilities` and the compiles lose LIBC_NAMESPACE; found 2026-11-06).
await requireFilcSrc(); // the pin is checked as everywhere
const src = await filcPackageDir();
if (!existsSync(`${src}/libc`) || !existsSync(`${src}/runtimes`)) throw new Error(`${src}: not the fetched Fil-C package (no libc/ or runtimes/); fetch it with \`zig build pure-zig\``);
const clang = filc();
const clangxx = clang.replace(/clang$/, "clang++");
const script = await readFile(`${src}/build_cxx.sh`, "utf8");

// ---- upstream's configure line (build_cxx.sh, not cosmo), each option asserted
const fixed = [
  "-DCMAKE_BUILD_TYPE=RelWithDebInfo",
  "-DCMAKE_C_COMPILER_WORKS=ON", "-DCMAKE_CXX_COMPILER_WORKS=ON", "-DCMAKE_ASM_COMPILER_WORKS=ON",
  "-DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=ON",
  "-DLIBCXXABI_HAS_PTHREAD_API=ON", "-DLIBCXX_ENABLE_EXCEPTIONS=ON",
  "-DLIBCXXABI_ENABLE_EXCEPTIONS=ON", "-DLIBCXX_HAS_PTHREAD_API=ON",
  "-DLIBCXXABI_USE_LLVM_UNWINDER=OFF",
  "-DLIBCXX_FORCE_LIBCXXABI=ON",
  "-DLLVM_ENABLE_ASSERTIONS=ON",
  "-DLIBCXX_HARDENING_MODE=extensive",
  "-DLLVM_INCLUDE_TESTS=OFF",
];
for (const o of [...fixed, '-DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi"', 'LLVMLIBCOPT="-DLIBCXX_HAS_MUSL_LIBC=ON"', "cmake -S runtimes -B runtimes-build -G Ninja"]) {
  if (!script.includes(o)) throw new Error(`build_cxx.sh no longer contains: ${o}`);
}
const triple = (await must([clang, "-print-target-triple"])).trim();
const cmake = env("CMAKE", "cmake"), ninja = env("NINJA", "ninja");
const scratch = `${WORK}/pure-zig/gen/libcxx-configure`;
await rmrf(scratch);
await must([cmake, "-S", `${src}/runtimes`, "-B", scratch, "-G", "Ninja", `-DCMAKE_MAKE_PROGRAM=${ninja}`,
  `-DCMAKE_C_COMPILER=${clang}`, `-DCMAKE_CXX_COMPILER=${clangxx}`, `-DCMAKE_ASM_COMPILER=${clang}`,
  ...fixed, "-DLLVM_ENABLE_RUNTIMES=libcxx;libcxxabi", `-DLLVM_DEFAULT_TARGET_TRIPLE=${triple}`, "-DLIBCXX_HAS_MUSL_LIBC=ON"]);

// ---- build.ninja: `build <outs>: <rule> <ins> [| implicit] [|| order-only]` + indented `  VAR = value`
interface Edge { outs: string[]; rule: string; ins: string[]; vars: Record<string, string> }
const ninjaText = await readFile(`${scratch}/build.ninja`, "utf8");
const edges: Edge[] = [];
{
  const lines = ninjaText.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const m = lines[i].match(/^build (.+?): (\S+)(.*)$/);
    if (!m) continue;
    const unesc = (s: string) => s.replace(/\$:/g, ":").replace(/\$ /g, " ").replace(/\$\$/g, "$");
    const ins = m[3].split(" | ")[0].split(" || ")[0].trim().split(/\s+/).filter(Boolean).map(unesc);
    const vars: Record<string, string> = {};
    while (i + 1 < lines.length && /^\s+\w+ = /.test(lines[i + 1])) {
      const v = lines[++i].match(/^\s+(\w+) = (.*)$/)!;
      vars[v[1]] = v[2];
    }
    edges.push({ outs: m[1].split(/\s+/).map(unesc), rule: m[2], ins, vars });
  }
}
// Tokens: the sources and the scratch build dir appear by absolute path.
const tok = (s: string) => s.replaceAll(`${src}/runtimes/cmake/Modules/../../../`, "<src>/").replaceAll(`${src}/libcxxabi/../`, "<src>/").replaceAll(src, "<src>").replaceAll(scratch, "<gen>");
const words = (s: string | undefined) => (s ?? "").trim().split(/\s+/).filter(Boolean).map(tok);

// ---- compiles, per target
interface Tgt { sources: string[]; defines: string[]; flags: string[]; includes: string[] }
const targets = new Map<string, Tgt>();
const objToSrc = new Map<string, string>();
for (const e of edges) {
  const m = e.rule.match(/^CXX_COMPILER__(\w+?)_unscanned_RelWithDebInfo$/);
  if (!m) continue;
  const t = m[1], source = tok(e.ins[0]);
  if (!source.startsWith("<src>/")) throw new Error(`compile of ${e.outs[0]}: source outside the tree: ${e.ins[0]}`);
  const set = { defines: words(e.vars.DEFINES), flags: words(e.vars.FLAGS), includes: words(e.vars.INCLUDES) };
  const have = targets.get(t);
  if (!have) targets.set(t, { sources: [source], ...set });
  else {
    for (const k of ["defines", "flags", "includes"] as const) if (have[k].join(" ") !== set[k].join(" ")) throw new Error(`target ${t}: ${k} differ between objects (${e.outs[0]}): extend this tool to per-object flags`);
    have.sources.push(source);
  }
  objToSrc.set(e.outs[0], source);
}
const want = ["cxx_static", "cxx_shared", "cxxabi_static_objects", "cxxabi_shared_objects", "cxx_experimental"];
if ([...targets.keys()].sort().join(" ") !== [...want].sort().join(" ")) throw new Error(`compile targets are ${[...targets.keys()].join(", ")}, expected ${want.join(", ")}`);

// ---- archives and shared links
const libdir = `lib/${triple}`;
const archive = (name: string) => {
  const e = edges.find((x) => x.outs[0] === `${libdir}/${name}` && x.rule.startsWith("CXX_STATIC_LIBRARY_LINKER__"));
  if (!e) throw new Error(`no archive rule for ${name}`);
  return e.ins.map((o) => {
    const s = objToSrc.get(o);
    if (!s) throw new Error(`${name}: member ${o} is not a compiled object`);
    return { object: o, source: s };
  });
};
const archives = ["libc++.a", "libc++abi.a", "libc++experimental.a"].map((name) => ({ name, members: archive(name) }));
const targetOf = (o: string) => o.match(/CMakeFiles\/(\w+)\.dir\//)![1];

// The driver's linker line for each shared library: clang++ with the rule's flags on placeholder
// inputs (empty files: -### only needs them to exist), then tokenized.
const rules = await readFile(`${scratch}/CMakeFiles/rules.ninja`, "utf8");
interface Link { name: string; target: string; soname: string; ld: string[] }
const links: Link[] = [];
for (const name of ["libc++abi.so.1.0", "libc++.so.1.0"]) {
  const e = edges.find((x) => x.outs[0] === `${libdir}/${name}` && x.rule.startsWith("CXX_SHARED_LIBRARY_LINKER__"));
  if (!e) throw new Error(`no shared link rule for ${name}`);
  const rule = rules.split(/\nrule /).find((r) => r.startsWith(e.rule));
  const cmd = rule?.match(/\n\s+command = (.*)/)?.[1] ?? "";
  // Expect CMake's usual shape; anything else would change what the substitution below means.
  if (!cmd.includes("$LANGUAGE_COMPILE_FLAGS") || !cmd.includes("$LINK_FLAGS") || !cmd.includes("$SONAME_FLAG$SONAME") || !cmd.includes("$in $LINK_PATH $LINK_LIBRARIES")) throw new Error(`${e.rule}: unexpected command: ${cmd}`);
  const objs = e.ins.filter((x) => x.endsWith(".o"));
  const libsIn = e.ins.filter((x) => !x.endsWith(".o"));
  // Libraries named by relative path in LINK_LIBRARIES (libc++abi.so.1.0 for libc++.so.1.0) are
  // implicit inputs, not in `ins`: they need a placeholder too.
  const relLibs = (e.vars.LINK_LIBRARIES ?? "").trim().split(/\s+/).filter((w) => w && !w.startsWith("-") && !w.startsWith("/"));
  for (const p of [...objs, ...libsIn, ...relLibs]) {
    await mkdir(`${scratch}/${p.slice(0, p.lastIndexOf("/"))}`, { recursive: true });
    await writeFile(`${scratch}/${p}`, "");
  }
  const so = e.vars.SONAME;
  const argv = [clangxx, "-###", ...words(e.vars.LANGUAGE_COMPILE_FLAGS).map((w) => w.replaceAll("<gen>", scratch).replaceAll("<src>", src)),
    ...(e.vars.LINK_FLAGS ?? "").trim().split(/\s+/).filter(Boolean), "-shared", `-Wl,-soname,${so}`, "-o", `${scratch}/${libdir}/${name}`,
    ...[...objs, ...libsIn].map((p) => `${scratch}/${p}`), ...(e.vars.LINK_PATH ?? "").trim().split(/\s+/).filter(Boolean), ...(e.vars.LINK_LIBRARIES ?? "").trim().split(/\s+/).filter(Boolean)];
  const out = await must(["sh", "-c", '"$@" 2>&1', "sh", ...argv], { cwd: scratch });
  const ldLine = out.split("\n").find((l) => /^\s*"[^"]*\/(ld|ld\.lld)"\s/.test(l));
  if (!ldLine) throw new Error(`${name}: no linker line in clang++ -###:\n${out}`);
  const toks = [...ldLine.matchAll(/"((?:[^"\\]|\\.)*)"/g)].map((m) => m[1].replace(/\\(.)/g, "$1"));
  // The objects become one token, <objects>, at the first object's place; the input libraries keep
  // their place as <libdir>/<file>.
  const objSet = new Set(objs.map((p) => `${scratch}/${p}`));
  const ld: string[] = [];
  let placed = false;
  for (const t of toks.slice(1)) {
    if (objSet.has(t)) {
      if (!placed) (ld.push("<objects>"), (placed = true));
      continue;
    }
    if (t === `${scratch}/${libdir}/${name}`) { ld.push("<out>"); continue; }
    ld.push(tok(t.replaceAll(`${scratch}/${libdir}`, "<libdir>")).replace(clang.replace(/\/build\/bin\/clang$/, ""), "<filc>"));
  }
  links.push({ name, target: targetOf(objs[0]), soname: so, ld });
}

// ---- the header tree: build the header targets only, then classify each file by content
await must([ninja, "-C", scratch, "generate-cxx-headers", "generate-cxxabi-headers"]);
const walk = (root: string, rel = ""): string[] =>
  readdirSync(`${root}/${rel}`).flatMap((n) => {
    const p = rel ? `${rel}/${n}` : n;
    return statSync(`${root}/${p}`).isDirectory() ? walk(root, p) : [p];
  });
const sha = (p: string) => createHash("sha256").update(readFileSync(p)).digest("hex");
const byHash = new Map<string, string>();
for (const dir of ["libcxx/include", "libcxxabi/include", "libcxx/utils", "libcxx/vendor"]) {
  try {
    for (const f of walk(`${src}/${dir}`)) byHash.set(sha(`${src}/${dir}/${f}`), `${dir}/${f}`);
  } catch (e) {
    if ((e as NodeJS.ErrnoException).code !== "ENOENT") throw e;
  }
}
interface Header { dest: string; copy?: string; content?: string }
const headers: Header[] = [];
for (const base of ["c++/v1", `${triple}/c++/v1`]) {
  for (const f of walk(`${scratch}/include/${base}`).sort()) {
    const p = `${scratch}/include/${base}/${f}`;
    const h = sha(p);
    // Prefer the file at the same relative path when several sources share the content.
    const at = `libcxx/include/${f}`;
    const copy = existsSync(`${src}/${at}`) && sha(`${src}/${at}`) === h ? at : byHash.get(h);
    if (copy) headers.push({ dest: `${base}/${f}`, copy });
    else {
      const content = readFileSync(p, "utf8");
      if (content.includes(scratch) || content.includes(src)) throw new Error(`generated header ${base}/${f} names a build path: extend this tool`);
      headers.push({ dest: `${base}/${f}`, content });
    }
  }
}

// ---- emit
const z = (s: string) => JSON.stringify(s);
const list = (xs: string[]) => `&.{${xs.map(z).join(", ")}}`;
const out = [
  // libc++/libc++abi's build recipe, as data (third_party/LICENSES.md `libcxx-recipe`).
  "// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception",
  "//",
  "// GENERATED by tools/runtime/import-libcxx-sources.ts. Do not edit: re-run the tool.",
  `// Source: Fil-C ${FILC_VERSION} (${FILC_SHA}): LLVM's runtimes/ (libcxx, libcxxabi) as build_cxx.sh`,
  "// configures them with CMake for Fil-C's clang, read from the build.ninja that generates. Tokens:",
  "// <src> the Fil-C tree, <gen> the generated header root's parent (CMake's build dir: <gen>/include),",
  "// <libdir> where the shared libraries are linked, <out> the output, <objects> the objects in order,",
  "// <filc> the Fil-C toolchain tree (the driver's crt files and pizfix/).",
  "",
  `pub const triple = ${z(triple)};`,
  "",
  "pub const Target = struct { name: []const u8, sources: []const []const u8, defines: []const []const u8, flags: []const []const u8, includes: []const []const u8 };",
  "/// The compile targets (one flag set each, asserted by the tool); sources in CMake's order.",
  "pub const targets = [_]Target{",
  ...want.map((t) => {
    const x = targets.get(t)!;
    return `    .{ .name = ${z(t)}, .sources = ${list(x.sources)}, .defines = ${list(x.defines)}, .flags = ${list(x.flags)}, .includes = ${list(x.includes)} },`;
  }),
  "};",
  "",
  "pub const Member = struct { target: []const u8, source: []const u8 };",
  "pub const Archive = struct { name: []const u8, members: []const Member };",
  "/// Static libraries, members in order; CMake names each member `<source file name>.o`.",
  "pub const archives = [_]Archive{",
  ...archives.map((a) => `    .{ .name = ${z(a.name)}, .members = &.{${a.members.map((m) => `.{ .target = ${z(targetOf(m.object))}, .source = ${z(m.source)} }`).join(", ")}} },`),
  "};",
  "",
  "pub const Link = struct { name: []const u8, target: []const u8, soname: []const u8, ld: []const []const u8 };",
  "/// Shared libraries: the linker arguments Fil-C's clang++ driver makes of CMake's link line.",
  "pub const links = [_]Link{",
  ...links.map((l) => `    .{ .name = ${z(l.name)}, .target = ${z(l.target)}, .soname = ${z(l.soname)}, .ld = ${list(l.ld)} },`),
  "};",
  "",
  "pub const Header = struct { dest: []const u8, copy: ?[]const u8 = null, content: ?[]const u8 = null };",
  `/// The header tree under <gen>/include (${headers.length} files): copies of source files, or generated content.`,
  "pub const headers = [_]Header{",
  ...headers.map((h) => (h.copy ? `    .{ .dest = ${z(h.dest)}, .copy = ${z(h.copy)} },` : `    .{ .dest = ${z(h.dest)}, .content = ${z(h.content!)} },`)),
  "};",
  "",
].join("\n");

const dest = `${REPO}/src/runtime/libcxx_sources.zig`;
await writeFile(dest, out);
await must([ZIG, "fmt", dest]);
console.log(`${dest}: ${want.map((t) => `${t} ${targets.get(t)!.sources.length}`).join(", ")}; archives ${archives.map((a) => `${a.name} ${a.members.length}`).join(", ")}; links ${links.map((l) => `${l.name} (${l.ld.length} args)`).join(", ")}; headers ${headers.length} (${headers.filter((h) => h.content !== undefined).length} generated)`);
