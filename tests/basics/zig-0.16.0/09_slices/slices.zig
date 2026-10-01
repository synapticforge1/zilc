const std = @import("std");

fn printStringSlice(writer: anytype, slice: []const []const u8) !void {
    try writer.print("[", .{});
    for (slice, 0..) |v, i| {
        if (i > 0) try writer.print(" ", .{});
        try writer.print("{s}", .{v});
    }
    try writer.print("]", .{});
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var s = std.array_list.Managed([]const u8).init(allocator);
    defer s.deinit();
    try s.append("");
    try s.append("");
    try s.append("");

    try stdout.print("emp: ", .{});
    try printStringSlice(stdout, s.items);
    try stdout.print("\n", .{});

    s.items[0] = "a";
    s.items[1] = "b";
    s.items[2] = "c";
    try stdout.print("set: ", .{});
    try printStringSlice(stdout, s.items);
    try stdout.print("\n", .{});

    try stdout.print("get: {s}\n", .{s.items[2]});
    try stdout.print("len: {d}\n", .{s.items.len});

    try s.append("d");
    try s.append("e");
    try s.append("f");
    try stdout.print("apd: ", .{});
    try printStringSlice(stdout, s.items);
    try stdout.print("\n", .{});

    var c = std.array_list.Managed([]const u8).init(allocator);
    defer c.deinit();
    try c.appendSlice(s.items);
    try stdout.print("cpy: ", .{});
    try printStringSlice(stdout, c.items);
    try stdout.print("\n", .{});

    try stdout.print("sl1: ", .{});
    try printStringSlice(stdout, s.items[2..5]);
    try stdout.print("\n", .{});

    try stdout.print("sl2: ", .{});
    try printStringSlice(stdout, s.items[0..5]);
    try stdout.print("\n", .{});

    try stdout.print("sl3: ", .{});
    try printStringSlice(stdout, s.items[2..]);
    try stdout.print("\n", .{});

    const t_arr = [_][]const u8{ "g", "h", "i" };
    try stdout.print("dcl: ", .{});
    try printStringSlice(stdout, &t_arr);
    try stdout.print("\n", .{});

    // 2d: [[0] [1 2] [2 3 4]]
    var twoD: [3][]i64 = undefined;
    defer {
        for (twoD) |inner| allocator.free(inner);
    }
    for (0..3) |i| {
        const innerLen = i + 1;
        twoD[i] = try allocator.alloc(i64, innerLen);
        for (0..innerLen) |j| {
            twoD[i][j] = @intCast(i + j);
        }
    }

    try stdout.print("2d:  [", .{});
    for (twoD, 0..) |row, i| {
        if (i > 0) try stdout.print(" ", .{});
        try stdout.print("[", .{});
        for (row, 0..) |v, j| {
            if (j > 0) try stdout.print(" ", .{});
            try stdout.print("{d}", .{v});
        }
        try stdout.print("]", .{});
    }
    try stdout.print("]\n", .{});
}
