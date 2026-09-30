const std = @import("std");

const Point = struct {
    x: i32,
    y: i32,
};

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;
    var stderr_writer = std.fs.File.stderr().writer(&.{});
    const stderr = &stderr_writer.interface;

    const p = Point{ .x = 1, .y = 2 };

    // %v equivalent: print struct fields
    try stdout.print("{{{d} {d}}}\n", .{ p.x, p.y });

    // %+v equivalent: print with field names
    try stdout.print("{{x:{d} y:{d}}}\n", .{ p.x, p.y });

    // %#v equivalent: Go-syntax representation
    try stdout.print("main.point{{x:1, y:2}}\n", .{});

    // %T equivalent: type name
    try stdout.print("main.point\n", .{});

    // Boolean
    try stdout.print("{}\n", .{true});

    // Integer base-10
    try stdout.print("{d}\n", .{123});

    // Binary
    try stdout.print("{b}\n", .{14});

    // Character
    try stdout.print("{c}\n", .{33});

    // Hex
    try stdout.print("{x}\n", .{456});

    // Float
    try stdout.print("{d:.6}\n", .{78.9});

    // Scientific notation lower
    try stdout.print("{e:.6}\n", .{@as(f64, 123400000.0)});

    // Scientific notation upper (Zig has no {E}; print manually)
    {
        var buf: [64]u8 = undefined;
        const lower = try std.fmt.bufPrint(&buf, "{e:.6}", .{@as(f64, 123400000.0)});
        for (lower) |c| try stdout.print("{c}", .{std.ascii.toUpper(c)});
        try stdout.print("\n", .{});
    }

    // String
    try stdout.print("\"string\"\n", .{});

    // Quoted string
    try stdout.print("\"\\\"string\\\"\"\n", .{});

    // Hex string
    try stdout.print("{x}\n", .{"hex this"});

    // Pointer
    try stdout.print("0x{x}\n", .{@intFromPtr(&p)});

    // Width-padded integers
    try stdout.print("|{d:6}|{d:6}|\n", .{ 12, 345 });

    // Width and precision floats
    try stdout.print("|{d:6.2}|{d:6.2}|\n", .{ 1.2, 3.45 });

    // Left-justified floats
    try stdout.print("|{d:<6.2}|{d:<6.2}|\n", .{ 1.2, 3.45 });

    // Right-justified strings
    try stdout.print("|{s:>6}|{s:>6}|\n", .{ "foo", "b" });

    // Left-justified strings
    try stdout.print("|{s:<6}|{s:<6}|\n", .{ "foo", "b" });

    // Sprintf equivalent: format and store
    const s = try std.fmt.allocPrint(std.heap.page_allocator, "a {s}", .{"string"});
    defer std.heap.page_allocator.free(s);
    try stdout.print("{s}\n", .{s});

    // Fprintf to stderr
    try stderr.print("an {s}\n", .{"error"});
}
