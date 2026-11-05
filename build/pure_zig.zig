// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! The pure-Zig track's build recipes (cmem/roadmap.md Z1): Fil-C's runtime pieces built by Zig
//! from Fil-C's own sources, faithful to the release (no departures). Brought from zailc's build.zig
//! on 2026-10-27 (owner: zailc's build up to a pure-Zig Fil-C on Linux lives in zilc). The file
//! lists and flags are the generated tables in src/runtime/ (tools/runtime/import-*.ts); the
//! recipes are upstream's Makefile and CMake rules re-expressed (third_party/LICENSES.md
//! `libpas-recipe`, `yolomusl-recipe`, `compiler-rt-recipe`). Checked object by object against the
//! release tarball by tools/runtime/verify-*.ts, then as a whole by `zig build gate-zig-modules`.
//!
//!   zig build libpas | yolomusl | compiler-rt | pure-zig  [-Dfilc-src=<Fil-C tree>] [-Dpizfix=<pizfix>]
//!                                                         --prefix ~/zilc-work/pure-zig/filc-<release>
//!
//! Fil-C's tree is the one build/filc_source.zig provides: fetched by zig build on first use, or
//! -Dfilc-src.
const std = @import("std");
const libpas_sources = @import("../src/runtime/libpas_sources.zig");
const musl_headers = @import("../src/gen/musl_headers.zig");
const yolomusl_sources = @import("../src/runtime/yolomusl_sources.zig");
const compiler_rt_sources = @import("../src/runtime/compiler_rt_sources.zig");

pub fn addSteps(b: *std.Build, gen: *std.Build.Step.Compile, filc_src: ?[]const u8) void {
    const pizfix_opt = b.option([]const u8, "pizfix", "A pizfix/ with os-include and stdfil-include (default: made as upstream makes them, from the Fil-C sources and the host's kernel headers)");
    const filc_clang = b.option([]const u8, "filc-clang", "libpas: Fil-C's clang (its pizfix/ must hold stdfil-include and os-include) to compile libpas's Fil-C half and link libpizlo.so / libpizlo.a");
    const need = "needs Fil-C's sources: the `filc` dependency (fetched when this step is named) or -Dfilc-src=<the Fil-C tree at zilc's release>";

    const all = b.step("pure-zig", "Build every pure-Zig runtime piece (libpas, yolomusl, compiler-rt) from -Dfilc-src");
    // `zig build libpas`: the stock-compiled half of Fil-C's runtime, libpizlo-stock.a, from
    // upstream's sources, compiled by Zig's clang with the flags of libpas/Makefile (PASCC +
    // PASCFLAGS, static variant). With -Dfilc-clang, the rest of libpas too: its Fil-C half
    // (filc/src, compiled by that clang) and libpizlo.so (four variants) and libpizlo.a.
    const libpas_step = b.step("libpas", "Build Fil-C's runtime from -Dfilc-src: libpizlo-stock.a, filc_crt.o, filc_mincrt.o, libyolounwind.a; with -Dfilc-clang also libpizlo.so (4 variants) and libpizlo.a");
    // `zig build yolomusl`: Fil-C's patched musl (projects/yolomusl) as upstream's
    // build_yolomusl.sh installs it: libyoloc.a, the crt objects and the empty libyolom.a.
    // libyoloc.so and ld-fil1 are not built yet.
    const yolomusl_step = b.step("yolomusl", "Build Fil-C's yolo musl from -Dfilc-src: libyoloc.a, crt1.o, Scrt1.o, rcrt1.o, crti.o, crtn.o, libyolom.a");
    // `zig build compiler-rt`: Fil-C's compiler-rt as upstream's build_compiler_rt.sh installs it:
    // the builtins archive as libyolort.a, and crtbegin.o / crtend.o.
    const crt_step = b.step("compiler-rt", "Build Fil-C's compiler-rt from -Dfilc-src: libyolort.a, crtbegin.o, crtend.o");
    for ([_]*std.Build.Step{ libpas_step, yolomusl_step, crt_step }) |s| all.dependOn(s);

    if (filc_src) |src| {
        // yolo musl's shared half links compiler-rt's builtins as its LIBCC, as upstream's
        // build_yolomusl.sh does (`LIBCC=…/pizfix/lib/libyolort.a`).
        const rt = buildCompilerRt(b, crt_step, src);
        const yolo = buildYoloMusl(b, yolomusl_step, gen, src, rt.lib);
        // With a Fil-C clang, libpas is built whole: its Fil-C half and libpizlo.so / .a too.
        const half: ?FilcHalf = if (filc_clang) |c| (if (yolo) |y| FilcHalf{ .clang = c, .rt = rt, .yolo = y } else null) else null;
        buildStockRuntime(b, libpas_step, gen, src, pizfixIncludes(b, src, pizfix_opt), half);
    } else {
        for ([_]*std.Build.Step{ libpas_step, yolomusl_step, crt_step }) |s|
            s.dependOn(&b.addFail(b.fmt("zig build {s} {s}", .{ s.name, need })).step);
    }
}

