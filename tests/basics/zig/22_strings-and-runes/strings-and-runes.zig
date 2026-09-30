const std = @import("std");

fn examineRune(r: u21, stdout: anytype) !void {
    if (r == 't') {
        try stdout.print("found tee\n", .{});
    } else if (r == 0x0E2A) { // 'ส'
        try stdout.print("found so sua\n", .{});
    }
}

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    const s = "สวัสดี";

    try stdout.print("Len: {d}\n", .{s.len});

    for (s) |b| {
        try stdout.print("{x} ", .{b});
    }
    try stdout.print("\n", .{});

    var rune_count: usize = 0;
    var view = try std.unicode.Utf8View.init(s);
    var iter = view.iterator();
    while (iter.nextCodepoint()) |_| {
        rune_count += 1;
    }
    try stdout.print("Rune count: {d}\n", .{rune_count});

    view = try std.unicode.Utf8View.init(s);
    iter = view.iterator();
    var byte_pos: usize = 0;
    while (iter.nextCodepoint()) |cp| {
        try stdout.print("U+{X:0>4} '{u}' starts at {d}\n", .{ cp, cp, byte_pos });
        const cp_len = std.unicode.utf8CodepointSequenceLength(cp) catch 1;
        byte_pos += cp_len;
    }

    try stdout.print("\nUsing DecodeRuneInString\n", .{});

    var i: usize = 0;
    while (i < s.len) {
        const cp_len = std.unicode.utf8ByteSequenceLength(s[i]) catch 1;
        const end = i + cp_len;
        const cp = std.unicode.utf8Decode(s[i..end]) catch 0xFFFD;
        try stdout.print("U+{X:0>4} '{u}' starts at {d}\n", .{ cp, cp, i });
        try examineRune(cp, stdout);
        i += cp_len;
    }
}
