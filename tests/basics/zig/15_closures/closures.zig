const std = @import("std");

const IntSeq = struct {
    i: i64 = 0,

    fn next(self: *IntSeq) i64 {
        self.i += 1;
        return self.i;
    }
};

pub fn main() void {
    var nextInt = IntSeq{};
    std.debug.print("{d}\n", .{nextInt.next()});
    std.debug.print("{d}\n", .{nextInt.next()});
    std.debug.print("{d}\n", .{nextInt.next()});

    var newInts = IntSeq{};
    std.debug.print("{d}\n", .{newInts.next()});
}