/// Ubuntu's GCC compiles with hardening ON by default, so the release's GCC-built pieces carry it:
/// compiler-rt (GCC 11.4), yolo musl and the crt objects (GCC 12.3). Zig's clang adds each only when
/// asked (cmem/toolchain-quirks.md C-7, C-7b). The clang-14-built pieces (libpas's stock half,
/// filc_crt.o, yolounwind) have none of them, as in the release. Per piece, what the release shows:
///   * CET, `-fcf-protection` (`endbr64`, IBT/SHSTK notes): every GCC-built piece (2026-11-04);
///   * `-fstack-protector-strong`: compiler-rt (9 `__stack_chk_fail` calls, 18 guard loads); yolo
///     musl's use already equals the release's, so it is not added there (2026-11-05);
///   * `-fstack-clash-protection`: yolo musl (15 probes) and compiler-rt;
///   * `-D_FORTIFY_SOURCE=2`: Ubuntu applies it only when optimizing, so the `-O3` builtins and not
///     crtbegin/crtend (`-O0`). Under clang glibc's headers fortify `fprintf` as `__vfprintf_chk`
///     where GCC's give `__fprintf_chk`: the same check through another glibc entry point.
const ubuntu_gcc_cet = "-fcf-protection";
const ubuntu_gcc_clash = "-fstack-clash-protection";
const ubuntu_gcc_ssp = "-fstack-protector-strong";
const ubuntu_gcc_fortify = "-D_FORTIFY_SOURCE=2";

/// Static libraries with upstream's member names and order (tools/archive-rename.zig; Zig's own
/// names are full cache paths, toolchain-quirks.md Z-b-8). `specs` are `<stem>=<name>`, in order.
fn installUpstreamArchive(b: *std.Build, step: *std.Build.Step, lib: *std.Build.Step.Compile, dest: []const u8, specs: []const []const u8) void {
    const tool = b.addExecutable(.{
        .name = "archive-rename",
        .root_module = b.createModule(.{ .root_source_file = b.path("tools/archive-rename.zig"), .target = b.graph.host }),
    });
    const run = b.addRunArtifact(tool);
    run.addArg(b.graph.zig_exe);
    run.addArtifactArg(lib);
    const out = run.addOutputFileArg(std.fs.path.basename(dest));
    run.addArgs(specs);
    step.dependOn(&b.addInstallFile(out, dest).step);
}

/// `flags` plus Ubuntu GCC's defaults for an optimized compiler-rt member (above).
fn withUbuntuGccOptimized(b: *std.Build, flags: []const []const u8) []const []const u8 {
    return std.mem.concat(b.allocator, []const u8, &.{ flags, &.{ ubuntu_gcc_cet, ubuntu_gcc_ssp, ubuntu_gcc_clash, ubuntu_gcc_fortify } }) catch @panic("OOM");
}

/// libpas's archive order (libpas/Makefile PASPIZLO*OBJS): PASSRCS as common.mk lists them,
/// sorted, with the generated filc_native_forwarders.c in its sorted place; then the assembly; then
/// the variant's own objects; then FILPIZLOOBJS. Names `pas-pizlo-release-<stem>.o`, `fil-pizlo-*.o`.
fn pasSpecs(b: *std.Build, extras: []const []const u8, fil: []const []const u8) []const []const u8 {
    var l: std.ArrayList([]const u8) = .empty;
    var fwd_done = false;
    for (libpas_sources.c) |c| {
        const st = std.fs.path.stem(c);
        if (!fwd_done and std.mem.order(u8, "filc_native_forwarders", st) == .lt) {
            l.append(b.allocator, "filc_native_forwarders=pas-pizlo-release-filc_native_forwarders.o") catch @panic("OOM");
            fwd_done = true;
        }
        l.append(b.allocator, b.fmt("{s}=pas-pizlo-release-{s}.o", .{ st, st })) catch @panic("OOM");
    }
    if (!fwd_done) l.append(b.allocator, "filc_native_forwarders=pas-pizlo-release-filc_native_forwarders.o") catch @panic("OOM");
    for (libpas_sources.assembly) |a| l.append(b.allocator, b.fmt("{s}=pas-pizlo-release-{s}.o", .{ std.fs.path.stem(a), std.fs.path.stem(a) })) catch @panic("OOM");
    for (extras) |e| l.append(b.allocator, b.fmt("{s}=pas-pizlo-release-{s}.o", .{ e, e })) catch @panic("OOM");
    for (fil) |f| l.append(b.allocator, b.fmt("{s}={s}.o", .{ f, f })) catch @panic("OOM");
    return l.items;
}

/// The two pizfix include directories libpas is compiled against.
const Pizfix = struct { os_include: std.Build.LazyPath, stdfil_include: std.Build.LazyPath };

