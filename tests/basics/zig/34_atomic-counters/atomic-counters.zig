// Atomic counters accessed by multiple threads using std.atomic.Value.

const std = @import("std");

var ops = std.atomic.Value(u64).init(0);

fn increment(_: void) void {
    for (0..1000) |_| {
        _ = ops.fetchAdd(1, .seq_cst);
    }
}

pub fn main() !void {
    var threads: [50]std.Thread = undefined;

    for (&threads) |*t| {
        t.* = try std.Thread.spawn(.{}, increment, .{{}});
    }

    for (&threads) |*t| {
        t.join();
    }

    std.debug.print("ops: {d}\n", .{ops.load(.seq_cst)});
}
