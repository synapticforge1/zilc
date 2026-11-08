// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//! x86_64 floating-point / SIMD knowledge (a port of projects/sarcasm/sarcasm/x86_64_fp.luau,
//! Fil-C 0.687): the EXACT width table and its pattern rules (lookup), FP def/use modeling
//! (classify), checked-access width and alignment (accessWidth), the AVX512 / AVX2 masked-access
//! lane structure (maskedAccessInfo), the vector-register effects for the FP save/restore
//! expansion (vecEffects), and the unsafe-instruction reject list (unsafeReject).
//!
//! Upstream's entry `w` is a number, "vec", "pspd" or a function; here the functions are the
//! WFn enum (two of them closures over a divisor: pmov, pmovtr), so SIZE_DRIVEN, a set of function
//! identities upstream, is a set of enum values. Every string.match is upstream's pattern
//! through the ported Lua matcher, or (for pure literal prefixes) the same test written out.

const std = @import("std");
const err = @import("err.zig");
const ir = @import("ir.zig");
const lt = @import("luau_table.zig");
const ln = @import("luau_number.zig");
const u = @import("util.zig");

const Allocator = std.mem.Allocator;
const E = err.Error;
const Op = ir.Operand;
const Ops = []const *Op;
const startsWith = std.mem.startsWith;
const eq = std.mem.eql;

// ---------------------------------------------------------------------------
// operand helpers

fn isGprOp(o: ?*const Op) bool {
    const x = o orelse return false;
    return x.kind == .reg and x.rc == .gpr;
}
fn isXmmOp(o: ?*const Op) bool {
    const x = o orelse return false;
    return x.kind == .reg and x.rc == .xmm;
}
fn first(ops: Ops) ?*Op {
    return if (ops.len > 0) ops[0] else null;
}
fn at(ops: Ops, i: usize) ?*Op {
    return if (i < ops.len) ops[i] else null;
}
/// max(1, floor((o.width or dflt) / 8))
fn gw(o: *const Op, dflt: f64) f64 {
    return @max(1, @floor((o.width orelse dflt) / 8));
}

pub fn memOperand(ops: Ops) ?*Op {
    for (ops) |o| if (o.kind == .mem) return o;
    return null;
}

fn opsHaveFp(ops: Ops) bool {
    for (ops) |o| {
        if (isXmmOp(o)) return true;
        if (o.kind == .mem and (isXmmOp(o.base) or isXmmOp(o.index))) return true;
    }
    return false;
}

pub fn hasFpReg(insn: *const ir.Stmt) bool {
    return opsHaveFp(insn.operands.items);
}

/// The vector byte width an xmm-class register operand implies (nil for st(N) and k registers).
pub fn vecBytesOf(o: ?*const Op) ?f64 {
    if (!isXmmOp(o)) return null;
    const nm = o.?.name orelse "";
    if (startsWith(u8, nm, "xmm")) return 16;
    if (startsWith(u8, nm, "ymm")) return 32;
    if (startsWith(u8, nm, "zmm")) return 64;
    if (startsWith(u8, nm, "mm")) return 8;
    return null;
}

pub fn widestVecBytes(ops: Ops) ?f64 {
    var w: ?f64 = null;
    for (ops) |o| {
        if (vecBytesOf(o)) |b| {
            if (w == null or b > w.?) w = b;
        }
    }
    return w;
}

// ---------------------------------------------------------------------------
// the table entry

pub const WFn = enum { cvtInt, movnti, x87Mem, vmovddup, vCvtHalf, vCvtNarrow, vCvtQuarter, dstGpr, vcvtps2ph, farPtr, firstGpr, crc32 };
pub const W = union(enum) {
    bytes: f64,
    vec,
    pspd,
    func: WFn,
    /// lookup's pmovzx/pmovsx closure: vecBytesOf(ops[1]) / div
    pmov: f64,
    /// lookup's truncating-store closure: widestVecBytes / div
    pmovtr: f64,
};
pub const Align = union(enum) { bytes: f64, vec };
pub const Gpr = enum { dst, src, byPosition, xadd, rmwDst };

pub const Entry = struct {
    w: ?W = null,
    @"align": ?Align = null,
    gpr: ?Gpr = null,
    memOk: ?bool = null,
    reject: ?[]const u8 = null,
    noCheck: bool = false,
    claim: bool = false,

    fn g(e: Entry, x: Gpr) Entry {
        var c = e;
        c.gpr = x;
        return c;
    }
    fn al(e: Entry, a: Align) Entry {
        var c = e;
        c.@"align" = a;
        return c;
    }
    fn unclaimed(e: Entry) Entry {
        var c = e;
        c.claim = false;
        return c;
    }
};

/// SIZE_DRIVEN: the width functions that take their width from the PTR annotation.
fn sizeDriven(wf: WFn) bool {
    return wf == .cvtInt or wf == .x87Mem or wf == .vCvtNarrow;
}

// ---------------------------------------------------------------------------
// narrowing converts

const Fam = enum { dbl, quadz, quad };
const NARROW_DBL = [_][]const u8{ "vcvtpd2ps", "vcvtpd2dq", "vcvttpd2dq", "vcvtpd2udq", "vcvttpd2udq", "vcvtuqq2ps", "vcvtqq2ps", "vcvtneps2bf16", "vcvtps2phx" };
const NARROW_QUADZ = [_][]const u8{ "vcvtpd2ph", "vcvtqq2ph", "vcvtuqq2ph" };
const NARROW_QUAD = [_][]const u8{ "vcvtdq2ph", "vcvtudq2ph" };

pub const Narrow = struct { fam: Fam, suf: ?u8, base: []const u8 };

pub fn narrowFamily(mnem: []const u8) ?Narrow {
    if (u.in(mnem, &NARROW_DBL)) return .{ .fam = .dbl, .suf = null, .base = mnem };
    if (u.in(mnem, &NARROW_QUADZ)) return .{ .fam = .quadz, .suf = null, .base = mnem };
    if (u.in(mnem, &NARROW_QUAD)) return .{ .fam = .quad, .suf = null, .base = mnem };
    // string.match(mnem, "^(.-)([xyz])$")
    if (mnem.len >= 1 and std.mem.indexOfScalar(u8, "xyz", mnem[mnem.len - 1]) != null) {
        const base = mnem[0 .. mnem.len - 1];
        const suf = mnem[mnem.len - 1];
        if (u.in(base, &NARROW_DBL) and suf != 'z') return .{ .fam = .dbl, .suf = suf, .base = base };
        if (u.in(base, &NARROW_QUADZ)) return .{ .fam = .quadz, .suf = suf, .base = base };
        if (u.in(base, &NARROW_QUAD) and suf != 'z') return .{ .fam = .quad, .suf = suf, .base = base };
    }
    return null;
}

/// fp.narrowSuffix: the AT&T source-width suffix a bare narrowing mnemonic needs with a sized
/// memory operand.
pub fn narrowSuffix(mnem: []const u8, msize: ?f64) ?[]const u8 {
    const nf = narrowFamily(mnem) orelse return null;
    if (nf.suf != null) return null;
    const m = msize orelse return null;
    if (m == 16) return "x";
    if (m == 32) return "y";
    if (m == 64 and nf.fam == .quadz) return "z";
    return null;
}

// ---------------------------------------------------------------------------
// the width functions

const WCtx = struct { alloc: Allocator, ops: Ops, mem: ?*Op, mnem: []const u8, raw: ?[]const u8, st: ?err.Loc };

fn memSize(mem: ?*Op) ?f64 {
    return if (mem) |m| m.size else null;
}

fn callW(w: W, c: WCtx) E!?f64 {
    const ops = c.ops;
    switch (w) {
        .pmov => |div| return @max(1, @floor((vecBytesOf(first(ops)) orelse 16) / div)),
        .pmovtr => |div| return @max(1, @floor((widestVecBytes(ops) orelse 16) / div)),
        .func => |wf| switch (wf) {
            .cvtInt => {
                if (memSize(c.mem)) |s| return s;
                for (ops) |o| if (isGprOp(o)) return gw(o, 32);
                return 4;
            },
            .movnti => {
                for (ops) |o| if (isGprOp(o)) return @max(4, @floor((o.width orelse 64) / 8));
                return 4;
            },
            .x87Mem => return memSize(c.mem),
            .vmovddup => {
                const b = widestVecBytes(ops) orelse 16;
                return if (b >= 32) b else 8;
            },
            .vCvtHalf => return @max(1, @floor((vecBytesOf(first(ops)) orelse 16) / 2)),
            .vCvtQuarter => return @max(1, @floor((vecBytesOf(first(ops)) orelse 16) / 4)),
            .vCvtNarrow => return try vCvtNarrowW(c),
            .dstGpr => {
                const o = first(ops);
                if (isGprOp(o)) return gw(o.?, 64);
                if (memSize(c.mem)) |s| return s;
                return 8;
            },
            .vcvtps2ph => return @max(1, @floor((widestVecBytes(ops) orelse 16) / 2)),
            .farPtr => {
                const o = first(ops);
                if (isGprOp(o)) return gw(o.?, 32) + 2;
                return 6;
            },
            .firstGpr => {
                for (ops) |o| if (isGprOp(o)) return gw(o, 64);
                if (memSize(c.mem)) |s| return s;
                return 8;
            },
            .crc32 => return try crc32W(c),
        },
        else => unreachable,
    }
}

