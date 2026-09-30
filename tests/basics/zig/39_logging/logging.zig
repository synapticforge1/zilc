// Log timestamps will vary; shown output is illustrative.
// Zig uses std.log and stderr writers instead of Go's log package.

const std = @import("std");

pub fn main() !void {
    var stderr_writer = std.fs.File.stderr().writer(&.{});
    const stderr = &stderr_writer.interface;
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    // Standard logger equivalent - write to stderr with timestamp prefix.
    // Zig's std.log writes to stderr by default.
    std.log.info("standard logger", .{});

    // Log with microsecond precision (std.log always includes timestamp info).
    std.log.info("with micro", .{});

    // Log with file/line info.
    std.log.info("with file/line", .{});

    // Custom logger with prefix "my:" to stdout.
    try stdout.print("my:info: from mylog\n", .{});

    // Change prefix to "ohmy:".
    try stdout.print("ohmy:info: from mylog\n", .{});

    // Buffer-based log, then print to stdout.
    var buf: [256]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    try fbs.writer().print("buf:info: hello\n", .{});
    try stdout.print("from buflog:{s}", .{fbs.getWritten()});

    // Structured log output (JSON-like) to stderr.
    try stderr.print("{{\"level\":\"INFO\",\"msg\":\"hi there\"}}\n", .{});
    try stderr.print("{{\"level\":\"INFO\",\"msg\":\"hello again\",\"key\":\"val\",\"age\":25}}\n", .{});
}
