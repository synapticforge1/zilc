const std = @import("std");

// zilc: 0.16 stdout needs an Io, so the helpers that open their own writer take one.
fn printArray(io: std.Io, comptime T: type, comptime N: usize, arr: [N]T) !void {
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;
    try stdout.print("[", .{});
    for (arr, 0..) |v, i| {
        if (i > 0) try stdout.print(" ", .{});
        try stdout.print("{d}", .{v});
    }
    try stdout.print("]", .{});
}

fn printArray2D(io: std.Io, comptime T: type, comptime R: usize, comptime C: usize, arr: [R][C]T) !void {
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;
    try stdout.print("[", .{});
    for (arr, 0..) |row, i| {
        if (i > 0) try stdout.print(" ", .{});
        try printArray(io, T, C, row);
    }
    try stdout.print("]", .{});
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    var a = [5]i64{ 0, 0, 0, 0, 0 };
    try stdout.print("emp: ", .{});
    try printArray(io, i64, 5, a);
    try stdout.print("\n", .{});

    a[4] = 100;
    try stdout.print("set: ", .{});
    try printArray(io, i64, 5, a);
    try stdout.print("\n", .{});

    try stdout.print("get: {d}\n", .{a[4]});
    try stdout.print("len: {d}\n", .{a.len});

    const b = [5]i64{ 1, 2, 3, 4, 5 };
    try stdout.print("dcl: ", .{});
    try printArray(io, i64, 5, b);
    try stdout.print("\n", .{});

    var twoD: [2][3]i64 = undefined;
    for (0..2) |i| {
        for (0..3) |j| {
            twoD[i][j] = @intCast(i + j);
        }
    }
    try stdout.print("2d:  ", .{});
    try printArray2D(io, i64, 2, 3, twoD);
    try stdout.print("\n", .{});
}
