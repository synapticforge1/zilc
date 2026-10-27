// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! The pure-Zig track's build recipes (cmem/roadmap.md Z1): Fil-C's runtime pieces built by Zig
//! from Fil-C's own sources, faithful to the release (no departures). Brought from zailc's build.zig
//! on 2026-10-27 (owner: zailc's build up to a pure-Zig Fil-C on Linux lives in zilc). The file
//! lists and flags are the generated tables in src/runtime/ (tools/runtime/import-*.ts); the
//! recipes are upstream's Makefile and CMake rules re-expressed (third_party/LICENSES.md
//! `libpas-recipe`, `yolomusl-recipe`, `compiler-rt-recipe`). Checked object by object against the
//! release tarball by tools/runtime/verify-*.ts, then as a whole by `zig build gate-zig-modules`.
//!
//!   zig build libpas | yolomusl | compiler-rt | pure-zig  -Dfilc-src=<Fil-C tree> [-Dpizfix=<pizfix>]
//!                                                         --prefix ~/zilc-work/pure-zig/filc-<release>
const std = @import("std");
const libpas_sources = @import("../src/runtime/libpas_sources.zig");
const musl_headers = @import("../src/gen/musl_headers.zig");
const yolomusl_sources = @import("../src/runtime/yolomusl_sources.zig");
const compiler_rt_sources = @import("../src/runtime/compiler_rt_sources.zig");

pub fn addSteps(b: *std.Build, gen: *std.Build.Step.Compile) void {
    const filc_src = b.option([]const u8, "filc-src", "The Fil-C source tree (at the release zilc is on) to compile the runtime from");
    const pizfix_opt = b.option([]const u8, "pizfix", "A pizfix/ with os-include and stdfil-include (default: <filc-src>/pizfix)");
    const need = "needs -Dfilc-src=<the Fil-C tree at zilc's release, e.g. ~/zilc-work/filc-src/repo>";

    const all = b.step("pure-zig", "Build every pure-Zig runtime piece (libpas, yolomusl, compiler-rt) from -Dfilc-src");
    // `zig build libpas`: the stock-compiled half of Fil-C's runtime, libpizlo-stock.a, from
    // upstream's sources, compiled by Zig's clang with the flags of libpas/Makefile (PASCC +
    // PASCFLAGS, static variant). The three Fil-C-compiled pieces (filc/src) are not in it yet.
    const libpas_step = b.step("libpas", "Build the stock half of Fil-C's runtime from -Dfilc-src: libpizlo-stock.a, filc_crt.o, filc_mincrt.o, libyolounwind.a");
    // `zig build yolomusl`: Fil-C's patched musl (projects/yolomusl) as upstream's
    // build_yolomusl.sh installs it: libyoloc.a, the crt objects and the empty libyolom.a.
    // libyoloc.so and ld-fil1 are not built yet.
    const yolomusl_step = b.step("yolomusl", "Build Fil-C's yolo musl from -Dfilc-src: libyoloc.a, crt1.o, Scrt1.o, rcrt1.o, crti.o, crtn.o, libyolom.a");
    // `zig build compiler-rt`: Fil-C's compiler-rt as upstream's build_compiler_rt.sh installs it:
    // the builtins archive as libyolort.a, and crtbegin.o / crtend.o.
    const crt_step = b.step("compiler-rt", "Build Fil-C's compiler-rt from -Dfilc-src: libyolort.a, crtbegin.o, crtend.o");
    for ([_]*std.Build.Step{ libpas_step, yolomusl_step, crt_step }) |s| all.dependOn(s);

    if (filc_src) |src| {
        buildStockRuntime(b, libpas_step, gen, src, pizfix_opt orelse b.pathJoin(&.{ src, "pizfix" }));
        buildYoloMusl(b, yolomusl_step, gen, src);
        buildCompilerRt(b, crt_step, src);
    } else {
        for ([_]*std.Build.Step{ libpas_step, yolomusl_step, crt_step }) |s|
            s.dependOn(&b.addFail(b.fmt("zig build {s} {s}", .{ s.name, need })).step);
    }
}

