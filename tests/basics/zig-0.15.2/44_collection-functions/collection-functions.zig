// Zig lacks native closures; function pointers are used instead.

const std = @import("std");

fn indexOf(vs: []const []const u8, t: []const u8) i32 {
    for (vs, 0..) |v, i| {
        if (std.mem.eql(u8, v, t)) return @intCast(i);
    }
    return -1;
}

fn include(vs: []const []const u8, t: []const u8) bool {
    return indexOf(vs, t) >= 0;
}

fn any(vs: []const []const u8, f: *const fn ([]const u8) bool) bool {
    for (vs) |v| {
        if (f(v)) return true;
    }
    return false;
}

fn all(vs: []const []const u8, f: *const fn ([]const u8) bool) bool {
    for (vs) |v| {
        if (!f(v)) return false;
    }
    return true;
}

fn filter(
    allocator: std.mem.Allocator,
    vs: []const []const u8,
    f: *const fn ([]const u8) bool,
) ![][]const u8 {
    var result = std.array_list.Managed([]const u8).init(allocator);
    for (vs) |v| {
        if (f(v)) try result.append(v);
    }
    return result.toOwnedSlice();
}

fn mapStrings(
    allocator: std.mem.Allocator,
    vs: []const []const u8,
    f: *const fn (std.mem.Allocator, []const u8) anyerror![]u8,
) ![][]u8 {
    var result = try allocator.alloc([]u8, vs.len);
    for (vs, 0..) |v, i| {
        result[i] = try f(allocator, v);
    }
    return result;
}

fn hasPrefix(v: []const u8) bool {
    return std.mem.startsWith(u8, v, "p");
}

fn containsE(v: []const u8) bool {
    return std.mem.indexOf(u8, v, "e") != null;
}

fn toUpper(allocator: std.mem.Allocator, v: []const u8) anyerror![]u8 {
    const result = try allocator.alloc(u8, v.len);
    for (v, 0..) |c, i| {
        result[i] = std.ascii.toUpper(c);
    }
    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;

    const strs = [_][]const u8{ "peach", "apple", "pear", "plum" };

    try stdout.print("{d}\n", .{indexOf(&strs, "pear")});
    try stdout.print("{}\n", .{include(&strs, "grape")});
    try stdout.print("{}\n", .{any(&strs, hasPrefix)});
    try stdout.print("{}\n", .{all(&strs, hasPrefix)});

    const filtered = try filter(allocator, &strs, containsE);
    defer allocator.free(filtered);
    try stdout.print("[", .{});
    for (filtered, 0..) |s, i| {
        if (i > 0) try stdout.print(" ", .{});
        try stdout.print("{s}", .{s});
    }
    try stdout.print("]\n", .{});

    const mapped = try mapStrings(allocator, &strs, toUpper);
    defer {
        for (mapped) |s| allocator.free(s);
        allocator.free(mapped);
    }
    try stdout.print("[", .{});
    for (mapped, 0..) |s, i| {
        if (i > 0) try stdout.print(" ", .{});
        try stdout.print("{s}", .{s});
    }
    try stdout.print("]\n", .{});
}
