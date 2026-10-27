// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! Builds the toolchain for `zig build gate-zig-modules`: a copy of zilc's Fil-C tree in which
//! Fil-C's runtime modules are swapped for pure-Zig builds of the same modules (owner,
//! 2026-10-27: "when we have a pure zig build of those changes we run the same build by just
//! swapping out the fil-c specific modules with the pure zig modules").
//!
//!   swap-modules <fil-c clang> <modules dir> <declared Fil-C release> <out dir>
//!
//! A module is a file in `<modules dir>/lib/` with the same name as a file in the tree's
//! `pizfix/lib/` (`libyoloc.a`, `libyolort.a`, `crt1.o`, `filc_crt.o`, `libpizlo.a`, …). Each one
//! found replaces Fil-C's in the copy; every other module stays Fil-C's, and the table printed
//! says which is which, so no run can claim "pure Zig" while quietly linking Fil-C.
//!
//! ⚠️ Swapped is not the same as USED: Fil-C's clang links dynamically by default, so `-lc`,
//! `-lpizlo`, `-lyoloc` resolve to the tree's `.so` files and a swapped `libyoloc.a` would change
//! nothing. The tool therefore asks the copy's own clang for its link line (`clang -###` on a
//! one-line C program, the link zilc's driver hands to it) and marks each module LINKED or not.
//!
//! ⚠️ Refuses (exit 1) rather than mixing what it cannot vouch for:
//!   * the declared release must equal the one the tree's own `clang --version` names, because
//!     modules built from another release's sources would be compared against the wrong oracle;
//!   * at least one swapped module must be LINKED, or the run would be the plain gate under a new
//!     name.
//!
//! Prints the copy's clang on its last line; build.zig points the gate at it.

const std = @import("std");

fn fail(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print("gate-zig-modules: " ++ fmt ++ "\n", args);
    std.process.exit(1);
}

/// "Fil-C 0.687" in `clang --version` → "0.687".
fn filcRelease(gpa: std.mem.Allocator, clang: []const u8) ![]const u8 {
    const res = std.process.Child.run(.{ .allocator = gpa, .argv = &.{ clang, "--version" } }) catch |e|
        fail("cannot run {s} --version: {s}", .{ clang, @errorName(e) });
    const at = std.mem.indexOf(u8, res.stdout, "Fil-C ") orelse
        fail("{s} is not Fil-C's clang (its --version names no Fil-C release)", .{clang});
    const rest = res.stdout[at + "Fil-C ".len ..];
    const end = std.mem.indexOfAny(u8, rest, " )\n") orelse rest.len;
    return try gpa.dupe(u8, rest[0..end]);
}

