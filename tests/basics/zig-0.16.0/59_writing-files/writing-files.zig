const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    // Write a string (bytes) to a file
    // zilc: 0.16 moved std.fs.cwd() to std.Io.Dir.cwd(); file operations take an Io.
    const d1 = "hello\nzig\n";
    try std.Io.Dir.cwd().writeFile(io, .{
        .sub_path = "./tmp/dat1.txt",
        .data = d1,
    });

    // Open a file for more granular writes
    const f = try std.Io.Dir.cwd().createFile(io, "./tmp/dat2.txt", .{});
    defer f.close(io);

    // zilc: 0.16 File has no write(); an unbuffered streaming File.Writer writes at the
    // file's current offset and returns the byte count, as File.write did.
    var f_writer = f.writerStreaming(io, &.{});

    // Write byte slice
    const d2 = [_]u8{ 115, 111, 109, 101, 10 };
    const n2 = try f_writer.interface.write(&d2);
    try stdout.print("wrote {d} bytes\n", .{n2});

    // Write a string
    const n3 = try f_writer.interface.write("writes\n");
    try stdout.print("wrote {d} bytes\n", .{n3});

    // Sync (flush) writes to stable storage
    try f.sync(io);

    // Buffered writer
    // zilc: 0.15 replaced std.io.bufferedWriter with a caller-supplied buffer. writerStreaming
    // appends at the file's current offset, as the original did; plain writer() would write at
    // its own position, starting from 0, and overwrite the file's start.
    var write_buf: [4096]u8 = undefined;
    var buf_writer = f.writerStreaming(io, &write_buf);
    const n4 = try buf_writer.interface.write("buffered\n");
    try stdout.print("wrote {d} bytes\n", .{n4});

    // Flush the buffered writer
    try buf_writer.interface.flush();
}
