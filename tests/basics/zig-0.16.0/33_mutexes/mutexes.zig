// For more complex state a mutex safely synchronizes data across multiple
// threads.

const std = @import("std");

// zilc: 0.16 moved Mutex from std.Thread to std.Io; it blocks through an Io, so inc takes one
// (lockUncancelable: nothing here cancels, and the original lock could not fail).
const Container = struct {
    mutex: std.Io.Mutex = .init,
    a: i64 = 0,
    b: i64 = 0,

    fn inc(self: *Container, io: std.Io, key: u8) void {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);
        switch (key) {
            'a' => self.a += 1,
            'b' => self.b += 1,
            else => {},
        }
    }
};

var container = Container{};

const IncrArgs = struct { key: u8, n: usize };

fn doIncrement(io: std.Io, args: IncrArgs) void {
    for (0..args.n) |_| {
        container.inc(io, args.key);
    }
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const t1 = try std.Thread.spawn(.{}, doIncrement, .{ io, IncrArgs{ .key = 'a', .n = 10000 } });
    const t2 = try std.Thread.spawn(.{}, doIncrement, .{ io, IncrArgs{ .key = 'a', .n = 10000 } });
    const t3 = try std.Thread.spawn(.{}, doIncrement, .{ io, IncrArgs{ .key = 'b', .n = 10000 } });

    t1.join();
    t2.join();
    t3.join();

    std.debug.print("map[a:{d} b:{d}]\n", .{ container.a, container.b });
}
