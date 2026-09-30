const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    const builtin = @import("builtin");

    // Run a simple command: date (or equivalent)
    {
        const date_cmd = if (builtin.os.tag == .windows)
            &[_][]const u8{ "cmd", "/c", "date", "/t" }
        else
            &[_][]const u8{"date"};

        var child = std.process.Child.init(date_cmd, allocator);
        child.stdout_behavior = .Pipe;
        child.stderr_behavior = .Pipe;
        try child.spawn();

        const date_out = try child.stdout.?.readToEndAlloc(allocator, 1024 * 1024); // zilc: 0.15 dropped File.reader().readAllAlloc
        defer allocator.free(date_out);
        _ = try child.wait();

        try stdout.print("> date\n", .{});
        try stdout.print("{s}\n", .{date_out});
    }

    // Run a command with invalid flags to demonstrate error handling
    {
        const date_x_cmd = if (builtin.os.tag == .windows)
            &[_][]const u8{ "cmd", "/c", "date", "-x" }
        else
            &[_][]const u8{ "date", "-x" };

        var child = std.process.Child.init(date_x_cmd, allocator);
        child.stdout_behavior = .Pipe;
        child.stderr_behavior = .Pipe;
        try child.spawn();
        const result = try child.wait();
        switch (result) {
            .Exited => |code| {
                if (code != 0) {
                    try stdout.print("command exit rc = {d}\n", .{code});
                }
            },
            else => {},
        }
    }

    // Run grep with piped input (Unix only, on Windows use findstr)
    if (builtin.os.tag != .windows) {
        var grep_child = std.process.Child.init(
            &[_][]const u8{ "grep", "hello" },
            allocator,
        );
        grep_child.stdin_behavior = .Pipe;
        grep_child.stdout_behavior = .Pipe;
        grep_child.stderr_behavior = .Pipe;
        try grep_child.spawn();

        _ = try grep_child.stdin.?.write("hello grep\ngoodbye grep");
        grep_child.stdin.?.close();
        grep_child.stdin = null;

        const grep_out = try grep_child.stdout.?.readToEndAlloc(allocator, 1024 * 1024); // zilc: 0.15 dropped File.reader().readAllAlloc
        defer allocator.free(grep_out);
        _ = try grep_child.wait();

        try stdout.print("> grep hello\n", .{});
        try stdout.print("{s}\n", .{grep_out});
    }

    // Run ls (or dir on Windows) via shell
    {
        const ls_cmd = if (builtin.os.tag == .windows)
            &[_][]const u8{ "cmd", "/c", "dir" }
        else
            &[_][]const u8{ "bash", "-c", "ls -a -l -h" };

        var ls_child = std.process.Child.init(ls_cmd, allocator);
        ls_child.stdout_behavior = .Pipe;
        ls_child.stderr_behavior = .Pipe;
        try ls_child.spawn();

        const ls_out = try ls_child.stdout.?.readToEndAlloc(allocator, 1024 * 1024); // zilc: 0.15 dropped File.reader().readAllAlloc
        defer allocator.free(ls_out);
        _ = try ls_child.wait();

        try stdout.print("> ls -a -l -h\n", .{});
        try stdout.print("{s}\n", .{ls_out});
    }
}