fn rawOr(c: WCtx) []const u8 {
    return c.raw orelse c.mnem;
}

fn vCvtNarrowW(c: WCtx) E!f64 {
    const nf = narrowFamily(c.mnem);
    const fam: ?Fam = if (nf) |x| x.fam else null;
    const suf: ?u8 = if (nf) |x| x.suf else null;
    const base = if (nf) |x| x.base else c.mnem;
    var w: f64 = undefined;
    if (suf) |sx| {
        w = if (sx == 'x') 16 else if (sx == 'y') 32 else 64;
    } else if (memSize(c.mem)) |s| {
        w = s;
        if (!(w == 16 or w == 32 or w == 64)) {
            return err.at(c.st, try u.fmt(c.alloc, "PTR size annotation ({s} bytes) is not a legal memory source width for '{s}' (one of 16, 32, 64): {s}", .{ try u.num(c.alloc, w), base, rawOr(c) }));
        }
    } else if ((fam == Fam.dbl or fam == Fam.quad) and (vecBytesOf(first(c.ops)) orelse -1) == 32) {
        w = 64;
    } else {
        return err.at(c.st, try u.fmt(c.alloc, "cannot determine the memory access width of '{s}' (unsized memory operand is ambiguous; use a size suffix or PTR annotation): {s}", .{ c.mnem, rawOr(c) }));
    }
    const need: f64 = if ((fam == Fam.dbl or fam == Fam.quad) and w == 64) 32 else 16;
    if (vecBytesOf(first(c.ops))) |dw| {
        if (dw != need) return err.at(c.st, try u.fmt(c.alloc, "'{s}' has no memory form with a {s}-byte source and this destination register class: {s}", .{ c.mnem, try u.num(c.alloc, w), rawOr(c) }));
    }
    return w;
}

fn crc32W(c: WCtx) E!f64 {
    var w: ?f64 = null;
    if (try u.match1(c.alloc, c.mnem, "^crc32([bwlq])$")) |l| w = switch (l[0]) {
        'b' => 1,
        'w' => 2,
        'l' => 4,
        else => 8,
    };
    if (w == null) {
        const src = at(c.ops, 1);
        if (isGprOp(src)) w = gw(src.?, 32);
    }
    if (w == null) w = memSize(c.mem);
    var dstW: ?f64 = null;
    const dst = first(c.ops);
    if (isGprOp(dst)) dstW = gw(dst.?, 32);
    if (w == null) w = dstW;
    const ww = w orelse 4;
    if (dstW) |d| {
        if (!(ww == 1 or (d == 4 and (ww == 2 or ww == 4)) or (d == 8 and ww == 8))) {
            return err.at(c.st, try u.fmt(c.alloc, "illegal crc32 destination/source width combination ({s}-byte destination, {s}-byte source) for '{s}': {s}", .{ try u.num(c.alloc, d), try u.num(c.alloc, ww), c.mnem, rawOr(c) }));
        }
    }
    return ww;
}

// ---------------------------------------------------------------------------
// reject reasons

const REASON_X87STATE = "x87 environment/state-save instructions are not supported (cannot prove memory safety)";
const REASON_XSAVE = "xsave/xrstor state save/restore size is CPU-dependent (cannot prove memory safety)";
const REASON_GATHER = "gather/scatter instructions touch multiple discrete addresses (cannot prove memory safety)";
const REASON_MASKMOVDQU = "maskmovdqu/maskmovq store to an implicit memory operand (the DS:rdi destination) that cannot be bounds-checked (cannot prove memory safety)";
const REASON_ESTRI = "pcmpestri/pcmpistri-family instructions have implicit GPR operands (rax/rdx/rcx) that are not modeled (cannot prove memory safety)";
const REASON_AMX = "AMX tile instructions have strided, configuration-dependent memory footprints that cannot be bounds-checked (cannot prove memory safety)";

// ---------------------------------------------------------------------------
// the EXACT table

fn n(w: f64) Entry {
    return .{ .w = .{ .bytes = w }, .claim = true };
}
fn f(x: WFn) Entry {
    return .{ .w = .{ .func = x }, .claim = true };
}
const vec: Entry = .{ .w = .vec, .claim = true };
const regonly: Entry = .{ .memOk = false, .claim = true };
const nocheck: Entry = .{ .noCheck = true, .claim = true };
fn rej(r: []const u8) Entry {
    return .{ .reject = r, .claim = true };
}
const a16: Align = .{ .bytes = 16 };

const KV = struct { []const u8, Entry };

