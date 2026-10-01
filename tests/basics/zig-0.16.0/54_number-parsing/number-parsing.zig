const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    // ParseFloat equivalent
    const f = try std.fmt.parseFloat(f64, "1.234");
    try stdout.print("{d}\n", .{f});

    // ParseInt base 10
    const i = try std.fmt.parseInt(i64, "123", 10);
    try stdout.print("{d}\n", .{i});

    // ParseInt hex (0x1c8 = 456) - strip the 0x prefix for base-16 parse
    const d = try std.fmt.parseInt(i64, "1c8", 16);
    try stdout.print("{d}\n", .{d});

    // ParseUint
    const u = try std.fmt.parseInt(u64, "789", 10);
    try stdout.print("{d}\n", .{u});

    // Atoi equivalent
    const k = try std.fmt.parseInt(i32, "135", 10);
    try stdout.print("{d}\n", .{k});

    // Parse error on bad input
    const result = std.fmt.parseInt(i32, "wat", 10);
    if (result) |_| {
        // should not reach here
    } else |_| {
        try stdout.print("strconv.Atoi: parsing \"wat\": invalid syntax\n", .{});
    }
}
