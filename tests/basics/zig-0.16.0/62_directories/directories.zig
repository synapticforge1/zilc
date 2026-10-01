const std = @import("std");

// zilc: one named type; since Zig 0.14 every `struct { ... }` literal is a distinct type.
const Entry = struct { name: []u8, is_dir: bool };

// zilc: 0.16 moved std.fs.cwd() to std.Io.Dir.cwd(); every directory and file operation
// (and directory iteration) takes an Io, so the helpers below take one too.
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    // Create a new sub-directory
    // zilc: 0.16 renamed makeDir to createDir, which takes the new directory's permissions.
    try std.Io.Dir.cwd().createDir(io, "subdir", .default_dir);
    defer std.Io.Dir.cwd().deleteTree(io, "subdir") catch {};

    // Helper: create an empty file
    const createEmptyFile = struct {
        fn create(io_: std.Io, path: []const u8) !void {
            const f = try std.Io.Dir.cwd().createFile(io_, path, .{});
            f.close(io_);
        }
    }.create;

    try createEmptyFile(io, "subdir/file1");

    // Create a hierarchy of directories (like mkdir -p)
    // zilc: 0.16 renamed makePath to createDirPath.
    try std.Io.Dir.cwd().createDirPath(io, "subdir/parent/child");

    try createEmptyFile(io, "subdir/parent/file2");
    try createEmptyFile(io, "subdir/parent/file3");
    try createEmptyFile(io, "subdir/parent/child/file4");

    // List directory contents of subdir/parent
    try stdout.print("Listing subdir/parent\n", .{});
    {
        var dir = try std.Io.Dir.cwd().openDir(io, "subdir/parent", .{ .iterate = true });
        defer dir.close(io);

        // Collect entries for sorted output
        var entries = std.array_list.Managed(Entry).init(allocator);
        defer {
            for (entries.items) |e| allocator.free(e.name);
            entries.deinit();
        }

        var it = dir.iterate();
        while (try it.next(io)) |entry| {
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
    // zilc: 0.16 renamed std.process.changeCurDir to setCurrentPath, which takes an Io.
    try std.process.setCurrentPath(io, "subdir/parent/child");

    // List contents of current directory (subdir/parent/child)
    try stdout.print("Listing subdir/parent/child\n", .{});
    {
        var dir = try std.Io.Dir.cwd().openDir(io, ".", .{ .iterate = true });
        defer dir.close(io);

        var entries = std.array_list.Managed(Entry).init(allocator);
        defer {
            for (entries.items) |e| allocator.free(e.name);
            entries.deinit();
        }

        var it = dir.iterate();
        while (try it.next(io)) |entry| {
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
    try std.process.setCurrentPath(io, "../../..");

    // Walk directory tree recursively
    try stdout.print("Visiting subdir\n", .{});
    try walkDir(io, allocator, stdout, "subdir", "subdir");
}

fn walkDir(io: std.Io, allocator: std.mem.Allocator, writer: anytype, base: []const u8, path: []const u8) !void {
    const is_dir = blk: {
        const stat = std.Io.Dir.cwd().statFile(io, path, .{}) catch {
            break :blk false;
        };
        break :blk stat.kind == .directory;
    };
    try writer.print("  {s} {}\n", .{ path, is_dir });

    if (!is_dir) return;

    var dir = try std.Io.Dir.cwd().openDir(io, path, .{ .iterate = true });
    defer dir.close(io);

    var entries = std.array_list.Managed(Entry).init(allocator);
    defer {
        for (entries.items) |e| allocator.free(e.name);
        entries.deinit();
    }

    var it = dir.iterate();
    while (try it.next(io)) |entry| {
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
        try walkDir(io, allocator, writer, base, child_path);
    }
}
