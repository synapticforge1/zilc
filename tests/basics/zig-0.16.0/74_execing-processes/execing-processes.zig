const std = @import("std");
const builtin = @import("builtin");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Find the ls binary (use 'dir' on Windows or 'ls' on Unix)
    // On Unix systems, exec ls -a -l -h replacing this process.
    // On Windows, use 'cmd /c dir' as exec-replace is not supported the same way.

    if (builtin.os.tag == .windows) {
        // Windows: spawn as a child process since exec-replace is not available
        // zilc: 0.16 replaced Child.init()+spawn() with std.process.spawn(io, options); the
        // stdio behaviours are spawn options, and wait takes an Io.
        var child = try std.process.spawn(io, .{
            .argv = &[_][]const u8{ "cmd", "/c", "dir" },
            .stdout = .inherit,
            .stderr = .inherit,
        });
        _ = try child.wait(io);
    } else {
        // Unix: find ls and exec it, replacing this process
        const ls_path: []const u8 = blk: {
            for ([_][]const u8{ "/bin/ls", "/usr/bin/ls" }) |p| {
                // zilc: 0.16 moved std.fs.accessAbsolute to std.Io.Dir, and it takes an Io.
                std.Io.Dir.accessAbsolute(io, p, .{}) catch continue;
                break :blk p;
            }
            @panic("ls not found");
        };

        // Build null-terminated arg array
        const arg0 = try allocator.dupeZ(u8, "ls");
        defer allocator.free(arg0);
        const arg1 = try allocator.dupeZ(u8, "-a");
        defer allocator.free(arg1);
        const arg2 = try allocator.dupeZ(u8, "-l");
        defer allocator.free(arg2);
        const arg3 = try allocator.dupeZ(u8, "-h");
        defer allocator.free(arg3);

        const argv = [_:null]?[*:0]const u8{ arg0, arg1, arg2, arg3 };

        // Get current environment
        // zilc: 0.16 removed std.process.getEnvMap; the map is built from main's Init environ.
        var env_map = try init.minimal.environ.createMap(allocator);
        defer env_map.deinit();

        // Build null-terminated env array
        var env_list = std.array_list.Managed(?[*:0]const u8).init(allocator);
        defer {
            for (env_list.items) |e| {
                if (e) |ptr| allocator.free(std.mem.span(ptr));
            }
            env_list.deinit();
        }

        var it = env_map.iterator();
        while (it.next()) |entry| {
            const pair = try std.fmt.allocPrintSentinel(allocator, "{s}={s}", .{ entry.key_ptr.*, entry.value_ptr.* }, 0);
            try env_list.append(pair.ptr);
        }
        try env_list.append(null);

        const ls_path_z = try allocator.dupeZ(u8, ls_path);
        defer allocator.free(ls_path_z);

        // execveZ replaces the current process
        // zilc: 0.16 removed std.posix.execveZ (its replacement, std.process.replace, builds argv
        // and envp itself); call libc's execve, which the posix wrapper called. It returns only
        // on failure.
        _ = std.c.execve(ls_path_z, &argv, @ptrCast(env_list.items.ptr));
        return error.ExecveFailed;
    }
}
