const std = @import("std");

// Zig has no context package; cancellation is implemented using a shared atomic flag.
// This example demonstrates a simple HTTP server where a handler can detect
// when the client disconnects using a cancellation flag.

const cancelled = std.atomic.Value(bool);

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

    try stdout.print("Listening on http://localhost:8090/hello\n", .{});

    while (true) {
        const connection = try server.accept();
        const thread = try std.Thread.spawn(.{}, handleConnection, .{ allocator, connection });
        thread.detach();
    }
}

fn handleConnection(allocator: std.mem.Allocator, connection: std.net.Server.Connection) void {
    defer connection.stream.close();

    var cancel_flag = cancelled.init(false);

    // zilc: 0.15's http.Server runs over an Io.Reader/Io.Writer pair built from the
    // stream with caller-supplied buffers (respond() flushes the writer).
    var recv_buffer: [8192]u8 = undefined;
    var send_buffer: [8192]u8 = undefined;
    var conn_reader = connection.stream.reader(&recv_buffer);
    var conn_writer = connection.stream.writer(&send_buffer);
    var http_server = std.http.Server.init(conn_reader.interface(), &conn_writer.interface);

    var request = http_server.receiveHead() catch return;

    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;
    stdout.print("server: hello handler started\n", .{}) catch return;
    defer stdout.print("server: hello handler ended\n", .{}) catch {};

    // Simulate work with cancellation check
    // In a real scenario, check the cancel flag periodically during long work.
    // Here we sleep for up to 10 seconds, checking for cancellation.
    var elapsed: u64 = 0;
    const deadline: u64 = 10_000_000_000; // 10 seconds in nanoseconds

    while (elapsed < deadline) {
        if (cancel_flag.load(.acquire)) {
            stdout.print("server: context cancelled\n", .{}) catch return;
            request.respond("context cancelled\n", .{ .status = .internal_server_error }) catch return;
            return;
        }
        std.Thread.sleep(100_000_000); // 100ms
        elapsed += 100_000_000;
    }

    _ = allocator;
    request.respond("hello\n", .{}) catch return;
}
