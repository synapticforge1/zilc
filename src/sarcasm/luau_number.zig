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

fn isspace(c: u8) bool {
    return c == ' ' or (c >= '\t' and c <= '\r');
}

/// The longest prefix of `s` that C's strtod reads, from `i` (after optional whitespace and
/// sign): hex `0x…[.…][p±…]`, decimal `…[.…][e±…]`, `inf` / `infinity` / `nan[(…)]` (any case).
/// Returns the end index (== start when nothing was read).
fn strtodEnd(s: []const u8, start: usize) usize {
    var i = start;
    while (i < s.len and isspace(s[i])) i += 1;
    if (i < s.len and (s[i] == '+' or s[i] == '-')) i += 1;
    const lowerAt = struct {
        fn f(x: []const u8, at: usize, word: []const u8) bool {
            if (at + word.len > x.len) return false;
            for (word, 0..) |c, k| if (std.ascii.toLower(x[at + k]) != c) return false;
            return true;
        }
    }.f;
    if (lowerAt(s, i, "infinity")) return i + 8;
    if (lowerAt(s, i, "inf")) return i + 3;
    if (lowerAt(s, i, "nan")) {
        var j = i + 3;
        if (j < s.len and s[j] == '(') {
            var k = j + 1;
            while (k < s.len and (std.ascii.isAlphanumeric(s[k]) or s[k] == '_')) k += 1;
            if (k < s.len and s[k] == ')') j = k + 1;
        }
        return j;
    }
    // hexadecimal: 0x, then at least one hex digit before or after the point
    if (i + 1 < s.len and s[i] == '0' and (s[i + 1] == 'x' or s[i + 1] == 'X')) {
        var j = i + 2;
        var digits = false;
        while (j < s.len and std.ascii.isHex(s[j])) : (j += 1) digits = true;
        if (j < s.len and s[j] == '.') {
            j += 1;
            while (j < s.len and std.ascii.isHex(s[j])) : (j += 1) digits = true;
        }
        if (digits) {
            if (j < s.len and (s[j] == 'p' or s[j] == 'P')) {
                var k = j + 1;
                if (k < s.len and (s[k] == '+' or s[k] == '-')) k += 1;
                if (k < s.len and std.ascii.isDigit(s[k])) {
                    while (k < s.len and std.ascii.isDigit(s[k])) k += 1;
                    j = k;
                }
            }
            return j;
        }
        // "0x" with no hex digits: strtod reads the "0"
        return i + 1;
    }
    var j = i;
    var digits = false;
    while (j < s.len and std.ascii.isDigit(s[j])) : (j += 1) digits = true;
    if (j < s.len and s[j] == '.') {
        j += 1;
        while (j < s.len and std.ascii.isDigit(s[j])) : (j += 1) digits = true;
    }
    if (!digits) return start;
    if (j < s.len and (s[j] == 'e' or s[j] == 'E')) {
        var k = j + 1;
        if (k < s.len and (s[k] == '+' or s[k] == '-')) k += 1;
        if (k < s.len and std.ascii.isDigit(s[k])) {
            while (k < s.len and std.ascii.isDigit(s[k])) k += 1;
            j = k;
        }
    }
    return j;
}

