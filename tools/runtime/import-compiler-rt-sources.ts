// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// (Brought from zailc, 2026-10-27; the pure-Zig track, cmem/roadmap.md Z1.)
// Derives src/runtime/compiler_rt_sources.zig from Fil-C's compiler-rt (the pinned tree's
// compiler-rt/), as upstream's build_compiler_rt.sh builds it: the builtins archive (installed as
// pizfix/lib/libyolort.a) and crtbegin.o / crtend.o.
//
// compiler-rt chooses its sources in CMake (the generic list, the x86_64 list, the filter that
// prefers an arch file over a generic one, feature probes such as _Float16). So this tool asks
// CMake itself: it runs compiler-rt's configure with upstream's CMAKEOPTIONS and Zig's clang as the
// compiler (`zig cc -target x86_64-linux-gnu`), in a SCRATCH build directory, and reads the
// generated build.ninja: the archive's members in the archive's order, each one's source and
// language, the flags, and the two crt objects' command lines. The Fil-C tree is never written.
// Re-run when the pin moves.
//
//   bun tools/runtime/import-compiler-rt-sources.ts

import { chmod, readFile, writeFile } from "node:fs/promises";
import { FILC_SHA, FILC_VERSION, REPO, WORK, linuxOnly, mkdirp, must, requireFilcSrc, rmrf, ZIG } from "../lib/tool.ts";

await linuxOnly(import.meta);

const ARCH = "x86_64";
const filc = await requireFilcSrc();
const crtDir = `${filc}/compiler-rt`;
const builtinsDir = `${crtDir}/lib/builtins`;

// The options must still be upstream's: fail loudly if build_compiler_rt.sh changed them.
const script = await readFile(`${filc}/build_compiler_rt.sh`, "utf8");
const OPTIONS = [
  "-DCMAKE_BUILD_TYPE=Release",
  "-DCOMPILER_RT_BUILD_BUILTINS=ON",
  "-DCOMPILER_RT_BUILD_CRT=ON",
  "-DCOMPILER_RT_CRT_USE_EH_FRAME_REGISTRY=ON",
  "-DCOMPILER_RT_BUILD_SANITIZERS=OFF",
  "-DCOMPILER_RT_BUILD_XRAY=OFF",
  "-DCOMPILER_RT_BUILD_LIBFUZZER=OFF",
  "-DCOMPILER_RT_BUILD_PROFILE=OFF",
];
for (const o of [...OPTIONS, "-DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=$arch-linux-gnu", "libclang_rt.builtins-$arch.a pizfix/lib/libyolort.a"]) {
  if (!script.includes(o)) throw new Error(`build_compiler_rt.sh no longer contains: ${o}`);
}

// ---- configure, with Zig's clang, in a scratch build directory
const scratch = `${WORK}/pure-zig/gen/compiler-rt-cmake`;
await rmrf(scratch);
await mkdirp(`${scratch}/bin`);
const wrap = async (name: string, body: string) => {
  await writeFile(`${scratch}/bin/${name}`, `#!/bin/sh\nexec ${body} "$@"\n`);
  await chmod(`${scratch}/bin/${name}`, 0o755);
};
await wrap("zigcc", `${ZIG} cc -target ${ARCH}-linux-gnu`);
await wrap("zigc++", `${ZIG} c++ -target ${ARCH}-linux-gnu`);
await wrap("zigar", `${ZIG} ar`);
await wrap("zigranlib", `${ZIG} ranlib`);
// FAITHFUL TO THE RELEASE, not to what Zig's clang could do: upstream's libyolort was built by GCC
// 11.4, for which compiler-rt's CMake probe leaves COMPILER_RT_HAS_FLOAT16 off (its two
// `_Float16`-only members are empty, and the `_Float16` conversions take the integer-register
// ABI). zailc lets the probe succeed under Zig's clang and so fixes that ABI mismatch — its
// recorded departure W-10, which stays in zailc. zilc sets the probe's result to upstream's, so its
// libyolort defines exactly the release's symbols (cmem/workarounds.md W-10). The probe's cache
// variable is per architecture (lib/builtins/CMakeLists.txt: COMPILER_RT_HAS_${arch}_FLOAT16, which
// adds -DCOMPILER_RT_HAS_FLOAT16 to the flags); the unsuffixed name does nothing (tried 2026-10-27:
// verify-compiler-rt.ts still found the two definitions).
const FAITHFUL = [`-DCOMPILER_RT_HAS_${ARCH}_FLOAT16=OFF`];
await must([
  "cmake", "-S", crtDir, "-B", `${scratch}/build`, "-G", "Ninja", ...OPTIONS, ...FAITHFUL,
  `-DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=${ARCH}-linux-gnu`,
  `-DCMAKE_C_COMPILER=${scratch}/bin/zigcc`, `-DCMAKE_CXX_COMPILER=${scratch}/bin/zigc++`,
  `-DCMAKE_ASM_COMPILER=${scratch}/bin/zigcc`, `-DCMAKE_AR=${scratch}/bin/zigar`, `-DCMAKE_RANLIB=${scratch}/bin/zigranlib`,
]);
const ninja = await readFile(`${scratch}/build/build.ninja`, "utf8");
const blocks = ninja.split("\n\n");

