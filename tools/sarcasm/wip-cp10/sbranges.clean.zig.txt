// SPDX-License-Identifier: BSD-2-Clause
// A port of Fil-C's sarcasm (projects/sarcasm). These are the terms of projects/sarcasm/install.sh,
// the folder's licence text, whose header names the sarcasm sources it installs (owner, 2026-11-24;
// third_party/fil-c/SARCASM-LICENSE.txt; ledger entry `sarcasm-port`).
// The port to Zig is zilc's (the module comment below says what was ported and how).
//
// Copyright (c) 2026 Filip Pizlo. All Rights Reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY FILIP PIZLO ``AS IS AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL FILIP PIZLO OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
// OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//! x86_64_frame's stack-buffer scan, first part: upstream x86_64_frame.luau lines 4696–4959. The
//! closures `checkRangeFits` (4696: does a declared buffer fit the frame: floor, push pad, clone
//! sub-frame, outstanding saves, outgoing area, fixed alloca regions), `widthOf` (4854: a stack
//! access's width and alignment), `resolveShortRangeFor` (4870: the range a SHORT form names for a
//! statement), and pass (a), the declarations loop (4908): every `#! stack buffer` declaration is
//! resolved, checked and recorded in sbRanges (this function's declarations, in body order),
//! cloneDeclRanges (per clone, per buffer id) and ownDeclIds (the enclosing function's own
//! declarations). The pass sets no mark; its results are Analysis.sbRanges / cloneDeclRanges /
//! ownDeclIds, and its only other result is a rejection. widthOf and resolveShortRangeFor have no
//! caller inside this span (first callers 5067 and 5138): they are ported with the span and
//! their faults are checked from the checkpoint that ports those callers.
//! The span runs inside the scan's gate (`regions ~= nil and not sbResolving`, 4641), so
//! resolveBufRangeAt never returns nil here (its nil is `sbResolving`'s, 454 / 4880).

const std = @import("std");
const err = @import("err.zig");
const ir = @import("ir.zig");
const fp = @import("x86_64_fp.zig");
const u = @import("util.zig");
const XF = @import("x86_64_frame.zig");
const flow = @import("x86_64_frame_flow.zig");

const E = err.Error;
const A = XF.Analysis;
const Stmt = ir.Stmt;

fn rawOf(st: *const Stmt) []const u8 {
    return st.raw orelse st.mnemonic orelse "?";
}

/// tostring of a depth value: a number, "dyn", or nil.
fn depthStr(alloc: std.mem.Allocator, d: ?XF.Depth) E![]const u8 {
    const dd = d orelse return "nil";
    return switch (dd) {
        .num => |n| try u.num(alloc, n),
        .dyn => "dyn",
    };
}

