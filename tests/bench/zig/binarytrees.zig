// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! binary-trees: the Benchmarks Game's algorithm (upstream Fil-C: filc/benchmarks/binarytrees.cpp),
//! written in plain Zig for zilc's Zig path. Every node is its own allocation from the C allocator
//! (Fil-C's libpas under zilc, musl's malloc for plain Zig), so this is the allocator's benchmark.
//!   binarytrees [max depth=16]

const std = @import("std");

const Node = struct { left: ?*Node, right: ?*Node };

fn create(alloc: std.mem.Allocator, depth: u32) !*Node {
    const n = try alloc.create(Node);
    if (depth == 0) {
        n.* = .{ .left = null, .right = null };
    } else {
        n.* = .{ .left = try create(alloc, depth - 1), .right = try create(alloc, depth - 1) };
    }
    return n;
}

fn check(n: *const Node) u64 {
    var c: u64 = 1;
    if (n.left) |l| c += check(l);
    if (n.right) |r| c += check(r);
    return c;
}

fn destroy(alloc: std.mem.Allocator, n: *Node) void {
    if (n.left) |l| destroy(alloc, l);
    if (n.right) |r| destroy(alloc, r);
    alloc.destroy(n);
}

pub fn main() !void {
    const alloc = std.heap.c_allocator;
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);
    const min_depth: u32 = 4;
    const max_depth: u32 = @max(min_depth + 2, if (args.len > 1) try std.fmt.parseInt(u32, args[1], 10) else 16);

    var out_w = std.fs.File.stdout().writerStreaming(&.{});
    const out = &out_w.interface;

    const stretch = try create(alloc, max_depth + 1);
    try out.print("stretch tree of depth {d}\t check: {d}\n", .{ max_depth + 1, check(stretch) });
    destroy(alloc, stretch);

    const long_lived = try create(alloc, max_depth);
    var depth = min_depth;
    while (depth <= max_depth) : (depth += 2) {
        const iterations = @as(u64, 1) << @intCast(max_depth - depth + min_depth);
        var total: u64 = 0;
        var i: u64 = 0;
        while (i < iterations) : (i += 1) {
            const t = try create(alloc, depth);
            total += check(t);
            destroy(alloc, t);
        }
        try out.print("{d}\t trees of depth {d}\t check: {d}\n", .{ iterations, depth, total });
    }
    try out.print("long lived tree of depth {d}\t check: {d}\n", .{ max_depth, check(long_lived) });
    destroy(alloc, long_lived);
}
