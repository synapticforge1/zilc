// Rate limiting controls resource utilization by throttling requests.
// Zig uses Io.sleep to implement the limiter.

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    // Basic rate limiting: 5 requests, each limited to 1 per 200ms.
    const requests = [_]usize{ 1, 2, 3, 4, 5 };

    // zilc: 0.16 removed std.time.sleep and std.time.nanoTimestamp; both go through an Io.
    for (requests) |req| {
        try io.sleep(.fromNanoseconds(200 * std.time.ns_per_ms), .awake);
        const t = std.Io.Timestamp.now(io, .real).nanoseconds;
        try stdout.print("request {d} {d}\n", .{ req, t });
    }

    // Bursty rate limiting: first 3 requests fire immediately (burst),
    // then remaining requests are throttled at 200ms each.
    const bursty_requests = [_]usize{ 1, 2, 3, 4, 5 };
    const burst_size: usize = 3;

    for (bursty_requests, 0..) |req, i| {
        if (i >= burst_size) {
            try io.sleep(.fromNanoseconds(200 * std.time.ns_per_ms), .awake);
        }
        const t = std.Io.Timestamp.now(io, .real).nanoseconds;
        try stdout.print("request {d} {d}\n", .{ req, t });
    }
}