/// From -Dpizfix when given; else as upstream makes them (a fetched tree has no pizfix/):
/// stdfil-include is libpas/build.sh's copy of filc/include, read in place, and os-include is
/// build_os_include.sh's three links into the host's kernel headers (tools/os-include.zig).
fn pizfixIncludes(b: *std.Build, filc_src: []const u8, pizfix: ?[]const u8) Pizfix {
    if (pizfix) |p| return .{
        .os_include = .{ .cwd_relative = b.pathJoin(&.{ p, "os-include" }) },
        .stdfil_include = .{ .cwd_relative = b.pathJoin(&.{ p, "stdfil-include" }) },
    };
    const tool = b.addExecutable(.{
        .name = "os-include",
        .root_module = b.createModule(.{ .root_source_file = b.path("tools/os-include.zig"), .target = b.graph.host }),
    });
    const run = b.addRunArtifact(tool);
    return .{
        .os_include = run.addOutputDirectoryArg("os-include"),
        .stdfil_include = .{ .cwd_relative = b.pathJoin(&.{ filc_src, "filc", "include" }) },
    };
}

/// compiler-rt's builtins and crt objects, as its CMake build compiles them for Zig's clang.
/// Upstream's release built them with GCC 11.4. CMake configured them for x86_64-linux-gnu with
/// the host's libc headers; here Zig's glibc headers stand in.
const CompilerRt = struct { lib: *std.Build.Step.Compile, crtbegin: std.Build.LazyPath, crtend: std.Build.LazyPath };

fn buildCompilerRt(b: *std.Build, step: *std.Build.Step, filc_src: []const u8) CompilerRt {
    const cs = compiler_rt_sources;
    const dir: std.Build.LazyPath = .{ .cwd_relative = b.pathJoin(&.{ filc_src, "compiler-rt", "lib", "builtins" }) };
    const module = struct {
        fn f(bb: *std.Build) *std.Build.Module {
            return bb.createModule(.{
                .target = bb.resolveTargetQuery(.{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu, .cpu_model = .baseline }),
                .optimize = .ReleaseFast, // the -O level is in the flags (-O3; crt: -O0)
                .pic = true,
                .sanitize_c = .off,
                .strip = true, // CMAKE_BUILD_TYPE=Release and the crt commands pass no -g
                .link_libc = true, // libc HEADERS only (stdint.h, ...), as the host's were for CMake
            });
        }
    }.f;

    const builtins = module(b);
    for (cs.builtins) |m| builtins.addCSourceFile(.{ .file = dir.path(b, m.path), .flags = withUbuntuGccOptimized(b, if (m.asm_) &cs.asm_flags else &cs.c_flags) });
    const lib = b.addLibrary(.{ .name = "yolort", .root_module = builtins, .linkage = .static });
    // CMake names each member `<source file>.o` (`absvdi2.c.o`, `chkstk.S.o`).
    const rt_specs = b.allocator.alloc([]const u8, cs.builtins.len) catch @panic("OOM");
    for (cs.builtins, 0..) |m, i| rt_specs[i] = b.fmt("{s}={s}.o", .{ std.fs.path.stem(m.path), std.fs.path.basename(m.path) });
    installUpstreamArchive(b, step, lib, "lib/libyolort.a", rt_specs);

    var crt: [2]std.Build.LazyPath = undefined;
    for ([_]struct { name: []const u8, path: []const u8, flags: []const []const u8 }{
        .{ .name = "crtbegin", .path = cs.crtbegin_path, .flags = &cs.crtbegin_flags },
        .{ .name = "crtend", .path = cs.crtend_path, .flags = &cs.crtend_flags },
    }, 0..) |o, i| {
        const m = module(b);
        // CMake's custom command passes no -O: the compiler's default, -O0.
        // Ubuntu GCC's defaults at -O0: no fortify (it needs optimization).
        const flags = std.mem.concat(b.allocator, []const u8, &.{ o.flags, &.{ "-O0", ubuntu_gcc_cet, ubuntu_gcc_ssp, ubuntu_gcc_clash } }) catch @panic("OOM");
        m.addCSourceFile(.{ .file = dir.path(b, o.path), .flags = flags });
        const obj = b.addObject(.{ .name = o.name, .root_module = m });
        crt[i] = obj.getEmittedBin();
        step.dependOn(&b.addInstallFile(crt[i], b.fmt("lib/{s}.o", .{o.name})).step);
    }
    return .{ .lib = lib, .crtbegin = crt[0], .crtend = crt[1] };
}

/// Fil-C's yolo musl, compiled as its Makefile compiles it (yolomusl_sources.zig has the rules'
/// result). Upstream's release built it with GCC 12.3; here Zig's clang with the flags musl's
/// configure picks for clang (cmem/workarounds.md W-8).
/// What a later link takes from yolo musl: crti.o / crtn.o, and the directories `-lyoloc` and
/// `-lyolom` find libyoloc.so and libyolom.a in.
const YoloMusl = struct { crti: std.Build.LazyPath, crtn: std.Build.LazyPath, yoloc_dir: std.Build.LazyPath, yolom_dir: std.Build.LazyPath };