/// compiler-rt's builtins and crt objects, as its CMake build compiles them for Zig's clang.
/// Upstream's release built them with GCC 11.4. CMake configured them for x86_64-linux-gnu with
/// the host's libc headers; here Zig's glibc headers stand in.
fn buildCompilerRt(b: *std.Build, step: *std.Build.Step, filc_src: []const u8) void {
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
    for (cs.builtins) |m| builtins.addCSourceFile(.{ .file = dir.path(b, m.path), .flags = if (m.asm_) &cs.asm_flags else &cs.c_flags });
    const lib = b.addLibrary(.{ .name = "yolort", .root_module = builtins, .linkage = .static });
    step.dependOn(&b.addInstallArtifact(lib, .{}).step);

    for ([_]struct { name: []const u8, path: []const u8, flags: []const []const u8 }{
        .{ .name = "crtbegin", .path = cs.crtbegin_path, .flags = &cs.crtbegin_flags },
        .{ .name = "crtend", .path = cs.crtend_path, .flags = &cs.crtend_flags },
    }) |o| {
        const m = module(b);
        // CMake's custom command passes no -O: the compiler's default, -O0.
        const flags = std.mem.concat(b.allocator, []const u8, &.{ o.flags, &.{"-O0"} }) catch @panic("OOM");
        m.addCSourceFile(.{ .file = dir.path(b, o.path), .flags = flags });
        const obj = b.addObject(.{ .name = o.name, .root_module = m });
        step.dependOn(&b.addInstallFile(obj.getEmittedBin(), b.fmt("lib/{s}.o", .{o.name})).step);
    }
}

