const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;

    // Contains
    try stdout.print("Contains:  {}\n", .{std.mem.indexOf(u8, "test", "es") != null});

    // Count occurrences of "t" in "test"
    try stdout.print("Count:     {d}\n", .{std.mem.count(u8, "test", "t")});

    // HasPrefix
    try stdout.print("HasPrefix: {}\n", .{std.mem.startsWith(u8, "test", "te")});

    // HasSuffix
    try stdout.print("HasSuffix: {}\n", .{std.mem.endsWith(u8, "test", "st")});

    // Index of "e" in "test" = 1
    const idx = std.mem.indexOf(u8, "test", "e");
    try stdout.print("Index:     {d}\n", .{if (idx) |i| @as(i32, @intCast(i)) else -1});

    // Join ["a","b"] with "-"
    const joined = try std.mem.join(allocator, "-", &[_][]const u8{ "a", "b" });
    defer allocator.free(joined);
    try stdout.print("Join:      {s}\n", .{joined});

    // Repeat "a" 5 times
    const repeated = try allocator.alloc(u8, 5);
    defer allocator.free(repeated);
    @memset(repeated, 'a');
    try stdout.print("Repeat:    {s}\n", .{repeated});

    // Replace all "o" with "0" in "foo"
    const replaceAll = try std.mem.replaceOwned(u8, allocator, "foo", "o", "0");
    defer allocator.free(replaceAll);
    try stdout.print("Replace:   {s}\n", .{replaceAll});

    // Replace first "o" with "0" in "foo"
    var buf1: [64]u8 = undefined;
    var buf1_idx: usize = 0;
    const haystack = "foo";
    const needle = "o";
    const replacement = "0";
    var remaining: []const u8 = haystack;
    var replaced_once = false;
    while (remaining.len > 0) {
        if (!replaced_once) {
            if (std.mem.indexOf(u8, remaining, needle)) |pos| {
                @memcpy(buf1[buf1_idx..][0..pos], remaining[0..pos]);
                buf1_idx += pos;
                @memcpy(buf1[buf1_idx..][0..replacement.len], replacement);
                buf1_idx += replacement.len;
                remaining = remaining[pos + needle.len ..];
                replaced_once = true;
                continue;
            }
        }
        buf1[buf1_idx] = remaining[0];
        buf1_idx += 1;
        remaining = remaining[1..];
    }
    try stdout.print("Replace:   {s}\n", .{buf1[0..buf1_idx]});

    // Split "a-b-c-d-e" by "-"
    var iter = std.mem.splitSequence(u8, "a-b-c-d-e", "-");
    try stdout.print("Split:     [", .{});
    var first = true;
    while (iter.next()) |part| {
        if (!first) try stdout.print(" ", .{});
        try stdout.print("{s}", .{part});
        first = false;
    }
    try stdout.print("]\n", .{});

    // ToLower
    const lower = try std.ascii.allocLowerString(allocator, "TEST");
    defer allocator.free(lower);
    try stdout.print("ToLower:   {s}\n", .{lower});

    // ToUpper
    const upper = try std.ascii.allocUpperString(allocator, "test");
    defer allocator.free(upper);
    try stdout.print("ToUpper:   {s}\n", .{upper});

    // Len
    try stdout.print("Len: {d}\n", .{"hello".len});

    // Char (byte value at index 1)
    try stdout.print("Char: {d}\n", .{"hello"[1]});
}
