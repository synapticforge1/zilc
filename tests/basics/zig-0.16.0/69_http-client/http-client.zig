const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    // Create an HTTP client
    // zilc: 0.16's http.Client does its networking through an Io, so it needs one.
    var client = std.http.Client{ .allocator = allocator, .io = io };
    defer client.deinit();

    // Issue a GET request to gobyexample.com
    const uri = try std.Uri.parse("https://gobyexample.com");

    // zilc: 0.15's client is request() -> sendBodiless() -> receiveHead() -> a body reader.
    // Compression is turned off so the body arrives as plain text, as the original printed it.
    var req = try client.request(.GET, uri, .{
        .headers = .{ .accept_encoding = .omit },
    });
    defer req.deinit();

    try req.sendBodiless();
    var redirect_buffer: [16 * 1024]u8 = undefined;
    var response = try req.receiveHead(&redirect_buffer);

    // Print the HTTP response status
    try stdout.print("Response status: {}\n", .{response.head.status});

    // Print the first 5 lines of the response body
    var transfer_buffer: [4096]u8 = undefined;
    const body = response.reader(&transfer_buffer);
    var i: usize = 0;
    while (i < 5) : (i += 1) {
        const line = body.takeDelimiterInclusive('\n') catch break;
        const trimmed = std.mem.trimEnd(u8, line, "\r\n"); // zilc: 0.16 renamed mem.trimRight to trimEnd
        try stdout.print("{s}\n", .{trimmed});
    }
}
