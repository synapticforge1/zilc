// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! The Zig side of tools/sarcasm/check-luau-number.ts: for each double (hex bits, one per line),
//! prints `tostring(n)` and `string.format("%.0f", n)` as src/sarcasm/luau_number.zig gives them,
//! tab-separated, as the Luau side prints them.
//!
//!   luau-number-check <numbers.hex>

const std = @import("std");
const ln = @import("luau_number");

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const gpa = arena_state.allocator();
    const args = try std.process.argsAlloc(gpa);
    const text = try std.fs.cwd().readFileAlloc(gpa, args[1], 1 << 30);
    var out: std.ArrayList(u8) = .empty;
    var it = std.mem.tokenizeScalar(u8, text, '\n');
    var buf: [64]u8 = undefined;
    while (it.next()) |line| {
        const n: f64 = @bitCast(try std.fmt.parseInt(u64, line, 16));
        try out.print(gpa, "{s}\t{s}\n", .{ ln.tostring(&buf, n), try ln.formatF0(gpa, n) });
    }
    try std.fs.File.stdout().writeAll(out.items);
}
