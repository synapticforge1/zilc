const std = @import("std");

fn strLessThan(_: void, a: []const u8, b: []const u8) bool {
    return std.mem.lessThan(u8, a, b);
}

fn intLessThan(_: void, a: i32, b: i32) bool {
    return a < b;
}

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;

    // Sort strings in-place.
    var strs = [_][]const u8{ "c", "a", "b" };
    std.sort.block([]const u8, &strs, {}, strLessThan);
    try stdout.print("Strings: [{s} {s} {s}]\n", .{ strs[0], strs[1], strs[2] });

    // Sort ints in-place.
    var ints = [_]i32{ 7, 2, 4 };
    std.sort.block(i32, &ints, {}, intLessThan);
    try stdout.print("Ints:    [{d} {d} {d}]\n", .{ ints[0], ints[1], ints[2] });

    // Check if already sorted.
    const sorted = std.sort.isSorted(i32, &ints, {}, intLessThan);
    try stdout.print("Sorted:  {}\n", .{sorted});
}
