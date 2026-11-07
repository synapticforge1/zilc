// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! The Zig side of tools/sarcasm/check-luau-table.ts: replays an operation trace on
//! src/sarcasm/luau_table.zig and prints what the Luau side prints (each `#t`, and each traversal
//! as the keys' indices in the trace's key pool).
//!
//!   luau-table-check <trace>
//! Trace lines: `K n <f64 bits hex>` / `K s <hex bytes>` (the key pool, in order), then per
//! scenario `S`, and `set <k> <v>`, `nil <k>`, `ins <v>`, `insat <pos> <v>`, `rem <pos|_>`, `len`,
//! `dump`.

const std = @import("std");
const lt = @import("luau_table");

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const gpa = arena_state.allocator();
    const args = try std.process.argsAlloc(gpa);
    const text = try std.fs.cwd().readFileAlloc(gpa, args[1], 1 << 30);

    var keys: std.ArrayList(lt.Key) = .empty;
    var out: std.ArrayList(u8) = .empty;
    var t: ?lt.Table(i64) = null;
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |line| {
        var w = std.mem.tokenizeScalar(u8, line, ' ');
        const op = w.next() orelse continue;
        if (std.mem.eql(u8, op, "K")) {
            const kind = w.next().?;
            const hex = w.next() orelse "";
            if (std.mem.eql(u8, kind, "n")) {
                try keys.append(gpa, .{ .num = @bitCast(try std.fmt.parseInt(u64, hex, 16)) });
            } else {
                const bytes = try gpa.alloc(u8, hex.len / 2);
                _ = try std.fmt.hexToBytes(bytes, hex);
                try keys.append(gpa, .{ .str = bytes });
            }
        } else if (std.mem.eql(u8, op, "S")) {
            t = try lt.Table(i64).init(gpa, 0, 0);
        } else if (std.mem.eql(u8, op, "set")) {
            const k = keys.items[try std.fmt.parseInt(usize, w.next().?, 10)];
            try t.?.set(k, try std.fmt.parseInt(i64, w.next().?, 10));
        } else if (std.mem.eql(u8, op, "nil")) {
            try t.?.set(keys.items[try std.fmt.parseInt(usize, w.next().?, 10)], null);
        } else if (std.mem.eql(u8, op, "ins")) {
            try t.?.append(try std.fmt.parseInt(i64, w.next().?, 10));
        } else if (std.mem.eql(u8, op, "insat")) {
            const pos = try std.fmt.parseInt(i32, w.next().?, 10);
            try t.?.insertAt(pos, try std.fmt.parseInt(i64, w.next().?, 10));
        } else if (std.mem.eql(u8, op, "rem")) {
            const p = w.next().?;
            _ = try t.?.remove(if (std.mem.eql(u8, p, "_")) null else try std.fmt.parseInt(i32, p, 10));
        } else if (std.mem.eql(u8, op, "len")) {
            try out.print(gpa, "len {d}\n", .{t.?.len()});
        } else if (std.mem.eql(u8, op, "dump")) {
            try out.appendSlice(gpa, "dump");
            var it = t.?.iterator();
            while (it.next()) |e| {
                const idx = for (keys.items, 0..) |k, i| {
                    if (keyIs(k, e.key)) break i;
                } else return error.KeyNotInPool;
                try out.print(gpa, " {d}", .{idx});
            }
            try out.append(gpa, '\n');
        }
    }
    try std.fs.File.stdout().writeAll(out.items);
}

/// The pool index of a traversed key: numbers by value (-0 is +0's), strings by bytes.
fn keyIs(a: lt.Key, b: lt.Key) bool {
    return switch (a) {
        .num => |x| b == .num and x == b.num,
        .str => |x| b == .str and std.mem.eql(u8, x, b.str),
        .boolean => |x| b == .boolean and x == b.boolean,
    };
}
