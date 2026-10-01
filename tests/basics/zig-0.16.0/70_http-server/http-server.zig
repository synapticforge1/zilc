const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    // Start an HTTP server on port 8090
    // zilc: 0.16 moved std.net to std.Io.net (Address is IpAddress); listening, accepting and
    // socket I/O take an Io, and accept() returns the connection's Stream.
    const address = try std.Io.net.IpAddress.parse("0.0.0.0", 8090);
    var server = try address.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);

    try stdout.print("Listening on http://localhost:8090\n", .{});

    // Accept connections in a loop
    while (true) {
        const connection = try server.accept(io);
        // Handle the connection in a new thread
        const thread = try std.Thread.spawn(.{}, handleConnection, .{ io, allocator, connection });
        thread.detach();
    }
}

fn handleConnection(io: std.Io, allocator: std.mem.Allocator, connection: std.Io.net.Stream) void {
    defer connection.close(io);

    // zilc: 0.15's http.Server runs over an Io.Reader/Io.Writer pair built from the
    // stream with caller-supplied buffers (respond() flushes the writer).
    var recv_buffer: [8192]u8 = undefined;
    var send_buffer: [8192]u8 = undefined;
    var conn_reader = connection.reader(io, &recv_buffer);
    var conn_writer = connection.writer(io, &send_buffer);
    var http_server = std.http.Server.init(&conn_reader.interface, &conn_writer.interface);

    var request = http_server.receiveHead() catch return;

    const path = request.head.target;

    if (std.mem.eql(u8, path, "/hello")) {
        // Simple hello handler
        request.respond("hello\n", .{}) catch return;
    } else if (std.mem.eql(u8, path, "/headers")) {
        // Echo request headers back in the response body
        var body = std.array_list.Managed(u8).init(allocator);
        defer body.deinit();

        var it = request.iterateHeaders();
        while (it.next()) |header| {
            // zilc: 0.16's managed ArrayList has no writer(); it prints directly.
            body.print("{s}: {s}\n", .{ header.name, header.value }) catch return;
        }

        request.respond(body.items, .{}) catch return;
    } else {
        request.respond("404 Not Found\n", .{ .status = .not_found }) catch return;
    }
}
