const std = @import("std");

const Rect = struct {
    width: f64,
    height: f64,

    fn area(self: Rect) f64 {
        return self.width * self.height;
    }

    fn perim(self: Rect) f64 {
        return 2 * self.width + 2 * self.height;
    }
};

const Circle = struct {
    radius: f64,

    fn area(self: Circle) f64 {
        return std.math.pi * self.radius * self.radius;
    }

    fn perim(self: Circle) f64 {
        return 2 * std.math.pi * self.radius;
    }
};

const Geometry = union(enum) {
    rect: Rect,
    circle: Circle,

    fn area(self: Geometry) f64 {
        return switch (self) {
            .rect => |r| r.area(),
            .circle => |c| c.area(),
        };
    }

    fn perim(self: Geometry) f64 {
        return switch (self) {
            .rect => |r| r.perim(),
            .circle => |c| c.perim(),
        };
    }
};

fn measure(g: Geometry, stdout: anytype) !void {
    switch (g) {
        .rect => |r| try stdout.print("{{{d} {d}}}\n", .{ @as(i64, @intFromFloat(r.width)), @as(i64, @intFromFloat(r.height)) }),
        .circle => |c| try stdout.print("{{{d}}}\n", .{@as(i64, @intFromFloat(c.radius))}),
    }
    try stdout.print("{d}\n", .{g.area()});
    try stdout.print("{d}\n", .{g.perim()});
}

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    const r = Geometry{ .rect = Rect{ .width = 3, .height = 4 } };
    const c = Geometry{ .circle = Circle{ .radius = 5 } };

    try measure(r, stdout);
    try measure(c, stdout);
}