fn buildYoloMusl(b: *std.Build, step: *std.Build.Step, gen: *std.Build.Step.Compile, filc_src: []const u8, yolort: *std.Build.Step.Compile) ?YoloMusl {
    const ys = yolomusl_sources;
    const tree = b.pathJoin(&.{ filc_src, "projects", "yolomusl" });

    // obj/include: musl's two generated headers (GENH), alone, as its build has them.
    const genh = b.addRunArtifact(gen);
    genh.addArgs(&.{ "musl-genh", tree });
    const obj_include = genh.addOutputDirectoryArg("obj-include");
    genh.addArg(ys.arch);
    const genh_inputs = musl_headers.inputs(b.allocator, tree, ys.arch) catch |err| {
        step.dependOn(&b.addFail(b.fmt("cannot list musl's headers in {s}: {s}", .{ tree, @errorName(err) })).step);
        return null;
    };
    for (genh_inputs) |in| if (in.use != .copy) genh.addFileInput(.{ .cwd_relative = b.pathJoin(&.{ tree, in.path }) });

    // obj/src/internal/version.h (tools/version.sh: no .git in the subtree, so VERSION).
    const version_dir = b.addWriteFiles();
    _ = version_dir.add("version.h", b.fmt("#define VERSION \"{s}\"\n", .{ys.version}));

    // CFLAGS_ALL's -I list, in the Makefile's order.
    const includes = struct {
        fn add(m: *std.Build.Module, bb: *std.Build, t: []const u8, oi: std.Build.LazyPath, vd: std.Build.LazyPath) void {
            m.addIncludePath(.{ .cwd_relative = bb.pathJoin(&.{ t, "arch", ys.arch }) });
            m.addIncludePath(.{ .cwd_relative = bb.pathJoin(&.{ t, "arch", "generic" }) });
            m.addIncludePath(vd);
            m.addIncludePath(.{ .cwd_relative = bb.pathJoin(&.{ t, "src", "include" }) });
            m.addIncludePath(.{ .cwd_relative = bb.pathJoin(&.{ t, "src", "internal" }) });
            m.addIncludePath(oi);
            m.addIncludePath(.{ .cwd_relative = bb.pathJoin(&.{ t, "include" }) });
        }
    }.add;

    // Upstream's make runs in projects/yolomusl and names sources relatively (W-6).
    const prefix_map = b.fmt("-ffile-prefix-map={s}/=", .{tree});
    const flagsFor = struct {
        fn f(bb: *std.Build, s: ys.Src, crt: bool, map: []const u8) []const []const u8 {
            var l: std.ArrayList([]const u8) = .empty;
            l.appendSlice(bb.allocator, &ys.c99fse) catch @panic("OOM");
            l.appendSlice(bb.allocator, &.{ "-D_XOPEN_SOURCE=700", "-g" }) catch @panic("OOM");
            l.appendSlice(bb.allocator, &ys.auto) catch @panic("OOM");
            if (s.o3) l.append(bb.allocator, "-O3") catch @panic("OOM");
            if (s.memops) l.appendSlice(bb.allocator, &ys.memops_flags) catch @panic("OOM");
            if (s.nossp) l.appendSlice(bb.allocator, &ys.nossp_flags) catch @panic("OOM");
            if (crt) l.append(bb.allocator, "-DCRT") catch @panic("OOM");
            if (s.pic) l.append(bb.allocator, "-fPIC") catch @panic("OOM");
            l.appendSlice(bb.allocator, &.{ ubuntu_gcc_cet, ubuntu_gcc_clash }) catch @panic("OOM"); // the release's GCC 12.3 defaults
            l.append(bb.allocator, map) catch @panic("OOM");
            return l.items;
        }
    }.f;

    // libyoloc.a: every LIBC_OBJS member as its .lo (PIC) form, as upstream's archive holds them.
    const libc_mod = runtimeModule(b, .baseline, true);
    includes(libc_mod, b, tree, obj_include, version_dir.getDirectory());
    const root: std.Build.LazyPath = .{ .cwd_relative = tree };
    for (ys.libc) |s| libc_mod.addCSourceFile(.{ .file = root.path(b, s.path), .flags = flagsFor(b, s, false, prefix_map) });
    const libc = b.addLibrary(.{ .name = "yoloc", .root_module = libc_mod, .linkage = .static });
    // musl's Makefile names each member `<stem>.lo` (two each of clone, free, realloc: in order).
    const libc_specs = b.allocator.alloc([]const u8, ys.libc.len) catch @panic("OOM");
    for (ys.libc, 0..) |s, i| libc_specs[i] = b.fmt("{s}={s}.lo", .{ std.fs.path.stem(s.path), std.fs.path.stem(s.path) });
    installUpstreamArchive(b, step, libc, "lib/libyoloc.a", libc_specs);

    // The crt objects, one each, installed under their base names (crt/x86_64/crti.s -> crti.o).
    var crti: ?std.Build.LazyPath = null;
    var crtn: ?std.Build.LazyPath = null;
    for (ys.crt) |s| {
        const m = runtimeModule(b, .baseline, s.pic);
        includes(m, b, tree, obj_include, version_dir.getDirectory());
        m.addCSourceFile(.{ .file = root.path(b, s.path), .flags = flagsFor(b, s, true, prefix_map) });
        const stem = std.fs.path.stem(s.path);
        const obj = b.addObject(.{ .name = stem, .root_module = m });
        if (std.mem.eql(u8, stem, "crti")) crti = obj.getEmittedBin();
        if (std.mem.eql(u8, stem, "crtn")) crtn = obj.getEmittedBin();
        step.dependOn(&b.addInstallFile(obj.getEmittedBin(), b.fmt("lib/{s}.o", .{stem})).step);
    }

    // libyolom.a: upstream's `ar cr libyolom.a` with no members.
    const empty = b.addWriteFiles();
    const yolom = empty.add("libyolom.a", "!<arch>\n");
    step.dependOn(&b.addInstallFile(yolom, "lib/libyolom.a").step);

    // libyoloc.so, which is also the dynamic loader (build_yolomusl.sh: `ln -fs libyoloc.so
    // ld-fil1-x86_64.so`): the Makefile's
    //   $(CC) $(CFLAGS_ALL) $(LDFLAGS_ALL) -nostdlib -shared -Wl,-e,_dlstart -o $@ \
    //       $(LOBJS) $(LDSO_OBJS) $(LIBCC)
    // LOBJS are exactly libyoloc.a's members, in order (upstream's archive holds the .lo objects,
    // measured: 1,343 of 1,343), so the archive goes in whole. Linked by Zig's own LLD (`zig
    // ld.lld`) because `zig cc` refuses two of upstream's LDFLAGS_AUTO (--exclude-libs,
    // --dynamic-list: "unsupported linker arg"), which change what binds inside libc.
    const ldso_objs = b.allocator.alloc(std.Build.LazyPath, ys.ldso.len) catch @panic("OOM");
    for (ys.ldso, 0..) |s, i| {
        const m = runtimeModule(b, .baseline, s.pic);
        includes(m, b, tree, obj_include, version_dir.getDirectory());
        m.addCSourceFile(.{ .file = root.path(b, s.path), .flags = flagsFor(b, s, false, prefix_map) });
        ldso_objs[i] = b.addObject(.{ .name = std.fs.path.stem(s.path), .root_module = m }).getEmittedBin();
    }
    const link = b.addSystemCommand(&.{ b.graph.zig_exe, "ld.lld", "-m", "elf_x86_64", "-shared", "-e", "_dlstart" });
    // What the release's GCC driver added around the Makefile's flags, as its libyoloc.so shows
    // (readelf, 0.687, 2026-10-27): a GNU build-id note (20 bytes: SHA-1), .eh_frame_hdr
    // (GNU_EH_FRAME), RELRO (GNU_RELRO); no BIND_NOW, no SONAME, no NEEDED.
    link.addArgs(&.{ "--build-id=sha1", "--eh-frame-hdr", "-z", "relro" });
    // `--exclude-libs=ALL` hides the symbols of every ARCHIVE on the line. Upstream's line has one
    // archive, LIBCC (libyolort.a): its LOBJS are loose objects. Here LOBJS arrive as libyoloc.a,
    // so ALL would hide libc's own exports too (measured 2026-10-27: 8 exports instead of 1,653).
    // Naming the one archive upstream's flag reaches gives exactly upstream's effect.
    for (ys.ld_args) |a| {
        const arg = if (std.mem.eql(u8, a, "--exclude-libs=ALL")) "--exclude-libs=libyolort.a" else a;
        link.addArg(std.mem.replaceOwned(u8, b.allocator, arg, "$srcdir", tree) catch @panic("OOM"));
    }
    link.addFileInput(.{ .cwd_relative = b.pathJoin(&.{ tree, "dynamic.list" }) });
    link.addArg("--whole-archive");
    link.addArtifactArg(libc);
    link.addArg("--no-whole-archive");
    for (ldso_objs) |o| link.addFileArg(o);
    link.addArtifactArg(yolort);
    link.addArg("-o");
    const so = link.addOutputFileArg("libyoloc.so");
    step.dependOn(&b.addInstallFile(so, "lib/libyoloc.so").step);
    return .{ .crti = crti.?, .crtn = crtn.?, .yoloc_dir = so.dirname(), .yolom_dir = yolom.dirname() };
}

