// Output will vary based on the current time.

const std = @import("std");

fn isLeapYear(year: i32) bool {
    return (@mod(year, 4) == 0 and @mod(year, 100) != 0) or (@mod(year, 400) == 0);
}

const days_in_month = [_]u8{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

fn printEpochAsTime(writer: anytype, secs: i64, nano: i64) !void {
    var s = secs;
    const days_from_epoch = @divFloor(s, 86400);
    s = @mod(s, 86400);
    if (s < 0) s += 86400;

    const hour: u8 = @intCast(@divFloor(s, 3600));
    const minute: u8 = @intCast(@divFloor(@mod(s, 3600), 60));
    const second: u8 = @intCast(@mod(s, 60));

    var d = days_from_epoch;
    var year: i32 = 1970;
    if (d >= 0) {
        while (true) {
            const days_in_year: i64 = if (isLeapYear(year)) 366 else 365;
            if (d < days_in_year) break;
            d -= days_in_year;
            year += 1;
        }
    } else {
        while (d < 0) {
            year -= 1;
            d += if (isLeapYear(year)) 366 else 365;
        }
    }

    var month: u8 = 1;
    var remaining: i64 = d;
    for (days_in_month, 0..) |dim, mi| {
        var days: i64 = dim;
        if (mi == 1 and isLeapYear(year)) days = 29;
        if (remaining < days) {
            month = @intCast(mi + 1);
            break;
        }
        remaining -= days;
    }
    const day: u8 = @intCast(remaining + 1);

    try writer.print("{d}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}.{d:0>9} +0000 UTC\n", .{
        year, month, day, hour, minute, second, nano,
    });
}

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    const now_ns = std.time.nanoTimestamp();
    const secs: i64 = @intCast(@divFloor(now_ns, 1_000_000_000));
    const nanos: i64 = @intCast(@mod(now_ns, 1_000_000_000));
    const millis: i64 = @intCast(@divFloor(now_ns, 1_000_000));

    try printEpochAsTime(stdout, secs, nanos);
    try stdout.print("{d}\n", .{secs});
    try stdout.print("{d}\n", .{millis});
    try stdout.print("{d}\n", .{now_ns});

    // time.Unix(secs, 0) and time.Unix(0, nanos_total)
    try printEpochAsTime(stdout, secs, 0);
    try printEpochAsTime(stdout, secs, nanos);
}
