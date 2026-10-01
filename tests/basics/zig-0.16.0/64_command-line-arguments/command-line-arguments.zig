const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    // argsAlloc returns all arguments including the program name
    // zilc: 0.16 removed std.process.argsAlloc/argsFree; main's Init carries the args, and
    // toSlice allocates them in the process arena, which is freed at exit (so the allocator
    // this example set up only for the args is gone).
    const args = try init.minimal.args.toSlice(init.arena.allocator());

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
