const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    // Listen on TCP port 7777
    // zilc: 0.16 moved std.net to std.Io.net (Address is IpAddress); listening, accepting and
    // socket I/O take an Io, and accept() returns the connection's Stream.
    const address = try std.Io.net.IpAddress.parse("0.0.0.0", 7777);
    var server = try address.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);

    try stdout.print("TCP server listening on port 7777\n", .{});

    // Accept connections in a loop
    while (true) {
        const connection = try server.accept(io);
        const thread = try std.Thread.spawn(.{}, handleConnection, .{ io, allocator, connection });
        thread.detach();
    }
}

fn handleConnection(io: std.Io, allocator: std.mem.Allocator, connection: std.Io.net.Stream) void {
    _ = allocator;
    defer connection.close(io);

    // Read one line from the client
    // zilc: 0.16 Stream has no read()/write(); an unbuffered stream reader's readVec does one
    // receive (like read), and an unbuffered writer's writeAll sends the reply.
    var buf: [4096]u8 = undefined;
    var conn_reader = connection.reader(io, &.{});
    var bufs: [1][]u8 = .{&buf};
    const n = conn_reader.interface.readVec(&bufs) catch return;
    if (n == 0) return;

    const message = buf[0..n];
    const trimmed = std.mem.trimEnd(u8, message, "\r\n"); // zilc: 0.16 renamed mem.trimRight to trimEnd

    // Uppercase the message
    var upper_buf: [4096]u8 = undefined;
    for (trimmed, 0..) |c, i| {
        upper_buf[i] = std.ascii.toUpper(c);
    }
    const upper = upper_buf[0..trimmed.len];

    // Send ACK response
    var response_buf: [4096 + 6]u8 = undefined;
    const response = std.fmt.bufPrint(&response_buf, "ACK: {s}\n", .{upper}) catch return;
    var conn_writer = connection.writer(io, &.{});
    conn_writer.interface.writeAll(response) catch return;
}
