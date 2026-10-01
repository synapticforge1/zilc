const std = @import("std");

const ArgError = struct {
    arg: i64,
    prob: []const u8,
};

const F2Error = error{ArgError};

var lastArgError: ArgError = undefined;

fn f1(arg: i64) !i64 {
    if (arg == 42) {
        return error.CantWorkWith42;
    }
    return arg + 3;
}

fn f2(arg: i64) !i64 {
    if (arg == 42) {
        lastArgError = ArgError{ .arg = arg, .prob = "can't work with it" };
        return F2Error.ArgError;
    }
    return arg + 3;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    const test_vals = [_]i64{ 7, 42 };

    for (test_vals) |i| {
        if (f1(i)) |r| {
            try stdout.print("f1 worked: {d}\n", .{r});
        } else |_| {
            try stdout.print("f1 failed: can't work with 42\n", .{});
        }
    }

    for (test_vals) |i| {
        if (f2(i)) |r| {
            try stdout.print("f2 worked: {d}\n", .{r});
        } else |_| {
            try stdout.print("f2 failed: {d} - {s}\n", .{ lastArgError.arg, lastArgError.prob });
        }
    }

    _ = f2(42) catch {};
    try stdout.print("{d}\n", .{lastArgError.arg});
    try stdout.print("{s}\n", .{lastArgError.prob});
}