const exact_base = [_]KV{
    // SSE scalar FP
    .{ "movss", n(4) },                           .{ "movsd", n(8) },
    .{ "addss", n(4) },                           .{ "addsd", n(8) },
    .{ "subss", n(4) },                           .{ "subsd", n(8) },
    .{ "mulss", n(4) },                           .{ "mulsd", n(8) },
    .{ "divss", n(4) },                           .{ "divsd", n(8) },
    .{ "minss", n(4) },                           .{ "minsd", n(8) },
    .{ "maxss", n(4) },                           .{ "maxsd", n(8) },
    .{ "sqrtss", n(4) },                          .{ "sqrtsd", n(8) },
    .{ "rcpss", n(4) },                           .{ "rsqrtss", n(4) },
    .{ "cmpss", n(4) },                           .{ "cmpsd", n(8) },
    .{ "comiss", n(4) },                          .{ "comisd", n(8) },
    .{ "ucomiss", n(4) },                         .{ "ucomisd", n(8) },
    .{ "roundss", n(4) },                         .{ "roundsd", n(8) },
    .{ "cvtss2sd", n(4) },                        .{ "cvtsd2ss", n(8) },
    // SSE packed FP
    .{ "movups", n(16) },                         .{ "movupd", n(16) },
    .{ "movaps", n(16).al(a16) },                 .{ "movapd", n(16).al(a16) },
    .{ "movntps", n(16) },                        .{ "movntpd", n(16) },
    .{ "movhps", n(8) },                          .{ "movhpd", n(8) },
    .{ "movlps", n(8) },                          .{ "movlpd", n(8) },
    .{ "movddup", n(8) },                         .{ "movsldup", n(16) },
    .{ "movshdup", n(16) },                       .{ "addps", n(16) },
    .{ "addpd", n(16) },                          .{ "subps", n(16) },
    .{ "subpd", n(16) },                          .{ "mulps", n(16) },
    .{ "mulpd", n(16) },                          .{ "divps", n(16) },
    .{ "divpd", n(16) },                          .{ "minps", n(16) },
    .{ "minpd", n(16) },                          .{ "maxps", n(16) },
    .{ "maxpd", n(16) },                          .{ "sqrtps", n(16) },
    .{ "sqrtpd", n(16) },                         .{ "rcpps", n(16) },
    .{ "rsqrtps", n(16) },                        .{ "cmpps", n(16) },
    .{ "cmppd", n(16) },                          .{ "andps", n(16) },
    .{ "andpd", n(16) },                          .{ "andnps", n(16) },
    .{ "andnpd", n(16) },                         .{ "orps", n(16) },
    .{ "orpd", n(16) },                           .{ "xorps", n(16) },
    .{ "xorpd", n(16) },                          .{ "shufps", n(16) },
    .{ "shufpd", n(16) },                         .{ "unpckhps", n(16) },
    .{ "unpckhpd", n(16) },                       .{ "unpcklps", n(16) },
    .{ "unpcklpd", n(16) },                       .{ "haddps", n(16) },
    .{ "haddpd", n(16) },                         .{ "hsubps", n(16) },
    .{ "hsubpd", n(16) },                         .{ "addsubps", n(16) },
    .{ "addsubpd", n(16) },                       .{ "dpps", n(16) },
    .{ "dppd", n(16) },                           .{ "roundps", n(16) },
    .{ "roundpd", n(16) },                        .{ "blendps", n(16) },
    .{ "blendpd", n(16) },                        .{ "blendvps", n(16) },
    .{ "blendvpd", n(16) },                       .{ "insertps", n(4) },
    // SSE/AVX converts
    .{ "cvtps2pd", n(8) },                        .{ "cvtpd2ps", n(16) },
    .{ "cvtdq2ps", n(16) },                       .{ "cvtps2dq", n(16) },
    .{ "cvttps2dq", n(16) },                      .{ "cvtdq2pd", n(8) },
    .{ "cvtpd2dq", n(8) },                        .{ "cvttpd2dq", n(8) },
    .{ "cvtpi2ps", n(8) },                        .{ "cvtpi2pd", n(8) },
    .{ "cvtps2pi", n(8) },                        .{ "cvttps2pi", n(8) },
    .{ "cvtpd2pi", n(16) },                       .{ "cvttpd2pi", n(16) },
    .{ "vcvtps2pd", f(.vCvtHalf) },               .{ "vcvtdq2pd", f(.vCvtHalf) },
    .{ "vcvtph2ps", f(.vCvtHalf) },               .{ "vcvtps2ph", f(.vcvtps2ph) },
    // remaining AVX512 packed converts
    .{ "vcvtudq2pd", f(.vCvtHalf) },              .{ "vcvtps2qq", f(.vCvtHalf) },
    .{ "vcvttps2qq", f(.vCvtHalf) },              .{ "vcvtps2uqq", f(.vCvtHalf) },
    .{ "vcvttps2uqq", f(.vCvtHalf) },             .{ "vcvtph2dq", f(.vCvtHalf) },
    .{ "vcvttph2dq", f(.vCvtHalf) },              .{ "vcvtph2udq", f(.vCvtHalf) },
    .{ "vcvttph2udq", f(.vCvtHalf) },             .{ "vcvtph2psx", f(.vCvtHalf) },
    .{ "vcvtph2pd", f(.vCvtQuarter) },            .{ "vcvtph2qq", f(.vCvtQuarter) },
    .{ "vcvttph2qq", f(.vCvtQuarter) },           .{ "vcvtph2uqq", f(.vCvtQuarter) },
    .{ "vcvttph2uqq", f(.vCvtQuarter) },          .{ "vcvtps2udq", vec },
    .{ "vcvttps2udq", vec },                      .{ "vcvtpd2qq", vec },
    .{ "vcvttpd2qq", vec },                       .{ "vcvtpd2uqq", vec },
    .{ "vcvttpd2uqq", vec },                      .{ "vcvtuqq2pd", vec },
    .{ "vcvtqq2pd", vec },                        .{ "vcvtudq2ps", vec },
    .{ "vcvtne2ps2bf16", vec },                   .{ "vcvtph2w", vec },
    .{ "vcvttph2w", vec },                        .{ "vcvtw2ph", vec },
    // VNNI / IFMA / dbpsadbw
    .{ "vpdpbusd", vec },                         .{ "vpdpbusds", vec },
    .{ "vpdpwssd", vec },                         .{ "vpdpwssds", vec },
    .{ "vpdpbssd", vec },                         .{ "vpdpbssds", vec },
    .{ "vp4dpwssd", n(16) },                      .{ "vp4dpwssds", n(16) },
    .{ "vpmadd52huq", vec },                      .{ "vpmadd52luq", vec },
    .{ "vdbpsadbw", vec },
    // vector moves
                           .{ "movd", n(4).g(.byPosition) },
    .{ "movq", n(8).g(.byPosition).unclaimed() }, .{ "movdqa", n(16).al(a16) },
    .{ "movdqu", n(16) },                         .{ "lddqu", n(16) },
    .{ "movntdq", n(16) },                        .{ "movntdqa", n(16) },
    .{ "movnti", f(.movnti).g(.src) },            .{ "vmovdqu8", vec },
    .{ "vmovdqu16", vec },                        .{ "vmovdqu32", vec },
    .{ "vmovdqu64", vec },                        .{ "vmovdqa32", vec.al(.vec) },
    .{ "vmovdqa64", vec.al(.vec) },               .{ "vmovddup", f(.vmovddup) },
    .{ "vbroadcastss", n(4) },                    .{ "vbroadcastsd", n(8) },
    .{ "vbroadcastf128", n(16) },                 .{ "vbroadcasti128", n(16) },
    .{ "vbroadcastf32x2", n(8) },                 .{ "vbroadcastf32x4", n(16) },
    .{ "vbroadcastf32x8", n(32) },                .{ "vbroadcastf64x2", n(16) },
    .{ "vbroadcastf64x4", n(32) },                .{ "vbroadcasti32x2", n(8) },
    .{ "vbroadcasti32x4", n(16) },                .{ "vbroadcasti32x8", n(32) },
    .{ "vbroadcasti64x2", n(16) },                .{ "vbroadcasti64x4", n(32) },
    .{ "vpbroadcastb", n(1).g(.src) },            .{ "vpbroadcastw", n(2).g(.src) },
    .{ "vpbroadcastd", n(4).g(.src) },            .{ "vpbroadcastq", n(8).g(.src) },
    .{ "vperm2f128", vec },                       .{ "vperm2i128", vec },
    .{ "vextractf128", n(16) },                   .{ "vextracti128", n(16) },
    .{ "vinsertf128", n(16) },                    .{ "vinserti128", n(16) },
    .{ "vextractf32x4", n(16) },                  .{ "vextractf32x8", n(32) },
    .{ "vextractf64x2", n(16) },                  .{ "vextractf64x4", n(32) },
    .{ "vinsertf32x4", n(16) },                   .{ "vinsertf32x8", n(32) },
    .{ "vinsertf64x2", n(16) },                   .{ "vinsertf64x4", n(32) },
    .{ "vextracti32x4", n(16) },                  .{ "vextracti32x8", n(32) },
    .{ "vextracti64x2", n(16) },                  .{ "vextracti64x4", n(32) },
    .{ "vinserti32x4", n(16) },                   .{ "vinserti32x8", n(32) },
    .{ "vinserti64x2", n(16) },                   .{ "vinserti64x4", n(32) },
    .{ "vshuff32x4", vec },                       .{ "vshuff64x2", vec },
    .{ "vshufi32x4", vec },                       .{ "vshufi64x2", vec },
    .{ "valignd", vec },                          .{ "valignq", vec },
    // GPR-mixing conversions
    .{ "cvtsi2ss", f(.cvtInt).g(.src) },          .{ "cvtsi2sd", f(.cvtInt).g(.src) },
    .{ "cvtsi2ssl", n(4).g(.src) },               .{ "cvtsi2ssq", n(8).g(.src) },
    .{ "cvtsi2sdl", n(4).g(.src) },               .{ "cvtsi2sdq", n(8).g(.src) },
    .{ "cvttss2si", n(4).g(.dst) },               .{ "cvttsd2si", n(8).g(.dst) },
    .{ "cvtss2si", n(4).g(.dst) },                .{ "cvtsd2si", n(8).g(.dst) },
    .{ "cvttss2sil", n(4).g(.dst) },              .{ "cvttss2siq", n(4).g(.dst) },
    .{ "cvttsd2sil", n(8).g(.dst) },              .{ "cvttsd2siq", n(8).g(.dst) },
    .{ "cvtss2sil", n(4).g(.dst) },               .{ "cvtss2siq", n(4).g(.dst) },
    .{ "cvtsd2sil", n(8).g(.dst) },               .{ "cvtsd2siq", n(8).g(.dst) },
    .{ "vcvtusi2ss", f(.cvtInt).g(.src) },        .{ "vcvtusi2sd", f(.cvtInt).g(.src) },
    .{ "vcvtusi2ssl", n(4).g(.src) },             .{ "vcvtusi2ssq", n(8).g(.src) },
    .{ "vcvtusi2sdl", n(4).g(.src) },             .{ "vcvtusi2sdq", n(8).g(.src) },
    .{ "vcvttss2usi", n(4).g(.dst) },             .{ "vcvtss2usi", n(4).g(.dst) },
    .{ "vcvttsd2usi", n(8).g(.dst) },             .{ "vcvtsd2usi", n(8).g(.dst) },
    .{ "movmskps", regonly.g(.dst) },             .{ "movmskpd", regonly.g(.dst) },
    .{ "pmovmskb", regonly.g(.dst) },             .{ "vpmovmskb", regonly.g(.dst) },
    .{ "vpmovmskw", regonly.g(.dst) },            .{ "vpmovmskd", regonly.g(.dst) },
    .{ "vpmovmskq", regonly.g(.dst) },            .{ "pextrb", n(1).g(.dst) },
    .{ "pextrw", n(2).g(.dst) },                  .{ "pextrd", n(4).g(.dst) },
    .{ "pextrq", n(8).g(.dst) },                  .{ "extractps", n(4).g(.dst) },
    .{ "pinsrb", n(1).g(.src) },                  .{ "pinsrw", n(2).g(.src) },
    .{ "pinsrd", n(4).g(.src) },                  .{ "pinsrq", n(8).g(.src) },
    .{ "kmovb", n(1).g(.byPosition) },            .{ "kmovw", n(2).g(.byPosition) },
    .{ "kmovd", n(4).g(.byPosition) },            .{ "kmovq", n(8).g(.byPosition) },
    // crypto
    .{ "aesenc", n(16) },                         .{ "aesdec", n(16) },
    .{ "aesenclast", n(16) },                     .{ "aesdeclast", n(16) },
    .{ "aesimc", regonly },                       .{ "aeskeygenassist", n(16) },
    .{ "pclmulqdq", n(16) },                      .{ "vpclmulqdq", vec },
    .{ "sha1rnds4", n(16) },                      .{ "sha1nexte", n(16) },
    .{ "sha1msg1", n(16) },                       .{ "sha1msg2", n(16) },
    .{ "sha256rnds2", n(16) },                    .{ "sha256msg1", n(16) },
    .{ "sha256msg2", n(16) },                     .{ "vsha512rnds2", n(16) },
    .{ "vsha512msg1", n(16) },                    .{ "vsha512msg2", n(32) },
    .{ "gf2p8mulb", vec },                        .{ "gf2p8affineb", vec },
    .{ "gf2p8affineqb", vec },                    .{ "gf2p8affineinvqb", vec },
    .{ "sm3rnds2", n(16) },                       .{ "sm3msg1", n(16) },
    .{ "sm3msg2", n(16) },                        .{ "sm4key4", n(16) },
    .{ "sm4rnds4", n(16) },
    // mxcsr, descriptor tables, far pointers
                          .{ "ldmxcsr", n(4) },
    .{ "stmxcsr", n(4) },                         .{ "sgdt", n(10) },
    .{ "sidt", n(10) },                           .{ "sldt", n(2).g(.dst) },
    .{ "str", n(2).g(.dst) },                     .{ "smsw", n(2).g(.dst) },
    .{ "lss", f(.farPtr).g(.dst) },               .{ "lfs", f(.farPtr).g(.dst) },
    .{ "lgs", f(.farPtr).g(.dst) },
    // x87 memory forms
                  .{ "flds", n(4) },
    .{ "fldl", n(8) },                            .{ "fldt", n(10) },
    .{ "fsts", n(4) },                            .{ "fstl", n(8) },
    .{ "fstt", n(10) },                           .{ "fstps", n(4) },
    .{ "fstpl", n(8) },                           .{ "fstpt", n(10) },
    .{ "filds", n(2) },                           .{ "fildl", n(4) },
    .{ "fildq", n(8) },                           .{ "fildll", n(8) },
    .{ "fists", n(2) },                           .{ "fistl", n(4) },
    .{ "fistq", n(8) },                           .{ "fistps", n(2) },
    .{ "fistpl", n(4) },                          .{ "fistpq", n(8) },
    .{ "fistpll", n(8) },                         .{ "fisttps", n(2) },
    .{ "fisttpl", n(4) },                         .{ "fisttpq", n(8) },
    .{ "fiadds", n(2) },                          .{ "fiaddl", n(4) },
    .{ "fisubs", n(2) },                          .{ "fisubl", n(4) },
    .{ "fisubrs", n(2) },                         .{ "fisubrl", n(4) },
    .{ "fimuls", n(2) },                          .{ "fimull", n(4) },
    .{ "fidivs", n(2) },                          .{ "fidivl", n(4) },
    .{ "fidivrs", n(2) },                         .{ "fidivrl", n(4) },
    .{ "ficoms", n(2) },                          .{ "ficoml", n(4) },
    .{ "ficomps", n(2) },                         .{ "ficompl", n(4) },
    .{ "fcoms", n(4) },                           .{ "fcoml", n(8) },
    .{ "fcomps", n(4) },                          .{ "fcompl", n(8) },
    .{ "fadds", n(4) },                           .{ "faddl", n(8) },
    .{ "fsubs", n(4) },                           .{ "fsubl", n(8) },
    .{ "fmuls", n(4) },                           .{ "fmull", n(8) },
    .{ "fdivs", n(4) },                           .{ "fdivl", n(8) },
    .{ "fsubrs", n(4) },                          .{ "fsubrl", n(8) },
    .{ "fdivrs", n(4) },                          .{ "fdivrl", n(8) },
    .{ "fbld", n(10) },                           .{ "fbstp", n(10) },
    .{ "fnstsw", n(2).g(.rmwDst) },               .{ "fstsw", n(2).g(.rmwDst) },
    .{ "fnstcw", n(2) },                          .{ "fstcw", n(2) },
    .{ "fldcw", n(2) },
    // fxsave/fxrstor
                              .{ "fxsave", n(512).al(a16) },
    .{ "fxsave64", n(512).al(a16) },              .{ "fxrstor", n(512).al(a16) },
    .{ "fxrstor64", n(512).al(a16) },
    // MMX/misc reg-only
                .{ "emms", regonly },
    .{ "femms", regonly },                        .{ "vzeroupper", regonly },
    .{ "vzeroall", regonly },
    // memory-neutral hints
                        .{ "prefetch", nocheck },
    .{ "prefetcht0", nocheck },                   .{ "prefetcht1", nocheck },
    .{ "prefetcht2", nocheck },                   .{ "prefetchnta", nocheck },
    .{ "prefetchw", nocheck },                    .{ "prefetchwt1", nocheck },
    .{ "clflush", nocheck },                      .{ "clflushopt", nocheck },
    .{ "clwb", nocheck },
    // hard rejects
                            .{ "fsave", rej(REASON_X87STATE) },
    .{ "fnsave", rej(REASON_X87STATE) },          .{ "frstor", rej(REASON_X87STATE) },
    .{ "fstenv", rej(REASON_X87STATE) },          .{ "fnstenv", rej(REASON_X87STATE) },
    .{ "fldenv", rej(REASON_X87STATE) },          .{ "xsave", rej(REASON_XSAVE) },
    .{ "xsave64", rej(REASON_XSAVE) },            .{ "xrstor", rej(REASON_XSAVE) },
    .{ "xrstor64", rej(REASON_XSAVE) },           .{ "xsaveopt", rej(REASON_XSAVE) },
    .{ "xsaveopt64", rej(REASON_XSAVE) },         .{ "xsaves", rej(REASON_XSAVE) },
    .{ "xsaves64", rej(REASON_XSAVE) },           .{ "xrstors", rej(REASON_XSAVE) },
    .{ "xrstors64", rej(REASON_XSAVE) },          .{ "xsavec", rej(REASON_XSAVE) },
    .{ "xsavec64", rej(REASON_XSAVE) },           .{ "vmaskmovps", vec },
    .{ "vmaskmovpd", vec },                       .{ "vpmaskmovd", vec },
    .{ "vpmaskmovq", vec },                       .{ "maskmovdqu", rej(REASON_MASKMOVDQU) },
    .{ "maskmovq", rej(REASON_MASKMOVDQU) },
};

