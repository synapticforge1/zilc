const std = @import("std");

const Base = struct {
    num: i64,

    fn describe(self: Base, buf: []u8) ![]u8 {
        return std.fmt.bufPrint(buf, "base with num={d}", .{self.num});
    }
};

const Container = struct {
    base: Base,
    str: []const u8,

    fn describe(self: Container, buf: []u8) ![]u8 {
        return self.base.describe(buf);
    }
};

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    const co = Container{
        .base = Base{ .num = 1 },
        .str = "some name",
    };

    try stdout.print("co={{num: {d}, str: {s}}}\n", .{ co.base.num, co.str });
    try stdout.print("also num: {d}\n", .{co.base.num});

    var buf: [64]u8 = undefined;
    const desc = try co.describe(&buf);
    try stdout.print("describe: {s}\n", .{desc});

    // Describer interface - use the same describe method
    const desc2 = try co.describe(&buf);
    try stdout.print("describer: {s}\n", .{desc2});
}
