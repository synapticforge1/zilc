// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! Rewrites a static library Zig made with upstream's member NAMES and ORDER (2026-11-04; owner:
//! "fix the two new items"; cmem/toolchain-quirks.md Z-b-8). Zig's archiver names each member by
//! the object's full cache path (`/home/<user>/.cache/…/o/<hash>/aio.o`): not reproducible across
//! machines, a home path inside the archive, and not upstream's `aio.lo` / `absvdi2.c.o` /
//! `pas-pizlo-release-x.o`. Linkers ignore member names, so this changes no link.
//!
//!   archive-rename <zig exe> <in.a> <out.a> <stem>=<name> ...
//!
//! Each `<stem>=<name>` is one member of the output, in output order. A member of <in.a> is matched
//! by its stem (base name without `.o`); repeated stems (musl's two clone.lo, free.lo, realloc.lo)
//! are taken in their input order. Every input member must be used exactly once, or it stops. The
//! output is written by `zig ar q` (append: `r` would REPLACE a repeated name and lose a member) and
//! indexed by `zig ranlib`; both are LLVM's, deterministic (no timestamps, owners or modes).

const std = @import("std");

/// The member folder of this run, removed by `fail` too (review 1, H8: it was left behind).
var cleanup_dir: ?[]const u8 = null;
/// The output's temporary name, removed by `fail` (the old output is never touched before the end).
var cleanup_file: ?[]const u8 = null;

fn fail(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print("archive-rename: " ++ fmt ++ "\n", args);
    if (cleanup_dir) |d| std.fs.cwd().deleteTree(d) catch {};
    if (cleanup_file) |f| std.fs.cwd().deleteFile(f) catch {};
    std.process.exit(1);
}

const Member = struct { name: []const u8, data: []const u8, used: bool = false };

/// Why `readArchive` refused (valid after `error.BadArchive`).
var bad_why: [128]u8 = undefined;
var bad_len: usize = 0;
fn bad(comptime fmt: []const u8, args: anytype) error{BadArchive} {
    bad_len = (std.fmt.bufPrint(&bad_why, fmt, args) catch &bad_why).len;
    return error.BadArchive;
}

/// The members of a System V / GNU archive, in order, without its symbol tables. A malformed,
/// truncated or oversized archive is refused with where and why, never a panic or a silently
/// short list (review 1, H7).
fn readArchive(gpa: std.mem.Allocator, bytes: []const u8) error{ BadArchive, OutOfMemory }![]Member {
    if (!std.mem.startsWith(u8, bytes, "!<arch>\n")) return bad("not an ar archive", .{});
    var out: std.ArrayListUnmanaged(Member) = .{};
    var long_names: []const u8 = "";
    var at: usize = 8;
    while (at < bytes.len) {
        if (bytes.len - at < 60) return bad("truncated member header at {d}", .{at});
        const h = bytes[at .. at + 60];
        if (!std.mem.eql(u8, h[58..60], "`\n")) return bad("bad member header at {d}", .{at});
        const raw = std.mem.trimRight(u8, h[0..16], " ");
        const size = std.fmt.parseInt(usize, std.mem.trim(u8, h[48..58], " "), 10) catch return bad("bad member size at {d}", .{at});
        if (size > bytes.len - at - 60) return bad("member at {d} claims {d} bytes, {d} remain", .{ at, size, bytes.len - at - 60 });
        const data = bytes[at + 60 .. at + 60 + size];
        at += 60 + size + (size % 2);
        if (std.mem.eql(u8, raw, "/") or std.mem.eql(u8, raw, "/SYM64/")) continue;
        if (std.mem.eql(u8, raw, "//")) {
            long_names = data;
            continue;
        }
        var name = raw;
        if (raw.len > 1 and raw[0] == '/' and std.ascii.isDigit(raw[1])) {
            const off = std.fmt.parseInt(usize, raw[1..], 10) catch return bad("bad long-name offset {s}", .{raw});
            if (off >= long_names.len) return bad("long-name offset {d} past the name table ({d} bytes)", .{ off, long_names.len });
            const end = std.mem.indexOfScalarPos(u8, long_names, off, '\n') orelse long_names.len;
            name = long_names[off..end];
        }
        try out.append(gpa, .{ .name = std.mem.trimRight(u8, name, "/"), .data = data });
    }
    return out.items;
}