/// The settings every stock-compiled runtime object shares: upstream compiles them with its
/// host clang for x86_64 Linux, -fPIC, no sanitizers, with debug info.
fn runtimeModule(b: *std.Build, cpu: std.Target.Query.CpuModel, pic: bool) *std.Build.Module {
    return b.createModule(.{
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .x86_64,
            .os_tag = .linux,
            .abi = .none, // no libc from Zig: musl's headers come from yolo-include, as upstream
            .cpu_model = cpu,
        }),
        .optimize = .ReleaseFast,
        .pic = pic,
        .sanitize_c = .off, // upstream compiles with plain clang; no UBSan
        .strip = false, // -g
        .link_libc = false,
    });
}

/// The libpas objects' compile settings, and a module of them per upstream object set.
const Pas = struct {
    b: *std.Build,
    root: std.Build.LazyPath,
    cflags: []const []const u8,
    test_cflags: []const []const u8,
    yolo_include: std.Build.LazyPath,
    pizfix: Pizfix,
    native_h_dir: std.Build.LazyPath,
    fwd_c: std.Build.LazyPath,
    libpas_src: []const u8,

    fn addIncludes(p: Pas, m: *std.Build.Module) void {
        m.addSystemIncludePath(p.yolo_include);
        m.addSystemIncludePath(p.pizfix.os_include);
        m.addSystemIncludePath(p.pizfix.stdfil_include);
        // `./find_clang_include_dir.rb` → the clang resource headers Zig ships (stddef.h, stdarg.h, …).
        m.addSystemIncludePath(.{ .cwd_relative = p.b.pathJoin(&.{ p.b.graph.zig_lib_directory.path orelse ".", "include" }) });
    }

    /// PASSRCS (+ the generated forwarders) and the assembly, plus `extras` (src/libpas/<name>.c),
    /// compiled as upstream's pas-pizlo-release-%.o, or pas-pizlo-test-%.o when `testing` (whose
    /// assembly is still the release objects: the Makefile reuses them).
    fn module(p: Pas, extras: []const []const u8, testing: bool) *std.Build.Module {
        const b = p.b;
        const flags = if (testing) p.test_cflags else p.cflags;
        const m = runtimeModule(b, .{ .explicit = &std.Target.x86.cpu.x86_64_v2 }, true); // -march=x86-64-v2
        p.addIncludes(m);
        m.addIncludePath(p.native_h_dir);
        m.addIncludePath(.{ .cwd_relative = p.libpas_src });
        m.addCSourceFiles(.{ .root = p.root, .files = &libpas_sources.c, .flags = flags });
        // PASASM = clang -march=x86-64-v2 -fPIC, no PASASMFLAGS.
        m.addCSourceFiles(.{ .root = p.root, .files = &libpas_sources.assembly, .flags = &.{} });
        m.addCSourceFile(.{ .file = p.fwd_c, .flags = flags });
        for (extras) |e| m.addCSourceFile(.{ .file = p.root.path(b, b.fmt("src/libpas/{s}.c", .{e})), .flags = flags });
        return m;
    }
};

