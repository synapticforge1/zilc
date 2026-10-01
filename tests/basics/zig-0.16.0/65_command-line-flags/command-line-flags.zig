const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    // Zig has no flag-parsing stdlib; flags are parsed manually.
    // Defaults
    var word: []const u8 = "foo";
    var numb: i64 = 42;
    var fork: bool = false;
    var svar: []const u8 = "bar";
    var tail_start: usize = 0;

    // zilc: 0.16 removed std.process.argsAlloc/argsFree; main's Init carries the args, and
    // toSlice allocates them in the process arena, which is freed at exit (so the allocator
    // this example set up only for the args is gone).
    const args = try init.minimal.args.toSlice(init.arena.allocator());

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
