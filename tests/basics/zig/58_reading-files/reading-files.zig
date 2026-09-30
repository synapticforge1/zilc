const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    // Read entire file contents into memory
    const file_contents = try std.fs.cwd().readFileAlloc(
        gpa.allocator(),
        "./tmp/dat.txt",
        1024 * 1024,
    );
    defer gpa.allocator().free(file_contents);
    try stdout.writeAll(file_contents);

    // Open the file for more granular reading
    const f = try std.fs.cwd().openFile("./tmp/dat.txt", .{});
    defer f.close();

    // Read some bytes from the beginning of the file
    var b1: [5]u8 = undefined;
    const n1 = try f.read(&b1);
    try stdout.print("{d} bytes: {s}\n", .{ n1, b1[0..n1] });

    // Seek to a known location and read from there
    try f.seekTo(6);
    var b2: [2]u8 = undefined;
    const n2 = try f.read(&b2);
    try stdout.print("{d} bytes @ {d}: ", .{ n2, 6 });
    try stdout.print("{s}\n", .{b2[0..n2]});

    // ReadAtLeast equivalent - seek back to position 6 and read
    try f.seekTo(6);
    var b3: [2]u8 = undefined;
    const n3 = try f.readAll(&b3); // zilc: 0.15 has no readAtLeast; readAll fills the buffer or hits EOF
    try stdout.print("{d} bytes @ {d}: {s}\n", .{ n3, 6, b3[0..n3] });

    // Rewind to start
    try f.seekTo(0);

    // Buffered read - peek at first 5 bytes
    // zilc: 0.15 replaced std.io.bufferedReader with a caller-supplied buffer and peek().
    var read_buf: [4096]u8 = undefined;
    var buf_reader = f.reader(&read_buf);
    const peek_buf = try buf_reader.interface.peek(5);
    try stdout.print("5 bytes: {s}\n", .{peek_buf[0..5]});
}
