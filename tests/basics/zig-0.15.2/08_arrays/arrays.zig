const std = @import("std");

fn printArray(comptime T: type, comptime N: usize, arr: [N]T) !void {
    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;
    try stdout.print("[", .{});
    for (arr, 0..) |v, i| {
        if (i > 0) try stdout.print(" ", .{});
        try stdout.print("{d}", .{v});
    }
    try stdout.print("]", .{});
}

fn printArray2D(comptime T: type, comptime R: usize, comptime C: usize, arr: [R][C]T) !void {
    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;
    try stdout.print("[", .{});
    for (arr, 0..) |row, i| {
        if (i > 0) try stdout.print(" ", .{});
        try printArray(T, C, row);
    }
    try stdout.print("]", .{});
}

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;

    var a = [5]i64{ 0, 0, 0, 0, 0 };
    try stdout.print("emp: ", .{});
    try printArray(i64, 5, a);
    try stdout.print("\n", .{});

    a[4] = 100;
    try stdout.print("set: ", .{});
    try printArray(i64, 5, a);
    try stdout.print("\n", .{});

    try stdout.print("get: {d}\n", .{a[4]});
    try stdout.print("len: {d}\n", .{a.len});

    const b = [5]i64{ 1, 2, 3, 4, 5 };
    try stdout.print("dcl: ", .{});
    try printArray(i64, 5, b);
    try stdout.print("\n", .{});

    var twoD: [2][3]i64 = undefined;
    for (0..2) |i| {
        for (0..3) |j| {
            twoD[i][j] = @intCast(i + j);
        }
    }
    try stdout.print("2d:  ", .{});
    try printArray2D(i64, 2, 3, twoD);
    try stdout.print("\n", .{});
}
