// Zig's standard library does not include a regular-expression engine;
// std.mem pattern-matching helpers are used instead.

const std = @import("std");

/// Returns true if s contains a p([a-z]+)ch pattern (starts with 'p', ends
/// with 'ch', has at least one lowercase letter between them).
fn matchPch(s: []const u8) bool {
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        if (s[i] != 'p') continue;
        var j = i + 1;
        while (j < s.len and s[j] >= 'a' and s[j] <= 'z') : (j += 1) {}
        if (j > i + 1 and j + 1 < s.len and s[j] == 'c' and s[j + 1] == 'h') {
            return true;
        }
    }
    return false;
}

/// Finds first substring matching p([a-z]+)ch, returns slice or null.
fn findPch(s: []const u8) ?[]const u8 {
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        if (s[i] != 'p') continue;
        var j = i + 1;
        while (j < s.len and s[j] >= 'a' and s[j] <= 'z') : (j += 1) {}
        if (j > i + 1 and j + 1 < s.len and s[j] == 'c' and s[j + 1] == 'h') {
            return s[i .. j + 2];
        }
    }
    return null;
}

/// Returns start/end indexes of first p([a-z]+)ch match.
fn findPchIndex(s: []const u8) ?[2]usize {
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        if (s[i] != 'p') continue;
        var j = i + 1;
        while (j < s.len and s[j] >= 'a' and s[j] <= 'z') : (j += 1) {}
        if (j > i + 1 and j + 1 < s.len and s[j] == 'c' and s[j + 1] == 'h') {
            return .{ i, j + 2 };
        }
    }
    return null;
}

/// Replace first p([a-z]+)ch match with replacement.
fn replacePch(
    allocator: std.mem.Allocator,
    s: []const u8,
    replacement: []const u8,
) ![]u8 {
    if (findPchIndex(s)) |idx| {
        const result = try allocator.alloc(u8, s.len - (idx[1] - idx[0]) + replacement.len);
        @memcpy(result[0..idx[0]], s[0..idx[0]]);
        @memcpy(result[idx[0]..][0..replacement.len], replacement);
        @memcpy(result[idx[0] + replacement.len ..], s[idx[1]..]);
        return result;
    }
    return allocator.dupe(u8, s);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;

    // MatchString equivalent
    try stdout.print("{}\n", .{matchPch("peach")});

    // MatchString on "peach"
    try stdout.print("{}\n", .{matchPch("peach")});

    // FindString
    if (findPch("peach punch")) |m| {
        try stdout.print("{s}\n", .{m});
    }

    // FindStringIndex
    if (findPchIndex("peach punch")) |idx| {
        try stdout.print("[{d} {d}]\n", .{ idx[0], idx[1] });
    }

    // FindStringSubmatch (whole match + submatch)
    if (findPch("peach punch")) |m| {
        // submatch is the inner [a-z]+ group
        const sub = m[1 .. m.len - 2];
        try stdout.print("[{s} {s}]\n", .{ m, sub });
    }

    // FindStringSubmatchIndex
    if (findPchIndex("peach punch")) |idx| {
        try stdout.print("[{d} {d} {d} {d}]\n", .{ idx[0], idx[1], idx[0] + 1, idx[1] - 2 });
    }

    // FindAllString
    const text = "peach punch pinch";
    try stdout.print("[", .{});
    var i: usize = 0;
    var first = true;
    while (i < text.len) {
        if (findPchIndex(text[i..])) |idx| {
            if (!first) try stdout.print(" ", .{});
            try stdout.print("{s}", .{text[i + idx[0] .. i + idx[1]]});
            first = false;
            i += idx[1];
        } else break;
    }
    try stdout.print("]\n", .{});

    // FindAllStringSubmatchIndex (all matches)
    try stdout.print("[", .{});
    i = 0;
    first = true;
    while (i < text.len) {
        if (findPchIndex(text[i..])) |idx| {
            const abs_start = i + idx[0];
            const abs_end = i + idx[1];
            const sub_start = abs_start + 1;
            const sub_end = abs_end - 2;
            if (!first) try stdout.print(" ", .{});
            try stdout.print("[{d} {d} {d} {d}]", .{ abs_start, abs_end, sub_start, sub_end });
            first = false;
            i += idx[1];
        } else break;
    }
    try stdout.print("]\n", .{});

    // FindAllString with limit 2
    try stdout.print("[", .{});
    i = 0;
    first = true;
    var count: usize = 0;
    while (i < text.len and count < 2) {
        if (findPchIndex(text[i..])) |idx| {
            if (!first) try stdout.print(" ", .{});
            try stdout.print("{s}", .{text[i + idx[0] .. i + idx[1]]});
            first = false;
            i += idx[1];
            count += 1;
        } else break;
    }
    try stdout.print("]\n", .{});

    // Match on []byte (same as string in Zig)
    try stdout.print("{}\n", .{matchPch("peach")});

    // MustCompile/print pattern representation
    try stdout.print("p([a-z]+)ch\n", .{});

    // ReplaceAllString
    const replaced = try replacePch(allocator, "a peach", "<fruit>");
    defer allocator.free(replaced);
    try stdout.print("{s}\n", .{replaced});

    // ReplaceAllFunc (uppercase the match)
    if (findPchIndex("a peach")) |idx| {
        const s = "a peach";
        const match = s[idx[0]..idx[1]];
        const upper = try std.ascii.allocUpperString(allocator, match);
        defer allocator.free(upper);
        try stdout.print("{s}{s}{s}\n", .{ s[0..idx[0]], upper, s[idx[1]..] });
    }
}
