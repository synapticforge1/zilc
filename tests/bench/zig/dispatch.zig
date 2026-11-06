// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! zilc's own: Zig's three dispatch styles in a hot loop — a tagged union `switch`, an interface
//! through a vtable of function pointers (Fil-C checks every indirect call), and error unions
//! with `try`/`catch` on the hot path. Prints a checksum.
//!   dispatch [iterations=20000000]

const std = @import("std");

const Shape = union(enum) {
    circle: f64,
    square: f64,
    rect: struct { w: f64, h: f64 },

    fn area(s: Shape) f64 {
        return switch (s) {
            .circle => |r| 3.141592653589793 * r * r,
            .square => |a| a * a,
            .rect => |r| r.w * r.h,
        };
    }
};

const Op = struct {
    ctx: *anyopaque,
    applyFn: *const fn (*anyopaque, u64) u64,

    fn apply(o: Op, x: u64) u64 {
        return o.applyFn(o.ctx, x);
    }
};

const Adder = struct {
    k: u64,
    fn apply(p: *anyopaque, x: u64) u64 {
        const self: *Adder = @ptrCast(@alignCast(p));
        return x +% self.k;
    }
};

const Mixer = struct {
    m: u64,
    fn apply(p: *anyopaque, x: u64) u64 {
        const self: *Mixer = @ptrCast(@alignCast(p));
        return (x ^ (x >> 29)) *% self.m;
    }
};

fn checked(x: u64) error{Odd}!u64 {
    if (x % 7 == 3) return error.Odd;
    return x >> 1;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const args = try std.process.argsAlloc(gpa.allocator());
    defer std.process.argsFree(gpa.allocator(), args);
    const n = if (args.len > 1) try std.fmt.parseInt(u64, args[1], 10) else 20_000_000;

    const shapes = [_]Shape{ .{ .circle = 1.5 }, .{ .square = 2.0 }, .{ .rect = .{ .w = 3.0, .h = 0.5 } }, .{ .circle = 0.25 } };
    var adder = Adder{ .k = 0x9e37 };
    var mixer = Mixer{ .m = 0xbf58476d1ce4e5b9 };
    const ops = [_]Op{ .{ .ctx = &adder, .applyFn = Adder.apply }, .{ .ctx = &mixer, .applyFn = Mixer.apply } };

    var area: f64 = 0;
    var acc: u64 = 1;
    var errors: u64 = 0;
    var i: u64 = 0;
    while (i < n) : (i += 1) {
        area += shapes[i & 3].area();
        acc = ops[i & 1].apply(acc);
        acc +%= checked(acc) catch blk: {
            errors += 1;
            break :blk 1;
        };
    }
    var out_w = std.fs.File.stdout().writerStreaming(&.{});
    try out_w.interface.print("{d:.3} {x} {d}\n", .{ area, acc, errors });
}
