const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    // Zig has no text-template stdlib; string formatting is used instead.

    // Equivalent of template "Value: {{.}}\n" executed with different values
    try stdout.print("Value: {s}\n", .{"some text"});
    try stdout.print("Value: {d}\n", .{5});
    // Slice formatted as [Go Rust C++ C#]
    const items = [_][]const u8{ "Go", "Rust", "C++", "C#" };
    try stdout.print("Value: [", .{});
    for (items, 0..) |item, i| {
        if (i > 0) try stdout.print(" ", .{});
        try stdout.print("{s}", .{item});
    }
    try stdout.print("]\n", .{});

    // Equivalent of template "Name: {{.Name}}\n" with struct
    const Person = struct { name: []const u8 };
    const p1 = Person{ .name = "Jane Doe" };
    try stdout.print("Name: {s}\n", .{p1.name});

    // Same with a map-like approach
    const p2_name = "Mickey Mouse";
    try stdout.print("Name: {s}\n", .{p2_name});

    // if/else conditional template equivalent
    const not_empty: []const u8 = "not empty";
    if (not_empty.len > 0) {
        try stdout.print("yes \n", .{});
    } else {
        try stdout.print("no \n", .{});
    }
    const empty: []const u8 = "";
    if (empty.len > 0) {
        try stdout.print("yes \n", .{});
    } else {
        try stdout.print("no \n", .{});
    }

    // range equivalent
    try stdout.print("Range: ", .{});
    for (items) |item| {
        try stdout.print("{s} ", .{item});
    }
    try stdout.print("\n", .{});
}
