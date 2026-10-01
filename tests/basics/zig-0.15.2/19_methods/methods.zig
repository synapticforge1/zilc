const std = @import("std");

const Rect = struct {
    width: i64,
    height: i64,

    fn area(self: *const Rect) i64 {
        return self.width * self.height;
    }

    fn perim(self: Rect) i64 {
        return 2 * self.width + 2 * self.height;
    }
};

pub fn main() void {
    const r = Rect{ .width = 10, .height = 5 };

    std.debug.print("area:  {d}\n", .{r.area()});
    std.debug.print("perim: {d}\n", .{r.perim()});

    const rp = &r;
    std.debug.print("area:  {d}\n", .{rp.area()});
    std.debug.print("perim: {d}\n", .{rp.perim()});
}
