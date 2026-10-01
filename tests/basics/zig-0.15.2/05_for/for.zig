const std = @import("std");

pub fn main() void {
    var i: i64 = 1;
    while (i <= 3) {
        std.debug.print("{d}\n", .{i});
        i += 1;
    }

    var j: i64 = 7;
    while (j <= 9) : (j += 1) {
        std.debug.print("{d}\n", .{j});
    }

    while (true) {
        std.debug.print("loop\n", .{});
        break;
    }

    var n: i64 = 0;
    while (n <= 5) : (n += 1) {
        if (@mod(n, 2) == 0) continue;
        std.debug.print("{d}\n", .{n});
    }
}
