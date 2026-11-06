// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! spectral-norm: the Benchmarks Game's algorithm (upstream Fil-C: filc/benchmarks/spectralnorm.c),
//! written in plain Zig for zilc's Zig path, scalar (upstream's C uses AVX intrinsics).
//!   spectralnorm [N=2000]

const std = @import("std");

fn a(i: usize, j: usize) f64 {
    return 1.0 / @as(f64, @floatFromInt((i + j) * (i + j + 1) / 2 + i + 1));
}

fn mulAv(v: []const f64, out: []f64) void {
    for (out, 0..) |*o, i| {
        var s: f64 = 0;
        for (v, 0..) |x, j| s += a(i, j) * x;
        o.* = s;
    }
}

fn mulAtv(v: []const f64, out: []f64) void {
    for (out, 0..) |*o, i| {
        var s: f64 = 0;
        for (v, 0..) |x, j| s += a(j, i) * x;
        o.* = s;
    }
}

fn mulAtAv(v: []const f64, out: []f64, tmp: []f64) void {
    mulAv(v, tmp);
    mulAtv(tmp, out);
}

pub fn main() !void {
    const alloc = std.heap.c_allocator;
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);
    const n = if (args.len > 1) try std.fmt.parseInt(usize, args[1], 10) else 2000;

    const u = try alloc.alloc(f64, n);
    defer alloc.free(u);
    const v = try alloc.alloc(f64, n);
    defer alloc.free(v);
    const tmp = try alloc.alloc(f64, n);
    defer alloc.free(tmp);
    @memset(u, 1.0);
    for (0..10) |_| {
        mulAtAv(u, v, tmp);
        mulAtAv(v, u, tmp);
    }
    var vbv: f64 = 0;
    var vv: f64 = 0;
    for (u, v) |ui, vi| {
        vbv += ui * vi;
        vv += vi * vi;
    }
    var out_w = std.fs.File.stdout().writerStreaming(&.{});
    try out_w.interface.print("{d:.9}\n", .{@sqrt(vbv / vv)});
}
