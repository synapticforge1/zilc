// Go's select lets you wait on multiple channel operations. Zig has no
// built-in select; this example uses two threads each sleeping then
// writing to a shared slot, and a polling loop to read results in order.

const std = @import("std");

const Slot = struct {
    mutex: std.Thread.Mutex = .{},
    cond: std.Thread.Condition = .{},
    value: ?[]const u8 = null,

    fn send(self: *Slot, val: []const u8) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.value = val;
        self.cond.signal();
    }

    fn recv(self: *Slot) []const u8 {
        self.mutex.lock();
        defer self.mutex.unlock();
        while (self.value == null) {
            self.cond.wait(&self.mutex);
        }
        const v = self.value.?;
        self.value = null;
        return v;
    }
};

var c1 = Slot{};
var c2 = Slot{};

fn sendOne(_: void) void {
    std.Thread.sleep(1 * std.time.ns_per_s);
    c1.send("one");
}

fn sendTwo(_: void) void {
    std.Thread.sleep(2 * std.time.ns_per_s);
    c2.send("two");
}

pub fn main() !void {
    const t1 = try std.Thread.spawn(.{}, sendOne, .{{}});
    const t2 = try std.Thread.spawn(.{}, sendTwo, .{{}});

    // Receive from whichever channel is ready first, then the second.
    // We simulate select by waiting on each in arrival order.
    const msg1 = c1.recv();
    std.debug.print("received {s}\n", .{msg1});
    const msg2 = c2.recv();
    std.debug.print("received {s}\n", .{msg2});

    t1.join();
    t2.join();
}
