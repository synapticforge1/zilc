const std = @import("std");

fn plus(a: i64, b: i64) i64 {
    return a + b;
}

fn plusPlus(a: i64, b: i64, c: i64) i64 {
    return a + b + c;
}

pub fn main() void {
    const res = plus(1, 2);
    std.debug.print("1+2 = {d}\n", .{res});

    const res2 = plusPlus(1, 2, 3);
    std.debug.print("1+2+3 = {d}\n", .{res2});
}