/// A hex float body (after "0x": `h…[.h…][p±d…]`) as musl's strtod reads it: a port of
/// hexfloat() in musl's src/internal/floatscan.c (MIT; the copy in Fil-C's projects/usermusl,
/// which minilute's tonumber runs on), in x87 80-bit `long double` (Zig's f80) as musl computes
/// it, with prec = double (bits 53, emin −1074), then strtod's conversion to double. Not simply
/// "correctly rounded": the long-double bias trick and the final narrowing round some subnormals
/// up (measured 2026-11-06: 0xd.87a1cbe50f29436d8p-1047, whose exact rounding is …5f, is …60 in
/// Luau), and Zig's parseFloat truncates past 64 bits ("0x7fffffffffffffffff" → 2^71 − 2^19).
fn hexToDouble(body: []const u8) f64 {
    const LDBL_MANT_DIG = 64;
    var bits: i64 = 53; // DBL_MANT_DIG
    const emin: i64 = -1021 - 53; // DBL_MIN_EXP - bits
    var x: u32 = 0;
    var y: f80 = 0;
    var scale: f80 = 1;
    var bias: f80 = 0;
    var gottail = false;
    var gotrad = false;
    var gotdig = false;
    var rp: i64 = 0;
    var dc: i64 = 0;
    var e2: i64 = 0;
    var i: usize = 0;
    const at = struct {
        fn f(b: []const u8, k: usize) u8 {
            return if (k < b.len) b[k] else 0;
        }
    }.f;
    while (at(body, i) == '0') : (i += 1) gotdig = true; // skip leading zeros
    if (at(body, i) == '.') {
        gotrad = true;
        i += 1;
        while (at(body, i) == '0') : ({
            i += 1;
            rp -= 1;
        }) gotdig = true;
    }
    while (true) : (i += 1) {
        const c = at(body, i);
        if (c == '.') {
            if (gotrad) break;
            rp = dc;
            gotrad = true;
            continue;
        }
        const d: u32 = std.fmt.charToDigit(c, 16) catch break;
        gotdig = true;
        if (dc < 8) {
            x = x *% 16 +% d;
        } else if (dc < LDBL_MANT_DIG / 4 + 1) {
            scale /= 16;
            y += @as(f80, @floatFromInt(d)) * scale;
        } else if (d != 0 and !gottail) {
            y += 0.5 * scale;
            gottail = true;
        }
        dc += 1;
    }
    if (!gotdig) return 0;
    if (!gotrad) rp = dc;
    while (dc < 8) : (dc += 1) x *%= 16;
    if (at(body, i) == 'p' or at(body, i) == 'P') {
        // scanexp: the exponent, saturating far beyond the double range
        var k = i + 1;
        var eneg = false;
        if (at(body, k) == '+' or at(body, k) == '-') {
            eneg = body[k] == '-';
            k += 1;
        }
        var e: i64 = 0;
        while (std.ascii.isDigit(at(body, k))) : (k += 1) e = @min(e * 10 + (body[k] - '0'), 1 << 40);
        e2 = if (eneg) -e else e;
    }
    e2 += 4 * rp - 32;
    if (x == 0) return 0;
    if (e2 > -emin) return std.math.inf(f64); // LDBL_MAX * LDBL_MAX
    if (e2 < emin - 2 * LDBL_MANT_DIG) return 0; // LDBL_MIN * LDBL_MIN
    while (x < 0x80000000) {
        if (y >= 0.5) {
            x +%= x + 1;
            y += y - 1;
        } else {
            x +%= x;
            y += y;
        }
        e2 -= 1;
    }
    if (bits > 32 + e2 - emin) {
        bits = 32 + e2 - emin;
        if (bits < 0) bits = 0;
    }
    if (bits < LDBL_MANT_DIG) bias = @floatCast(std.math.ldexp(@as(f64, 1), @intCast(32 + LDBL_MANT_DIG - bits - 1)));
    if (bits < 32 and y != 0 and x & 1 == 0) {
        x += 1;
        y = 0;
    }
    y = bias + @as(f80, @floatFromInt(x)) + y;
    y -= bias;
    return @floatCast(std.math.ldexp(y, @intCast(e2)));
}

/// C's strtoul(s, &end, 16) from `start`: whitespace, sign, optional 0x, hex digits; overflow
/// gives ULONG_MAX; a minus sign negates modulo 2^64. Returns the value and the end index.
fn strtoul16(s: []const u8, start: usize) struct { v: u64, end: usize } {
    var i = start;
    while (i < s.len and isspace(s[i])) i += 1;
    var neg = false;
    if (i < s.len and (s[i] == '+' or s[i] == '-')) {
        neg = s[i] == '-';
        i += 1;
    }
    // an 0x prefix counts only when a hex digit follows it (else strtoul reads the "0")
    if (i + 2 < s.len and s[i] == '0' and (s[i + 1] == 'x' or s[i + 1] == 'X') and std.ascii.isHex(s[i + 2])) i += 2;
    const first = i;
    var v: u64 = 0;
    var over = false;
    while (i < s.len and std.ascii.isHex(s[i])) : (i += 1) {
        const d: u64 = std.fmt.charToDigit(s[i], 16) catch unreachable;
        const m = @mulWithOverflow(v, 16);
        const a = @addWithOverflow(m[0], d);
        if (m[1] != 0 or a[1] != 0) over = true;
        v = a[0];
    }
    if (i == first) return .{ .v = 0, .end = start };
    if (over) return .{ .v = std.math.maxInt(u64), .end = i };
    return .{ .v = if (neg) 0 -% v else v, .end = i };
}

/// tonumber(s) for a string (luaO_str2d): null when it is not a number.
pub fn tonumber(s: []const u8) ?f64 {
    var end = strtodEnd(s, 0);
    if (end == 0) return null;
    // strtod's value of the prefix (Zig's parser is correctly rounded, as musl's strtod is);
    // inf / nan built directly, with C's sign.
    var v: f64 = blk: {
        var a: usize = 0;
        while (a < end and isspace(s[a])) a += 1;
        var text = s[a..end];
        var neg = false;
        if (text.len > 0 and (text[0] == '+' or text[0] == '-')) {
            neg = text[0] == '-';
            text = text[1..];
        }
        if (text.len > 0 and (text[0] == 'n' or text[0] == 'N')) break :blk std.math.nan(f64); // musl: `sign * NAN` keeps NAN's sign (measured: tonumber("-nan") is +nan)
        const mag: f64 = if (text.len > 0 and (text[0] == 'i' or text[0] == 'I'))
            std.math.inf(f64)
        else if (text.len > 1 and text[0] == '0' and (text[1] == 'x' or text[1] == 'X'))
            hexToDouble(text[2..])
        else
            std.fmt.parseFloat(f64, text) catch return null;
        break :blk if (neg) -mag else mag;
    };
    if (end < s.len and (s[end] == 'x' or s[end] == 'X')) {
        const u = strtoul16(s, 0);
        v = @floatFromInt(u.v);
        end = u.end;
    }
    while (end < s.len and isspace(s[end])) end += 1;
    if (end != s.len) return null;
    return v;
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
