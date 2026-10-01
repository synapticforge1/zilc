const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;

    // argsAlloc returns all arguments including the program name
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Print all args including the program name
    try stdout.print("[", .{});
    for (args, 0..) |arg, i| {
        if (i > 0) try stdout.print(" ", .{});
        try stdout.print("{s}", .{arg});
    }
    try stdout.print("]\n", .{});

    // Print args without the program name
    try stdout.print("[", .{});
    for (args[1..], 0..) |arg, i| {
        if (i > 0) try stdout.print(" ", .{});
        try stdout.print("{s}", .{arg});
    }
    try stdout.print("]\n", .{});

    // Print the third argument (index 3 in full args, index 2 without prog)
    if (args.len > 3) {
        try stdout.print("{s}\n", .{args[3]});
    }
}
