// A goroutine is a lightweight thread of execution.

const std = @import("std");

fn f(from: []const u8) void {
    for (0..3) |i| {
        std.debug.print("{s} : {d}\n", .{ from, i });
    }
}

fn goingThread(_: void) void {
    std.debug.print("going\n", .{});
}

pub fn main() !void {
    // Call f synchronously (direct call).
    f("direct");

    // Spawn a thread to run f concurrently (simulates "go f(goroutine)").
    const t1 = try std.Thread.spawn(.{}, f, .{"goroutine"});

    // Spawn a thread for an anonymous-style function (simulates "go func(msg)").
    const t2 = try std.Thread.spawn(.{}, goingThread, .{{}});

    // Wait for both threads to finish.
    t1.join();
    t2.join();

    std.debug.print("done\n", .{});
}
