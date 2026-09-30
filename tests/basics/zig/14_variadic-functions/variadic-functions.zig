const std = @import("std");

fn sum(nums: []const i64) !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
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

pub fn main() !void {
    try sum(&[_]i64{ 1, 2 });
    try sum(&[_]i64{ 1, 2, 3 });
    const nums = [_]i64{ 1, 2, 3, 4 };
    try sum(&nums);
}