// ---- the builtins archive: members in the archive's order, then each member's compile rule
const target = `clang_rt.builtins-${ARCH}`;
const link = blocks.find((b) => b.startsWith(`build lib/linux/lib${target}.a:`));
if (!link) throw new Error(`no link rule for lib${target}.a in build.ninja`);
const order = link.split("\n")[0].split(/\s+/).filter((t) => t.includes(`${target}.dir/`) && t.endsWith(".o"));
const rules = new Map<string, { lang: "c" | "asm"; src: string; flags: string; defines: string; includes: string }>();
for (const b of blocks) {
  const m = b.match(/^build (\S+\.o): (\S+) (\S+)/m);
  if (!m || !m[1].includes(`${target}.dir/`)) continue;
  const v = (k: string) => b.match(new RegExp(`^  ${k} = (.*)$`, "m"))?.[1] ?? "";
  rules.set(m[1], { lang: m[2].startsWith("ASM") ? "asm" : "c", src: m[3], flags: v("FLAGS"), defines: v("DEFINES"), includes: v("INCLUDES") });
}
const members = order.map((o) => {
  const r = rules.get(o);
  if (!r) throw new Error(`no compile rule for ${o}`);
  if (!r.src.startsWith(`${builtinsDir}/`)) throw new Error(`${o}: source outside lib/builtins: ${r.src}`);
  if (r.includes.trim()) throw new Error(`${o}: INCLUDES not empty (${r.includes}): extend this tool`);
  return { path: r.src.slice(builtinsDir.length + 1), ...r };
});
const flagSet = (lang: "c" | "asm") => {
  const sets = new Set(members.filter((m) => m.lang === lang).map((m) => `${m.defines} ${m.flags}`.trim()));
  if (sets.size !== 1) throw new Error(`${lang}: ${sets.size} distinct flag sets; this tool records one per language`);
  return [...sets][0].split(/\s+/);
};
const cFlags = flagSet("c"), asmFlags = flagSet("asm");

// ---- crtbegin.o / crtend.o: custom commands; their flags are the command line minus compiler, -o, -c
const crtFlags = (which: string): { path: string; flags: string[] } => {
  const b = blocks.find((x) => x.startsWith(`build lib/linux/clang_rt.${which}-${ARCH}.o`));
  const cmd = b?.match(/^  COMMAND = .*? && (.*)$/m)?.[1];
  if (!cmd) throw new Error(`no command for ${which}`);
  const argv = cmd.split(/\s+/);
  const src = argv[argv.indexOf("-c") + 1];
  const flags = argv.slice(1).filter((a, i, all) => a !== "-c" && a !== "-o" && all[i - 1] !== "-o" && all[i - 1] !== "-c");
  return { path: src.slice(builtinsDir.length + 1), flags };
};
const crtbegin = crtFlags("crtbegin"), crtend = crtFlags("crtend");

// ---- emit
const z = (s: string) => JSON.stringify(s);
const strs = (name: string, doc: string, xs: string[]) => [`/// ${doc}`, `pub const ${name} = [_][]const u8{${xs.map(z).join(", ")}};`, ""].join("\n");
const out = [
  // compiler-rt's build recipe, as data (third_party/LICENSES.md `compiler-rt-recipe`).
  "// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception",
  "//",
  "// GENERATED by tools/runtime/import-compiler-rt-sources.ts. Do not edit: re-run the tool.",
  `// Source: Fil-C ${FILC_VERSION} (${FILC_SHA}), compiler-rt/ configured as build_compiler_rt.sh does,`,
  `// with Zig's clang (zig cc -target ${ARCH}-linux-gnu) and ${FAITHFUL.join(" ")} (the release's`,
  "// GCC 11.4 build had it off; W-10); read from the generated build.ninja.",
  "// Paths are relative to <filc-src>/compiler-rt/lib/builtins.",
  "",
  "pub const Member = struct { path: []const u8, asm_: bool = false };",
  "",
  strs("c_flags", "DEFINES + FLAGS of every C member (one set).", cFlags),
  strs("asm_flags", "DEFINES + FLAGS of every assembly member (one set).", asmFlags),
  `/// lib${target}.a's members, in the archive's order (installed as libyolort.a; ${members.length}).`,
  "pub const builtins = [_]Member{",
  ...members.map((m) => `    .{ .path = ${z(m.path)}${m.lang === "asm" ? ", .asm_ = true" : ""} },`),
  "};",
  "",
  `pub const crtbegin_path = ${z(crtbegin.path)};`,
  strs("crtbegin_flags", "crtbegin.o's command line (custom command: no -O, no -g).", crtbegin.flags),
  `pub const crtend_path = ${z(crtend.path)};`,
  strs("crtend_flags", "crtend.o's command line.", crtend.flags),
].join("\n");

const dest = `${REPO}/src/runtime/compiler_rt_sources.zig`;
await writeFile(dest, out);
await must([ZIG, "fmt", dest]);
console.log(`${dest}: ${members.length} builtins (${members.filter((m) => m.lang === "asm").length} assembly), crtbegin ${crtbegin.path}, crtend ${crtend.path}`);
