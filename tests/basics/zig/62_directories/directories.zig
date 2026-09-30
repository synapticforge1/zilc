const std = @import("std");

// zilc: one named type; since Zig 0.14 every `struct { ... }` literal is a distinct type.
const Entry = struct { name: []u8, is_dir: bool };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    // Create a new sub-directory
    try std.fs.cwd().makeDir("subdir");
    defer std.fs.cwd().deleteTree("subdir") catch {};

    // Helper: create an empty file
    const createEmptyFile = struct {
        fn create(path: []const u8) !void {
            const f = try std.fs.cwd().createFile(path, .{});
            f.close();
        }
    }.create;

    try createEmptyFile("subdir/file1");

    // Create a hierarchy of directories (like mkdir -p)
    try std.fs.cwd().makePath("subdir/parent/child");

    try createEmptyFile("subdir/parent/file2");
    try createEmptyFile("subdir/parent/file3");
    try createEmptyFile("subdir/parent/child/file4");

    // List directory contents of subdir/parent
    try stdout.print("Listing subdir/parent\n", .{});
    {
        var dir = try std.fs.cwd().openDir("subdir/parent", .{ .iterate = true });
        defer dir.close();

        // Collect entries for sorted output
        var entries = std.array_list.Managed(Entry).init(allocator);
        defer {
            for (entries.items) |e| allocator.free(e.name);
            entries.deinit();
        }

        var it = dir.iterate();
        while (try it.next()) |entry| {
            const name = try allocator.dupe(u8, entry.name);
            try entries.append(.{
                .name = name,
                .is_dir = entry.kind == .directory,
            });
        }

        // Sort entries alphabetically
        std.sort.block(Entry, entries.items, {}, struct {
            fn lessThan(_: void, a: Entry, b: Entry) bool {
                return std.mem.lessThan(u8, a.name, b.name);
            }
        }.lessThan);

        for (entries.items) |entry| {
            try stdout.print("  {s} {}\n", .{ entry.name, entry.is_dir });
        }
    }

    // Change working directory to subdir/parent/child
    try std.process.changeCurDir("subdir/parent/child");

    // List contents of current directory (subdir/parent/child)
    try stdout.print("Listing subdir/parent/child\n", .{});
    {
        var dir = try std.fs.cwd().openDir(".", .{ .iterate = true });
        defer dir.close();

        var entries = std.array_list.Managed(Entry).init(allocator);
        defer {
            for (entries.items) |e| allocator.free(e.name);
            entries.deinit();
        }

        var it = dir.iterate();
        while (try it.next()) |entry| {
            const name = try allocator.dupe(u8, entry.name);
            try entries.append(.{
                .name = name,
                .is_dir = entry.kind == .directory,
            });
        }

        std.sort.block(Entry, entries.items, {}, struct {
            fn lessThan(_: void, a: Entry, b: Entry) bool {
                return std.mem.lessThan(u8, a.name, b.name);
            }
        }.lessThan);

        for (entries.items) |entry| {
            try stdout.print("  {s} {}\n", .{ entry.name, entry.is_dir });
        }
    }

    // cd back to where we started
    try std.process.changeCurDir("../../..");

    // Walk directory tree recursively
    try stdout.print("Visiting subdir\n", .{});
    try walkDir(allocator, stdout, "subdir", "subdir");
}

fn walkDir(allocator: std.mem.Allocator, writer: anytype, base: []const u8, path: []const u8) !void {
    const is_dir = blk: {
        const stat = std.fs.cwd().statFile(path) catch {
            break :blk false;
        };
        break :blk stat.kind == .directory;
    };
    try writer.print("  {s} {}\n", .{ path, is_dir });

    if (!is_dir) return;

    var dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
    defer dir.close();

    var entries = std.array_list.Managed(Entry).init(allocator);
    defer {
        for (entries.items) |e| allocator.free(e.name);
        entries.deinit();
    }

    var it = dir.iterate();
    while (try it.next()) |entry| {
        const name = try allocator.dupe(u8, entry.name);
        try entries.append(.{
            .name = name,
            .is_dir = entry.kind == .directory,
        });
    }

    std.sort.block(Entry, entries.items, {}, struct {
        fn lessThan(_: void, a: Entry, b: Entry) bool {
            return std.mem.lessThan(u8, a.name, b.name);
        }
    }.lessThan);

    for (entries.items) |entry| {
        const child_path = try std.fs.path.join(allocator, &[_][]const u8{ path, entry.name });
        defer allocator.free(child_path);
        try walkDir(allocator, writer, base, child_path);
    }
}
