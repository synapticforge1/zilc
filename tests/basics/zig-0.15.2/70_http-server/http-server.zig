const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;

    // Start an HTTP server on port 8090
    const address = try std.net.Address.parseIp("0.0.0.0", 8090);
    var server = try address.listen(.{ .reuse_address = true });
    defer server.deinit();

    try stdout.print("Listening on http://localhost:8090\n", .{});

    // Accept connections in a loop
    while (true) {
        const connection = try server.accept();
        // Handle the connection in a new thread
        const thread = try std.Thread.spawn(.{}, handleConnection, .{ allocator, connection });
        thread.detach();
    }
}

fn handleConnection(allocator: std.mem.Allocator, connection: std.net.Server.Connection) void {
    defer connection.stream.close();

    // zilc: 0.15's http.Server runs over an Io.Reader/Io.Writer pair built from the
    // stream with caller-supplied buffers (respond() flushes the writer).
    var recv_buffer: [8192]u8 = undefined;
    var send_buffer: [8192]u8 = undefined;
    var conn_reader = connection.stream.reader(&recv_buffer);
    var conn_writer = connection.stream.writer(&send_buffer);
    var http_server = std.http.Server.init(conn_reader.interface(), &conn_writer.interface);

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
            body.writer().print("{s}: {s}\n", .{ header.name, header.value }) catch return;
        }

        request.respond(body.items, .{}) catch return;
    } else {
        request.respond("404 Not Found\n", .{ .status = .not_found }) catch return;
    }
}
