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
    /// An exact replacement's original text occurs a different number of times than expected.
    PatchUnexpectedCount,
};

/// Bump when any patch changes, so stale overlays are rebuilt.
pub const overlay_version = 3;

pub const Patch = struct {
    /// Path relative to the Zig lib directory.
    file: []const u8,
    edit: union(enum) {
        /// From an exact first line to the next `}` at column 0: a whole top-level function.
        region: struct {
            start: []const u8,
            /// Text that must appear in the region, proving it is the original we expect.
            must_contain: []const u8,
            /// What the whole region becomes.
            replacement: []const u8,
        },
        /// Exact text, which must occur exactly `count` times; every occurrence is replaced.
        replace: struct {
            old: []const u8,
            new: []const u8,
            count: usize,
        },
    },
};

/// Zig 0.15.2: `indexOfSentinel` scans with 16-byte SIMD loads that read past the
/// end of the string's object, which Fil-C rejects as an out-of-bounds read.
/// Upstream fixed it in 0.16.0 by deleting the vector branch, leaving the scalar
/// loop; this replacement is that 0.16.0 function body, under the 0.15.2 name.
/// Zig std is MIT-licensed; ledger entry in third_party/LICENSES.md.
const zig_0_15_2 = [_]Patch{
    .{ .file = "std/mem.zig", .edit = .{ .region = .{
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
    } } },

    // DebugAllocator (KI-13, zig-upstream-notes.md Z-5). NOT a backport: 0.16.0 has the
    // same code. `BucketHeader.fromPage` receives the page ADDRESS as an integer and
    // turns it into a pointer. Under Fil-C an integer that arrives as a parameter has
    // no capability, so the bucket header pointer is dead and the first write traps.
    // Passing the page POINTER instead keeps every int->ptr round trip inside one
    // function, where Fil-C recovers the capability. Addresses are computed exactly
    // as before.
    .{ .file = "std/heap/debug_allocator.zig", .edit = .{ .replace = .{
        .old =
        \\            fn fromPage(page_addr: usize, slot_count: usize) *BucketHeader {
        \\                const unaligned = page_addr + page_size - bucketSize(slot_count);
        ,
        .new =
        \\            // zilc: takes the page POINTER, not its address, so the int->ptr round trip
        \\            // stays inside one function and Fil-C keeps the page's capability (Z-5).
        \\            fn fromPage(page: [*]align(page_size) u8, slot_count: usize) *BucketHeader {
        \\                const unaligned = @intFromPtr(page) + page_size - bucketSize(slot_count);
        ,
        .count = 1,
    } } },
    .{ .file = "std/heap/debug_allocator.zig", .edit = .{ .replace = .{
        // alloc: `page` is already a pointer.
        .old = "const bucket: *BucketHeader = .fromPage(@intFromPtr(page), slot_count);",
        .new = "const bucket: *BucketHeader = .fromPage(@alignCast(page), slot_count); // zilc: Z-5",
        .count = 1,
    } } },
    // Native stack walking (KI-15, zig-upstream-notes.md Z-8; owner chose this option).
    // In Debug, DebugAllocator captures a stack trace on every alloc/free by walking raw
    // frame pointers and probing them with process_vm_readv, which Fil-C stops ("unsupported
    // syscall: 310"). Turning saved frame-pointer integers into pointers can never be safe
    // under Fil-C. So std is told the truth: native stack walking is unavailable. Its users
    // (DebugAllocator's default frames, the testing allocators, the build system) then take
    // their existing 0-frame branch. Fil-C prints its own trace, with file:line, for every
    // safety stop, and panics go through zerror. The original switch is kept, renamed.
    .{ .file = "std/debug.zig", .edit = .{ .replace = .{
        .old = "pub const sys_can_stack_trace = switch (builtin.cpu.arch) {",
        .new =
        \\// zilc: native stack walking is unavailable under Fil-C (KI-15); the original follows, renamed.
        \\pub const sys_can_stack_trace = false;
        \\pub const zilc_native_sys_can_stack_trace = switch (builtin.cpu.arch) {
        ,
        .count = 1,
    } } },
    .{ .file = "std/heap/debug_allocator.zig", .edit = .{ .replace = .{
        // free and resizeSmall: page_addr comes from @intFromPtr(memory.ptr) in the SAME
        // function, so @ptrFromInt here recovers that pointer's capability.
        .old = "const bucket: *BucketHeader = .fromPage(page_addr, slot_count);",
        .new = "const bucket: *BucketHeader = .fromPage(@ptrFromInt(page_addr), slot_count); // zilc: Z-5",
        .count = 2,
    } } },
};

/// The patches for one Zig version (from `zig env`'s `.version`); empty if none.
pub fn patchesFor(zig_version: []const u8) []const Patch {
    if (std.mem.eql(u8, zig_version, "0.15.2")) return &zig_0_15_2;
    return &.{};
}

/// Returns `original` with the patch applied. The caller owns the result.
pub fn apply(gpa: std.mem.Allocator, original: []const u8, patch: Patch) ![]u8 {
    switch (patch.edit) {
        .region => |r| {
            const start = std.mem.indexOf(u8, original, r.start) orelse return Error.PatchStartNotFound;
            if (start != 0 and original[start - 1] != '\n') return Error.PatchStartNotFound;
            const close = "\n}\n";
            const close_at = std.mem.indexOfPos(u8, original, start, close) orelse return Error.PatchEndNotFound;
            const end = close_at + close.len - 1; // keep the newline after `}`
            if (std.mem.indexOf(u8, original[start..end], r.must_contain) == null) return Error.PatchUnexpectedOriginal;
            return std.mem.concat(gpa, u8, &.{ original[0..start], r.replacement, original[end..] });
        },
        .replace => |r| {
            if (std.mem.count(u8, original, r.old) != r.count) return Error.PatchUnexpectedCount;
            return std.mem.replaceOwned(u8, gpa, original, r.old, r.new);
        },
    }
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

test "only 0.15.2 has patches so far" {
    try testing.expectEqual(@as(usize, 5), patchesFor("0.15.2").len);
    // ⚠️ 0.16.0 fixed Z-1 upstream but NOT Z-5: a 0.16 line needs the DebugAllocator patch.
    try testing.expectEqual(@as(usize, 0), patchesFor("0.16.0").len);
}

test "the stack-trace patch keeps the original switch, renamed" {
    const src =
        \\pub const sys_can_stack_trace = switch (builtin.cpu.arch) {
        \\    .wasm32 => false,
        \\    else => true,
        \\};
        \\
    ;
    for (zig_0_15_2) |p| {
        if (!std.mem.eql(u8, p.file, "std/debug.zig")) continue;
        const got = try apply(testing.allocator, src, p);
        defer testing.allocator.free(got);
        try testing.expect(std.mem.indexOf(u8, got, "pub const sys_can_stack_trace = false;\n") != null);
        try testing.expect(std.mem.indexOf(u8, got, "pub const zilc_native_sys_can_stack_trace = switch (builtin.cpu.arch) {") != null);
        try testing.expect(std.mem.indexOf(u8, got, "    else => true,") != null);
    }
}

test "an exact replacement checks its occurrence count" {
    const p: Patch = .{ .file = "x", .edit = .{ .replace = .{ .old = "a", .new = "b", .count = 2 } } };
    const got = try apply(testing.allocator, "a-a", p);
    defer testing.allocator.free(got);
    try testing.expectEqualStrings("b-b", got);
    try testing.expectError(Error.PatchUnexpectedCount, apply(testing.allocator, "a", p));
    try testing.expectError(Error.PatchUnexpectedCount, apply(testing.allocator, "a-a-a", p));
}

test "the DebugAllocator patches match the real call-site shapes" {
    const src =
        \\            fn fromPage(page_addr: usize, slot_count: usize) *BucketHeader {
        \\                const unaligned = page_addr + page_size - bucketSize(slot_count);
        \\            const bucket: *BucketHeader = .fromPage(@intFromPtr(page), slot_count);
        \\            const bucket: *BucketHeader = .fromPage(page_addr, slot_count);
        \\            const bucket: *BucketHeader = .fromPage(page_addr, slot_count);
        \\
    ;
    var cur = try testing.allocator.dupe(u8, src);
    for (zig_0_15_2) |p| {
        if (!std.mem.eql(u8, p.file, "std/heap/debug_allocator.zig")) continue;
        const next = try apply(testing.allocator, cur, p);
        testing.allocator.free(cur);
        cur = next;
    }
    defer testing.allocator.free(cur);
    try testing.expect(std.mem.indexOf(u8, cur, "fn fromPage(page: [*]align(page_size) u8, slot_count: usize)") != null);
    try testing.expect(std.mem.indexOf(u8, cur, "@intFromPtr(page) + page_size") != null);
    try testing.expect(std.mem.indexOf(u8, cur, ".fromPage(@alignCast(page), slot_count)") != null);
    try testing.expectEqual(@as(usize, 2), std.mem.count(u8, cur, ".fromPage(@ptrFromInt(page_addr), slot_count)"));
    try testing.expect(std.mem.indexOf(u8, cur, "fromPage(page_addr, ") == null);
}
