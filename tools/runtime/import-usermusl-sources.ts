// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// (The pure-Zig track, cmem/roadmap.md Z1 item 3, "the user libc"; 2026-11-06.)
// Derives src/runtime/usermusl_sources.zig from Fil-C's USER musl (projects/usermusl, musl 1.2.4,
// patched for Fil-C): which files make libc.a / libc.so and the compile flags of each. Fil-C's
// clang compiles it (build_usermusl.sh: CC = "<Fil-C clang> -yolo-assembler", LIBCC=-lyolort).
// It evaluates the rules of usermusl's Makefile over the pinned tree, as
// tools/runtime/import-yolomusl-sources.ts does for yolomusl:
//
//   SRC_DIRS     = src/* src/malloc/$(MALLOC_DIR) crt ldso
//   BASE_SRCS    = $(sort $(wildcard SRC_DIRS/*.c));  ARCH_SRCS = SRC_DIRS/$(ARCH)/*.[csS]
//   ALL_OBJS     = sort(BASE_OBJS ARCH_OBJS) minus the base objects an arch object replaces
//   LIBC_OBJS    = obj/src/% and obj/compat/%; libc.a holds their .lo forms (config.mak:
//                  AOBJS = $(LOBJS)), libc.so links them; no crt objects, no ldso (LDSO_OBJS =)
//   OPTIMIZE     = src/{internal,malloc,string}/*.c get -O3 (CFLAGS, after CFLAGS_AUTO)
//   MEMOPS       = %/memcpy %/memmove %/memcmp %/memset get CFLAGS_MEMOPS
//   NOSSP        = __libc_start_main __init_tls __stack_chk_fail __set_thread_area memset memcpy
//   every .lo    = -fPIC (last)
//   EMPTY_LIBS   = lib/lib{m,rt,pthread,crypt,util,xnet,resolv,dl}.a, each `ar rc` of nothing
//
// The flags are what musl's own `configure` chooses when the compiler is Fil-C's clang: this tool
// runs configure (with the patched Fil-C clang zilc uses, `filc()`) in a SCRATCH COPY of the tree
// and reads its config.mak. The Fil-C tree is never written. Re-run when the pin moves.
//
//   bun tools/runtime/import-usermusl-sources.ts

import { readdirSync } from "node:fs";
import { readFile, writeFile } from "node:fs/promises";
import { filc, FILC_SHA, FILC_VERSION, REPO, WORK, linuxOnly, must, requireFilcSrc, rmrf, ZIG } from "../lib/tool.ts";

await linuxOnly(import.meta);

const ARCH = "x86_64";
const src = await requireFilcSrc();
const tree = `${src}/projects/usermusl`;
const mk = await readFile(`${tree}/Makefile`, "utf8");

// The rules this tool evaluates must still be the Makefile's: fail loudly if upstream changed them.
for (const rule of [
  "SRC_DIRS = $(addprefix $(srcdir)/,src/* src/malloc/$(MALLOC_DIR) crt ldso $(COMPAT_SRC_DIRS))",
  "BASE_GLOBS = $(addsuffix /*.c,$(SRC_DIRS))",
  "ARCH_GLOBS = $(addsuffix /$(ARCH)/*.[csS],$(SRC_DIRS))",
  "REPLACED_OBJS = $(sort $(subst /$(ARCH)/,/,$(ARCH_OBJS)))",
  "LIBC_OBJS = $(filter obj/src/%,$(ALL_OBJS)) $(filter obj/compat/%,$(ALL_OBJS))",
  "LOBJS = $(LIBC_OBJS:.o=.lo)",
  "\nLDSO_OBJS =\n",
  "CFLAGS_ALL += -D_XOPEN_SOURCE=700 -I$(srcdir)/arch/$(ARCH) -I$(srcdir)/arch/generic -Iobj/src/internal -I$(srcdir)/src/include -I$(srcdir)/src/internal -Iobj/include -I$(srcdir)/include",
  "CFLAGS_ALL += $(CPPFLAGS) $(CFLAGS_AUTO) $(CFLAGS)",
  "$(OPTIMIZE_SRCS:$(srcdir)/%.c=obj/%.o) $(OPTIMIZE_SRCS:$(srcdir)/%.c=obj/%.lo): CFLAGS += -O3",
  "MEMOPS_OBJS = $(filter %/memcpy.o %/memmove.o %/memcmp.o %/memset.o, $(LIBC_OBJS))",
  "%/__libc_start_main.o %/__init_tls.o %/__stack_chk_fail.o \\",
  "%/__set_thread_area.o %/memset.o %/memcpy.o \\",
  "$(NOSSP_OBJS) $(NOSSP_OBJS:%.o=%.lo): CFLAGS_ALL += $(CFLAGS_NOSSP)",
  "$(LOBJS) $(LDSO_OBJS): CFLAGS_ALL += -fPIC",
  "EMPTY_LIB_NAMES = m rt pthread crypt util xnet resolv dl",
  // The shared library: build/pure_zig.zig reproduces this link with the driver's additions.
  "lib/libc.so: $(LOBJS) $(LDSO_OBJS)",
  "-o $@ $(LOBJS) $(LDSO_OBJS) $(LIBCC) -nodefaultlibs",
]) {
  if (!mk.includes(rule)) throw new Error(`usermusl's Makefile no longer contains: ${rule}`);
}
// What usermusl differs from yolomusl in, and this tool relies on: no -fPIE, no -g in CFLAGS_ALL.
for (const absent of ["$(LIBC_OBJS): CFLAGS_ALL += -fPIE", "CFLAGS_ALL += -g "]) {
  if (mk.includes(absent)) throw new Error(`usermusl's Makefile now contains: ${absent}: extend this tool`);
}

