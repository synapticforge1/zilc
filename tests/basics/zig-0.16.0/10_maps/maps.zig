const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var m = std.StringHashMap(i64).init(allocator);
    defer m.deinit();

    try m.put("k1", 7);
    try m.put("k2", 13);

    // Print map in insertion order using sorted keys for determinism
    try stdout.print("map: map[k1:{d} k2:{d}]\n", .{ m.get("k1").?, m.get("k2").? });

    const v1 = m.get("k1").?;
    try stdout.print("v1:  {d}\n", .{v1});
    try stdout.print("len: {d}\n", .{m.count()});

    _ = m.remove("k2");
    try stdout.print("map: map[k1:{d}]\n", .{m.get("k1").?});

    const prs = m.contains("k2");
    try stdout.print("prs: {}\n", .{prs});

    var n = std.StringHashMap(i64).init(allocator);
    defer n.deinit();
    try n.put("foo", 1);
    try n.put("bar", 2);
    try stdout.print("map: map[bar:{d} foo:{d}]\n", .{ n.get("bar").?, n.get("foo").? });
}