/// What libpas's Fil-C half needs: Fil-C's clang (in a tree whose pizfix/ has stdfil-include and
/// os-include, which it reads by itself), and what libpizlo.so links against.
const FilcHalf = struct { clang: []const u8, rt: CompilerRt, yolo: YoloMusl };

/// The rest of libpas/Makefile's `all` (2026-10-30; owner: "complete the libpas part"):
/// filc/src/*.c compiled by Fil-C's clang ($(FILCC) $(FILCFLAGS)), the four libpizlo.so variants
/// ($(SHLD) … $(SHLDPOST)) and libpizlo.a (`ar cr` of the static objects and the Fil-C half).
fn buildLibpizlo(b: *std.Build, step: *std.Build.Step, pas: Pas, filc_src: []const u8, fh: FilcHalf) void {
    // FILPIZLOOBJS: `$(FILCC) $(FILCFLAGS) -c -o $@ $<`, FILCFLAGS = -O3 -g -W -Werror -MD, run in
    // libpas/ on `../filc/src/x.c` (hence the prefix map, as for filc_crt.o).
    const src_dir = b.pathJoin(&.{ filc_src, "filc", "src" });
    var dir = std.fs.cwd().openDir(src_dir, .{ .iterate = true }) catch |err| {
        step.dependOn(&b.addFail(b.fmt("cannot list {s}: {s}", .{ src_dir, @errorName(err) })).step);
        return;
    };
    defer dir.close();
    var names: std.ArrayList([]const u8) = .empty;
    var it = dir.iterate();
    while (it.next() catch null) |e| if (e.kind == .file and std.mem.endsWith(u8, e.name, ".c")) names.append(b.allocator, b.dupe(e.name)) catch @panic("OOM");
    std.mem.sort([]const u8, names.items, {}, struct {
        fn lt(_: void, x: []const u8, y: []const u8) bool {
            return std.mem.lessThan(u8, x, y);
        }
    }.lt);
    const fil_objs = b.allocator.alloc(std.Build.LazyPath, names.items.len) catch @panic("OOM");
    for (names.items, 0..) |n, i| {
        const cc = b.addSystemCommand(&.{ fh.clang, "-O3", "-g", "-W", "-Werror", b.fmt("-ffile-prefix-map={s}/=../", .{filc_src}), "-c", "-o" });
        fil_objs[i] = cc.addOutputFileArg(b.fmt("fil-pizlo-{s}.o", .{std.fs.path.stem(n)}));
        cc.addFileArg(.{ .cwd_relative = b.pathJoin(&.{ src_dir, n }) });
        // The clang reads headers from its own tree (pizfix/stdfil-include, os-include) and
        // filc/src/syscall.h; none is a declared input, so the compile always reruns (6 files).
        cc.has_side_effects = true;
    }

    // libpizlo.a: PASPIZLOSTATICOBJS + FILPIZLOOBJS.
    const static_mod = pas.module(&.{ "filc_static", "filc_default_settings" }, false);
    for (fil_objs) |o| static_mod.addObjectFile(o);
    const static_lib = b.addLibrary(.{ .name = "pizlo", .root_module = static_mod, .linkage = .static });
    const fil_stems = b.allocator.alloc([]const u8, names.items.len) catch @panic("OOM");
    for (names.items, 0..) |n, i| fil_stems[i] = b.fmt("fil-pizlo-{s}", .{std.fs.path.stem(n)});
    installUpstreamArchive(b, step, static_lib, "lib/libpizlo.a", pasSpecs(b, &.{ "filc_static", "filc_default_settings" }, fil_stems));

    // The four libpizlo.so: SHLD = $(HOST_CLANG) -Wl,-dynamic-linker,… -nostdlib -shared crti.o
    // crtbegin.o -L<lib>; then the objects; SHLDPOST = libyolort.a -lyoloc -lyolom crtend.o crtn.o.
    // Linked by Zig's LLD with what the release's clang driver added (readelf on 0.687's, and on
    // one linked by upstream's own script here, 2026-10-30): a SHA-1 build-id, .eh_frame_hdr,
    // RELRO, .gnu.hash only; no INTERP (a shared object gets none from -dynamic-linker).
    for ([_]struct { dir: []const u8, testing: bool, settings: []const u8 }{
        .{ .dir = "lib", .testing = false, .settings = "filc_default_settings" },
        .{ .dir = "lib_gcverify", .testing = false, .settings = "filc_gc_verify_settings" },
        .{ .dir = "lib_test", .testing = true, .settings = "filc_default_settings" },
        .{ .dir = "lib_test_gcverify", .testing = true, .settings = "filc_gc_verify_settings" },
    }) |v| {
        const objs = b.addLibrary(.{ .name = b.fmt("pizlo-{s}", .{v.dir}), .root_module = pas.module(&.{ "filc_dynamic", v.settings }, v.testing), .linkage = .static });
        const link = b.addSystemCommand(&.{ b.graph.zig_exe, "ld.lld", "-m", "elf_x86_64", "-shared", "--build-id=sha1", "--eh-frame-hdr", "-z", "relro", "--hash-style=gnu" });
        link.addFileArg(fh.yolo.crti);
        link.addFileArg(fh.rt.crtbegin);
        link.addArg("--whole-archive");
        link.addArtifactArg(objs);
        link.addArg("--no-whole-archive");
        for (fil_objs) |o| link.addFileArg(o);
        link.addArtifactArg(fh.rt.lib);
        link.addPrefixedDirectoryArg("-L", fh.yolo.yoloc_dir);
        link.addPrefixedDirectoryArg("-L", fh.yolo.yolom_dir);
        link.addArgs(&.{ "-lyoloc", "-lyolom" });
        link.addFileArg(fh.rt.crtend);
        link.addFileArg(fh.yolo.crtn);
        link.addArg("-o");
        const so = link.addOutputFileArg("libpizlo.so");
        step.dependOn(&b.addInstallFile(so, b.fmt("{s}/libpizlo.so", .{v.dir})).step);
    }
}

