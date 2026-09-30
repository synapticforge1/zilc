// To wait for multiple threads to finish, join all spawned threads.

const std = @import("std");

fn worker(id: usize) void {
    std.debug.print("Worker {d} starting\n", .{id});
    std.Thread.sleep(1 * std.time.ns_per_s);
    std.debug.print("Worker {d} done\n", .{id});
}

pub fn main() !void {
    var threads: [5]std.Thread = undefined;

    for (&threads, 1..) |*t, i| {
        t.* = try std.Thread.spawn(.{}, worker, .{i});
    }

    for (&threads) |*t| {
        t.join();
    }
}
