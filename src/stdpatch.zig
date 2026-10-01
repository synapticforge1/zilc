// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! Backports to Zig's standard library, applied to a cached overlay of the user's
//! own Zig lib directory (cmem/known-issues.md KI-11, zig-upstream-notes.md).
//!
//! zilc ships no Zig files. At build time it copies the installed Zig's `std/`,
//! applies the patches for that exact Zig version, and compiles with
//! `--zig-lib-dir` pointing at the overlay. Every patch checks the original text
//! it replaces, so a Zig whose file differs fails loudly instead of being
//! mis-patched. A Zig with no patch set (0.16.0, where upstream fixed it) gets no
//! overlay at all.

const std = @import("std");

pub const Error = error{
    /// The first line of the region to replace is not in the file.
    PatchStartNotFound,
    /// The region does not contain the text that identifies the expected original.
    PatchUnexpectedOriginal,
    /// No closing `}` at column 0 after the start.
    PatchEndNotFound,
};

/// Bump when any patch changes, so stale overlays are rebuilt.
pub const overlay_version = 1;

pub const Patch = struct {
    /// Path relative to the Zig lib directory.
    file: []const u8,
    /// The exact first line of the region; the region runs to the next `}` line at column 0.
    start: []const u8,
    /// Text that must appear in the region, proving it is the original we expect.
    must_contain: []const u8,
    /// What the whole region becomes.
    replacement: []const u8,
};

/// Zig 0.15.2: `indexOfSentinel` scans with 16-byte SIMD loads that read past the
/// end of the string's object, which Fil-C rejects as an out-of-bounds read.
/// Upstream fixed it in 0.16.0 by deleting the vector branch, leaving the scalar
/// loop; this replacement is that 0.16.0 function body, under the 0.15.2 name.
/// Zig std is MIT-licensed; ledger entry in third_party/LICENSES.md.
const zig_0_15_2 = [_]Patch{
    .{
        .file = "std/mem.zig",
        .start = "pub fn indexOfSentinel(comptime T: type, comptime sentinel: T, p: [*:sentinel]const T) usize {",
        .must_contain = "reading past the end of the buffer is valid, as long",
        .replacement =
        \\pub fn indexOfSentinel(comptime T: type, comptime sentinel: T, p: [*:sentinel]const T) usize {
        \\    // zilc: backport of Zig 0.16.0's `findSentinel`. 0.15.2's SIMD scan reads past the
        \\    // end of the string's object, which Fil-C rejects (zilc cmem/zig-upstream-notes.md Z-1).
        \\    var i: usize = 0;
        \\    while (p[i] != sentinel) {
        \\        i += 1;
        \\    }
        \\    return i;
        \\}
        ,
    },
};

/// The patches for one Zig version (from `zig env`'s `.version`); empty if none.
pub fn patchesFor(zig_version: []const u8) []const Patch {
    if (std.mem.eql(u8, zig_version, "0.15.2")) return &zig_0_15_2;
    return &.{};
}

/// Returns `original` with the patch applied. The caller owns the result.
pub fn apply(gpa: std.mem.Allocator, original: []const u8, patch: Patch) ![]u8 {
    const start = std.mem.indexOf(u8, original, patch.start) orelse return Error.PatchStartNotFound;
    if (start != 0 and original[start - 1] != '\n') return Error.PatchStartNotFound;
    const close = "\n}\n";
    const close_at = std.mem.indexOfPos(u8, original, start, close) orelse return Error.PatchEndNotFound;
    const end = close_at + close.len - 1; // keep the newline after `}`
    if (std.mem.indexOf(u8, original[start..end], patch.must_contain) == null) return Error.PatchUnexpectedOriginal;
    return std.mem.concat(gpa, u8, &.{ original[0..start], patch.replacement, original[end..] });
}

