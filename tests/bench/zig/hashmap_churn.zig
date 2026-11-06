// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! zilc's own: std.AutoHashMap and std.ArrayList growing, shrinking and being looked up, on the C
//! allocator — what a Zig program's containers cost under Fil-C (every rehash and growth is a
//! malloc/free through libpas; every element access is a checked load). Prints a checksum.
//!   hashmap_churn [rounds=40]

const std = @import("std");

pub fn main() !void {
    const alloc = std.heap.c_allocator;
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);
    const rounds = if (args.len > 1) try std.fmt.parseInt(u32, args[1], 10) else 40;

    var prng = std.Random.DefaultPrng.init(0x5eed_2026_1105);
    const rand = prng.random();
    var sum: u64 = 0;
    for (0..rounds) |round| {
        var map = std.AutoHashMap(u64, u64).init(alloc);
        defer map.deinit();
        var keys: std.ArrayList(u64) = .empty;
        defer keys.deinit(alloc);

        for (0..50_000) |i| {
            const k = rand.int(u64);
            try map.put(k, i ^ round);
            try keys.append(alloc, k);
        }
        // Remove every third key, then look every key up.
        for (keys.items, 0..) |k, i| {
            if (i % 3 == 0) _ = map.remove(k);
        }
        for (keys.items) |k| {
            if (map.get(k)) |v| sum +%= v *% 0x9e3779b97f4a7c15 +% k;
        }
        keys.shrinkRetainingCapacity(keys.items.len / 2);
        sum +%= keys.items.len +% map.count();
    }
    var out_w = std.fs.File.stdout().writerStreaming(&.{});
    try out_w.interface.print("{x}\n", .{sum});
}
