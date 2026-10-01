const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    // Zig has no TempFile stdlib function; create temp files manually.
    // Get the system temp directory from the environment.
    // zilc: 0.16 removed std.process.getEnvVarOwned; the environment comes from main's Init.
    const environ = init.minimal.environ;
    const tmp_base = environ.getAlloc(allocator, "TEMP") catch
        environ.getAlloc(allocator, "TMPDIR") catch
        try allocator.dupe(u8, "/tmp");
    defer allocator.free(tmp_base);

    // Build a unique temp file name using a timestamp
    // zilc: 0.16 removed std.time.milliTimestamp(); the real-time clock is read through an Io.
    const ts = std.Io.Timestamp.now(io, .real).toMilliseconds();
    const tmp_file_name = try std.fmt.allocPrint(allocator, "{s}/sample{d}", .{ tmp_base, ts });
    defer allocator.free(tmp_file_name);

    // Create the temp file
    // zilc: 0.16 moved the std.fs *Absolute helpers to std.Io.Dir, and they take an Io.
    const f = try std.Io.Dir.createFileAbsolute(io, tmp_file_name, .{});
    defer {
        f.close(io);
        std.Io.Dir.deleteFileAbsolute(io, tmp_file_name) catch {};
    }

    try stdout.print("Temp file name: {s}\n", .{tmp_file_name});

    // Write some data to the temp file
    // zilc: 0.16 File has no write(); writeStreamingAll writes at the file's current offset.
    try f.writeStreamingAll(io, &[_]u8{ 1, 2, 3, 4 });

    // Create a temporary directory (unique name using timestamp + 1)
    const tmp_dir_name = try std.fmt.allocPrint(allocator, "{s}/sampledir{d}", .{ tmp_base, ts + 1 });
    defer allocator.free(tmp_dir_name);

    try std.Io.Dir.createDirAbsolute(io, tmp_dir_name, .default_dir);
    // zilc: 0.16 has no deleteTreeAbsolute; deleteTree from cwd accepts an absolute path.
    defer std.Io.Dir.cwd().deleteTree(io, tmp_dir_name) catch {};

    try stdout.print("Temp dir name: {s}\n", .{tmp_dir_name});

    // Create a file in the temporary directory
    const fname = try std.fs.path.join(allocator, &[_][]const u8{ tmp_dir_name, "file1" });
    defer allocator.free(fname);

    const f2 = try std.Io.Dir.createFileAbsolute(io, fname, .{});
    defer f2.close(io);
    try f2.writeStreamingAll(io, &[_]u8{ 1, 2 });
}
