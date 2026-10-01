const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // zilc: 0.15 readers take a caller-supplied buffer, and a line lives in that buffer until
    // the next read, so it is not allocated or freed. Lines are limited to the buffer's size.
    // 0.16 readers also take an Io; stdin is read streaming, as it cannot seek.
    var stdin_buf: [64 * 1024]u8 = undefined;
    var stdin_reader = std.Io.File.stdin().readerStreaming(io, &stdin_buf);
    const stdin = &stdin_reader.interface;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    // Read lines from stdin and print them uppercased
    while (true) {
        const line = stdin.takeDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        // Trim the newline, and a Windows-style \r if present
        const trimmed = std.mem.trimEnd(u8, line, "\r\n"); // zilc: 0.16 renamed mem.trimRight to trimEnd

        // Uppercase the line
        const upper = try allocator.alloc(u8, trimmed.len);
        defer allocator.free(upper);
        for (trimmed, 0..) |c, i| {
            upper[i] = std.ascii.toUpper(c);
        }

        try stdout.print("{s}\n", .{upper});
    }
}