// reg-only x87 (no memory form)
const x87_regonly_names = [_][]const u8{
    "fldz",    "fld1",    "fldpi",   "fldl2t",  "fldl2e",  "fldlg2",   "fldln2",
    "faddp",   "fsubp",   "fsubrp",  "fmulp",   "fdivp",   "fdivrp",   "fcompp",
    "fucompp", "fxch",    "fxtract", "fyl2x",   "fyl2xp1", "f2xm1",    "fabs",
    "fchs",    "fcos",    "fsin",    "fsincos", "fptan",   "fpatan",   "fprem",
    "fprem1",  "frndint", "fscale",  "fsqrt",   "ftst",    "fxam",     "fwait",
    "fnop",    "ffree",   "ffreep",  "fincstp", "fdecstp", "fnclex",   "fclex",
    "fninit",  "finit",   "fcomi",   "fcomip",  "fucomi",  "fucomip",  "fcmovb",
    "fcmove",  "fcmovbe", "fcmovu",  "fcmovnb", "fcmovne", "fcmovnbe", "fcmovnu",
};

fn suffixed(comptime names: []const []const u8, comptime sufs: []const []const u8, comptime e: Entry) [names.len * sufs.len]KV {
    var out: [names.len * sufs.len]KV = undefined;
    for (names, 0..) |m, i| for (sufs, 0..) |s, j| {
        out[i * sufs.len + j] = .{ m ++ s, e };
    };
    return out;
}

const exact_all = exact_base ++
    suffixed(&x87_regonly_names, &.{""}, regonly) ++
    suffixed(&.{ "shlx", "sarx", "shrx", "andn", "bextr", "blsi", "blsr", "blsmsk", "bzhi", "pdep", "pext", "rorx" }, &.{ "", "l", "q" }, f(.dstGpr).g(.byPosition)) ++
    suffixed(&.{ "bsf", "bsr" }, &.{ "", "w", "l", "q" }, f(.dstGpr).g(.byPosition)) ++
    suffixed(&.{"xadd"}, &.{ "", "b", "w", "l", "q" }, f(.firstGpr).g(.xadd)) ++
    suffixed(&.{"crc32"}, &.{ "", "b", "w", "l", "q" }, f(.crc32).g(.rmwDst)) ++
    suffixed(&.{ "adcx", "adox" }, &.{ "", "l", "q" }, f(.firstGpr).g(.rmwDst));

const EXACT = blk: {
    @setEvalBranchQuota(200_000);
    break :blk std.StaticStringMap(Entry).initComptime(exact_all);
};

/// The EXACT table's keys (for the stage check).
pub fn exactKeys() []const []const u8 {
    return EXACT.keys();
}

test "EXACT has no duplicate keys (upstream's later assignment would win)" {
    var seen: std.StringHashMapUnmanaged(void) = .empty;
    defer seen.deinit(std.testing.allocator);
    for (exact_all) |kv| {
        const r = try seen.getOrPut(std.testing.allocator, kv[0]);
        try std.testing.expect(!r.found_existing);
    }
}

const PMOV_DIV = std.StaticStringMap(f64).initComptime(.{ .{ "bw", 2 }, .{ "bd", 4 }, .{ "bq", 8 }, .{ "wd", 2 }, .{ "wq", 4 }, .{ "dq", 2 } });
const PMOVTR_DIV = std.StaticStringMap(f64).initComptime(.{ .{ "qb", 8 }, .{ "qw", 4 }, .{ "qd", 2 }, .{ "db", 4 }, .{ "dw", 2 }, .{ "wb", 2 } });

// ---------------------------------------------------------------------------
// masked memory access metadata

