const std = @import("std");

const AnyType = union(enum) {
    boolean: bool,
    integer: i64,
    string: []const u8,
};

fn whatAmI(val: AnyType) void {
    switch (val) {
        .boolean => std.debug.print("I'm a bool\n", .{}),
        .integer => std.debug.print("I'm an int\n", .{}),
        .string => std.debug.print("Don't know type string\n", .{}),
    }
}

pub fn main() void {
    const i: i64 = 2;
    std.debug.print("Write {d} as ", .{i});
    switch (i) {
        1 => std.debug.print("one\n", .{}),
        2 => std.debug.print("two\n", .{}),
        3 => std.debug.print("three\n", .{}),
        else => {},
    }

    const epoch_secs = std.time.timestamp();
    const secs_per_day: i64 = 86400;
    const days_since_epoch = @divFloor(epoch_secs, secs_per_day);
    // Unix epoch (Jan 1, 1970) was a Thursday; offset +4 aligns to Sunday=0
    const weekday: i64 = @mod(days_since_epoch + 4, 7);
    switch (weekday) {
        0, 6 => std.debug.print("It's the weekend\n", .{}),
        else => std.debug.print("It's a weekday\n", .{}),
    }

    const secs_in_day = @mod(epoch_secs, secs_per_day);
    const hour = @divFloor(secs_in_day, 3600);
    if (hour < 12) {
        std.debug.print("It's before noon\n", .{});
    } else {
        std.debug.print("It's after noon\n", .{});
    }

    whatAmI(.{ .boolean = true });
    whatAmI(.{ .integer = 1 });
    whatAmI(.{ .string = "hey" });
}
