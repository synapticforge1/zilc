// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! fannkuch-redux: the Benchmarks Game's algorithm (upstream Fil-C: filc/benchmarks/fannkuch-redux*),
//! written in plain Zig for zilc's Zig path, single-threaded. Prints the checksum and the maximum
//! number of flips.
//!   fannkuch [N=10]

const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const args = try std.process.argsAlloc(gpa.allocator());
    defer std.process.argsFree(gpa.allocator(), args);
    const n = if (args.len > 1) try std.fmt.parseInt(usize, args[1], 10) else 10;
    if (n < 3 or n > 16) return error.BadN;

    var perm1: [16]u8 = undefined;
    var perm: [16]u8 = undefined;
    var count: [16]usize = undefined;
    for (0..n) |i| perm1[i] = @intCast(i);

    var checksum: i64 = 0;
    var max_flips: usize = 0;
    var perm_count: usize = 0;
    var r = n;
    outer: while (true) {
        while (r != 1) : (r -= 1) count[r - 1] = r;

        @memcpy(perm[0..n], perm1[0..n]);
        var flips: usize = 0;
        var k: usize = perm[0];
        while (k != 0) {
            std.mem.reverse(u8, perm[0 .. k + 1]);
            flips += 1;
            k = perm[0];
        }
        max_flips = @max(max_flips, flips);
        checksum += if (perm_count % 2 == 0) @as(i64, @intCast(flips)) else -@as(i64, @intCast(flips));

        // The next permutation, by rotation counts.
        while (true) {
            if (r == n) break :outer;
            const p0 = perm1[0];
            for (0..r) |i| perm1[i] = perm1[i + 1];
            perm1[r] = p0;
            count[r] -= 1;
            if (count[r] > 0) break;
            r += 1;
        }
        perm_count += 1;
    }

    var out_w = std.fs.File.stdout().writerStreaming(&.{});
    try out_w.interface.print("{d}\nPfannkuchen({d}) = {d}\n", .{ checksum, n, max_flips });
}