const MASKED_MOVE_ELEM = std.StaticStringMap(f64).initComptime(.{
    .{ "vmovdqu8", 1 }, .{ "vmovdqu16", 2 }, .{ "vmovdqu32", 4 }, .{ "vmovdqu64", 8 },
    .{ "vmovups", 4 },  .{ "vmovupd", 8 },   .{ "vmovdqa32", 4 }, .{ "vmovdqa64", 8 },
    .{ "vmovaps", 4 },  .{ "vmovapd", 8 },
});
const PMOVTR_ELEM = std.StaticStringMap(f64).initComptime(.{ .{ "qb", 1 }, .{ "qw", 2 }, .{ "qd", 4 }, .{ "db", 1 }, .{ "dw", 2 }, .{ "wb", 1 } });
const EXPAND_ELEM = std.StaticStringMap(f64).initComptime(.{ .{ "b", 1 }, .{ "w", 2 }, .{ "d", 4 }, .{ "q", 8 }, .{ "ps", 4 }, .{ "pd", 8 } });

const BROADCAST_LOAD_KEYS = [_][]const u8{
    "vpbroadcastb",    "vpbroadcastw",    "vpbroadcastd",    "vpbroadcastq",
    "vbroadcastss",    "vbroadcastsd",    "vbroadcastf128",  "vbroadcasti128",
    "vbroadcastf32x2", "vbroadcastf32x4", "vbroadcastf32x8", "vbroadcastf64x2",
    "vbroadcastf64x4", "vbroadcasti32x2", "vbroadcasti32x4", "vbroadcasti32x8",
    "vbroadcasti64x2", "vbroadcasti64x4",
};
pub fn isBroadcastLoad(mnem: []const u8) bool {
    return u.in(mnem, &BROADCAST_LOAD_KEYS);
}

pub const Extract = enum { k, movmsk };
pub const Masked = struct { elem: f64, lanes: f64, vecsize: f64, contiguous: bool, extract: Extract, movmskPd: bool = false };

fn fdiv(a: f64, b: f64) f64 {
    return @floor(a / b); // Luau's //
}

pub fn maskedAccessInfo(alloc: Allocator, mnem: []const u8, ops: Ops) E!?Masked {
    const V = widestVecBytes(ops) orelse return null;
    if (MASKED_MOVE_ELEM.get(mnem)) |e| return .{ .elem = e, .lanes = fdiv(V, e), .vecsize = V, .contiguous = false, .extract = .k };
    if (eq(u8, mnem, "vmaskmovps") or eq(u8, mnem, "vpmaskmovd"))
        return .{ .elem = 4, .lanes = fdiv(V, 4), .vecsize = V, .contiguous = false, .extract = .movmsk };
    if (eq(u8, mnem, "vmaskmovpd") or eq(u8, mnem, "vpmaskmovq"))
        return .{ .elem = 8, .lanes = fdiv(V, 8), .vecsize = V, .contiguous = false, .extract = .movmsk, .movmskPd = true };
    if (try u.match(alloc, mnem, "^v?pmov([su]*)([a-z][a-z])$")) |c| {
        const tsat = c[0].str;
        const tpair = c[1].str;
        if (tsat.len == 0 or eq(u8, tsat, "s") or eq(u8, tsat, "us")) {
            if (PMOVTR_ELEM.get(tpair)) |e| {
                const div = PMOVTR_DIV.get(tpair).?;
                const v = @max(1, @floor(V / div));
                return .{ .elem = e, .lanes = fdiv(v, e), .vecsize = v, .contiguous = false, .extract = .k };
            }
        }
    }
    const suf = (try u.match1(alloc, mnem, "^vexpand([bdwq])$")) orelse (try u.match1(alloc, mnem, "^vpexpand([bdwq])$")) orelse
        (try u.match1(alloc, mnem, "^vcompress([bdwq])$")) orelse (try u.match1(alloc, mnem, "^vpcompress([bdwq])$")) orelse
        (try u.match1(alloc, mnem, "^vexpand(p[sd])$")) orelse (try u.match1(alloc, mnem, "^vcompress(p[sd])$"));
    if (suf) |sx| {
        const e = EXPAND_ELEM.get(sx).?;
        return .{ .elem = e, .lanes = fdiv(V, e), .vecsize = V, .contiguous = true, .extract = .k };
    }
    const mem = memOperand(ops);
    if (mem) |m| if (first(ops) != m and m.bcastN == null) {
        var elem: ?f64 = null;
        if ((try u.matches(alloc, mnem, "^vp[%a]+$")) or (try u.matches(alloc, mnem, "^vperm[i]?[a-z0-9]*$"))) {
            elem = switch (mnem[mnem.len - 1]) {
                'b' => 1,
                'w' => 2,
                'd' => 4,
                'q' => 8,
                else => null,
            };
        } else if (try u.match(alloc, mnem, "^v([%a][%w]-)(p[sd])$")) |c| {
            if (c[0].str[0] != 'p') elem = if (eq(u8, c[1].str, "ps")) 4 else 8;
        }
        if (elem) |e| return .{ .elem = e, .lanes = fdiv(V, e), .vecsize = V, .contiguous = false, .extract = .k };
    };
    return null;
}

// ---------------------------------------------------------------------------
// lookup: EXACT table + pattern rules

const NARROW_ENTRY = f(.vCvtNarrow);

pub fn lookup(alloc: Allocator, mnem_in: []const u8) E!?Entry {
    const mnem = try u.lower(alloc, mnem_in);
    if (EXACT.get(mnem)) |e| return e;
    if (narrowFamily(mnem) != null) return NARROW_ENTRY;
    if (startsWith(u8, mnem, "vgather") or startsWith(u8, mnem, "vpgather") or startsWith(u8, mnem, "vscatter") or startsWith(u8, mnem, "vpscatter"))
        return rej(REASON_GATHER);
    if (startsWith(u8, mnem, "tile") or eq(u8, mnem, "ldtilecfg")) return rej(REASON_AMX);
    if ((try u.matches(alloc, mnem, "^lzcnt[wlq]?$")) or (try u.matches(alloc, mnem, "^tzcnt[wlq]?$")) or (try u.matches(alloc, mnem, "^popcnt[wlq]?$")))
        return f(.dstGpr).g(.byPosition);
    if ((try u.matches(alloc, mnem, "^vexpand[bdwq]$")) or (try u.matches(alloc, mnem, "^vcompress[bdwq]$"))) return vec;
    if (startsWith(u8, mnem, "vpermi2") or startsWith(u8, mnem, "vpermt2")) return vec;
    {
        const e = if (startsWith(u8, mnem, "v")) mnem[1..] else mnem;
        if (u.in(e, &.{ "pcmpestri", "pcmpistri", "pcmpestrm", "pcmpistrm" })) return rej(REASON_ESTRI);
    }
    if (try u.match(alloc, mnem, "^v?pmov([sz])x([a-z]+)$")) |c| {
        if (PMOV_DIV.get(c[1].str)) |div| return .{ .w = .{ .pmov = div }, .claim = true };
        return null;
    }
    if (try u.match(alloc, mnem, "^v?pmov([su]*)([a-z][a-z])$")) |c| {
        const tsat = c[0].str;
        if (tsat.len == 0 or eq(u8, tsat, "s") or eq(u8, tsat, "us")) {
            if (PMOVTR_DIV.get(c[1].str)) |div| return .{ .w = .{ .pmovtr = div }, .claim = true };
        }
    }
    if (mnem.len > 1 and mnem[0] == 'v') {
        if (EXACT.get(mnem[1..])) |be| {
            var c = be;
            if (c.w) |w| if (w == .bytes and w.bytes == 16) {
                c.w = .vec;
            };
            if (c.@"align") |a| if (a == .bytes and a.bytes == 16) {
                c.@"align" = .vec;
            };
            return c;
        }
    }
    {
        const rest = if (startsWith(u8, mnem, "v")) mnem[1..] else mnem;
        if (!startsWith(u8, rest, "p")) {
            if (try u.match(alloc, rest, "^([%a][%w]-)([ps][sdh])$")) |c| {
                const sf = c[1].str;
                if (!eq(u8, sf, "sh")) {
                    if (eq(u8, sf, "ss")) return .{ .w = .{ .bytes = 4 } };
                    if (eq(u8, sf, "sd")) return .{ .w = .{ .bytes = 8 } };
                    return .{ .w = .pspd };
                }
            }
        }
    }
    if (try u.matches(alloc, mnem, "^v?p[%a]+$")) return .{ .w = .vec };
    if (try u.matches(alloc, mnem, "^k[%a%d]+$")) return regonly;
    if (try u.matches(alloc, mnem, "^f[%a%d]*$")) return f(.x87Mem);
    return null;
}

// ---------------------------------------------------------------------------
// def/use modeling

fn insert(alloc: Allocator, l: *std.ArrayList(*Op), o: *Op) E!void {
    try l.append(alloc, o);
}

