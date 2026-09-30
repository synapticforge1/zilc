const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    // Join constructs paths portably using the OS separator
    const p = try std.fs.path.join(allocator, &[_][]const u8{ "dir1", "dir2", "filename" });
    defer allocator.free(p);
    try stdout.print("p: {s}\n", .{p});

    // Join normalizes redundant separators
    const p2 = try std.fs.path.join(allocator, &[_][]const u8{ "dir1", "filename" });
    defer allocator.free(p2);
    try stdout.print("{s}\n", .{p2});

    const p3 = try std.fs.path.join(allocator, &[_][]const u8{ "dir1", "filename" });
    defer allocator.free(p3);
    try stdout.print("{s}\n", .{p3});

    // Dir and Base split a path
    const dir_p = std.fs.path.dirname(p) orelse ".";
    try stdout.print("Dir(p): {s}\n", .{dir_p});

    const base_p = std.fs.path.basename(p);
    try stdout.print("Base(p): {s}\n", .{base_p});

    // Check if path is absolute
    try stdout.print("{}\n", .{std.fs.path.isAbsolute("dir/file")});
    try stdout.print("{}\n", .{std.fs.path.isAbsolute("/dir/file")});

    const filename = "config.json";

    // Get the extension
    const ext = std.fs.path.extension(filename);
    try stdout.print("{s}\n", .{ext});

    // File name without extension
    const stem = filename[0 .. filename.len - ext.len];
    try stdout.print("{s}\n", .{stem});

    // Relative path from a base to a target
    const rel1 = try std.fs.path.relative(allocator, "a/b", "a/b/t/file");
    defer allocator.free(rel1);
    try stdout.print("{s}\n", .{rel1});

    const rel2 = try std.fs.path.relative(allocator, "a/b", "a/c/t/file");
    defer allocator.free(rel2);
    try stdout.print("{s}\n", .{rel2});
}
