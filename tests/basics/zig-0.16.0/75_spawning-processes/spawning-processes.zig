const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    const builtin = @import("builtin");

    // zilc: 0.16 replaced Child.init()+spawn() with std.process.spawn(io, options): the stdio
    // behaviours are spawn options (.Pipe is .pipe), wait takes an Io, and Term's tags are
    // lowercase. A child's pipe is an Io.File, read to the end through a File.Reader.

    // Run a simple command: date (or equivalent)
    {
        const date_cmd = if (builtin.os.tag == .windows)
            &[_][]const u8{ "cmd", "/c", "date", "/t" }
        else
            &[_][]const u8{"date"};

        var child = try std.process.spawn(io, .{
            .argv = date_cmd,
            .stdout = .pipe,
            .stderr = .pipe,
        });

        var date_reader = child.stdout.?.readerStreaming(io, &.{});
        const date_out = try date_reader.interface.allocRemaining(allocator, .limited(1024 * 1024));
        defer allocator.free(date_out);
        _ = try child.wait(io);

        try stdout.print("> date\n", .{});
        try stdout.print("{s}\n", .{date_out});
    }

    // Run a command with invalid flags to demonstrate error handling
    {
        const date_x_cmd = if (builtin.os.tag == .windows)
            &[_][]const u8{ "cmd", "/c", "date", "-x" }
        else
            &[_][]const u8{ "date", "-x" };

        var child = try std.process.spawn(io, .{
            .argv = date_x_cmd,
            .stdout = .pipe,
            .stderr = .pipe,
        });
        const result = try child.wait(io);
        switch (result) {
            .exited => |code| {
                if (code != 0) {
                    try stdout.print("command exit rc = {d}\n", .{code});
                }
            },
            else => {},
        }
    }

    // Run grep with piped input (Unix only, on Windows use findstr)
    if (builtin.os.tag != .windows) {
        var grep_child = try std.process.spawn(io, .{
            .argv = &[_][]const u8{ "grep", "hello" },
            .stdin = .pipe,
            .stdout = .pipe,
            .stderr = .pipe,
        });

        try grep_child.stdin.?.writeStreamingAll(io, "hello grep\ngoodbye grep");
        grep_child.stdin.?.close(io);
        grep_child.stdin = null;

        var grep_reader = grep_child.stdout.?.readerStreaming(io, &.{});
        const grep_out = try grep_reader.interface.allocRemaining(allocator, .limited(1024 * 1024));
        defer allocator.free(grep_out);
        _ = try grep_child.wait(io);

        try stdout.print("> grep hello\n", .{});
        try stdout.print("{s}\n", .{grep_out});
    }

    // Run ls (or dir on Windows) via shell
    {
        const ls_cmd = if (builtin.os.tag == .windows)
            &[_][]const u8{ "cmd", "/c", "dir" }
        else
            &[_][]const u8{ "bash", "-c", "ls -a -l -h" };

        var ls_child = try std.process.spawn(io, .{
            .argv = ls_cmd,
            .stdout = .pipe,
            .stderr = .pipe,
        });

        var ls_reader = ls_child.stdout.?.readerStreaming(io, &.{});
        const ls_out = try ls_reader.interface.allocRemaining(allocator, .limited(1024 * 1024));
        defer allocator.free(ls_out);
        _ = try ls_child.wait(io);

        try stdout.print("> ls -a -l -h\n", .{});
        try stdout.print("{s}\n", .{ls_out});
    }
}
