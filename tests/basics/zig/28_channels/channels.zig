// Channels are the pipes that connect concurrent goroutines. Zig has no
// built-in channels; this example uses a mutex-protected slot with a
// condition variable to simulate a synchronous unbuffered channel.

const std = @import("std");

const StringChannel = struct {
    mutex: std.Thread.Mutex = .{},
    cond: std.Thread.Condition = .{},
    value: ?[]const u8 = null,

    fn send(self: *StringChannel, val: []const u8) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.value = val;
        self.cond.signal();
    }

    fn recv(self: *StringChannel) []const u8 {
        self.mutex.lock();
        defer self.mutex.unlock();
        while (self.value == null) {
            self.cond.wait(&self.mutex);
        }
        return self.value.?;
    }
};

var messages = StringChannel{};

fn sender(_: void) void {
    messages.send("ping");
}

pub fn main() !void {
    const t = try std.Thread.spawn(.{}, sender, .{{}});
    const msg = messages.recv();
    std.debug.print("{s}\n", .{msg});
    t.join();
}