// ---- configure, with Fil-C's clang, in a scratch copy
const scratch = `${WORK}/pure-zig/gen/usermusl-configure`;
await rmrf(scratch);
await must(["cp", "-r", tree, scratch]);
const cc = `${filc()} -yolo-assembler`;
await must(["./configure", `--prefix=${scratch}/out`, `CC=${cc}`, "LIBCC=-lyolort"], { cwd: scratch });
const config = await readFile(`${scratch}/config.mak`, "utf8");
const cfg = (name: string): string[] => {
  const m = config.match(new RegExp(`^${name} = (.*)$`, "m"));
  if (!m) throw new Error(`config.mak has no ${name}`);
  return m[1].trim().split(/\s+/).filter(Boolean);
};
const c99fse = cfg("CFLAGS_C99FSE"), auto = cfg("CFLAGS_AUTO"), nossp = cfg("CFLAGS_NOSSP"), memops = cfg("CFLAGS_MEMOPS");
const mallocDir = cfg("MALLOC_DIR")[0];
if (cfg("AOBJS").join(" ") !== "$(LOBJS)") throw new Error(`config.mak's AOBJS is ${cfg("AOBJS")}, not $(LOBJS): libc.a would hold the .o forms`);
if (cfg("OPTIMIZE_GLOBS").join(" ") !== "internal/*.c malloc/*.c string/*.c") throw new Error(`OPTIMIZE_GLOBS changed: ${cfg("OPTIMIZE_GLOBS")}`);
if (cfg("ADD_CFI")[0] !== "no") throw new Error("ADD_CFI is not `no`: the assembler path would differ");
// LDFLAGS_AUTO: Fil-C's driver links with GNU ld, which takes every probe, so config.mak is the
// source here (yolomusl's tool had to read configure's probes instead, for Zig's clang).
const ldArgs = cfg("LDFLAGS_AUTO").flatMap((f) => {
  if (!f.startsWith("-Wl,")) throw new Error(`LDFLAGS_AUTO flag is not -Wl,: ${f}`);
  return f.slice(4).split(",");
});

// ---- the Makefile's object rules
const listDir = (d: string, ok: (name: string) => boolean): string[] => {
  try {
    return readdirSync(`${tree}/${d}`, { withFileTypes: true }).filter((e) => e.isFile() && ok(e.name)).map((e) => `${d}/${e.name}`);
  } catch (e) {
    if ((e as NodeJS.ErrnoException).code === "ENOENT") return [];
    throw e;
  }
};
const srcDirs = [
  ...readdirSync(`${tree}/src`, { withFileTypes: true }).filter((e) => e.isDirectory()).map((e) => `src/${e.name}`).sort(),
  `src/malloc/${mallocDir}`, "crt", "ldso",
];
const byteSort = (a: string, b: string) => (a < b ? -1 : a > b ? 1 : 0); // GNU make's $(sort): bytes
const baseSrcs = srcDirs.flatMap((d) => listDir(d, (n) => n.endsWith(".c"))).sort(byteSort);
const archSrcs = srcDirs.flatMap((d) => listDir(`${d}/${ARCH}`, (n) => /\.[csS]$/.test(n))).sort(byteSort);
const obj = (s: string) => s.replace(/\.[csS]$/, ".o");
const srcOf = new Map<string, string>();
for (const s of [...baseSrcs, ...archSrcs]) srcOf.set(obj(s), s);
const replaced = new Set(archSrcs.map((s) => obj(s).replace(`/${ARCH}/`, "/")));
const allObjs = [...new Set([...baseSrcs, ...archSrcs].map(obj))].sort(byteSort).filter((o) => !replaced.has(o));
const libcObjs = [...allObjs.filter((o) => o.startsWith("src/")), ...allObjs.filter((o) => o.startsWith("compat/"))];

