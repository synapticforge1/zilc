const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    // Read entire file contents into memory
    // zilc: 0.16 moved std.fs.cwd() to std.Io.Dir.cwd(); file operations take an Io, and
    // readFileAlloc takes (io, path, allocator, limit).
    const file_contents = try std.Io.Dir.cwd().readFileAlloc(
        io,
        "./tmp/dat.txt",
        gpa.allocator(),
        .limited(1024 * 1024),
    );
    defer gpa.allocator().free(file_contents);
    try stdout.writeAll(file_contents);

    // Open the file for more granular reading
    const f = try std.Io.Dir.cwd().openFile(io, "./tmp/dat.txt", .{});
    defer f.close(io);

    // zilc: 0.16 File has no read()/seekTo(); reads and seeks go through a File.Reader,
    // unbuffered here so every read and seek goes straight to the file like the original's.
    var f_reader = f.reader(io, &.{});

    // Read some bytes from the beginning of the file
    var b1: [5]u8 = undefined;
    const n1 = try f_reader.interface.readSliceShort(&b1);
    try stdout.print("{d} bytes: {s}\n", .{ n1, b1[0..n1] });

    // Seek to a known location and read from there
    try f_reader.seekTo(6);
    var b2: [2]u8 = undefined;
    const n2 = try f_reader.interface.readSliceShort(&b2);
    try stdout.print("{d} bytes @ {d}: ", .{ n2, 6 });
    try stdout.print("{s}\n", .{b2[0..n2]});

    // ReadAtLeast equivalent - seek back to position 6 and read
    try f_reader.seekTo(6);
    var b3: [2]u8 = undefined;
    // zilc: 0.15 has no readAtLeast; readSliceShort fills the buffer or hits EOF
    const n3 = try f_reader.interface.readSliceShort(&b3);
    try stdout.print("{d} bytes @ {d}: {s}\n", .{ n3, 6, b3[0..n3] });

    // Rewind to start
    try f_reader.seekTo(0);

    // Buffered read - peek at first 5 bytes
    // zilc: 0.15 replaced std.io.bufferedReader with a caller-supplied buffer and peek().
    var read_buf: [4096]u8 = undefined;
    var buf_reader = f.reader(io, &read_buf);
    const peek_buf = try buf_reader.interface.peek(5);
    try stdout.print("5 bytes: {s}\n", .{peek_buf[0..5]});
}
