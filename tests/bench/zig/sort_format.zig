// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! zilc's own: std.fmt formatting and parsing, many small heap strings, and std.mem.sort over
//! slices of them — Zig's string handling (slices, bounds checks, allocator) under Fil-C. Prints a
//! hash of the sorted strings.
//!   sort_format [count=300000]

const std = @import("std");

fn lessThan(_: void, x: []const u8, y: []const u8) bool {
    return std.mem.order(u8, x, y) == .lt;
}

pub fn main() !void {
    const alloc = std.heap.c_allocator;
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);
    const count = if (args.len > 1) try std.fmt.parseInt(usize, args[1], 10) else 300_000;

    var prng = std.Random.DefaultPrng.init(42);
    const rand = prng.random();
    var strings: std.ArrayList([]u8) = .empty;
    defer {
        for (strings.items) |s| alloc.free(s);
        strings.deinit(alloc);
    }
    var parsed: u64 = 0;
    for (0..count) |i| {
        const v = rand.int(u32);
        const s = try std.fmt.allocPrint(alloc, "{x:0>8}-{d}-{s}", .{ v, i % 977, if (v & 1 == 0) "even" else "odd" });
        try strings.append(alloc, s);
        // Parse the number back out of the text, as a program reading its own output would.
        var it = std.mem.splitScalar(u8, s, '-');
        parsed +%= try std.fmt.parseInt(u32, it.first(), 16);
    }
    std.mem.sort([]u8, strings.items, {}, lessThan);

    var h = std.hash.Wyhash.init(0);
    for (strings.items) |s| h.update(s);
    var out_w = std.fs.File.stdout().writerStreaming(&.{});
    try out_w.interface.print("{x} {x}\n", .{ h.final(), parsed });
}
