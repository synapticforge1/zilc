const std = @import("std");

pub fn main() void {
    if (7 % 2 == 0) {
        std.debug.print("7 is even\n", .{});
    } else {
        std.debug.print("7 is odd\n", .{});
    }

    if (8 % 4 == 0) {
        std.debug.print("8 is divisible by 4\n", .{});
    }

    const num: i64 = 9;
    if (num < 0) {
        std.debug.print("{d} is negative\n", .{num});
    } else if (num < 10) {
        std.debug.print("{d} has 1 digit\n", .{num});
    } else {
        std.debug.print("{d} has multiple digits\n", .{num});
    }
}
