// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! `zig build gcc-reference`: MAINTAINER-ONLY. The GCC versions Fil-C's release was built with,
//! compiled by Zig from GNU's signed release tarballs (build.zig.zon), for the quality-control
//! chain that builds Fil-C the upstream way (`tools/filc/build-filc-from-source.ts MODE=upstream`)
//! and is compared with the Zig-only chain (`tools/filc/compare-chains.ts`). Owner, 2026-10-30:
//! GCC is a maintainer's tool, never a user's; pinned so the reference does not drift with the
//! system's GCC, and matching the release's versions (cmem/design-decisions.md, open-work.md).
//!
//!   zig build gcc-reference [-Dgcc-version=11.4.0|12.3.0] [-Dgcc-jobs=16]
//!                           [-Dgcc-prefix=<dir>] [-Dgcc-work=<dir>]
//!
//! Installs into ~/zilc-work/tools/gcc-<version> by default. Needs, besides Zig: make, binutils
//! (`as`, `ld`: GCC emits assembly), the system's libc headers and crt files (the new GCC compiles
//! libgcc and libstdc++ against them), perl, sh. The release's map (2026-11-04, `.comment`): GCC
//! 11.4.0 built compiler-rt (libyolort.a, crtbegin.o, crtend.o), GCC 12.3.0 built yolo musl.

const std = @import("std");
const filc_source = @import("filc_source.zig");

pub fn addStep(b: *std.Build) void {
    const version = b.option([]const u8, "gcc-version", "gcc-reference: 11.4.0 or 12.3.0 (default: both)");
    const jobs = b.option(u32, "gcc-jobs", "gcc-reference: make jobs (default 16)") orelse 16;
    const home = b.graph.env_map.get("HOME") orelse ".";
    const prefix_opt = b.option([]const u8, "gcc-prefix", "gcc-reference: install directory (default ~/zilc-work/tools/gcc-<version>; only with one -Dgcc-version)");
    const work = b.option([]const u8, "gcc-work", "gcc-reference: staging and build directory (default ~/zilc-work/gcc-reference)") orelse
        b.pathJoin(&.{ home, "zilc-work", "gcc-reference" });

    const step = b.step("gcc-reference", "MAINTAINER-ONLY: build GCC 11.4.0 / 12.3.0 (the release's) with Zig, for the GCC comparison chain");
    // Fetched only when this step is named: a user's build never downloads GCC.
    if (!filc_source.named(b, "gcc-reference")) return;

    const versions: []const []const u8 = if (version) |v| &.{v} else &.{ "11.4.0", "12.3.0" };
    const gmp = b.lazyDependency("gmp", .{});
    const mpfr = b.lazyDependency("mpfr", .{});
    const mpc = b.lazyDependency("mpc", .{});
    var srcs: [2]?*std.Build.Dependency = .{ null, null };
    for (versions, 0..) |v, i| {
        if (std.mem.eql(u8, v, "11.4.0")) srcs[i] = b.lazyDependency("gcc_11_4_0", .{}) else if (std.mem.eql(u8, v, "12.3.0")) srcs[i] = b.lazyDependency("gcc_12_3_0", .{}) else {
            step.dependOn(&b.addFail(b.fmt("gcc-reference: no pinned GCC {s} (11.4.0 or 12.3.0)", .{v})).step);
            return;
        }
    }
    if (gmp == null or mpfr == null or mpc == null) return; // fetched, then build.zig runs again
    for (srcs[0..versions.len]) |s| if (s == null) return;

    const host = b.graph.host;
    const tool = b.addExecutable(.{
        .name = "gcc-reference",
        .root_module = b.createModule(.{ .root_source_file = b.path("tools/gcc-reference.zig"), .target = host, .optimize = .ReleaseSafe }),
    });
    // GCC's host compiler: Zig's cc / c++, with ar / ranlib (tools/gcc-host-shim.zig: like
    // patched-clang's shims, plus GCC 11's `.c`-as-C++ rule).
    var shims: [4]std.Build.LazyPath = undefined;
    for ([_][]const u8{ "cc", "c++", "ar", "ranlib" }, 0..) |sub, i| {
        const opts = b.addOptions();
        opts.addOption([]const u8, "zig_exe", b.graph.zig_exe);
        opts.addOption([]const u8, "subcommand", sub);
        const shim = b.addExecutable(.{
            .name = b.fmt("zig-{s}", .{sub}),
            .root_module = b.createModule(.{ .root_source_file = b.path("tools/gcc-host-shim.zig"), .target = host, .optimize = .ReleaseSafe }),
        });
        shim.root_module.addOptions("shim_options", opts);
        shims[i] = shim.getEmittedBin();
    }
    for (versions, 0..) |v, i| {
        const run = b.addRunArtifact(tool);
        run.addArgs(&.{ v, srcs[i].?.builder.build_root.path.?, gmp.?.builder.build_root.path.?, mpfr.?.builder.build_root.path.?, mpc.?.builder.build_root.path.? });
        run.addArgs(&.{ work, if (versions.len == 1 and prefix_opt != null) prefix_opt.? else b.pathJoin(&.{ home, "zilc-work", "tools", b.fmt("gcc-{s}", .{v}) }), b.fmt("{d}", .{jobs}) });
        for (shims) |s| run.addFileArg(s);
        run.addFileArg(b.path(b.fmt("third_party/gcc-patches/gcc-{s}-PR111632-safe-ctype.patch", .{v})));
        run.has_side_effects = true; // make keeps its own state
        step.dependOn(&run.step);
    }
}
