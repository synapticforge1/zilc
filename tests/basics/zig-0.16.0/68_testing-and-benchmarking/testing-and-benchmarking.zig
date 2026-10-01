const std = @import("std");

// We'll be testing this simple implementation of an integer minimum.
fn intMin(a: i64, b: i64) i64 {
    if (a < b) {
        return a;
    }
    return b;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    // This file is primarily for testing. Run with: zig test testing-and-benchmarking.zig
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;
    try stdout.print("intMin(2, -2) = {d}\n", .{intMin(2, -2)});
}

test "intMin basic" {
    const ans = intMin(2, -2);
    try std.testing.expectEqual(@as(i64, -2), ans);
}

test "intMin table driven" {
    const TestCase = struct { a: i64, b: i64, want: i64 };
    const tests = [_]TestCase{
        .{ .a = 0, .b = 1, .want = 0 },
        .{ .a = 1, .b = 0, .want = 0 },
        .{ .a = 2, .b = -2, .want = -2 },
        .{ .a = 0, .b = -1, .want = -1 },
        .{ .a = -1, .b = 0, .want = -1 },
    };

    for (tests) |tt| {
        const ans = intMin(tt.a, tt.b);
        try std.testing.expectEqual(tt.want, ans);
    }
}