/// Builds (once) and returns the overlay directory for this Zig version, or null
/// if the version needs no patches. `cache_root` is zilc's cache directory.
pub fn ensureOverlay(gpa: std.mem.Allocator, lib_dir: []const u8, zig_version: []const u8, cache_root: []const u8) !?[]u8 {
    const patches = patchesFor(zig_version);
    if (patches.len == 0) return null;

    const dir = try std.fmt.allocPrint(gpa, "{s}/std-overlay/{s}-v{d}", .{ cache_root, zig_version, overlay_version });
    errdefer gpa.free(dir);
    const marker = try std.fmt.allocPrint(gpa, "{s}/.complete", .{dir});
    defer gpa.free(marker);
    if (std.fs.cwd().access(marker, .{})) |_| return dir else |_| {}

    // Build beside the final path and rename at the end, so a crash or a parallel
    // build never leaves a half-made overlay that looks complete.
    const tmp = try std.fmt.allocPrint(gpa, "{s}.tmp-{d}", .{ dir, std.Thread.getCurrentId() });
    defer gpa.free(tmp);
    std.fs.cwd().deleteTree(tmp) catch {};
    try std.fs.cwd().makePath(tmp);
    errdefer std.fs.cwd().deleteTree(tmp) catch {};

    // Everything but std/ is a symlink to the real lib; std/ is a real copy.
    var lib = try std.fs.cwd().openDir(lib_dir, .{ .iterate = true });
    defer lib.close();
    var out = try std.fs.cwd().openDir(tmp, .{});
    defer out.close();
    var it = lib.iterate();
    while (try it.next()) |entry| {
        if (std.mem.eql(u8, entry.name, "std")) continue;
        const target = try std.fs.path.join(gpa, &.{ lib_dir, entry.name });
        defer gpa.free(target);
        try out.symLink(target, entry.name, .{ .is_directory = entry.kind == .directory });
    }
    try copyTree(gpa, lib, "std", out, "std");

    for (patches) |p| {
        const original = try out.readFileAlloc(gpa, p.file, 64 * 1024 * 1024);
        defer gpa.free(original);
        const patched = try apply(gpa, original, p);
        defer gpa.free(patched);
        try out.writeFile(.{ .sub_path = p.file, .data = patched });
    }
    try out.writeFile(.{ .sub_path = ".complete", .data = zig_version });

    std.fs.cwd().rename(tmp, dir) catch |e| switch (e) {
        // Another build finished first; its overlay is identical, so use it.
        error.PathAlreadyExists => std.fs.cwd().deleteTree(tmp) catch {},
        else => return e,
    };
    return dir;
}

fn copyTree(gpa: std.mem.Allocator, src_parent: std.fs.Dir, src_name: []const u8, dst_parent: std.fs.Dir, dst_name: []const u8) !void {
    var src = try src_parent.openDir(src_name, .{ .iterate = true });
    defer src.close();
    try dst_parent.makePath(dst_name);
    var dst = try dst_parent.openDir(dst_name, .{});
    defer dst.close();
    var walker = try src.walk(gpa);
    defer walker.deinit();
    while (try walker.next()) |entry| switch (entry.kind) {
        .directory => try dst.makePath(entry.path),
        .file => try src.copyFile(entry.path, dst, entry.path, .{}),
        else => {},
    };
}

// ---------------------------------------------------------------------------

const testing = std.testing;

test "the 0.15.2 patch replaces the whole vectorised function with the scalar loop" {
    const original =
        \\pub fn before() void {}
        \\
        \\pub fn indexOfSentinel(comptime T: type, comptime sentinel: T, p: [*:sentinel]const T) usize {
        \\    var i: usize = 0;
        \\    if (use_vectors) {
        \\        // The below branch assumes that reading past the end of the buffer is valid, as long
        \\        // as we don't read into a new page.
        \\        const x = 1;
        \\    }
        \\    while (p[i] != sentinel) {
        \\        i += 1;
        \\    }
        \\    return i;
        \\}
        \\
        \\pub fn after() void {}
        \\
    ;
    const got = try apply(testing.allocator, original, zig_0_15_2[0]);
    defer testing.allocator.free(got);
    try testing.expect(std.mem.indexOf(u8, got, "use_vectors") == null);
    try testing.expect(std.mem.indexOf(u8, got, "backport of Zig 0.16.0") != null);
    try testing.expect(std.mem.startsWith(u8, got, "pub fn before() void {}\n\npub fn indexOfSentinel("));
    try testing.expect(std.mem.endsWith(u8, got, "    return i;\n}\n\npub fn after() void {}\n"));
}

test "a different original is refused, not mis-patched" {
    const changed =
        \\pub fn indexOfSentinel(comptime T: type, comptime sentinel: T, p: [*:sentinel]const T) usize {
        \\    return 0;
        \\}
        \\
    ;
    try testing.expectError(Error.PatchUnexpectedOriginal, apply(testing.allocator, changed, zig_0_15_2[0]));
    try testing.expectError(Error.PatchStartNotFound, apply(testing.allocator, "pub fn other() void {}\n", zig_0_15_2[0]));
}

test "only 0.15.2 has patches; 0.16.0 is fixed upstream" {
    try testing.expectEqual(@as(usize, 1), patchesFor("0.15.2").len);
    try testing.expectEqual(@as(usize, 0), patchesFor("0.16.0").len);
}
