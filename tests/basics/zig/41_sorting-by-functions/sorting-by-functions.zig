// Sort strings by length using a custom comparator with std.sort.block.

const std = @import("std");

fn byLength(_: void, a: []const u8, b: []const u8) bool {
    return a.len < b.len;
}

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    var fruits = [_][]const u8{ "peach", "banana", "kiwi" };
    std.sort.block([]const u8, &fruits, {}, byLength);

    try stdout.print("[{s} {s} {s}]\n", .{ fruits[0], fruits[1], fruits[2] });
}
