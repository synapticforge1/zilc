// Timers represent a single event in the future. Zig uses Io.sleep
// to implement timer behavior.

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    // Timer 1: sleep 2 seconds then fire.
    // zilc: 0.16 removed std.time.sleep / std.Thread.sleep; sleeping goes through Io.sleep.
    try io.sleep(.fromNanoseconds(2 * std.time.ns_per_s), .awake);
    std.debug.print("Timer 1 fired\n", .{});

    // Timer 2: would fire after 1 second, but we stop it immediately.
    // Since we choose to stop before sleeping, it never fires.
    const stop2 = true;
    if (stop2) {
        std.debug.print("Timer 2 stopped\n", .{});
    }

    // Give timer2 enough time to fire if it ever was going to.
    try io.sleep(.fromNanoseconds(2 * std.time.ns_per_s), .awake);
}