/// The regular files directly in `dir`, sorted.
fn listFiles(gpa: std.mem.Allocator, dir: []const u8) ![][]const u8 {
    var d = std.fs.cwd().openDir(dir, .{ .iterate = true }) catch |e|
        fail("cannot open {s}: {s}", .{ dir, @errorName(e) });
    defer d.close();
    var names: std.ArrayListUnmanaged([]const u8) = .{};
    var it = d.iterate();
    while (try it.next()) |entry| {
        if (entry.kind == .file) try names.append(gpa, try gpa.dupe(u8, entry.name));
    }
    std.mem.sort([]const u8, names.items, {}, struct {
        fn lt(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lt);
    return names.items;
}

fn contains(list: []const []const u8, name: []const u8) bool {
    for (list) |n| if (std.mem.eql(u8, n, name)) return true;
    return false;
}

/// The link command `clang` would run for a one-line C program: its last `-###` line naming
/// the linker. `dir` is a scratch directory for the input.
fn linkLine(gpa: std.mem.Allocator, clang: []const u8, dir: []const u8) ![]const u8 {
    const c = try std.fs.path.join(gpa, &.{ dir, "probe.c" });
    try std.fs.cwd().writeFile(.{ .sub_path = c, .data = "int main(void) { return 0; }\n" });
    const exe = try std.fs.path.join(gpa, &.{ dir, "probe" });
    const res = try std.process.Child.run(.{ .allocator = gpa, .argv = &.{ clang, "-###", "-O2", c, "-o", exe } });
    var last: []const u8 = "";
    var it = std.mem.splitScalar(u8, res.stderr, '\n');
    while (it.next()) |line| {
        if (std.mem.indexOf(u8, line, "ld\"") != null or std.mem.indexOf(u8, line, "/ld ") != null or
            std.mem.indexOf(u8, line, "-dynamic-linker") != null) last = line;
    }
    if (last.len == 0) fail("{s} -### printed no link command:\n{s}", .{ clang, res.stderr });
    return last;
}

/// Whether the link line pulls in `pizfix/lib/<name>`: named by path (crt objects), or through
/// `-l<x>` for `lib<x>.a` when no `lib<x>.so` sits beside it (a dynamic link prefers the `.so`).
fn linked(line: []const u8, name: []const u8, fil_names: []const []const u8) bool {
    var buf: [256]u8 = undefined;
    const by_path = std.fmt.bufPrint(&buf, "/{s}\"", .{name}) catch return false;
    if (std.mem.indexOf(u8, line, by_path) != null) return true;
    if (std.mem.startsWith(u8, name, "lib") and std.mem.endsWith(u8, name, ".a")) {
        const stem = name[3 .. name.len - 2];
        var fbuf: [256]u8 = undefined;
        const flag = std.fmt.bufPrint(&fbuf, "\"-l{s}\"", .{stem}) catch return false;
        if (std.mem.indexOf(u8, line, flag) == null) return false;
        var sbuf: [256]u8 = undefined;
        const so = std.fmt.bufPrint(&sbuf, "lib{s}.so", .{stem}) catch return false;
        const static = std.mem.indexOf(u8, line, "\"-static\"") != null;
        return static or !contains(fil_names, so);
    }
    // `lib<x>.so` through `-l<x>` in a dynamic link (the `.so` wins over the `.a`). libyoloc.so is
    // also the dynamic loader (ld-fil1-x86_64.so links to it), so it is used even without `-lyoloc`.
    if (std.mem.startsWith(u8, name, "lib") and std.mem.endsWith(u8, name, ".so")) {
        if (std.mem.indexOf(u8, line, "\"-static\"") != null) return false;
        if (std.mem.eql(u8, name, "libyoloc.so") and std.mem.indexOf(u8, line, "ld-fil1-") != null) return true;
        const stem = name[3 .. name.len - 3];
        var fbuf: [256]u8 = undefined;
        const flag = std.fmt.bufPrint(&fbuf, "\"-l{s}\"", .{stem}) catch return false;
        return std.mem.indexOf(u8, line, flag) != null;
    }
    return false;
}

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena_state.deinit();
    const gpa = arena_state.allocator();

    const args = try std.process.argsAlloc(gpa);
    if (args.len != 5) fail("usage: swap-modules <fil-c clang> <modules dir> <declared Fil-C release> <out dir>", .{});
    const clang = args[1];
    const modules = args[2];
    const declared = args[3];
    const out = args[4];

    // <tree>/build/bin/clang → <tree>
    const tree = std.fs.path.dirname(std.fs.path.dirname(std.fs.path.dirname(clang) orelse ".") orelse ".") orelse ".";
    const release = try filcRelease(gpa, clang);
    if (!std.mem.eql(u8, release, declared))
        fail("the modules are declared as built from Fil-C {s}, but the toolchain is Fil-C {s} ({s}); rebuild them from {s}'s sources or point ZILC_FILC at a {s} toolchain", .{ declared, release, clang, release, declared });

    const fil_lib = try std.fs.path.join(gpa, &.{ tree, "pizfix", "lib" });
    const zig_lib = try std.fs.path.join(gpa, &.{ modules, "lib" });
    const fil_names = try listFiles(gpa, fil_lib);
    const zig_names = try listFiles(gpa, zig_lib);

    var swapped: usize = 0;
    for (zig_names) |n| {
        if (contains(fil_names, n)) swapped += 1;
    }
    if (swapped == 0)
        fail("no module in {s} has the name of one of Fil-C's ({s}); nothing to swap, so this would be the plain gate", .{ zig_lib, fil_lib });

    // The copy: the whole tree (the driver finds pizfix relative to clang), then the swaps.
    const copy = try std.fs.path.join(gpa, &.{ out, try std.fmt.allocPrint(gpa, "filc-{s}-zig-modules", .{release}) });
    try std.fs.cwd().makePath(out);
    std.fs.cwd().deleteTree(copy) catch {};
    const cp = try std.process.Child.run(.{ .allocator = gpa, .argv = &.{ "cp", "-a", tree, copy } });
    if (cp.term != .Exited or cp.term.Exited != 0) fail("cp -a {s} {s} failed: {s}", .{ tree, copy, cp.stderr });

    const copy_lib = try std.fs.path.join(gpa, &.{ copy, "pizfix", "lib" });
    var record: std.ArrayListUnmanaged(u8) = .{};
    try record.print(gpa, "Fil-C {s} toolchain {s}\npure-Zig modules from {s}\n\n", .{ release, tree, zig_lib });

    const copy_clang = try std.fs.path.join(gpa, &.{ copy, "build", "bin", "clang" });
    const link = try linkLine(gpa, copy_clang, out);
    try record.print(gpa, "default link line (clang -###, a one-line C program):\n{s}\n\n", .{link});

    std.debug.print("gate-zig-modules: Fil-C {s}; modules from {s}\n", .{ release, zig_lib });
    var used_zig: usize = 0;
    for (fil_names) |n| {
        const from_zig = contains(zig_names, n);
        if (from_zig) {
            const src = try std.fs.path.join(gpa, &.{ zig_lib, n });
            const dst = try std.fs.path.join(gpa, &.{ copy_lib, n });
            try std.fs.cwd().copyFile(src, std.fs.cwd(), dst, .{});
        }
        const in_link = linked(link, n, fil_names);
        if (from_zig and in_link) used_zig += 1;
        const what = if (from_zig and in_link) "PURE ZIG, linked" else if (from_zig) "pure Zig, but NOT in the default link" else if (in_link) "Fil-C's, linked" else "Fil-C's";
        const line = try std.fmt.allocPrint(gpa, "  {s:<28} {s}\n", .{ n, what });
        std.debug.print("{s}", .{line});
        try record.appendSlice(gpa, line);
    }
    for (zig_names) |n| {
        if (!contains(fil_names, n)) {
            const line = try std.fmt.allocPrint(gpa, "  {s:<28} ignored: Fil-C has no module of that name\n", .{n});
            std.debug.print("{s}", .{line});
            try record.appendSlice(gpa, line);
        }
    }
    const summary = try std.fmt.allocPrint(gpa, "{d} of {d} modules swapped for pure Zig; {d} of those are in the default link\n", .{ swapped, fil_names.len, used_zig });
    std.debug.print("gate-zig-modules: {s}", .{summary});
    try record.print(gpa, "\n{s}", .{summary});
    const record_path = try std.fs.path.join(gpa, &.{ copy, "ZIG-MODULES.txt" });
    try std.fs.cwd().writeFile(.{ .sub_path = record_path, .data = record.items });
    if (used_zig == 0)
        fail("none of the swapped modules is in the default link, so the gate would test only Fil-C's runtime (see {s})", .{record_path});

    std.debug.print("{s}/build/bin/clang\n", .{copy});
}
