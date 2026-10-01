// Tickers fire repeatedly at regular intervals. Zig has no built-in ticker;
// this example uses a loop with Io.sleep and Io.Timestamp.now.

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    // Tick 3 times at 500ms intervals (matching Go's 1600ms window).
    for (0..3) |_| {
        // zilc: 0.16 removed std.time.sleep and std.time.nanoTimestamp; both go through an Io.
        try io.sleep(.fromNanoseconds(500 * std.time.ns_per_ms), .awake);
        const t = std.Io.Timestamp.now(io, .real).nanoseconds;
        try stdout.print("Tick at {d}\n", .{t});
    }

    try stdout.print("Ticker stopped\n", .{});
}
