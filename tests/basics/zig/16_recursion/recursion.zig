const std = @import("std");

fn fact(n: i64) i64 {
    if (n == 0) return 1;
    return n * fact(n - 1);
}

pub fn main() void {
    std.debug.print("{d}\n", .{fact(7)});
}
