const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;

    // Write a string (bytes) to a file
    const d1 = "hello\nzig\n";
    try std.fs.cwd().writeFile(.{
        .sub_path = "./tmp/dat1.txt",
        .data = d1,
    });

    // Open a file for more granular writes
    const f = try std.fs.cwd().createFile("./tmp/dat2.txt", .{});
    defer f.close();

    // Write byte slice
    const d2 = [_]u8{ 115, 111, 109, 101, 10 };
    const n2 = try f.write(&d2);
    try stdout.print("wrote {d} bytes\n", .{n2});

    // Write a string
    const n3 = try f.write("writes\n");
    try stdout.print("wrote {d} bytes\n", .{n3});

    // Sync (flush) writes to stable storage
    try f.sync();

    // Buffered writer
    // zilc: 0.15 replaced std.io.bufferedWriter with a caller-supplied buffer. writerStreaming
    // appends at the file's current offset, as the original did; plain writer() would write at
    // its own position, starting from 0, and overwrite the file's start.
    var write_buf: [4096]u8 = undefined;
    var buf_writer = f.writerStreaming(&write_buf);
    const n4 = try buf_writer.interface.write("buffered\n");
    try stdout.print("wrote {d} bytes\n", .{n4});

    // Flush the buffered writer
    try buf_writer.interface.flush();
}