/// checkRangeFits (4696). `dDecl` is st.x86_depth and `sv` is st.x86_saves (the statement's own
/// marks, passed in: the port keeps them in per-index arrays).
fn checkRangeFits(a: *A, loN: f64, hiN: f64, homeLo: f64, homeHi: f64, id: []const u8, dDecl: ?XF.Depth, st: *const Stmt, sv: ?XF.Saves) E!void {
    const alloc = a.alloc;
    const L = st.loc();
    // 4734
    var frameFloor: f64 = 0;
    if (dDecl) |dd| if (!XF.isDynDepth(dd)) {
        frameFloor = XF.D0 - dd.num;
    };
    // 4741: a clone statement's own-frame floor sits 8 lower
    if (st.localClone != null) if (dDecl) |dd| if (!XF.isDynDepth(dd)) {
        frameFloor = frameFloor - 8;
    };
    if (loN < frameFloor) { // 4744
        const why = if (frameFloor == 0)
            try u.fmt(alloc, "; buffers must live inside the function's own frame", .{})
        else
            try u.fmt(alloc, "; the declaring statement's rsp depth {s} only proves the bytes at or above {s}", .{ try depthStr(alloc, dDecl), try u.num(alloc, frameFloor) });
        return err.at(L, try u.fmt(alloc, "stack buffer ({s}) reaches below the function's own allocated stack (normalized offset {s} < floor {s}{s}): {s} < {s}", .{
            id, try u.num(alloc, loN), try u.num(alloc, frameFloor), why, try u.num(alloc, loN), try u.num(alloc, frameFloor),
        }));
    }
    if (homeLo < XF.D0 and homeHi > a.pushTop) { // 4754
        // 4768: frameAndSeen with no outstanding saves grows the usable top to frameSize
        const andTop: ?f64 = if (XF.frameAndSeen and a.maxSaves == 0) a.frameSize else null;
        if (!(andTop != null and homeHi <= andTop.?)) {
            return err.at(L, try u.fmt(alloc, "stack buffer ({s}) extends to normalized offset {s}, past the frame's usable top {s} (the frame is [0, {s}) and its top {s} bytes are the outstanding push/callee-save slots): {s} > {s}", .{
                id,
                try u.num(alloc, homeHi),
                try u.num(alloc, a.pushTop),
                try u.num(alloc, XF.D0),
                try u.num(alloc, 8 * @as(f64, @floatFromInt(a.maxSaves))),
                try u.num(alloc, homeHi),
                try u.num(alloc, a.pushTop),
            }));
        }
    }
    if (st.localClone) |lc| { // 4786
        const ed = a.cloneEntryDepth.get(@bitCast(lc));
        const cloneTop: ?f64 = if (ed) |e| XF.D0 - e - 8 else null;
        if (cloneTop == null or hiN > cloneTop.?) {
            return err.at(L, try u.fmt(alloc, "stack buffer ({s}) is declared inside a local subroutine clone but reaches normalized offset {s}, above the clone's own sub-frame (top {s}); a clone-declared buffer must live in the subroutine's own frame below its caller's return-address word: {s}", .{
                id, try u.num(alloc, hiN), if (cloneTop) |ct| try u.num(alloc, ct) else "nil", rawOf(st),
            }));
        }
    }
    // 4812: the declaring statement's own outstanding saves (st is never nil here)
    if (sv) |s_| {
        if (XF.isDynSaves(s_)) {
            return err.at(L, try u.fmt(alloc, "stack buffer ({s}) is declared at a statement whose outstanding-save state cannot be proven (the buffer's bytes must be provably disjoint from every pushed-register save slot): {s}", .{ id, rawOf(st) }));
        }
        for (s_.items) |s| {
            if (a.usesRbp and std.mem.eql(u8, s.name, "rbp")) continue; // saved frame pointer
            if (s.spill orelse false) continue; // a spill slot is an ordinary slot
            const slo = XF.D0 - s.depth;
            const shi = XF.D0 - s.depth + 8;
            if (loN < shi and hiN > slo) {
                return err.at(L, try u.fmt(alloc, "stack buffer ({s}) overlaps a pushed register's save slot at normalized [{s}, {s}) (the slot's bytes are the pushed register's web while the push is outstanding; move the buffer below the push or pop it first): {s}", .{
                    id, try u.num(alloc, slo), try u.num(alloc, shi), rawOf(st),
                }));
            }
        }
    }
    // 4838: the outgoing call-argument area [0, sbOutgoing)
    if (homeLo < a.sbOutgoing and homeHi > 0) {
        return err.at(L, try u.fmt(alloc, "stack buffer ({s}) overlaps the outgoing call-argument area [0, {s}): {s} < {s}", .{
            id, try u.num(alloc, a.sbOutgoing), try u.num(alloc, homeLo), try u.num(alloc, a.sbOutgoing),
        }));
    }
    for (a.regions orelse &.{}) |r| { // 4843
        if (!(r.anchored orelse false) and r.base < homeHi and r.base + r.size > homeLo) {
            return err.at(L, try u.fmt(alloc, "stack buffer ({s}) overlaps a fixed alloca region at normalized offsets [{s}, {s}) (buffer region and alloca region coordinates must not collide)", .{
                id, try u.num(alloc, @max(r.base, homeLo)), try u.num(alloc, @min(r.base + r.size, homeHi)),
            }));
        }
    }
}

pub const Width = struct { w: ?f64, @"align": ?f64 };

/// widthOf (4854): a stack access's width and alignment (alignment only for FP accesses).
pub fn widthOf(a: *A, st: *const Stmt, mem: *const ir.Operand) E!Width {
    const alloc = a.alloc;
    const m = try u.lower(alloc, st.mnemonic.?);
    const fpe = try fp.lookup(alloc, m);
    if (flow.isFpInsn(fpe, st)) {
        const acc = (try fp.accessWidth(alloc, m, st.operands.items, st.raw, st.loc())) orelse return .{ .w = null, .@"align" = null };
        return .{ .w = acc.w, .@"align" = acc.@"align" };
    }
    // 4862: gprStackWidth never returns nil, so `or mem.size` is never reached
    return .{ .w = try flow.gprStackWidth(alloc, m, mem), .@"align" = null };
}

