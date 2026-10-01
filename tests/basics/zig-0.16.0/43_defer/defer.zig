// Zig has native defer; it runs at the end of the enclosing scope.

const std = @import("std");

// zilc: 0.16 moved std.fs.File/cwd() to std.Io.File/std.Io.Dir.cwd(); every file operation
// takes an Io, so the helpers take one too.
fn createFile(io: std.Io, path: []const u8) !std.Io.File {
    std.debug.print("creating\n", .{});
    return std.Io.Dir.cwd().createFile(io, path, .{});
}

fn writeFile(io: std.Io, file: std.Io.File) !void {
    std.debug.print("writing\n", .{});
    // zilc: 0.16 File has no writeAll(); writeStreamingAll writes at the file's current offset.
    try file.writeStreamingAll(io, "data\n");
}

fn closeFile(io: std.Io, file: std.Io.File) void {
    std.debug.print("closing\n", .{});
    file.close(io);
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    // Create tmp directory if it does not exist.
    // zilc: 0.16 renamed makeDir to createDir, which takes the new directory's permissions.
    std.Io.Dir.cwd().createDir(io, "tmp", .default_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    const f = try createFile(io, "tmp/defer.txt");
    defer closeFile(io, f);
    try writeFile(io, f);
}
