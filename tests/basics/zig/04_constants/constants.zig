const std = @import("std");

const s: []const u8 = "constant";

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    try stdout.print("{s}\n", .{s});

    const n: f64 = 500000000;
    const d: f64 = 3e20 / n;
    try stdout.print("{e}\n", .{d});
    try stdout.print("{d}\n", .{@as(i64, @intFromFloat(d))});
    try stdout.print("{d}\n", .{std.math.sin(n)});
}
