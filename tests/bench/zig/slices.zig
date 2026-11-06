// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! zilc's own: indexing-heavy slice code — a sieve of Eratosthenes over a []bool and a matrix
//! multiply over [][]f64 (rows as separate allocations, so each row access goes through a pointer
//! Fil-C checks, besides Zig's own bounds checks in ReleaseSafe). Prints a checksum.
//!   slices [sieve limit=20000000] [matrix size=300]

const std = @import("std");

pub fn main() !void {
    const alloc = std.heap.c_allocator;
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);
    const limit = if (args.len > 1) try std.fmt.parseInt(usize, args[1], 10) else 20_000_000;
    const m = if (args.len > 2) try std.fmt.parseInt(usize, args[2], 10) else 300;

    const composite = try alloc.alloc(bool, limit + 1);
    defer alloc.free(composite);
    @memset(composite, false);
    var primes: usize = 0;
    var i: usize = 2;
    while (i <= limit) : (i += 1) {
        if (composite[i]) continue;
        primes += 1;
        var j = i * i;
        while (j <= limit) : (j += i) composite[j] = true;
    }

    const rows = struct {
        fn make(a: std.mem.Allocator, n: usize, seed: f64) ![][]f64 {
            const r = try a.alloc([]f64, n);
            for (r, 0..) |*row, y| {
                row.* = try a.alloc(f64, n);
                for (row.*, 0..) |*v, x| v.* = @as(f64, @floatFromInt((x * 31 + y * 17) % 101)) / 101.0 + seed;
            }
            return r;
        }
        fn free(a: std.mem.Allocator, r: [][]f64) void {
            for (r) |row| a.free(row);
            a.free(r);
        }
    };
    const a = try rows.make(alloc, m, 0.5);
    defer rows.free(alloc, a);
    const b = try rows.make(alloc, m, 0.25);
    defer rows.free(alloc, b);
    const c = try rows.make(alloc, m, 0.0);
    defer rows.free(alloc, c);
    for (0..m) |y| {
        for (0..m) |x| {
            var s: f64 = 0;
            for (0..m) |k| s += a[y][k] * b[k][x];
            c[y][x] = s;
        }
    }
    var trace: f64 = 0;
    for (0..m) |k| trace += c[k][k];

    var out_w = std.fs.File.stdout().writerStreaming(&.{});
    try out_w.interface.print("{d} {d:.6}\n", .{ primes, trace });
}
