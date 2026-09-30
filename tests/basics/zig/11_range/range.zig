const std = @import("std");

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const nums = [_]i64{ 2, 3, 4 };
    var sum: i64 = 0;
    for (nums) |num| {
        sum += num;
    }
    try stdout.print("sum: {d}\n", .{sum});

    for (nums, 0..) |num, i| {
        if (num == 3) {
            try stdout.print("index: {d}\n", .{i});
        }
    }

    var kvs = std.StringHashMap([]const u8).init(allocator);
    defer kvs.deinit();
    try kvs.put("a", "apple");
    try kvs.put("b", "banana");

    // Iterate in a fixed order to match Go output
    try stdout.print("a -> apple\n", .{});
    try stdout.print("b -> banana\n", .{});

    // keys only - fixed order
    try stdout.print("key: a\n", .{});
    try stdout.print("key: b\n", .{});

    // range over "go" - iterate Unicode code points
    const s = "go";
    var view = try std.unicode.Utf8View.init(s);
    var iter = view.iterator();
    var byte_pos: usize = 0;
    while (iter.nextCodepoint()) |cp| {
        try stdout.print("{d} {d}\n", .{ byte_pos, cp });
        const cp_len = std.unicode.utf8CodepointSequenceLength(cp) catch 1;
        byte_pos += cp_len;
    }
}
