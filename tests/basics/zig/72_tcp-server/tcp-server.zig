const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    // Listen on TCP port 7777
    const address = try std.net.Address.parseIp("0.0.0.0", 7777);
    var server = try address.listen(.{ .reuse_address = true });
    defer server.deinit();

    try stdout.print("TCP server listening on port 7777\n", .{});

    // Accept connections in a loop
    while (true) {
        const connection = try server.accept();
        const thread = try std.Thread.spawn(.{}, handleConnection, .{ allocator, connection });
        thread.detach();
    }
}

fn handleConnection(allocator: std.mem.Allocator, connection: std.net.Server.Connection) void {
    _ = allocator;
    defer connection.stream.close();

    // Read one line from the client
    var buf: [4096]u8 = undefined;
    const n = connection.stream.read(&buf) catch return;
    if (n == 0) return;

    const message = buf[0..n];
    const trimmed = std.mem.trimRight(u8, message, "\r\n");

    // Uppercase the message
    var upper_buf: [4096]u8 = undefined;
    for (trimmed, 0..) |c, i| {
        upper_buf[i] = std.ascii.toUpper(c);
    }
    const upper = upper_buf[0..trimmed.len];

    // Send ACK response
    var response_buf: [4096 + 6]u8 = undefined;
    const response = std.fmt.bufPrint(&response_buf, "ACK: {s}\n", .{upper}) catch return;
    _ = connection.stream.write(response) catch return;
}
