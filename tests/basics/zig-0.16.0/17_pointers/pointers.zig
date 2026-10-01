const std = @import("std");

fn zeroval(ival: i64) void {
    _ = ival;
}

fn zeroptr(iptr: *i64) void {
    iptr.* = 0;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    var i: i64 = 1;
    try stdout.print("initial: {d}\n", .{i});

    zeroval(i);
    try stdout.print("zeroval: {d}\n", .{i});

    zeroptr(&i);
    try stdout.print("zeroptr: {d}\n", .{i});

    try stdout.print("pointer: 0x{x}\n", .{@intFromPtr(&i)});
}