fn buildStockRuntime(b: *std.Build, step: *std.Build.Step, gen: *std.Build.Step.Compile, filc_src: []const u8, pizfix: Pizfix, filc_half: ?FilcHalf) void {
    const libpas_dir = b.pathJoin(&.{ filc_src, "libpas" });

    // pizfix/yolo-include: musl's installed headers, generated by zilc-gen from the yolomusl tree
    // (upstream: `make install` in projects/yolomusl, then `mv yolo/include yolo-include`).
    const musl_src = b.pathJoin(&.{ filc_src, "projects", "yolomusl" });
    const headers = b.addRunArtifact(gen);
    headers.addArg("musl-headers");
    headers.addArg(musl_src);
    const yolo_include = headers.addOutputDirectoryArg("yolo-include");
    headers.addArg("x86_64");
    // The step is cached by its arguments, and the musl tree is only a path among them: declare
    // every file zilc-gen reads as an input, from the same list it reads them by, so an edit in
    // the tree (or a release move) reruns it (cmem/workarounds.md W-5).
    const header_inputs = musl_headers.inputs(b.allocator, musl_src, "x86_64") catch |err| {
        step.dependOn(&b.addFail(b.fmt("cannot list musl's headers in {s}: {s}", .{ musl_src, @errorName(err) })).step);
        return;
    };
    for (header_inputs) |in| headers.addFileInput(.{ .cwd_relative = b.pathJoin(&.{ musl_src, in.path }) });

    // The two generated sources (upstream: ruby, in-tree; here: into the cache, the tree stays
    // read-only). `filc_runtime.c` finds "filc_native.h" through the include path.
    const native_h = b.addRunArtifact(gen);
    native_h.addArg("header");
    const native_h_out = native_h.addOutputFileArg("filc_native.h");
    const fwd_c = b.addRunArtifact(gen);
    fwd_c.addArg("forwarders");
    const fwd_c_out = fwd_c.addOutputFileArg("filc_native_forwarders.c");

    // PASCC = clang -march=x86-64-v2 -fPIC -pthread -nostdinc -isystem yolo-include
    //         -isystem os-include -isystem stdfil-include -isystem <clang resource include>
    // PASCFLAGS = -g -O3 -W -Werror -fno-strict-aliasing (-MD)      plus -DPAS_FILC=1
    const pascc = [_][]const u8{ "-pthread", "-nostdinc", "-g", "-O3", "-W", "-Werror", "-fno-strict-aliasing" };
    // Upstream runs make in libpas/ and names sources `src/libpas/x.c`, so `__FILE__` (in every
    // PAS_ASSERT and panic message) reads `src/libpas/x.c`. Zig passes absolute paths; map them
    // back so the runtime's messages are upstream's (cmem/workarounds.md W-6).
    const libpas_map = b.fmt("-ffile-prefix-map={s}/=", .{libpas_dir});
    const pas: Pas = .{
        .b = b,
        .root = .{ .cwd_relative = libpas_dir },
        .cflags = b.allocator.dupe([]const u8, &(pascc ++ [_][]const u8{ "-DPAS_FILC=1", libpas_map })) catch @panic("OOM"),
        // The pas-pizlo-test-%.o rule: the same, plus -DENABLE_PAS_TESTING=1.
        .test_cflags = b.allocator.dupe([]const u8, &(pascc ++ [_][]const u8{ "-DPAS_FILC=1", libpas_map, "-DENABLE_PAS_TESTING=1" })) catch @panic("OOM"),
        .yolo_include = yolo_include,
        .pizfix = pizfix,
        .native_h_dir = native_h_out.dirname(),
        .fwd_c = fwd_c_out,
        .libpas_src = b.pathJoin(&.{ libpas_dir, "src", "libpas" }),
    };

    // The static variant: PASPIZLOSTATICOBJS adds filc_static.o and filc_default_settings.o.
    const lib = b.addLibrary(.{ .name = "pizlo-stock", .root_module = pas.module(&.{ "filc_static", "filc_default_settings" }, false), .linkage = .static });
    installUpstreamArchive(b, step, lib, "lib/libpizlo-stock.a", pasSpecs(b, &.{ "filc_static", "filc_default_settings" }, &.{}));
    // pizfix/yolo-include, as upstream's tree has it after build_yolomusl.sh: what libpas's objects
    // were compiled against, and what Fil-C's clang reads next to its pizfix/.
    step.dependOn(&b.addInstallDirectory(.{ .source_dir = yolo_include, .install_dir = .prefix, .install_subdir = "yolo-include" }).step);

    if (filc_half) |fh| buildLibpizlo(b, step, pas, filc_src, fh);
    const v2: std.Target.Query.CpuModel = .{ .explicit = &std.Target.x86.cpu.x86_64_v2 }; // -march=x86-64-v2
    const addPasccIncludes = Pas.addIncludes;

    // filc_crt.o / filc_mincrt.o: $(PASCC) -c ../filc/main/main.c $(MAINCFLAGS) -DUSE_LIBC=1 / 0
    // (MAINCFLAGS = -g -O3 -W -Werror -fno-strict-aliasing, the same as PASCFLAGS without -MD).
    const main_c = b.pathJoin(&.{ filc_src, "filc", "main", "main.c" });
    for ([_]struct { name: []const u8, def: []const u8 }{
        .{ .name = "filc_crt", .def = "-DUSE_LIBC=1" },
        .{ .name = "filc_mincrt", .def = "-DUSE_LIBC=0" },
    }) |crt| {
        const m = runtimeModule(b, v2, true);
        addPasccIncludes(pas, m);
        // Upstream compiles it from libpas/ as `../filc/main/main.c`.
        const crt_map = b.fmt("-ffile-prefix-map={s}/=../", .{filc_src});
        m.addCSourceFile(.{ .file = .{ .cwd_relative = main_c }, .flags = b.allocator.dupe([]const u8, &(pascc ++ [_][]const u8{ crt.def, crt_map })) catch @panic("OOM") });
        const obj = b.addObject(.{ .name = crt.name, .root_module = m });
        step.dependOn(&b.addInstallFile(obj.getEmittedBin(), b.fmt("lib/{s}.o", .{crt.name})).step);
    }

    // libyolounwind.a: `clang -c yolounwind.c -O2 -g` with the host's defaults (baseline x86-64,
    // no -fPIC), then `ar cr`. Six trap stubs; the file includes nothing.
    const unwind = runtimeModule(b, .baseline, false);
    // Upstream compiles it from yolounwind/ as `yolounwind.c`.
    const unwind_map = b.fmt("-ffile-prefix-map={s}/=", .{b.pathJoin(&.{ filc_src, "yolounwind" })});
    unwind.addCSourceFile(.{ .file = .{ .cwd_relative = b.pathJoin(&.{ filc_src, "yolounwind", "yolounwind.c" }) }, .flags = b.allocator.dupe([]const u8, &.{ "-O2", "-g", unwind_map }) catch @panic("OOM") });
    const unwind_lib = b.addLibrary(.{ .name = "yolounwind", .root_module = unwind, .linkage = .static });
    installUpstreamArchive(b, step, unwind_lib, "lib/libyolounwind.a", &.{"yolounwind=yolounwind.o"});
}
