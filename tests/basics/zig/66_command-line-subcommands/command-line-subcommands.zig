const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    // Zig has no subcommand stdlib; dispatch is implemented manually.
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        try stdout.print("expected 'foo' or 'bar' subcommands\n", .{});
        std.process.exit(1);
    }

    const subcmd = args[1];

    if (std.mem.eql(u8, subcmd, "foo")) {
        // Parse foo subcommand flags
        var enable: bool = false;
        var name: []const u8 = "";
        var tail_start: usize = 0;

        var i: usize = 2;
        while (i < args.len) : (i += 1) {
            const arg = args[i];
            if (std.mem.eql(u8, arg, "-enable")) {
                enable = true;
            } else if (std.mem.startsWith(u8, arg, "-name=")) {
                name = arg["-name=".len..];
            } else {
                tail_start = i;
                break;
            }
        }

        try stdout.print("subcommand 'foo'\n", .{});
        try stdout.print("  enable: {}\n", .{enable});
        try stdout.print("  name: {s}\n", .{name});
        try stdout.print("  tail: [", .{});
        if (tail_start > 0) {
            for (args[tail_start..], 0..) |arg, j| {
                if (j > 0) try stdout.print(" ", .{});
                try stdout.print("{s}", .{arg});
            }
        }
        try stdout.print("]\n", .{});
    } else if (std.mem.eql(u8, subcmd, "bar")) {
        // Parse bar subcommand flags
        var level: i64 = 0;
        var tail_start: usize = 0;

        var i: usize = 2;
        while (i < args.len) : (i += 1) {
            const arg = args[i];
            if (std.mem.startsWith(u8, arg, "-level=")) {
                level = try std.fmt.parseInt(i64, arg["-level=".len..], 10);
            } else if (std.mem.eql(u8, arg, "-level") and i + 1 < args.len) {
                i += 1;
                level = try std.fmt.parseInt(i64, args[i], 10);
            } else {
                tail_start = i;
                break;
            }
        }

        try stdout.print("subcommand 'bar'\n", .{});
        try stdout.print("  level: {d}\n", .{level});
        try stdout.print("  tail: [", .{});
        if (tail_start > 0) {
            for (args[tail_start..], 0..) |arg, j| {
                if (j > 0) try stdout.print(" ", .{});
                try stdout.print("{s}", .{arg});
            }
        }
        try stdout.print("]\n", .{});
    } else {
        try stdout.print("expected 'foo' or 'bar' subcommands\n", .{});
        std.process.exit(1);
    }
}
