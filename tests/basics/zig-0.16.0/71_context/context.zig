const std = @import("std");

// Zig has no context package; cancellation is implemented using a shared atomic flag.
// This example demonstrates a simple HTTP server where a handler can detect
// when the client disconnects using a cancellation flag.

const cancelled = std.atomic.Value(bool);

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

    try stdout.print("Listening on http://localhost:8090/hello\n", .{});

    while (true) {
        const connection = try server.accept(io);
        const thread = try std.Thread.spawn(.{}, handleConnection, .{ io, allocator, connection });
        thread.detach();
    }
}

fn handleConnection(io: std.Io, allocator: std.mem.Allocator, connection: std.Io.net.Stream) void {
    defer connection.close(io);

    var cancel_flag = cancelled.init(false);

    // zilc: 0.15's http.Server runs over an Io.Reader/Io.Writer pair built from the
    // stream with caller-supplied buffers (respond() flushes the writer).
    var recv_buffer: [8192]u8 = undefined;
    var send_buffer: [8192]u8 = undefined;
    var conn_reader = connection.reader(io, &recv_buffer);
    var conn_writer = connection.writer(io, &send_buffer);
    var http_server = std.http.Server.init(&conn_reader.interface, &conn_writer.interface);

    var request = http_server.receiveHead() catch return;

    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
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
        // zilc: 0.16 removed std.time.sleep / std.Thread.sleep; sleeping goes through Io.sleep.
        io.sleep(.fromNanoseconds(100_000_000), .awake) catch {}; // 100ms
        elapsed += 100_000_000;
    }

    _ = allocator;
    request.respond("hello\n", .{}) catch return;
}
