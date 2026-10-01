const std = @import("std");

const ValPair = struct { a: i64, b: i64 };

fn vals() ValPair {
    return .{ .a = 3, .b = 7 };
}

pub fn main() void {
    const result = vals();
    std.debug.print("{d}\n", .{result.a});
    std.debug.print("{d}\n", .{result.b});

    const result2 = vals();
    std.debug.print("{d}\n", .{result2.b});
}