/// Fil-C's yolo musl, compiled as its Makefile compiles it (yolomusl_sources.zig has the rules'
/// result). Upstream's release built it with GCC 12.3; here Zig's clang with the flags musl's
/// configure picks for clang (cmem/workarounds.md W-8).
fn buildYoloMusl(b: *std.Build, step: *std.Build.Step, gen: *std.Build.Step.Compile, filc_src: []const u8) void {
    const ys = yolomusl_sources;
    const tree = b.pathJoin(&.{ filc_src, "projects", "yolomusl" });

    // obj/include: musl's two generated headers (GENH), alone, as its build has them.
    const genh = b.addRunArtifact(gen);
    genh.addArgs(&.{ "musl-genh", tree });
    const obj_include = genh.addOutputDirectoryArg("obj-include");
    genh.addArg(ys.arch);
    const genh_inputs = musl_headers.inputs(b.allocator, tree, ys.arch) catch |err| {
        step.dependOn(&b.addFail(b.fmt("cannot list musl's headers in {s}: {s}", .{ tree, @errorName(err) })).step);
        return;
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
    step.dependOn(&b.addInstallArtifact(libc, .{}).step);

    // The crt objects, one each, installed under their base names (crt/x86_64/crti.s -> crti.o).
    for (ys.crt) |s| {
        const m = runtimeModule(b, .baseline, s.pic);
        includes(m, b, tree, obj_include, version_dir.getDirectory());
        m.addCSourceFile(.{ .file = root.path(b, s.path), .flags = flagsFor(b, s, true, prefix_map) });
        const stem = std.fs.path.stem(s.path);
        const obj = b.addObject(.{ .name = stem, .root_module = m });
        step.dependOn(&b.addInstallFile(obj.getEmittedBin(), b.fmt("lib/{s}.o", .{stem})).step);
    }

    // libyolom.a: upstream's `ar cr libyolom.a` with no members.
    const empty = b.addWriteFiles();
    step.dependOn(&b.addInstallFile(empty.add("libyolom.a", "!<arch>\n"), "lib/libyolom.a").step);
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

fn buildStockRuntime(b: *std.Build, step: *std.Build.Step, gen: *std.Build.Step.Compile, filc_src: []const u8, pizfix: []const u8) void {
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
    const v2: std.Target.Query.CpuModel = .{ .explicit = &std.Target.x86.cpu.x86_64_v2 }; // -march=x86-64-v2
    const mod = runtimeModule(b, v2, true);
    const pascc = [_][]const u8{ "-pthread", "-nostdinc", "-g", "-O3", "-W", "-Werror", "-fno-strict-aliasing" };
    // Upstream runs make in libpas/ and names sources `src/libpas/x.c`, so `__FILE__` (in every
    // PAS_ASSERT and panic message) reads `src/libpas/x.c`. Zig passes absolute paths; map them
    // back so the runtime's messages are upstream's (cmem/workarounds.md W-6).
    const libpas_map = b.fmt("-ffile-prefix-map={s}/=", .{libpas_dir});
    const cflags = b.allocator.dupe([]const u8, &(pascc ++ [_][]const u8{ "-DPAS_FILC=1", libpas_map })) catch @panic("OOM");
    const addPasccIncludes = struct {
        fn f(m: *std.Build.Module, bb: *std.Build, yolo: std.Build.LazyPath, piz: []const u8) void {
            m.addSystemIncludePath(yolo);
            m.addSystemIncludePath(.{ .cwd_relative = bb.pathJoin(&.{ piz, "os-include" }) });
            m.addSystemIncludePath(.{ .cwd_relative = bb.pathJoin(&.{ piz, "stdfil-include" }) });
            // `./find_clang_include_dir.rb` → the clang resource headers Zig ships (stddef.h, stdarg.h, …).
            m.addSystemIncludePath(.{ .cwd_relative = bb.pathJoin(&.{ bb.graph.zig_lib_directory.path orelse ".", "include" }) });
        }
    }.f;
    addPasccIncludes(mod, b, yolo_include, pizfix);
    mod.addIncludePath(native_h_out.dirname());
    mod.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ libpas_dir, "src", "libpas" }) });

    const root: std.Build.LazyPath = .{ .cwd_relative = libpas_dir };
    mod.addCSourceFiles(.{ .root = root, .files = &libpas_sources.c, .flags = cflags });
    // PASASM = clang -march=x86-64-v2 -fPIC, no PASASMFLAGS.
    mod.addCSourceFiles(.{ .root = root, .files = &libpas_sources.assembly, .flags = &.{} });
    mod.addCSourceFile(.{ .file = fwd_c_out, .flags = cflags });
    // The static variant: PASPIZLOSTATICOBJS adds filc_static.o and filc_default_settings.o.
    mod.addCSourceFiles(.{ .root = root, .files = &.{ "src/libpas/filc_static.c", "src/libpas/filc_default_settings.c" }, .flags = cflags });

    const lib = b.addLibrary(.{ .name = "pizlo-stock", .root_module = mod, .linkage = .static });
    step.dependOn(&b.addInstallArtifact(lib, .{}).step);

    // filc_crt.o / filc_mincrt.o: $(PASCC) -c ../filc/main/main.c $(MAINCFLAGS) -DUSE_LIBC=1 / 0
    // (MAINCFLAGS = -g -O3 -W -Werror -fno-strict-aliasing, the same as PASCFLAGS without -MD).
    const main_c = b.pathJoin(&.{ filc_src, "filc", "main", "main.c" });
    for ([_]struct { name: []const u8, def: []const u8 }{
        .{ .name = "filc_crt", .def = "-DUSE_LIBC=1" },
        .{ .name = "filc_mincrt", .def = "-DUSE_LIBC=0" },
    }) |crt| {
        const m = runtimeModule(b, v2, true);
        addPasccIncludes(m, b, yolo_include, pizfix);
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
    step.dependOn(&b.addInstallArtifact(unwind_lib, .{}).step);
}
