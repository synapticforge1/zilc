const std = @import("std");

pub fn main() void {
    const a: []const u8 = "initial";
    std.debug.print("{s}\n", .{a});

    const b: i64 = 1;
    const c: i64 = 2;
    std.debug.print("{d} {d}\n", .{ b, c });

    const d: bool = true;
    std.debug.print("{}\n", .{d});

    const e: i64 = 0;
    std.debug.print("{d}\n", .{e});

    const f: []const u8 = "apple";
    std.debug.print("{s}\n", .{f});
}
