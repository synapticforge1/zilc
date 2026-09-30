// For more complex state a mutex safely synchronizes data across multiple
// threads.

const std = @import("std");

const Container = struct {
    mutex: std.Thread.Mutex = .{},
    a: i64 = 0,
    b: i64 = 0,

    fn inc(self: *Container, key: u8) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        switch (key) {
            'a' => self.a += 1,
            'b' => self.b += 1,
            else => {},
        }
    }
};

var container = Container{};

const IncrArgs = struct { key: u8, n: usize };

fn doIncrement(args: IncrArgs) void {
    for (0..args.n) |_| {
        container.inc(args.key);
    }
}

pub fn main() !void {
    const t1 = try std.Thread.spawn(.{}, doIncrement, .{IncrArgs{ .key = 'a', .n = 10000 }});
    const t2 = try std.Thread.spawn(.{}, doIncrement, .{IncrArgs{ .key = 'a', .n = 10000 }});
    const t3 = try std.Thread.spawn(.{}, doIncrement, .{IncrArgs{ .key = 'b', .n = 10000 }});

    t1.join();
    t2.join();
    t3.join();

    std.debug.print("map[a:{d} b:{d}]\n", .{ container.a, container.b });
}
