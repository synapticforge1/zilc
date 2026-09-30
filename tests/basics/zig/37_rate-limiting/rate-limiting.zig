// Rate limiting controls resource utilization by throttling requests.
// Zig uses std.Thread.sleep to implement the limiter.

const std = @import("std");

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    // Basic rate limiting: 5 requests, each limited to 1 per 200ms.
    const requests = [_]usize{ 1, 2, 3, 4, 5 };

    for (requests) |req| {
        std.Thread.sleep(200 * std.time.ns_per_ms);
        const t = std.time.nanoTimestamp();
        try stdout.print("request {d} {d}\n", .{ req, t });
    }

    // Bursty rate limiting: first 3 requests fire immediately (burst),
    // then remaining requests are throttled at 200ms each.
    const bursty_requests = [_]usize{ 1, 2, 3, 4, 5 };
    const burst_size: usize = 3;

    for (bursty_requests, 0..) |req, i| {
        if (i >= burst_size) {
            std.Thread.sleep(200 * std.time.ns_per_ms);
        }
        const t = std.time.nanoTimestamp();
        try stdout.print("request {d} {d}\n", .{ req, t });
    }
}
