// Timers represent a single event in the future. Zig uses std.Thread.sleep
// to implement timer behavior.

const std = @import("std");

pub fn main() !void {
    // Timer 1: sleep 2 seconds then fire.
    std.Thread.sleep(2 * std.time.ns_per_s);
    std.debug.print("Timer 1 fired\n", .{});

    // Timer 2: would fire after 1 second, but we stop it immediately.
    // Since we choose to stop before sleeping, it never fires.
    const stop2 = true;
    if (stop2) {
        std.debug.print("Timer 2 stopped\n", .{});
    }

    // Give timer2 enough time to fire if it ever was going to.
    std.Thread.sleep(2 * std.time.ns_per_s);
}
