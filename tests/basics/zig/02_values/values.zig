const std = @import("std");

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    try stdout.print("golang\n", .{});
    try stdout.print("1+1 = {d}\n", .{1 + 1});
    const ratio: f64 = @as(f64, 7.0) / @as(f64, 3.0);
    try stdout.print("7.0/3.0 = {d}\n", .{ratio});
    try stdout.print("{}\n", .{true and false});
    try stdout.print("{}\n", .{true or false});
    try stdout.print("{}\n", .{!true});
}
