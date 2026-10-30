// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! `zig build patched-clang`: the Fil-C side's compiler, Fil-C's clang with zilc's pass fixes,
//! built from the sources build/filc_source.zig provides (tools/patched-clang.zig says how).
//!
//!   zig build patched-clang [-Dclang-cc=zig|system] [-Dclang-jobs=12] [-Dclang-work=<dir>]
//!
//! Needs cmake and ninja on PATH (LLVM's build system; not compilers). The compilers are Zig's own
//! by default (owner, 2026-10-27: "just zig to start"): Fil-C's suite gave 0 differences on all
//! 7,269 tests against stock, 2026-10-30 (cmem/testing.md). `system` uses the system's cc/c++, as
//! tools/filc/build-patched-clang.ts does.

const std = @import("std");
const signatures = @import("../src/gen/signatures.zig");

/// The origin the prebuilt's `clang --version` names (tools/lib/tool.ts FILC_SOURCE_URL).
const vc_repository = "git@github.com:pizlonator/llvm-project-deluge.git";

pub fn addStep(b: *std.Build, filc_src: ?[]const u8) void {
    const cc = b.option(enum { zig, system }, "clang-cc", "Compilers for patched-clang: zig (zig cc/c++, the default) or system (cc/c++)") orelse .zig;
    const jobs = b.option(u32, "clang-jobs", "ninja jobs for patched-clang (default 12: one per core exhausted a 31 GB VM)") orelse 12;
    const home = b.graph.env_map.get("HOME") orelse ".";
    // Off the repo: the build tree holds ~100k files and the repo may be on exFAT (KI-2).
    const work = b.option([]const u8, "clang-work", "patched-clang's staging and build directory (default ~/zilc-work/patched-clang/filc-<release>)") orelse
        b.pathJoin(&.{ home, "zilc-work", "patched-clang", "filc-" ++ signatures.filc_version });

    const step = b.step("patched-clang", "Build Fil-C's clang with zilc's pass fixes from Fil-C's sources (fetched on first use; needs cmake + ninja)");
    const src = filc_src orelse {
        step.dependOn(&b.addFail("patched-clang: Fil-C's sources are not available (-Dfilc-src, or the `filc` dependency)").step);
        return;
    };

    const host = b.graph.host;
    const tool = b.addExecutable(.{
        .name = "patched-clang",
        .root_module = b.createModule(.{ .root_source_file = b.path("tools/patched-clang.zig"), .target = host, .optimize = .ReleaseSafe }),
    });
    const run = b.addRunArtifact(tool);
    run.addArg(src);
    run.addFileArg(b.path("third_party/filc-patches/zilc-filc-pass.patch"));
    run.addArgs(&.{ work, b.fmt("{d}", .{jobs}), vc_repository, signatures.filc_commit });
    run.addArg(b.getInstallPath(.prefix, "patched-clang"));
    if (cc == .zig) {
        for ([_][2][]const u8{ .{ "--cc", "cc" }, .{ "--cxx", "c++" }, .{ "--ar", "ar" }, .{ "--ranlib", "ranlib" } }) |t| {
            const opts = b.addOptions();
            opts.addOption([]const u8, "zig_exe", b.graph.zig_exe);
            opts.addOption([]const u8, "subcommand", t[1]);
            const shim = b.addExecutable(.{
                .name = b.fmt("zig-{s}", .{t[1]}),
                .root_module = b.createModule(.{ .root_source_file = b.path("tools/zig-shim.zig"), .target = host, .optimize = .ReleaseSafe }),
            });
            shim.root_module.addOptions("shim_options", opts);
            run.addArg(t[0]);
            run.addFileArg(shim.getEmittedBin());
        }
    }
    // cmake and ninja keep their own state; the tool decides what is current.
    run.has_side_effects = true;
    step.dependOn(&run.step);
}
