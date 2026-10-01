// To wait for multiple threads to finish, join all spawned threads.

const std = @import("std");

// zilc: 0.16 removed std.time.sleep / std.Thread.sleep; sleeping goes through Io.sleep.
fn worker(io: std.Io, id: usize) void {
    std.debug.print("Worker {d} starting\n", .{id});
    io.sleep(.fromNanoseconds(1 * std.time.ns_per_s), .awake) catch {};
    std.debug.print("Worker {d} done\n", .{id});
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var threads: [5]std.Thread = undefined;

    for (&threads, 1..) |*t, i| {
        t.* = try std.Thread.spawn(.{}, worker, .{ io, i });
    }

    for (&threads) |*t| {
        t.join();
    }
}
