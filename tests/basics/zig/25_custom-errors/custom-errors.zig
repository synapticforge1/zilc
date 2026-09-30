const std = @import("std");

const ArgError = struct {
    arg: i64,
    message: []const u8,
};

const MyError = error{ArgError};

var argErrorData: ArgError = undefined;

fn f(arg: i64) !i64 {
    if (arg == 42) {
        argErrorData = ArgError{ .arg = arg, .message = "can't work with it" };
        return MyError.ArgError;
    }
    return arg + 3;
}

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    if (f(42)) |_| {} else |err| {
        if (err == MyError.ArgError) {
            try stdout.print("{d}\n", .{argErrorData.arg});
            try stdout.print("{s}\n", .{argErrorData.message});
        } else {
            try stdout.print("err doesn't match argError\n", .{});
        }
    }
}
