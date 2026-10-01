// Go's select lets you wait on multiple channel operations. Zig has no
// built-in select; this example uses two threads each sleeping then
// writing to a shared slot, and a polling loop to read results in order.

const std = @import("std");

// zilc: 0.16 moved Mutex/Condition from std.Thread to std.Io; they block through an Io,
// so the methods take one (Uncancelable: nothing here cancels, and the originals could not fail).
const Slot = struct {
    mutex: std.Io.Mutex = .init,
    cond: std.Io.Condition = .init,
    value: ?[]const u8 = null,

    fn send(self: *Slot, io: std.Io, val: []const u8) void {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);
        self.value = val;
        self.cond.signal(io);
    }

    fn recv(self: *Slot, io: std.Io) []const u8 {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);
        while (self.value == null) {
            self.cond.waitUncancelable(io, &self.mutex);
        }
        const v = self.value.?;
        self.value = null;
        return v;
    }
};

var c1 = Slot{};
var c2 = Slot{};

// zilc: 0.16 removed std.time.sleep / std.Thread.sleep; sleeping goes through Io.sleep.
fn sendOne(io: std.Io) void {
    io.sleep(.fromNanoseconds(1 * std.time.ns_per_s), .awake) catch {};
    c1.send(io, "one");
}

fn sendTwo(io: std.Io) void {
    io.sleep(.fromNanoseconds(2 * std.time.ns_per_s), .awake) catch {};
    c2.send(io, "two");
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const t1 = try std.Thread.spawn(.{}, sendOne, .{io});
    const t2 = try std.Thread.spawn(.{}, sendTwo, .{io});

    // Receive from whichever channel is ready first, then the second.
    // We simulate select by waiting on each in arrival order.
    const msg1 = c1.recv(io);
    std.debug.print("received {s}\n", .{msg1});
    const msg2 = c2.recv(io);
    std.debug.print("received {s}\n", .{msg2});

    t1.join();
    t2.join();
}
