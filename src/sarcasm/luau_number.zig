// SPDX-License-Identifier: MIT
//! Numbers as sarcasm's Luau prints them (cmem/sarcasm-port.md, foundation 2):
//!   tostring(n)            — luai_num2str in Luau's VM/src/lnumprint.cpp (MIT, Roblox): the
//!                            shortest round-trip digits, laid out fixed when the decimal point
//!                            falls in -5..21, else scientific with an exponent of at least two
//!                            digits; "nan", "inf", "-inf", "-0".
//!   string.format("%.0f")  — C's printf: the exact decimal value rounded half-to-even; "-nan".
//! The shortest digits come from Zig's own formatter (Ryu); only the layout is Luau's, and both
//! are proven against Luau by tools/sarcasm/check-luau-number.ts.

const std = @import("std");

/// tostring(n), into `buf` (≥ 48 bytes, LUAI_MAXNUM2STR).
pub fn tostring(buf: []u8, n: f64) []const u8 {
    const bits: u64 = @bitCast(n);
    const sign = bits >> 63 != 0;
    const exponent = (bits >> 52) & 2047;
    const fraction = bits & ((@as(u64, 1) << 52) - 1);
    if (exponent == 0x7ff) return if (fraction != 0) "nan" else if (sign) "-inf" else "inf"; // printspecial
    var w: usize = 0;
    if (sign) {
        buf[0] = '-';
        w = 1;
    }
    if (exponent == 0 and fraction == 0) {
        buf[w] = '0';
        return buf[0 .. w + 1];
    }
    // The shortest digits and the decimal exponent: Zig's {e} gives "d.ddde±x".
    var tmp: [64]u8 = undefined;
    const sci = std.fmt.bufPrint(&tmp, "{e}", .{@abs(n)}) catch unreachable;
    const epos = std.mem.indexOfScalar(u8, sci, 'e').?;
    var digits_buf: [24]u8 = undefined;
    var nd: usize = 0;
    for (sci[0..epos]) |c| if (c != '.') {
        digits_buf[nd] = c;
        nd += 1;
    };
    while (nd > 1 and digits_buf[nd - 1] == '0') nd -= 1; // the layout trims them anyway
    const digits = digits_buf[0..nd];
    const e10 = std.fmt.parseInt(i32, sci[epos + 1 ..], 10) catch unreachable;
    const declen: i32 = @intCast(nd);
    const dot = e10 + 1; // digits d1 d2 … with the point after `dot` of them
    if (dot >= -5 and dot <= 21) {
        if (dot <= 0) {
            buf[w] = '0';
            buf[w + 1] = '.';
            w += 2;
            var z: i32 = 0;
            while (z < -dot) : (z += 1) {
                buf[w] = '0';
                w += 1;
            }
            @memcpy(buf[w..][0..nd], digits);
            return buf[0 .. w + nd];
        } else if (dot >= declen) {
            @memcpy(buf[w..][0..nd], digits);
            w += nd;
            var z: i32 = 0;
            while (z < dot - declen) : (z += 1) {
                buf[w] = '0';
                w += 1;
            }
            return buf[0..w];
        } else {
            const d: usize = @intCast(dot);
            @memcpy(buf[w..][0..d], digits[0..d]);
            buf[w + d] = '.';
            @memcpy(buf[w + d + 1 ..][0 .. nd - d], digits[d..]);
            return buf[0 .. w + nd + 1];
        }
    }
    // scientific: d[.ddd]e±xx (printexp: at least two exponent digits)
    buf[w] = digits[0];
    w += 1;
    if (nd > 1) {
        buf[w] = '.';
        @memcpy(buf[w + 1 ..][0 .. nd - 1], digits[1..]);
        w += nd;
    }
    const ex = dot - 1;
    const s = std.fmt.bufPrint(buf[w..], "e{c}{d:0>2}", .{ @as(u8, if (ex < 0) '-' else '+'), @abs(ex) }) catch unreachable;
    return buf[0 .. w + s.len];
}

/// string.format("%.0f", n): C printf's exact decimal rounding (half to even), into `buf`.
pub fn formatF0(alloc: std.mem.Allocator, n: f64) ![]u8 {
    if (std.math.isNan(n)) return alloc.dupe(u8, if (std.math.signbit(n)) "-nan" else "nan");
    if (std.math.isInf(n)) return alloc.dupe(u8, if (n < 0) "-inf" else "inf");
    const neg = std.math.signbit(n);
    const a = @abs(n);
    // Round to an integer, half to even, exactly: the double's value is m · 2^e.
    const r = roundHalfEven(a);
    // r is integral and exact in binary; print its exact decimal value.
    const bits: u64 = @bitCast(r);
    const biased: i32 = @intCast((bits >> 52) & 2047);
    var m: u64 = bits & ((@as(u64, 1) << 52) - 1);
    var out: std.ArrayList(u8) = .empty;
    if (neg) try out.append(alloc, '-');
    if (r == 0) {
        try out.append(alloc, '0');
        return out.items;
    }
    m |= @as(u64, 1) << 52;
    const e = biased - 1075; // r = m · 2^e
    var big = try std.math.big.int.Managed.initSet(alloc, m);
    if (e > 0) try big.shiftLeft(&big, @intCast(e)) else if (e < 0) try big.shiftRight(&big, @intCast(-e));
    const s = try big.toString(alloc, 10, .lower);
    try out.appendSlice(alloc, s);
    return out.items;
}

/// Round to the nearest integer, ties to even (the default rounding mode printf uses).
fn roundHalfEven(a: f64) f64 {
    if (a >= 4503599627370496.0) return a; // ≥ 2^52: already integral
    const f = @floor(a);
    const diff = a - f; // exact for these magnitudes
    if (diff > 0.5) return f + 1;
    if (diff < 0.5) return f;
    return if (@mod(f, 2) == 0) f else f + 1;
}
