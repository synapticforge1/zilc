// Channels are the pipes that connect concurrent goroutines. Zig has no
// built-in channels; this example uses a mutex-protected slot with a
// condition variable to simulate a synchronous unbuffered channel.

const std = @import("std");

// zilc: 0.16 moved Mutex/Condition from std.Thread to std.Io; they block through an Io,
// so the methods take one (Uncancelable: nothing here cancels, and the originals could not fail).
const StringChannel = struct {
    mutex: std.Io.Mutex = .init,
    cond: std.Io.Condition = .init,
    value: ?[]const u8 = null,

    fn send(self: *StringChannel, io: std.Io, val: []const u8) void {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);
        self.value = val;
        self.cond.signal(io);
    }

    fn recv(self: *StringChannel, io: std.Io) []const u8 {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);
        while (self.value == null) {
            self.cond.waitUncancelable(io, &self.mutex);
        }
        return self.value.?;
    }
};

var messages = StringChannel{};

fn sender(io: std.Io) void {
    messages.send(io, "ping");
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const t = try std.Thread.spawn(.{}, sender, .{io});
    const msg = messages.recv(io);
    std.debug.print("{s}\n", .{msg});
    t.join();
}
