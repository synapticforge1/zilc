// Timeouts are important for programs that connect to external resources or
// that otherwise need to bound execution time.

const std = @import("std");

// zilc: 0.16 moved Mutex from std.Thread to std.Io, and Io.Condition has no timedWait;
// the timed wait is an Io.Event (set by send) waited on with a timeout instead.
const ResultSlot = struct {
    mutex: std.Io.Mutex = .init,
    ready: std.Io.Event = .unset,
    value: ?[]const u8 = null,

    fn send(self: *ResultSlot, io: std.Io, val: []const u8) void {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);
        self.value = val;
        self.ready.set(io);
    }

    // Returns the value if it arrives within timeout_ns, otherwise null.
    fn recvTimeout(self: *ResultSlot, io: std.Io, timeout_ns: u64) ?[]const u8 {
        self.ready.waitTimeout(io, .{ .duration = .{
            .raw = .fromNanoseconds(timeout_ns),
            .clock = .awake,
        } }) catch {};
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);
        return self.value;
    }
};

var slot1 = ResultSlot{};
var slot2 = ResultSlot{};

// zilc: 0.16 removed std.time.sleep / std.Thread.sleep; sleeping goes through Io.sleep.
fn worker1(io: std.Io) void {
    io.sleep(.fromNanoseconds(2 * std.time.ns_per_s), .awake) catch {};
    slot1.send(io, "result 1");
}

fn worker2(io: std.Io) void {
    io.sleep(.fromNanoseconds(2 * std.time.ns_per_s), .awake) catch {};
    slot2.send(io, "result 2");
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    // First case: operation takes 2s, timeout is 1s -> timeout fires.
    const t1 = try std.Thread.spawn(.{}, worker1, .{io});
    if (slot1.recvTimeout(io, 1 * std.time.ns_per_s)) |res| {
        std.debug.print("{s}\n", .{res});
    } else {
        std.debug.print("timeout 1\n", .{});
    }
    t1.join();

    // Second case: operation takes 2s, timeout is 3s -> result arrives.
    const t2 = try std.Thread.spawn(.{}, worker2, .{io});
    if (slot2.recvTimeout(io, 3 * std.time.ns_per_s)) |res| {
        std.debug.print("{s}\n", .{res});
    } else {
        std.debug.print("timeout 2\n", .{});
    }
    t2.join();
}
