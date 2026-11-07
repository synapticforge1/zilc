// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! Where `zig build` finds Fil-C's sources (owner, 2026-10-27: "when a user clones our repository
//! and performs the fil-c side build (first build) the build goes and gets all of the files
//! necessary to build, then builds it. And we just have our zig sources files in the repo").
//!
//! The lazy dependency `filc` in build.zig.zon is GitHub's archive of Fil-C's LLVM fork at the
//! compiler commit, pinned by Zig's package hash (which covers the unpacked files), so the first
//! build that needs it downloads it once into Zig's global cache, and every later one, from any
//! clone, reuses it. `-Dfilc-src=<tree>` still wins: an offline or local checkout at the same commit.
//!
//! Only the steps that read Fil-C's sources ask for it, so `zig build test`, `gate` and the rest
//! never download it. build.zig cannot see which steps were named, so this reads the build
//! runner's own arguments: a bare argument is a step name (lib/compiler/build_runner.zig), and
//! everything after `--` belongs to `run`.

const std = @import("std");

/// The steps that read Fil-C's sources (build/pure_zig.zig, build/patched_clang.zig).
pub const steps = [_][]const u8{ "pure-zig", "libpas", "yolomusl", "compiler-rt", "usermusl", "libcxx", "patched-clang" };

/// The Fil-C source tree, or null when no named step needs it (or it is still being fetched:
/// the build runner then fetches it and runs build.zig again).
pub fn path(b: *std.Build) ?[]const u8 {
    if (b.option([]const u8, "filc-src", "A local Fil-C source tree at zilc's commit, instead of the one zig build fetches (build.zig.zon `filc`)")) |p| return p;
    if (!requested(b)) return null;
    const dep = b.lazyDependency("filc", .{}) orelse return null;
    return dep.builder.build_root.path orelse ".";
}

fn requested(b: *std.Build) bool {
    for (steps) |s| if (named(b, s)) return true;
    return false;
}

/// Whether `step` was named on the command line (for the other lazy dependencies too).
pub fn named(b: *std.Build, step: []const u8) bool {
    const args = std.process.argsAlloc(b.allocator) catch @panic("OOM");
    for (args[1..]) |a| {
        if (std.mem.eql(u8, a, "--")) break;
        if (std.mem.eql(u8, a, step)) return true;
    }
    return false;
}
