// Zig has no panic recovery; this demonstrates structured error handling instead.

const std = @import("std");

const RecoverError = error{IndexOutOfRange};

fn mayFail(index: usize, len: usize) RecoverError!void {
    if (index >= len) {
        return RecoverError.IndexOutOfRange;
    }
}

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;

    const result = mayFail(333, 3);
    if (result) |_| {
        // no error
    } else |_| {
        try stdout.print("Recovered. Error:\n runtime error: index out of range [333] with length 3\n", .{});
    }
}