pub fn classify(alloc: Allocator, insn: *const ir.Stmt) E!?ir.Class {
    const mnem = try u.lower(alloc, insn.mnemonic.?);
    const ops = insn.operands.items;
    const raw = insn.raw orelse mnem;
    const mem = memOperand(ops);
    if (try lookup(alloc, mnem)) |entry| {
        if (entry.reject) |r| return err.at(insn.loc(), try u.fmt(alloc, "{s}: {s}", .{ r, raw }));
        if (!opsHaveFp(ops) and !entry.claim) return null;
        if (mem) |m| {
            if (entry.memOk != null and !entry.memOk.?)
                return err.at(insn.loc(), try u.fmt(alloc, "`{s}` does not have a memory form (cannot prove memory safety): {s}", .{ mnem, raw }));
            var knum: ?[]const u8 = null;
            for (ops) |o| if (o.deco) |d| {
                if (try u.match1(alloc, d, "{%%?k([0-7])}")) |k| {
                    knum = k;
                    break;
                }
            };
            if (knum) |k| {
                if (eq(u8, k, "0"))
                    return err.at(insn.loc(), try u.fmt(alloc, "{{%k0}} is not a valid writemask on a memory access (k0 reads as all-ones; gas rejects it too): {s}", .{raw}));
                if (!(m.bcastN != null or isBroadcastLoad(mnem))) {
                    const mi = try maskedAccessInfo(alloc, mnem, ops);
                    if (mi == null or mi.?.extract != .k)
                        return err.at(insn.loc(), try u.fmt(alloc, "AVX512 mask-register ({{k}}) memory access on '{s}' is not supported (only the masked vector moves, truncating stores, and expand/compress forms are; masked-off lanes may not touch memory; cannot prove memory safety): {s}", .{ mnem, raw }));
                }
            }
            if (u.in(mnem, &.{ "vmaskmovps", "vmaskmovpd", "vpmaskmovd", "vpmaskmovq" })) {
                if (ops.len != 3 or !isXmmOp(ops[1]))
                    return err.at(insn.loc(), try u.fmt(alloc, "`{s}` requires the three-operand form (load: dest, mask, mem; store: mem, mask, src): {s}", .{ mnem, raw }));
            }
        }
        var c: ir.Class = .{};
        if (entry.gpr) |g| switch (g) {
            .dst, .src => for (ops) |o| if (isGprOp(o)) try insert(alloc, if (g == .dst) &c.defs else &c.uses, o),
            .byPosition => for (ops) |o| if (isGprOp(o)) try insert(alloc, if (o == ops[0]) &c.defs else &c.uses, o),
            .xadd => for (ops) |o| if (isGprOp(o)) {
                try insert(alloc, &c.defs, o);
                try insert(alloc, &c.uses, o);
            },
            .rmwDst => {
                if (isGprOp(first(ops))) {
                    try insert(alloc, &c.defs, ops[0]);
                    try insert(alloc, &c.uses, ops[0]);
                }
                if (ops.len > 1) for (ops[1..]) |o| if (isGprOp(o)) try insert(alloc, &c.uses, o);
            },
        };
        if (mem) |m| {
            if (isGprOp(m.base)) try insert(alloc, &c.uses, m.base.?);
            if (isGprOp(m.index)) try insert(alloc, &c.uses, m.index.?);
        }
        for (c.uses.items) |o| {
            for (c.defs.items) |d| if (d.num.? == o.num.?) {
                try c.rmw.append(alloc, o.num.?);
                break;
            };
        }
        return c;
    }
    if (mem != null and (opsHaveFp(ops) or (try u.matches(alloc, mnem, "^[fv]"))))
        return err.at(insn.loc(), try u.fmt(alloc, "cannot determine the memory access width of '{s}' (cannot prove memory safety): {s}", .{ mnem, raw }));
    return null;
}

// ---------------------------------------------------------------------------
// memory access width / alignment

pub const Access = struct { w: f64, @"align": f64 };

pub fn accessWidth(alloc: Allocator, mnem: []const u8, ops: Ops, raw: ?[]const u8, st: ?err.Loc) E!?Access {
    const mem = memOperand(ops) orelse return null;
    const C = struct {
        fn checkSize(a: Allocator, m: *Op, w: f64, mn: []const u8, rw: ?[]const u8, s: ?err.Loc) E!f64 {
            if (m.size) |sz| if (sz != w) {
                return err.at(s, try u.fmt(a, "PTR size annotation ({s} bytes) contradicts the memory access width ({s} bytes) of '{s}': {s}", .{ try u.num(a, sz), try u.num(a, w), mn, rw orelse mn }));
            };
            return w;
        }
    };
    if (mem.bcastN) |bn| {
        const b = widestVecBytes(ops) orelse 16;
        return .{ .w = try C.checkSize(alloc, mem, @max(1, @floor(b / bn)), mnem, raw, st), .@"align" = 1 };
    }
    const entry = (try lookup(alloc, mnem)) orelse return null;
    if (entry.reject != null or entry.noCheck) return null;
    if (!opsHaveFp(ops) and !entry.claim) return null;
    const ew = entry.w orelse return null;
    var sd = false;
    var w: ?f64 = switch (ew) {
        .bytes => |b| b,
        .vec => widestVecBytes(ops),
        .pspd => @max(16, widestVecBytes(ops) orelse 16),
        .func, .pmov, .pmovtr => null,
    };
    if (ew == .func or ew == .pmov or ew == .pmovtr) {
        if (ew == .func) sd = sizeDriven(ew.func);
        w = try callW(ew, .{ .alloc = alloc, .ops = ops, .mem = mem, .mnem = mnem, .raw = raw, .st = st });
    }
    const ww = w orelse return null;
    if (!sd) _ = try C.checkSize(alloc, mem, ww, mnem, raw, st);
    var a: ?f64 = null;
    if (entry.@"align") |al| a = switch (al) {
        .bytes => |b| b,
        .vec => widestVecBytes(ops),
    };
    return .{ .w = ww, .@"align" = a orelse 1 };
}

// ---------------------------------------------------------------------------
// vector-register effects for the FP save/restore expansion

const VecReg = struct { num: f64, class: f64 };
fn vecRegOf(o: ?*const Op) ?VecReg {
    if (!isXmmOp(o)) return null;
    const x = o.?;
    const nm = x.name orelse "";
    if (startsWith(u8, nm, "xmm")) return .{ .num = x.num.?, .class = 16 };
    if (startsWith(u8, nm, "ymm")) return .{ .num = x.num.?, .class = 32 };
    if (startsWith(u8, nm, "zmm")) return .{ .num = x.num.?, .class = 64 };
    return null;
}

const SfxKind = enum { scalar, @"packed" };
const Sfx = struct { kind: SfxKind, bytes: ?f64 };
fn fpSuffixKind(alloc: Allocator, mnem: []const u8) E!?Sfx {
    const rest = if (startsWith(u8, mnem, "v")) mnem[1..] else mnem;
    if (startsWith(u8, rest, "p")) return null;
    const c = try u.match(alloc, rest, "^([%a][%w]-)([ps][sdh])$") orelse return null;
    const sf = c[1].str;
    if (eq(u8, sf, "sh")) return null;
    if (eq(u8, sf, "ss")) return .{ .kind = .scalar, .bytes = 4 };
    if (eq(u8, sf, "sd")) return .{ .kind = .scalar, .bytes = 8 };
    return .{ .kind = .@"packed", .bytes = null };
}

const READONLY_VEC_FIRST = [_][]const u8{ "comiss", "comisd", "ucomiss", "ucomisd", "testps", "testpd", "ptest", "vcomiss", "vcomisd", "vucomiss", "vucomisd", "vtestps", "vtestpd", "vptest" };
const LEGACY_PURE_MOVE = [_][]const u8{ "movups", "movupd", "movaps", "movapd", "movdqa", "movdqu", "movntdq", "movntdqa", "movntps", "movntpd", "lddqu", "movsldup", "movshdup", "movddup" };
const LEGACY_PARTIAL = [_][]const u8{ "movhps", "movhpd", "movlps", "movlpd", "insertps", "blendps", "blendpd", "pinsrb", "pinsrw", "pinsrd", "pinsrq" };
const IMPLICIT_XMM0_USE = [_][]const u8{ "blendvps", "blendvpd", "sha256rnds2", "vsha512rnds2" };
const LEGACY_CVT_FULL = [_][]const u8{ "cvtdq2ps", "cvtps2dq", "cvttps2dq", "cvtpd2dq", "cvttpd2dq" };
const SELF_ZERO = [_][]const u8{ "pxor", "xorps", "xorpd", "psubb", "psubw", "psubd", "psubq" };

const CVTSI_READ = std.StaticStringMap(f64).initComptime(
    suffixedN(&.{ "cvttss2si", "cvtss2si", "vcvttss2si", "vcvtss2si", "vcvttss2usi", "vcvtss2usi" }, 4) ++
        suffixedN(&.{ "cvttsd2si", "cvtsd2si", "vcvttsd2si", "vcvtsd2si", "vcvttsd2usi", "vcvtsd2usi" }, 8),
);
fn suffixedN(comptime names: []const []const u8, comptime v: f64) [names.len * 3]struct { []const u8, f64 } {
    var out: [names.len * 3]struct { []const u8, f64 } = undefined;
    for (names, 0..) |m, i| {
        out[i * 3] = .{ m, v };
        out[i * 3 + 1] = .{ m ++ "l", v };
        out[i * 3 + 2] = .{ m ++ "q", v };
    }
    return out;
}

pub const VecEffects = struct { uses: lt.Table(f64), defs: lt.Table(f64) };

const Fx = struct {
    uses: lt.Table(f64),
    defs: lt.Table(f64),
    fn add(t: *lt.Table(f64), num_: ?f64, w_: ?f64) E!void {
        const nm = num_ orelse return;
        const w = w_.?;
        if ((t.get(.{ .num = nm }) orelse 0) < w) t.set(.{ .num = nm }, w) catch return error.OutOfMemory;
    }
    fn use(x: *Fx, nm: ?f64, w: ?f64) E!void {
        try add(&x.uses, nm, w);
    }
    fn def(x: *Fx, nm: ?f64, w: ?f64) E!void {
        try add(&x.defs, nm, w);
    }
    fn done(x: *Fx) VecEffects {
        return .{ .uses = x.uses, .defs = x.defs };
    }
};