test "a malformed archive is refused, never a panic or a short list (review 1, H7)" {
    var arena_state: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena_state.deinit();
    const a = arena_state.allocator();
    const hdr = struct {
        fn make(alloc: std.mem.Allocator, name: []const u8, size: []const u8) ![]u8 {
            const h = try alloc.alloc(u8, 60);
            @memset(h, ' ');
            @memcpy(h[0..name.len], name);
            @memcpy(h[48 .. 48 + size.len], size);
            @memcpy(h[58..60], "`\n");
            return h;
        }
    };
    const ok = try std.mem.concat(a, u8, &.{ "!<arch>\n", try hdr.make(a, "a.o/", "2"), "xy" });
    try std.testing.expectEqual(@as(usize, 1), (try readArchive(a, ok)).len);
    for ([_][]const u8{
        try std.mem.concat(a, u8, &.{ "!<arch>\n", try hdr.make(a, "a.o/", "999"), "xy" }), // oversized
        ok[0 .. ok.len - 40], // truncated mid-header
        try std.mem.concat(a, u8, &.{ ok, "tail" }), // trailing garbage
        try std.mem.concat(a, u8, &.{ "!<arch>\n", try hdr.make(a, "//", "4"), "a.o\n", try hdr.make(a, "/99999999", "0") }), // bad offset
        try std.mem.concat(a, u8, &.{ "!<arch>\n", try hdr.make(a, "a.o/", "x"), "" }), // bad size
    }) |bytes| try std.testing.expectError(error.BadArchive, readArchive(a, bytes));
}

fn stem(name: []const u8) []const u8 {
    const base = std.fs.path.basename(name);
    return if (std.mem.endsWith(u8, base, ".o")) base[0 .. base.len - 2] else base;
}

fn run(gpa: std.mem.Allocator, argv: []const []const u8) !void {
    var child = std.process.Child.init(argv, gpa);
    const term = try child.spawnAndWait();
    if (term != .Exited or term.Exited != 0) fail("failed: {s}", .{try std.mem.join(gpa, " ", argv[0..@min(argv.len, 4)])});
}

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const gpa = arena_state.allocator();
    const args = try std.process.argsAlloc(gpa);
    if (args.len < 5) fail("usage: archive-rename <zig exe> <in.a> <out.a> <stem>=<name> ...", .{});
    const zig = args[1];
    const bytes = std.fs.cwd().readFileAlloc(gpa, args[2], 1 << 30) catch |e| fail("cannot read {s}: {s}", .{ args[2], @errorName(e) });
    const members = readArchive(gpa, bytes) catch |e| switch (e) {
        error.BadArchive => fail("{s}: {s}", .{ args[2], bad_why[0..bad_len] }),
        error.OutOfMemory => fail("out of memory", .{}),
    };
    const out = args[3];

    // One directory per member, so repeated names do not collide on disk.
    const tmp = try std.fmt.allocPrint(gpa, "{s}.members", .{out});
    std.fs.cwd().deleteTree(tmp) catch {};
    cleanup_dir = tmp;
    // The archive is written under a temporary name and renamed over <out> only when ar and ranlib
    // both succeeded: a failed run leaves the previous <out> as it was (review 1, H8).
    const new = try std.fmt.allocPrint(gpa, "{s}.new", .{out});
    std.fs.cwd().deleteFile(new) catch {};
    cleanup_file = new;
    var ar_argv: std.ArrayListUnmanaged([]const u8) = .{};
    try ar_argv.appendSlice(gpa, &.{ zig, "ar", "qc", new });
    for (args[4..], 0..) |spec, i| {
        const eq = std.mem.indexOfScalar(u8, spec, '=') orelse fail("not <stem>=<name>: {s}", .{spec});
        const want = spec[0..eq];
        const name = spec[eq + 1 ..];
        const m = for (members) |*m| {
            if (!m.used and std.mem.eql(u8, stem(m.name), want)) break m;
        } else fail("{s}: no (unused) member with stem `{s}` for `{s}`", .{ args[2], want, name });
        m.used = true;
        const dir = try std.fmt.allocPrint(gpa, "{s}/{d}", .{ tmp, i });
        try std.fs.cwd().makePath(dir);
        const path = try std.fs.path.join(gpa, &.{ dir, name });
        try std.fs.cwd().writeFile(.{ .sub_path = path, .data = m.data });
        try ar_argv.append(gpa, path);
    }
    for (members) |m| if (!m.used) fail("{s}: member {s} has no name in the list", .{ args[2], m.name });
    run(gpa, ar_argv.items) catch |e| fail("cannot run {s}: {s}", .{ zig, @errorName(e) });
    run(gpa, &.{ zig, "ranlib", new }) catch |e| fail("cannot run {s}: {s}", .{ zig, @errorName(e) });
    std.fs.cwd().rename(new, out) catch |e| fail("cannot rename {s} to {s}: {s}", .{ new, out, @errorName(e) });
    cleanup_file = null;
    std.fs.cwd().deleteTree(tmp) catch {};
}
