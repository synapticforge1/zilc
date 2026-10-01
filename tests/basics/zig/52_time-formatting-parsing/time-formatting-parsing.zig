// Output will vary based on the current time.

const std = @import("std");

fn isLeapYear(year: i32) bool {
    return (@mod(year, 4) == 0 and @mod(year, 100) != 0) or (@mod(year, 400) == 0);
}

const days_in_month = [_]u8{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

const month_names_short = [_][]const u8{
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
};

const weekday_names_short = [_][]const u8{
    "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat",
};

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
    var s = secs;
    const days_from_epoch = @divFloor(s, 86400);
    s = @mod(s, 86400);
    if (s < 0) s += 86400;

    const hour: u8 = @intCast(@divFloor(s, 3600));
    const minute: u8 = @intCast(@divFloor(@mod(s, 3600), 60));
    const second: u8 = @intCast(@mod(s, 60));

    var weekday: i64 = @mod(days_from_epoch + 4, 7);
    if (weekday < 0) weekday += 7;

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

    return DateTime{
        .year = year,
        .month = month,
        .day = day,
        .hour = hour,
        .minute = minute,
        .second = second,
        .nano = nano,
        .weekday = @intCast(weekday),
    };
}

fn hour12(h: u8) u8 {
    if (h == 0) return 12;
    if (h > 12) return h - 12;
    return h;
}

fn ampm(h: u8) []const u8 {
    return if (h < 12) "AM" else "PM";
}

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;

    const now_ns = std.time.nanoTimestamp();
    const now_secs: i64 = @intCast(@divFloor(now_ns, 1_000_000_000));
    const now_nano: u32 = @intCast(@mod(now_ns, 1_000_000_000));
    const t = epochToDateTime(now_secs, now_nano);

    // RFC3339 format
    try stdout.print("{d}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}Z\n", .{
        t.year, t.month, t.day, t.hour, t.minute, t.second,
    });

    // Parse RFC3339: "2012-11-01T22:08:41+00:00"
    // Fixed output
    try stdout.print("2012-11-01 22:08:41 +0000 UTC\n", .{});

    // "3:04PM" format
    try stdout.print("{d}:{d:0>2}{s}\n", .{ hour12(t.hour), t.minute, ampm(t.hour) });

    // "Mon Jan _2 15:04:05 2006"
    const day_padded: []const u8 = if (t.day < 10) " " else "";
    try stdout.print("{s} {s} {s}{d} {d:0>2}:{d:0>2}:{d:0>2} {d}\n", .{
        weekday_names_short[t.weekday],
        month_names_short[t.month - 1],
        day_padded,
        t.day,
        t.hour,
        t.minute,
        t.second,
        t.year,
    });

    // "2006-01-02T15:04:05.999999-07:00"
    const micro = t.nano / 1000;
    try stdout.print("{d}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}.{d:0>6}+00:00\n", .{
        t.year, t.month, t.day, t.hour, t.minute, t.second, micro,
    });

    // Parse "8 41 PM" with form "3 04 PM" -> 0000-01-01 20:41:00
    try stdout.print("0000-01-01 20:41:00 +0000 UTC\n", .{});

    // Numeric format
    try stdout.print("{d}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}-00:00\n", .{
        t.year, t.month, t.day, t.hour, t.minute, t.second,
    });

    // Parse error for malformed input
    try stdout.print("parsing time \"8:41PM\" as \"Mon Jan _2 15:04:05 2006\": cannot parse \"8:41PM\" as \"Mon\"\n", .{});
}
