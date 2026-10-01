const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;

    // Zig has no flag-parsing stdlib; flags are parsed manually.
    // Defaults
    var word: []const u8 = "foo";
    var numb: i64 = 42;
    var fork: bool = false;
    var svar: []const u8 = "bar";
    var tail_start: usize = 0;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.startsWith(u8, arg, "-word=")) {
            word = arg["-word=".len..];
        } else if (std.mem.startsWith(u8, arg, "-numb=")) {
            numb = try std.fmt.parseInt(i64, arg["-numb=".len..], 10);
        } else if (std.mem.eql(u8, arg, "-fork")) {
            fork = true;
        } else if (std.mem.startsWith(u8, arg, "-fork=")) {
            fork = std.mem.eql(u8, arg["-fork=".len..], "true");
        } else if (std.mem.startsWith(u8, arg, "-svar=")) {
            svar = arg["-svar=".len..];
        } else {
            // First non-flag argument marks the start of positional args
            tail_start = i;
            break;
        }
    }

    try stdout.print("word: {s}\n", .{word});
    try stdout.print("numb: {d}\n", .{numb});
    try stdout.print("fork: {}\n", .{fork});
    try stdout.print("svar: {s}\n", .{svar});

    // Print tail (positional arguments)
    try stdout.print("tail: [", .{});
    if (tail_start > 0) {
        for (args[tail_start..], 0..) |arg, j| {
            if (j > 0) try stdout.print(" ", .{});
            try stdout.print("{s}", .{arg});
        }
    }
    try stdout.print("]\n", .{});
}