/// resolveShortRangeFor (4870): the buffer range a SHORT form names for `st`; the clone's own
/// declaration wins inside a clone. A null result is `return nil, nil` (sbResolving).
pub fn resolveShortRangeFor(a: *A, st: *const Stmt) E!?XF.LoHi {
    const alloc = a.alloc;
    const L = st.loc();
    const sb = st.stackBufAnno.?;
    const canon = XF.stackBufCanonOf(sb.id); // 4872
    if (st.localClone) |lc| { // 4873
        if (a.cloneDeclRanges.get(@bitCast(lc))) |cm| if (cm.get(sb.id)) |r| return r;
        const cn = canon orelse
            return err.at(L, try u.fmt(alloc, "`stack buffer ({s})` short form has no long form anywhere in this file (declare the buffer with e.g. `#! stack buffer ({s}, %rsp, %rsp + N)` on a buffer access in some function): {s}", .{ sb.id, sb.id, rawOf(st) }));
        if (!a.ownDeclIds.contains(sb.id))
            return err.at(L, try u.fmt(alloc, "`stack buffer ({s})` is declared inside local subroutine '{s}' (its bytes live in that subroutine's own frame); only that subroutine's cloned code addresses it - declare a buffer in this function with the long form instead: {s}", .{ sb.id, cn.fn_ orelse "nil", rawOf(st) }));
        return .{ .lo = cn.lo, .hi = cn.hi };
    }
    const cn = canon orelse { // 4892
        if (XF.sbResolving) return null;
        return err.at(L, try u.fmt(alloc, "`stack buffer ({s})` short form has no long form anywhere in this file (declare the buffer with e.g. `#! stack buffer ({s}, %rsp, %rsp + N)` on a buffer access in some function): {s}", .{ sb.id, sb.id, rawOf(st) }));
    };
    if (cn.sub orelse false)
        return err.at(L, try u.fmt(alloc, "`stack buffer ({s})` is declared inside local subroutine '{s}' (its bytes live in that subroutine's own frame); only that subroutine's cloned code addresses it - declare a buffer in this function with the long form instead: {s}", .{ sb.id, cn.fn_ orelse "nil", rawOf(st) }));
    return .{ .lo = cn.lo, .hi = cn.hi };
}

/// Pass (a) (4908; the loop is 4911): the declarations, FIRST (before any access is classified against them).
pub fn declarations(a: *A) E!void {
    const alloc = a.alloc;
    for (a.body, 1..) |st, ia| {
        if (st.kind != .insn) continue; // 4912
        const sb = st.stackBufAnno orelse continue;
        // 4913: a short form on a CLONE statement resolves per access, not here
        if (sb.short and st.localClone != null) continue;
        const d = a.depthIn[ia - 1]; // st.x86_depth / x86_fp / x86_smap (3305–3325)
        const rg = (try flow.resolveBufRangeAt(a, st, d, a.smapIn[ia - 1], a.fpIn[ia - 1], ia < a.prologueEnd)) orelse continue; // 4921
        const loN = rg.lo;
        const hiN = rg.hi;
        if (std.mem.eql(u8, try u.lower(alloc, st.mnemonic.?), "lea")) // 4924
            return err.at(st.loc(), try u.fmt(alloc, "`stack buffer` annotation on a lea is not supported (a lea takes no memory access; annotate the accesses or the rep instead): {s}", .{rawOf(st)}));
        const band = st.x86.b2band orelse 0; // 4932
        try checkRangeFits(a, loN, hiN, loN + band, hiN + band, sb.id, d, st, a.savesIn[ia - 1]); // 4933
        try a.sbRanges.append(alloc, .{ .lo = loN + band, .hi = hiN + band, .id = sb.id, .declIdx = ia, .band = band }); // 4935
        if (st.localClone) |lc| { // 4947
            const gop = try a.cloneDeclRanges.getOrPut(alloc, @bitCast(lc));
            if (!gop.found_existing) gop.value_ptr.* = .empty;
            try gop.value_ptr.put(alloc, sb.id, .{ .lo = loN, .hi = hiN });
        } else {
            try a.ownDeclIds.put(alloc, sb.id, {}); // 4955
        }
    }
}
