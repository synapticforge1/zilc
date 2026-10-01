const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;

    // Zig has no TempFile stdlib function; create temp files manually.
    // Get the system temp directory from the environment.
    const tmp_base = std.process.getEnvVarOwned(allocator, "TEMP") catch
        std.process.getEnvVarOwned(allocator, "TMPDIR") catch
        try allocator.dupe(u8, "/tmp");
    defer allocator.free(tmp_base);

    // Build a unique temp file name using a timestamp
    const ts = std.time.milliTimestamp();
    const tmp_file_name = try std.fmt.allocPrint(allocator, "{s}/sample{d}", .{ tmp_base, ts });
    defer allocator.free(tmp_file_name);

    // Create the temp file
    const f = try std.fs.createFileAbsolute(tmp_file_name, .{});
    defer {
        f.close();
        std.fs.deleteFileAbsolute(tmp_file_name) catch {};
    }

    try stdout.print("Temp file name: {s}\n", .{tmp_file_name});

    // Write some data to the temp file
    _ = try f.write(&[_]u8{ 1, 2, 3, 4 });

    // Create a temporary directory (unique name using timestamp + 1)
    const tmp_dir_name = try std.fmt.allocPrint(allocator, "{s}/sampledir{d}", .{ tmp_base, ts + 1 });
    defer allocator.free(tmp_dir_name);

    try std.fs.makeDirAbsolute(tmp_dir_name);
    defer std.fs.deleteTreeAbsolute(tmp_dir_name) catch {};

    try stdout.print("Temp dir name: {s}\n", .{tmp_dir_name});

    // Create a file in the temporary directory
    const fname = try std.fs.path.join(allocator, &[_][]const u8{ tmp_dir_name, "file1" });
    defer allocator.free(fname);

    const f2 = try std.fs.createFileAbsolute(fname, .{});
    defer f2.close();
    _ = try f2.write(&[_]u8{ 1, 2 });
}
