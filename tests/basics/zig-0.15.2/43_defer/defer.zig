// Zig has native defer; it runs at the end of the enclosing scope.

const std = @import("std");

fn createFile(path: []const u8) !std.fs.File {
    std.debug.print("creating\n", .{});
    return std.fs.cwd().createFile(path, .{});
}

fn writeFile(file: std.fs.File) !void {
    std.debug.print("writing\n", .{});
    try file.writeAll("data\n");
}

fn closeFile(file: std.fs.File) void {
    std.debug.print("closing\n", .{});
    file.close();
}

pub fn main() !void {
    // Create tmp directory if it does not exist.
    std.fs.cwd().makeDir("tmp") catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    const f = try createFile("tmp/defer.txt");
    defer closeFile(f);
    try writeFile(f);
}
