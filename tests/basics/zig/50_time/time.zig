// Output will vary based on the current time.

const std = @import("std");

const days_in_month = [_]u8{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

const month_names = [_][]const u8{
    "January", "February", "March",     "April",   "May",      "June",
    "July",    "August",   "September", "October", "November", "December",
};

const weekday_names = [_][]const u8{
    "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
};

fn isLeapYear(year: i32) bool {
    return (@mod(year, 4) == 0 and @mod(year, 100) != 0) or (@mod(year, 400) == 0);
}

const DateTime = struct {
    year: i32,
    month: u8,
    day: u8,
    hour: u8,
    minute: u8,
    second: u8,
    nano: u32,
    weekday: u8,
};

fn epochToDateTime(secs: i64, nano: u32) DateTime {
    const days_from_epoch = @divFloor(secs, 86400);
    const time_of_day = @mod(secs, 86400);
    const tod: i64 = if (time_of_day < 0) time_of_day + 86400 else time_of_day;

    const hour: u8 = @intCast(@divFloor(tod, 3600));
    const minute: u8 = @intCast(@divFloor(@mod(tod, 3600), 60));
    const second: u8 = @intCast(@mod(tod, 60));

    // Jan 1 1970 was Thursday (weekday 4)
    const wd_raw = @mod(days_from_epoch + 4, 7);
    const weekday: u8 = @intCast(if (wd_raw < 0) wd_raw + 7 else wd_raw);

    var d: i64 = days_from_epoch;
    var year: i32 = 1970;
    if (d >= 0) {
        while (true) {
            const dy: i64 = if (isLeapYear(year)) 366 else 365;
            if (d < dy) break;
            d -= dy;
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
        const days: i64 = if (mi == 1 and isLeapYear(year)) 29 else dim;
        if (remaining < days) {
            month = @intCast(mi + 1);
            break;
        }
        remaining -= days;
    }
    const day: u8 = @intCast(remaining + 1);

    return DateTime{
        .year = year, .month = month, .day = day,
        .hour = hour, .minute = minute, .second = second,
        .nano = nano, .weekday = weekday,
    };
}

fn printDateTime(writer: anytype, dt: DateTime) !void {
    try writer.print("{d}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}.{d:0>9} +0000 UTC\n", .{
        dt.year, dt.month, dt.day,
        dt.hour, dt.minute, dt.second, dt.nano,
    });
}

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    const now_ns: i128 = std.time.nanoTimestamp();
    const now_secs: i64 = @intCast(@divFloor(now_ns, 1_000_000_000));
    const now_nano: u32 = @intCast(@mod(now_ns, 1_000_000_000));
    const now = epochToDateTime(now_secs, now_nano);

    try printDateTime(stdout, now);

    // Fixed time: 2009-11-17 20:34:58.651387237 UTC
    const then_secs: i64 = 1258490098;
    const then_nano: u32 = 651387237;
    const then = epochToDateTime(then_secs, then_nano);

    try printDateTime(stdout, then);
    try stdout.print("{d}\n", .{then.year});
    try stdout.print("{s}\n", .{month_names[then.month - 1]});
    try stdout.print("{d}\n", .{then.day});
    try stdout.print("{d}\n", .{then.hour});
    try stdout.print("{d}\n", .{then.minute});
    try stdout.print("{d}\n", .{then.second});
    try stdout.print("{d}\n", .{then.nano});
    try stdout.print("UTC\n", .{});
    try stdout.print("{s}\n", .{weekday_names[then.weekday]});

    // Comparisons (then is in the past)
    try stdout.print("{}\n", .{then_secs < now_secs});
    try stdout.print("{}\n", .{then_secs > now_secs});
    try stdout.print("{}\n", .{then_secs == now_secs});

    // Duration between now and then
    const diff_secs = now_secs - then_secs;
    const diff_ns_part: i64 = @as(i64, now_nano) - @as(i64, then_nano);
    const total_diff_ns = diff_secs * 1_000_000_000 + diff_ns_part;
    const diff_s = @as(f64, @floatFromInt(total_diff_ns)) / 1.0e9;
    const diff_hours = diff_s / 3600.0;
    const diff_minutes = diff_s / 60.0;
    const h_int = @as(i64, @intFromFloat(@floor(diff_hours)));
    const m_int = @as(i64, @intFromFloat(@floor(@mod(diff_s, 3600.0) / 60.0)));
    const s_int = @as(i64, @intFromFloat(@floor(@mod(diff_s, 60.0))));
    const ns_int = diff_ns_part + diff_secs * 1_000_000_000;

    try stdout.print("{d}h{d}m{d}s\n", .{ h_int, m_int, s_int });
    try stdout.print("{d}\n", .{diff_hours});
    try stdout.print("{d}\n", .{diff_minutes});
    try stdout.print("{d}\n", .{diff_s});
    try stdout.print("{d}\n", .{ns_int});

    // then.Add(diff) = approximately now
    try printDateTime(stdout, epochToDateTime(now_secs, now_nano));

    // then.Add(-diff) = then - (now - then) = 2*then - now
    const sub_secs = then_secs - diff_secs;
    const sub_nano_i: i64 = @as(i64, then_nano) - diff_ns_part;
    const sub_secs_adj = if (sub_nano_i < 0) sub_secs - 1 else sub_secs;
    const sub_nano: u32 = if (sub_nano_i < 0)
        @intCast(sub_nano_i + 1_000_000_000)
    else
        @intCast(sub_nano_i);
    try printDateTime(stdout, epochToDateTime(sub_secs_adj, sub_nano));
}
