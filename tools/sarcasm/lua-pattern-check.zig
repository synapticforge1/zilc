// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! The Zig side of tools/sarcasm/check-lua-pattern.ts: for every pattern, runs string.find /
//! match / gmatch / gsub (src/sarcasm/lua_pattern.zig) over every subject and prints one line per
//! pattern: the length and checksum of the canonical encoding of all results, exactly as the Luau
//! side computes them.
//!
//!   lua-pattern-check <patterns.hex> <subjects.hex>     (one hex-encoded string per line)

const std = @import("std");
const lp = @import("lua_pattern");

fn readHexLines(gpa: std.mem.Allocator, path: []const u8) ![][]const u8 {
    const text = try std.fs.cwd().readFileAlloc(gpa, path, 1 << 30);
    var out: std.ArrayList([]const u8) = .empty;
    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |line| {
        if (line.len == 0 and it.peek() == null) break;
        const b = try gpa.alloc(u8, line.len / 2);
        _ = try std.fmt.hexToBytes(b, line);
        try out.append(gpa, b);
    }
    return out.items;
}

const Sum = struct {
    len: u64 = 0,
    h: u64 = 0,
    fn add(s: *Sum, bytes: []const u8) void {
        for (bytes) |c| {
            s.h = (s.h * 31 + c) % 4294967296;
            s.len += 1;
        }
    }
    fn num(s: *Sum, n: usize) void {
        var buf: [32]u8 = undefined;
        s.add(std.fmt.bufPrint(&buf, "{d}", .{n}) catch unreachable);
    }
};

fn caps(s: *Sum, cs: []const lp.Capture) void {
    for (cs) |c| switch (c) {
        .str => |x| {
            s.add("s");
            s.num(x.len);
            s.add(":");
            s.add(x);
        },
        .pos => |n| {
            s.add("p");
            s.num(n);
        },
    };
}

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const gpa = arena_state.allocator();
    const args = try std.process.argsAlloc(gpa);
    const pats = try readHexLines(gpa, args[1]);
    const subs = try readHexLines(gpa, args[2]);
    var out: std.ArrayList(u8) = .empty;
    for (pats) |p| {
        var sum: Sum = .{};
        var err = false;
        for (subs) |s| {
            if (lp.find(gpa, s, p, 1, false)) |r| {
                if (r) |m| {
                    sum.add("F");
                    sum.num(m.start);
                    sum.add(",");
                    sum.num(m.end);
                    caps(&sum, m.caps);
                } else sum.add("F-");
                if (try lp.matchStr(gpa, s, p, 1)) |cs| {
                    sum.add("M");
                    caps(&sum, cs);
                } else sum.add("M-");
                sum.add("G");
                var g = lp.gmatch(gpa, s, p);
                while (try g.next()) |cs| {
                    caps(&sum, cs);
                    sum.add(";");
                }
                const r2 = try lp.gsub(gpa, s, p, .{ .str = "<%0>" }, null);
                sum.add("S");
                sum.num(r2.n);
                sum.add(":");
                sum.add(r2.text);
            } else |_| {
                err = true;
                break;
            }
        }
        if (err) try out.appendSlice(gpa, "E\n") else try out.print(gpa, "{d} {d}\n", .{ sum.len, sum.h });
    }
    try std.fs.File.stdout().writeAll(out.items);
}
