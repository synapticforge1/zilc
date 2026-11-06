// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! zilc's own: Zig ⇄ C across the boundary in both directions, in a hot loop. Zig calls C (a dot
//! product kernel in kernel.c, called once per row) and C calls Zig (libc's qsort calling a Zig
//! comparator per comparison: an indirect call into Zig that Fil-C checks). Prints a checksum.
//!   interop [elements=1000000]

const std = @import("std");

extern fn bench_dot(a: [*]const f64, b: [*]const f64, n: usize) f64;
extern fn qsort(base: *anyopaque, n: usize, size: usize, cmp: *const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) void;

fn cmpU64(pa: ?*const anyopaque, pb: ?*const anyopaque) callconv(.c) c_int {
    const a: *const u64 = @ptrCast(@alignCast(pa.?));
    const b: *const u64 = @ptrCast(@alignCast(pb.?));
    return if (a.* < b.*) -1 else if (a.* > b.*) 1 else 0;
}

pub fn main() !void {
    const alloc = std.heap.c_allocator;
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);
    const n = if (args.len > 1) try std.fmt.parseInt(usize, args[1], 10) else 1_000_000;

    // C calls Zig: sort n keys with libc's qsort and a Zig comparator.
    const keys = try alloc.alloc(u64, n);
    defer alloc.free(keys);
    var prng = std.Random.DefaultPrng.init(7);
    for (keys) |*k| k.* = prng.random().int(u64);
    qsort(keys.ptr, keys.len, @sizeOf(u64), cmpU64);
    var sorted = true;
    for (keys[1..], keys[0 .. keys.len - 1]) |b, a| sorted = sorted and a <= b;

    // Zig calls C: one C dot product per row of a 256-wide matrix.
    const w = 256;
    const rows = n / 64;
    const mat = try alloc.alloc(f64, w * 2);
    defer alloc.free(mat);
    for (mat, 0..) |*v, i| v.* = @as(f64, @floatFromInt(i % 13)) * 0.125;
    var total: f64 = 0;
    for (0..rows) |r| total += bench_dot(mat.ptr, mat.ptr + w, w) + @as(f64, @floatFromInt(r & 1));

    var out_w = std.fs.File.stdout().writerStreaming(&.{});
    try out_w.interface.print("{} {x} {d:.3}\n", .{ sorted, keys[n / 2], total });
}
