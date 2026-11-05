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

fn fail(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print("archive-rename: " ++ fmt ++ "\n", args);
    std.process.exit(1);
}

const Member = struct { name: []const u8, data: []const u8, used: bool = false };

/// The members of a System V / GNU archive, in order, without its symbol tables.
fn readArchive(gpa: std.mem.Allocator, bytes: []const u8) ![]Member {
    if (!std.mem.startsWith(u8, bytes, "!<arch>\n")) fail("not an ar archive", .{});
    var out: std.ArrayListUnmanaged(Member) = .{};
    var long_names: []const u8 = "";
    var at: usize = 8;
    while (at + 60 <= bytes.len) {
        const h = bytes[at .. at + 60];
        if (!std.mem.eql(u8, h[58..60], "`\n")) fail("bad member header at {d}", .{at});
        const raw = std.mem.trimRight(u8, h[0..16], " ");
        const size = try std.fmt.parseInt(usize, std.mem.trim(u8, h[48..58], " "), 10);
        const data = bytes[at + 60 .. at + 60 + size];
        at += 60 + size + (size % 2);
        if (std.mem.eql(u8, raw, "/") or std.mem.eql(u8, raw, "/SYM64/")) continue;
        if (std.mem.eql(u8, raw, "//")) {
            long_names = data;
            continue;
        }
        var name = raw;
        if (raw.len > 1 and raw[0] == '/' and std.ascii.isDigit(raw[1])) {
            const off = try std.fmt.parseInt(usize, raw[1..], 10);
            const end = std.mem.indexOfScalarPos(u8, long_names, off, '\n') orelse long_names.len;
            name = long_names[off..end];
        }
        try out.append(gpa, .{ .name = std.mem.trimRight(u8, name, "/"), .data = data });
    }
    return out.items;
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
    const members = try readArchive(gpa, try std.fs.cwd().readFileAlloc(gpa, args[2], 1 << 30));
    const out = args[3];

    // One directory per member, so repeated names do not collide on disk.
    const tmp = try std.fmt.allocPrint(gpa, "{s}.members", .{out});
    std.fs.cwd().deleteTree(tmp) catch {};
    var ar_argv: std.ArrayListUnmanaged([]const u8) = .{};
    try ar_argv.appendSlice(gpa, &.{ zig, "ar", "qc", out });
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
    std.fs.cwd().deleteFile(out) catch {};
    try run(gpa, ar_argv.items);
    try run(gpa, &.{ zig, "ranlib", out });
    std.fs.cwd().deleteTree(tmp) catch {};
}
