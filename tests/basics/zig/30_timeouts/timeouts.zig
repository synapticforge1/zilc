// Timeouts are important for programs that connect to external resources or
// that otherwise need to bound execution time.

const std = @import("std");

const ResultSlot = struct {
    mutex: std.Thread.Mutex = .{},
    cond: std.Thread.Condition = .{},
    value: ?[]const u8 = null,

    fn send(self: *ResultSlot, val: []const u8) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.value = val;
        self.cond.signal();
    }

    // Returns the value if it arrives within timeout_ns, otherwise null.
    fn recvTimeout(self: *ResultSlot, timeout_ns: u64) ?[]const u8 {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (self.value == null) {
            self.cond.timedWait(&self.mutex, timeout_ns) catch {};
        }
        return self.value;
    }
};

var slot1 = ResultSlot{};
var slot2 = ResultSlot{};

fn worker1(_: void) void {
    std.Thread.sleep(2 * std.time.ns_per_s);
    slot1.send("result 1");
}

fn worker2(_: void) void {
    std.Thread.sleep(2 * std.time.ns_per_s);
    slot2.send("result 2");
}

pub fn main() !void {
    // First case: operation takes 2s, timeout is 1s -> timeout fires.
    const t1 = try std.Thread.spawn(.{}, worker1, .{{}});
    if (slot1.recvTimeout(1 * std.time.ns_per_s)) |res| {
        std.debug.print("{s}\n", .{res});
    } else {
        std.debug.print("timeout 1\n", .{});
    }
    t1.join();

    // Second case: operation takes 2s, timeout is 3s -> result arrives.
    const t2 = try std.Thread.spawn(.{}, worker2, .{{}});
    if (slot2.recvTimeout(3 * std.time.ns_per_s)) |res| {
        std.debug.print("{s}\n", .{res});
    } else {
        std.debug.print("timeout 2\n", .{});
    }
    t2.join();
}