pub fn vecEffects(alloc: Allocator, stmt: *const ir.Stmt) E!VecEffects {
    const mnem = try u.lower(alloc, stmt.mnemonic.?);
    const ops = stmt.operands.items;
    var x: Fx = .{
        .uses = lt.Table(f64).init(alloc, 0, 0) catch return error.OutOfMemory,
        .defs = lt.Table(f64).init(alloc, 0, 0) catch return error.OutOfMemory,
    };
    if (eq(u8, mnem, "vzeroupper")) {
        var i: f64 = 0;
        while (i <= 15) : (i += 1) {
            try x.use(i, 16);
            try x.def(i, 64);
        }
        return x.done();
    }
    if (eq(u8, mnem, "vzeroall")) {
        var i: f64 = 0;
        while (i <= 15) : (i += 1) try x.def(i, 64);
        return x.done();
    }
    if (eq(u8, mnem, "fxsave") or eq(u8, mnem, "fxsave64")) {
        var i: f64 = 0;
        while (i <= 15) : (i += 1) try x.use(i, 16);
        return x.done();
    }
    if (eq(u8, mnem, "fxrstor") or eq(u8, mnem, "fxrstor64")) {
        var i: f64 = 0;
        while (i <= 15) : (i += 1) try x.def(i, 16);
        return x.done();
    }
    const d = vecRegOf(first(ops));
    const dNum: ?f64 = if (d) |v| v.num else null;
    const dClass: ?f64 = if (d) |v| v.class else null;
    var srcs: std.ArrayList(VecReg) = .empty;
    if (ops.len > 1) for (ops[1..]) |o| if (vecRegOf(o)) |v| try srcs.append(alloc, v);
    if (dNum == null and srcs.items.len == 0) return x.done();

    const S = struct {
        fn defaultEffects(fx: *Fx, dn: ?f64, dc: ?f64, ss: []const VecReg) E!VecEffects {
            try fx.use(dn, dc);
            for (ss) |s| try fx.use(s.num, s.class);
            return fx.done();
        }
    };

    if (u.in(mnem, &IMPLICIT_XMM0_USE)) try x.use(0, 16);
    const sfx = try fpSuffixKind(alloc, mnem);
    const scalar = sfx != null and sfx.?.kind == .scalar;
    const sBytes: ?f64 = if (sfx) |v| v.bytes else null;

    if (CVTSI_READ.get(mnem)) |r| {
        for (srcs.items) |s| try x.use(s.num, r);
        return x.done();
    }

    const mem = memOperand(ops);
    const isStore = mem != null and first(ops) == mem;
    if (isStore or u.in(mnem, &READONLY_VEC_FIRST)) {
        if (scalar) {
            try x.use(dNum, sBytes);
            for (srcs.items) |s| try x.use(s.num, sBytes);
            return x.done();
        }
        return S.defaultEffects(&x, dNum, dClass, srcs.items);
    }

    if (startsWith(u8, mnem, "v")) {
        if (eq(u8, mnem, "vmovd") or eq(u8, mnem, "vmovq")) {
            const w: f64 = if (eq(u8, mnem, "vmovd")) 4 else 8;
            if (dNum) |dn| try x.def(dn, 64);
            for (srcs.items) |s| try x.use(s.num, w);
            return x.done();
        }
        if (dNum == null) return S.defaultEffects(&x, dNum, dClass, srcs.items);
        try x.def(dNum, 64);
        const readsDest = startsWith(u8, mnem, "vpdp") or startsWith(u8, mnem, "vpternlog") or
            startsWith(u8, mnem, "vpshld") or startsWith(u8, mnem, "vpshrd") or startsWith(u8, mnem, "vfixupimm") or
            startsWith(u8, mnem, "vpermi2") or startsWith(u8, mnem, "vpermt2") or startsWith(u8, mnem, "vpmadd52") or
            startsWith(u8, mnem, "vp4dp") or startsWith(u8, mnem, "v4fmadd") or
            startsWith(u8, mnem, "v4fnmadd") or startsWith(u8, mnem, "vpmac") or
            (startsWith(u8, mnem, "vf") and (std.mem.indexOf(u8, mnem, "madd") != null or std.mem.indexOf(u8, mnem, "msub") != null));
        if (readsDest) try x.use(dNum, dClass);
        if (ops[0].deco) |deco| {
            if ((try u.matches(alloc, deco, "{%%k%d")) and std.mem.indexOf(u8, deco, "{z}") == null) try x.use(dNum, dClass);
        }
        if (scalar) {
            var src2W = sBytes;
            const m2 = mnem[1..];
            if (eq(u8, m2, "cvtsd2ss")) src2W = 8 else if (eq(u8, m2, "cvtss2sd")) src2W = 4;
            if (srcs.items.len > 0) try x.use(srcs.items[0].num, 16);
            if (srcs.items.len > 1) try x.use(srcs.items[1].num, src2W);
        } else {
            for (srcs.items) |s| try x.use(s.num, s.class);
        }
        return x.done();
    }

    if (eq(u8, mnem, "movd") or eq(u8, mnem, "movq")) {
        const w: f64 = if (eq(u8, mnem, "movd")) 4 else 8;
        if (dNum) |dn| try x.def(dn, 16);
        for (srcs.items) |s| try x.use(s.num, w);
        return x.done();
    }

    const cvtIntW2: ?f64 = if (u.in(mnem, &.{ "cvtsi2ss", "cvtsi2ssl", "cvtsi2ssq" })) 4 else if (u.in(mnem, &.{ "cvtsi2sd", "cvtsi2sdl", "cvtsi2sdq" })) 8 else null;
    if (cvtIntW2) |w| {
        try x.def(dNum, w);
        return x.done();
    }

    if (scalar) {
        if (eq(u8, mnem, "movss") or eq(u8, mnem, "movsd")) {
            if (mem != null) {
                try x.def(dNum, 16);
            } else {
                try x.def(dNum, sBytes);
                for (srcs.items) |s| try x.use(s.num, sBytes);
            }
            return x.done();
        }
        if (eq(u8, mnem, "cvtss2sd") or eq(u8, mnem, "cvtsd2ss")) {
            const sDst: f64 = if (eq(u8, mnem, "cvtss2sd")) 8 else 4;
            const sSrc: f64 = if (eq(u8, mnem, "cvtss2sd")) 4 else 8;
            try x.def(dNum, sDst);
            for (srcs.items) |s| try x.use(s.num, sSrc);
            return x.done();
        }
        try x.def(dNum, sBytes);
        try x.use(dNum, sBytes);
        for (srcs.items) |s| try x.use(s.num, sBytes);
        return x.done();
    }

    if (u.in(mnem, &LEGACY_PARTIAL)) return S.defaultEffects(&x, dNum, dClass, srcs.items);
    if (u.in(mnem, &LEGACY_PURE_MOVE)) {
        try x.def(dNum, 16);
        for (srcs.items) |s| try x.use(s.num, s.class);
        return x.done();
    }
    if (u.in(mnem, &SELF_ZERO) and dNum != null and srcs.items.len == 1 and srcs.items[0].num == dNum.?) {
        try x.def(dNum, 16);
        return x.done();
    }
    if ((sfx != null and sfx.?.kind == .@"packed") or u.in(mnem, &LEGACY_CVT_FULL) or (try u.matches(alloc, mnem, "^p[%a]+$"))) {
        try x.def(dNum, 16);
        try x.use(dNum, 16);
        for (srcs.items) |s| try x.use(s.num, s.class);
        return x.done();
    }
    return S.defaultEffects(&x, dNum, dClass, srcs.items);
}

// ---------------------------------------------------------------------------
// unsafe-instruction rejection

