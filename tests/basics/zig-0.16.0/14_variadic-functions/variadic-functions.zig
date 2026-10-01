const std = @import("std");

// zilc: 0.16 stdout needs an Io, so sum, which opens its own writer, takes one.
fn sum(io: std.Io, nums: []const i64) !void {
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;
    try stdout.print("[", .{});
    for (nums, 0..) |n, i| {
        if (i > 0) try stdout.print(" ", .{});
        try stdout.print("{d}", .{n});
    }
    try stdout.print("] ", .{});
    var total: i64 = 0;
    for (nums) |n| total += n;
    try stdout.print("{d}\n", .{total});
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    try sum(io, &[_]i64{ 1, 2 });
    try sum(io, &[_]i64{ 1, 2, 3 });
    const nums = [_]i64{ 1, 2, 3, 4 };
    try sum(io, &nums);
}
