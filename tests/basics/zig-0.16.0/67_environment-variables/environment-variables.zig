const std = @import("std");

// zilc: std.c.setenv is gone in Zig 0.15; declare it from libc directly.
extern "c" fn setenv(name: [*:0]const u8, value: [*:0]const u8, overwrite: c_int) c_int;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    // Set an environment variable using OS-specific call
    const builtin = @import("builtin");
    if (builtin.os.tag == .windows) {
        // zilc: 0.16 dropped kernel32.SetEnvironmentVariableW from std; declare it directly.
        const kernel32 = struct {
            extern "kernel32" fn SetEnvironmentVariableW(
                name: [*:0]const u16,
                value: ?[*:0]const u16,
            ) callconv(.winapi) std.os.windows.BOOL;
        };
        _ = kernel32.SetEnvironmentVariableW(
            std.unicode.utf8ToUtf16LeStringLiteral("FOO"),
            std.unicode.utf8ToUtf16LeStringLiteral("1"),
        );
    } else {
        _ = setenv("FOO", "1", 1);
    }

    // zilc: 0.16 removed std.process.getEnvVarOwned and getEnvMap; variables are read from a
    // std.process.Environ. On POSIX the one main's Init carries is the startup block, which would
    // not show the setenv above, so read libc's live environ there (Windows' reads the live PEB).
    const environ: std.process.Environ = if (builtin.os.tag == .windows)
        init.minimal.environ
    else
        .{ .block = .{ .slice = std.mem.span(std.c.environ) } };

    // Get environment variables
    const foo = environ.getAlloc(allocator, "FOO") catch try allocator.dupe(u8, "");
    defer allocator.free(foo);
    try stdout.print("FOO: {s}\n", .{foo});

    const bar = environ.getAlloc(allocator, "BAR") catch try allocator.dupe(u8, "");
    defer allocator.free(bar);
    try stdout.print("BAR: {s}\n", .{bar});

    // List all environment variables (keys only)
    try stdout.print("\n", .{});
    var env_map = try environ.createMap(allocator);
    defer env_map.deinit();

    var env_it = env_map.iterator();
    while (env_it.next()) |entry| {
        try stdout.print("{s}\n", .{entry.key_ptr.*});
    }
}