const optimizeSrcs = new Set(["internal", "malloc", "string"].flatMap((d) => listDir(`src/${d}`, (n) => n.endsWith(".c"))));
const base = (o: string) => o.split("/").pop()!;
const memopsNames = new Set(["memcpy.o", "memmove.o", "memcmp.o", "memset.o"]);
const nosspLibc = new Set(["__libc_start_main.o", "__init_tls.o", "__stack_chk_fail.o", "__set_thread_area.o", "memset.o", "memcpy.o"]);

interface Row { path: string; o3: boolean; memops: boolean; nossp: boolean }
const libc: Row[] = libcObjs.map((o) => ({ path: srcOf.get(o)!, o3: optimizeSrcs.has(srcOf.get(o)!), memops: memopsNames.has(base(o)), nossp: nosspLibc.has(base(o)) }));
const asm = libc.filter((r) => /\.[sS]$/.test(r.path));
if (asm.length) throw new Error(`usermusl now has ${asm.length} assembly sources (${asm[0].path}): extend build/pure_zig.zig's compile step`);
const emptyLibs = (mk.match(/^EMPTY_LIB_NAMES = (.*)$/m)?.[1] ?? "").trim().split(/\s+/);
const version = (await readFile(`${tree}/VERSION`, "utf8")).trim();

// ---- emit
const z = (s: string) => JSON.stringify(s);
const flags = (name: string, doc: string, items: string[]) => [`/// ${doc}`, `pub const ${name} = [_][]const u8{${items.map(z).join(", ")}};`, ""].join("\n");
const out = [
  // musl's build recipe, as data (third_party/LICENSES.md `usermusl-recipe`).
  "// SPDX-License-Identifier: MIT",
  "//",
  "// GENERATED by tools/runtime/import-usermusl-sources.ts. Do not edit: re-run the tool.",
  `// Source: Fil-C ${FILC_VERSION} (${FILC_SHA}), projects/usermusl (musl ${version}): its Makefile's`,
  "// object rules evaluated over the tree, and the flags musl's configure chooses for Fil-C's clang",
  "// (CC = <Fil-C clang> -yolo-assembler). Paths are relative to <filc-src>/projects/usermusl.",
  "",
  "pub const Src = struct {",
  "    path: []const u8,",
  "    /// OPTIMIZE_GLOBS: -O3 after CFLAGS_AUTO.",
  "    o3: bool = false,",
  "    /// MEMOPS_OBJS: CFLAGS_MEMOPS.",
  "    memops: bool = false,",
  "    /// NOSSP_OBJS: CFLAGS_NOSSP.",
  "    nossp: bool = false,",
  "};",
  "",
  `pub const arch = ${z(ARCH)};`,
  `/// \`VERSION\`; obj/src/internal/version.h is \`#define VERSION "<this>"\` (tools/version.sh, no .git).`,
  `pub const version = ${z(version)};`,
  "/// The compiler's own flag (build_usermusl.sh: CC = \"<Fil-C clang> -yolo-assembler\").",
  `pub const cc_flags = [_][]const u8{${z("-yolo-assembler")}};`,
  "",
  flags("c99fse", "CFLAGS_C99FSE.", c99fse),
  flags("auto", "CFLAGS_AUTO.", auto),
  flags("nossp_flags", "CFLAGS_NOSSP.", nossp),
  flags("memops_flags", "CFLAGS_MEMOPS (empty for clang).", memops),
  `/// LIBC_OBJS, in the Makefile's order: libc.a's members as their .lo forms, and libc.so's objects (${libc.length}).`,
  "pub const libc = [_]Src{",
  ...libc.map((r) => {
    const extra = [r.o3 && ".o3 = true", r.memops && ".memops = true", r.nossp && ".nossp = true"].filter(Boolean);
    return `    .{ .path = ${z(r.path)}${extra.length ? ", " + extra.join(", ") : ""} },`;
  }),
  "};",
  "",
  flags("empty_libs", "EMPTY_LIB_NAMES: lib<name>.a, each an archive with no members.", emptyLibs),
  flags("ld_args", "LDFLAGS_AUTO as linker arguments (config.mak; `./dynamic.list` is relative to the tree).", ldArgs),
].join("\n");

const dest = `${REPO}/src/runtime/usermusl_sources.zig`;
await writeFile(dest, out);
await must([ZIG, "fmt", dest]);
const n = (k: keyof Row) => libc.filter((r) => r[k]).length;
console.log(`${dest}: libc ${libc.length} (${n("o3")} -O3, ${n("nossp")} nossp, ${n("memops")} memops), empty libs ${emptyLibs.length}; musl ${version}`);
console.log(`flags from ${scratch}/config.mak: CFLAGS_AUTO ${auto.length} flags, LDFLAGS_AUTO ${ldArgs.length} args`);