const REASON_SYSCALL = "system-call instructions cannot be bounds-checked (their effect on memory safety is unknowable)";
const REASON_PORTIO = "port-I/O instructions cannot be bounds-checked (they transfer data the checker cannot see)";
const REASON_PRIV = "privileged instructions are not supported (cannot prove memory safety)";
const REASON_STRING = "string instructions use implicit rsi/rdi memory operands that cannot be bounds-checked (cannot prove memory safety)";
const REASON_PREFIX = "instruction prefixes (rep/lock/xacquire/xrelease) are not supported (the prefixed instruction's memory effects cannot be modeled; cannot prove memory safety)";
const REASON_INT = "software interrupt `int N` is not supported for N != 3 (only int3/`int $3`, which raises SIGTRAP, is allowed)";
const REASON_CRDR = "control/debug register moves are not supported (privileged processor state; cannot prove memory safety)";
const REASON_CLZERO = "clzero stores to an implicit memory operand (the 64-byte cache line addressed by rax) that cannot be bounds-checked (cannot prove memory safety)";
const REASON_XLAT = "xlatb loads from an implicit memory operand (the byte at rbx + al) that cannot be bounds-checked (cannot prove memory safety)";
const REASON_FARCTL = "far control-transfer instructions (lcall/ljmp) have implicit stack memory effects (a far return-frame push) that cannot be modeled (cannot prove memory safety)";
const REASON_FSGSBASE = "FSGSBASE instructions (rdfsbase/rdgsbase/wrfsbase/wrgsbase) read or write the fs/gs thread-pointer base registers, which the Fil-C runtime owns (silently corrupting fs.base/gs.base breaks thread-local storage for the whole thread; cannot prove memory safety)";
const REASON_SEGWRITE = "writes to a segment register (es/cs/ss/ds/fs/gs) change processor state the checker cannot model (a bad selector raises an unconverted hardware fault; cannot prove memory safety)";
const REASON_SEGXFER = "push/pop of a segment register is not supported (it transfers the segment selector, which the checker does not model)";
const REASON_SWAPGS = "swapgs swaps the gs.base thread-pointer base, which the Fil-C runtime owns (silently corrupting it breaks thread-local state; cannot prove memory safety)";
const REASON_TSX = "TSX transactional-memory instructions (xbegin/xend/xabort) have transactional control flow and memory semantics the checker cannot model (an xabort/xbegin fallback path is unmodeled control flow; cannot prove memory safety)";
const REASON_SETSSBSY = "setssbsy operates on the CET shadow stack through the implicit shadow-stack pointer (memory the checker cannot see or bounds-check; cannot prove memory safety)";
const REASON_SGX = "SGX enclave instructions (encls/enclu/enclv) have implicit eax/rbx/rcx operands and enclave-controlled memory effects the checker cannot model (cannot prove memory safety)";
const REASON_NOTRACK = "the CET `notrack` prefix is not supported (it changes indirect-branch tracking for the instruction that follows, which the checker does not model; cannot prove memory safety)";
const REASON_LOOPZF = "loop's ZF-consuming form branches on the flags left by the PRECEDING instruction, and sarcasm's injected memory-access checks clobber EFLAGS (the documented known issue), so the pending condition could be silently polluted (modeling it cannot be proven sound; use plain `loop`, which branches on the decremented counter instead)";
const REASON_ADDRSIZE = "an address-size prefix changes the addressing mode of the instruction that follows, which sarcasm does not model (the size-suffixed spelling is supported where one exists, e.g. loopl for the 0x67-address-size `loop`)";
const REASON_FLAGXFER16 = "the 16-bit flag-stack transfers (pushfw/popfw) move a 2-byte word (rsp shifts by 2 and only the low 16 bits of EFLAGS transfer), which the stack model does not track (cannot prove memory safety; use the 64-bit pushf/popf or pushfq/popfq)";
const REASON_FLAGREAD = "flag-reading/writing instructions with unmodeled EFLAGS effects cannot be proven sound against sarcasm's injected flag-clobbering checks (the flag-liveness model has no entry for this mnemonic, so a default-dead assumption would silently omit a required save/restore)";
const REASON_BCD = "BCD arithmetic instructions (daa/das/aaa/aas/aam/aad) read and write AF/CF with unmodeled EFLAGS effects that sarcasm's injected flag-clobbering checks could silently pollute (cannot prove memory safety)";

fn implicitGprReason(comptime mnem: []const u8, comptime list: []const u8) []const u8 {
    return mnem ++ " has implicit GPR operands (" ++ list ++ ") that are not modeled (cannot prove memory safety)";
}

const SEG_PUSHPOP = [_][]const u8{ "push", "pushw", "pushl", "pushq", "pop", "popw", "popl", "popq" };

const UNSAFE = std.StaticStringMap([]const u8).initComptime(.{
    .{ "syscall", REASON_SYSCALL },   .{ "sysenter", REASON_SYSCALL },                                                                                                                   .{ "sysexit", REASON_SYSCALL },                                                                                                             .{ "sysret", REASON_SYSCALL },
    .{ "in", REASON_PORTIO },         .{ "ins", REASON_PORTIO },                                                                                                                         .{ "inb", REASON_PORTIO },                                                                                                                  .{ "inw", REASON_PORTIO },
    .{ "inl", REASON_PORTIO },        .{ "insb", REASON_PORTIO },                                                                                                                        .{ "insw", REASON_PORTIO },                                                                                                                 .{ "insl", REASON_PORTIO },
    .{ "insd", REASON_PORTIO },       .{ "out", REASON_PORTIO },                                                                                                                         .{ "outs", REASON_PORTIO },                                                                                                                 .{ "outb", REASON_PORTIO },
    .{ "outw", REASON_PORTIO },       .{ "outl", REASON_PORTIO },                                                                                                                        .{ "outsb", REASON_PORTIO },                                                                                                                .{ "outsw", REASON_PORTIO },
    .{ "outsl", REASON_PORTIO },      .{ "outsd", REASON_PORTIO },                                                                                                                       .{ "hlt", REASON_PRIV },                                                                                                                    .{ "wrmsr", REASON_PRIV },
    .{ "rdmsr", REASON_PRIV },        .{ "lgdt", REASON_PRIV },                                                                                                                          .{ "lidt", REASON_PRIV },                                                                                                                   .{ "lldt", REASON_PRIV },
    .{ "ltr", REASON_PRIV },          .{ "lmsw", REASON_PRIV },                                                                                                                          .{ "into", REASON_INT },                                                                                                                    .{ "int1", REASON_INT },
    .{ "clzero", REASON_CLZERO },     .{ "xlat", REASON_XLAT },                                                                                                                          .{ "xlatb", REASON_XLAT },                                                                                                                  .{ "lcall", REASON_FARCTL },
    .{ "ljmp", REASON_FARCTL },       .{ "umwait", implicitGprReason("umwait", "rax/rdx") },                                                                                             .{ "tpause", implicitGprReason("tpause", "rax/rdx") },                                                                                      .{ "wrfsbase", REASON_FSGSBASE },
    .{ "wrgsbase", REASON_FSGSBASE }, .{ "rdfsbase", REASON_FSGSBASE },                                                                                                                  .{ "rdgsbase", REASON_FSGSBASE },                                                                                                           .{ "swapgs", REASON_SWAPGS },
    .{ "xbegin", REASON_TSX },        .{ "xend", REASON_TSX },                                                                                                                           .{ "xabort", REASON_TSX },                                                                                                                  .{ "setssbsy", REASON_SETSSBSY },
    .{ "encls", REASON_SGX },         .{ "enclu", REASON_SGX },                                                                                                                          .{ "enclv", REASON_SGX },                                                                                                                   .{ "skinit", REASON_PRIV },
    .{ "notrack", REASON_NOTRACK },   .{ "umonitor", "umonitor arms address-monitoring hardware on a memory range whose extent cannot be bounds-checked (cannot prove memory safety)" }, .{ "loope", REASON_LOOPZF },                                                                                                                .{ "loopz", REASON_LOOPZF },
    .{ "loopne", REASON_LOOPZF },     .{ "loopnz", REASON_LOOPZF },                                                                                                                      .{ "jcxz", "jcxz is not supported in 64-bit mode (the 16-bit-counter form is not encodable; use jrcxz, or jecxz for the 32-bit counter)" }, .{ "addr32", REASON_ADDRSIZE },
    .{ "addr16", REASON_ADDRSIZE },   .{ "pushfw", REASON_FLAGXFER16 },                                                                                                                  .{ "popfw", REASON_FLAGXFER16 },                                                                                                            .{ "salc", REASON_FLAGREAD },
    .{ "daa", REASON_BCD },           .{ "das", REASON_BCD },                                                                                                                            .{ "aaa", REASON_BCD },                                                                                                                     .{ "aas", REASON_BCD },
    .{ "aam", REASON_BCD },           .{ "aad", REASON_BCD },                                                                                                                            .{ "arpl", REASON_FLAGREAD },
});

const STRINGOPS = [_][]const u8{ "lods", "lodsb", "lodsw", "lodsl", "lodsq", "lodsd", "scas", "scasb", "scasw", "scasl", "scasq", "scasd", "cmps", "cmpsb", "cmpsw", "cmpsl", "cmpsq" };

pub fn unsafeReject(alloc: Allocator, mnem_in: []const u8, insn: *const ir.Stmt) E!?[]const u8 {
    const mnem = try u.lower(alloc, mnem_in);
    const ops = insn.operands.items;
    if (UNSAFE.get(mnem)) |r| return r;
    if (u.in(mnem, &STRINGOPS)) return REASON_STRING;
    if (u.in(mnem, &.{ "lock", "xacquire", "xrelease" })) return REASON_PREFIX;
    if (u.in(mnem, &.{ "movsd", "cmpsd" }) and ops.len == 0) return REASON_STRING;
    if (first(ops)) |dest| if (dest.kind == .reg and dest.rc == .seg) {
        if (u.in(mnem, &SEG_PUSHPOP)) return REASON_SEGXFER;
        return REASON_SEGWRITE;
    };
    if (eq(u8, mnem, "int")) {
        var v: ?f64 = null;
        if (first(ops)) |o| if (o.kind == .imm) {
            v = o.value orelse if (o.text) |t| ln.tonumber(t) else null;
        };
        if (v != null and v.? == 3) return null;
        return REASON_INT;
    }
    if (u.in(mnem, &.{ "mov", "movq", "movl" })) {
        for (ops) |o| if (o.kind == .sym) {
            if (try u.matches(alloc, try u.lower(alloc, o.text.?), "^%%?[cd]r[0-9]+$")) return REASON_CRDR;
        };
    }
    return null;
}
