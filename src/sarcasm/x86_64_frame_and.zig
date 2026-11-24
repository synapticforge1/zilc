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
//! x86_64_frame's pre/post-`and` walks: upstream x86_64_frame.luau lines 3751–4069 (andDomOf,
//! reachedFromAnd, the x86_preAnd / x86_postAnd marks, the governing-`and` dataflow, the
//! alias-carrier crossing rejection, and the prologue-`and` fill of andDomOf). A free function
//! over x86_64_frame.Analysis, like the flow file. andDomOf and reachedFromAnd are Analysis
//! fields with a slot per body index 1..#body+1 (successors can name #body+1).

const std = @import("std");
const err = @import("err.zig");
const ir = @import("ir.zig");
const isa = @import("x86_64_isa.zig");
const u = @import("util.zig");
const XF = @import("x86_64_frame.zig");
const flow = @import("x86_64_frame_flow.zig");

const E = err.Error;
const Stmt = ir.Stmt;
const eq = std.mem.eql;
const A = XF.Analysis;
const Gand = XF.Gand;
const rcIs = XF.rcIs;
const kindIs = XF.kindIs;

fn baseOf(a: *A, st: *const Stmt) E![]const u8 {
    return isa.baseMnemonic(a.alloc, try u.lower(a.alloc, st.mnemonic.?));
}

fn lastMem(st: *const Stmt) ?*ir.Operand {
    var m: ?*ir.Operand = null;
    for (st.operands.items) |o| if (o.kind == .mem) {
        m = o;
    };
    return m;
}

/// reachedFromAnd[k] (nil / out of range: false).
fn reachedAt(a: *A, k: f64) bool {
    if (k < 1 or k != @floor(k) or k >= @as(f64, @floatFromInt(a.reachedFromAnd.len))) return false;
    return a.reachedFromAnd[@intFromFloat(k)];
}

/// gandJoin (3860).
fn gandJoin(x: ?Gand, y: ?Gand) ?Gand {
    const xv = x orelse return y;
    const yv = y orelse return x;
    if (gandEq(xv, yv)) return xv;
    return .dyn;
}

fn gandEq(x: ?Gand, y: ?Gand) bool {
    if (x == null or y == null) return x == null and y == null;
    return std.meta.activeTag(x.?) == std.meta.activeTag(y.?) and (x.? != .num or x.?.num == y.?.num);
}

/// dropRestoreCrossingExempt (3959).
fn dropRestoreCrossingExempt(a: *A, i: usize, st: *const Stmt) bool {
    if (!st.x86.dropRestore) return false;
    const mem = lastMem(st) orelse return false;
    const base = mem.base orelse return false;
    if (base.kind != .reg) return false;
    const sm = a.smapIn[i - 1] orelse return false;
    const e = flow.sget(sm, base.name) orelse return false;
    if (!(!(e.redefined orelse false) and !(e.slot orelse false) and e.roff == null and !(e.conflict orelse false))) return false;
    // Entry-derived: the parked value must be the entry rsp itself (depth 0), parked on a path
    // reached from no mid-function and.
    const ed = e.depth orelse return false;
    if (ed != 0) return false;
    const parkIdx = e.saveIdx orelse (st.x86.aliasSaveIdx orelse 0);
    if (parkIdx == 0 or reachedAt(a, parkIdx)) return false;
    // Save-depth match, re-verified against the incoming save stack.
    const sv = a.savesIn[i - 1] orelse return false;
    if (XF.isDynSaves(sv)) return false;
    const want = ed - (mem.dispVal orelse 0);
    for (sv.items) |s| {
        if (s.depth == want) {
            const n = st.operands.items[0].name orelse return false;
            return eq(u8, s.name, n);
        }
    }
    return false;
}

pub fn andWalk(a: *A) E!void {
    const alloc = a.alloc;
    const body = a.body;
    const n = body.len;
    a.andDomOf = try alloc.alloc(?Gand, n + 2);
    @memset(a.andDomOf, null);
    a.reachedFromAnd = try alloc.alloc(bool, n + 2);
    @memset(a.reachedFromAnd, false);

    // 3758
    var andIdxs: std.ArrayList(usize) = .empty;
    for (body, 1..) |st, i| if (st.kind == .insn and st.x86.midAnd) try andIdxs.append(alloc, i);
    if (andIdxs.items.len > 0) {
        const firstAnd = andIdxs.items[0];
        const isAnd = try alloc.alloc(bool, n + 2);
        @memset(isAnd, false);
        for (andIdxs.items) |x| isAnd[x] = true;
        // pred (3781): successors of every insn, inverted
        const pred = try alloc.alloc(std.ArrayList(usize), n + 2);
        for (pred) |*p| p.* = .empty;
        for (body, 1..) |st, i| if (st.kind == .insn) {
            for (try flow.successors(a, i)) |s| try pred[s].append(alloc, i);
        };
        // the walk back from every and (3791)
        const reached = try alloc.alloc(bool, n + 2);
        @memset(reached, false);
        var work: std.ArrayList(usize) = .empty;
        for (andIdxs.items) |x| if (!reached[x]) {
            reached[x] = true;
            try work.append(alloc, x);
        };
        while (work.pop()) |j| {
            for (pred[j].items) |p| if (!reached[p]) {
                reached[p] = true;
                try work.append(alloc, p);
            };
        }
        for (body, 1..) |st, i| if (st.kind == .insn and reached[i] and !isAnd[i]) {
            st.x86.preAnd = true;
        };
        // forward reachability from the mids (3826)
        var work2: std.ArrayList(usize) = .empty;
        for (andIdxs.items) |x| if (!a.reachedFromAnd[x]) {
            a.reachedFromAnd[x] = true;
            try work2.append(alloc, x);
        };
        while (work2.pop()) |j| {
            if (j > n) @panic("x86_64_frame: reachedFromAnd walk reached the end of the body (upstream indexes nil there)");
            for (try flow.successors(a, j)) |s| if (!a.reachedFromAnd[s]) {
                a.reachedFromAnd[s] = true;
                try work2.append(alloc, s);
            };
        }
        for (body, 1..) |st, j| if (st.kind == .insn and a.reachedFromAnd[j] and !isAnd[j]) {
            st.x86.postAnd = true;
        };

        // the governing-`and` dataflow (3859)
        const gand = a.andDomOf;
        const gqueued = try alloc.alloc(bool, n + 2);
        @memset(gqueued, false);
        var gwork: std.ArrayList(usize) = .empty;
        var gentry: ?usize = null;
        for (body, 1..) |st, i| if (st.kind == .insn) {
            gentry = i;
            break;
        };
        if (gentry) |g| {
            gand[g] = .none;
            try gwork.append(alloc, g);
            gqueued[g] = true;
        }
        while (gwork.pop()) |i| {
            if (i > n) @panic("x86_64_frame: andDomOf walk reached the end of the body (upstream indexes nil there)");
            const st = body[i - 1];
            const din = a.depthIn[i - 1];
            var out: ?Gand = null;
            if (st.kind != .insn) {
                out = gand[i];
            } else if (isAnd[i]) {
                if (din) |d| out = switch (d) {
                    .num => |x| Gand{ .num = x },
                    .dyn => Gand.dyn,
                };
            } else if (din != null and din.? == .dyn) {
                // already at an unprovable depth: the and story is moot
                out = .dyn;
            } else {
                const bm = try baseOf(a, st);
                const ops = st.operands.items;
                const spDst = ops.len > 0 and rcIs(ops[0], .sp);
                if (eq(u8, bm, "pop") or eq(u8, bm, "ret") or eq(u8, bm, "leave") or
                    (eq(u8, bm, "add") and spDst) or
                    ((eq(u8, bm, "mov") or eq(u8, bm, "lea")) and spDst))
                {
                    out = .dyn;
                } else out = gand[i];
            }
            if (out != null) {
                for (try flow.successors(a, i)) |s2| {
                    const merged = gandJoin(gand[s2], out);
                    if (!gandEq(merged, gand[s2])) {
                        gand[s2] = merged;
                        if (!gqueued[s2]) {
                            gqueued[s2] = true;
                            try gwork.append(alloc, s2);
                        }
                    }
                }
            }
        }

        // alias-carrier accesses crossing a mid-function and (3988)
        for (body, 1..) |st, i| {
            if (st.kind == .insn and st.x86.aliasOff != null and !st.x86.preAnd and !isAnd[i] and
                !dropRestoreCrossingExempt(a, i, st))
            {
                const sIdx = st.x86.aliasSaveIdx orelse 0;
                var prevAnd: ?usize = null;
                for (andIdxs.items) |x| {
                    if (x < i) prevAnd = x else break;
                }
                const crosses = if (prevAnd) |p| !(sIdx > @as(f64, @floatFromInt(p))) else !(sIdx < @as(f64, @floatFromInt(firstAnd)));
                if (crosses) {
                    return err.at(st.loc(), try u.fmt(alloc, "stack access through a saved stack-pointer register crossing a mid-function `and $-N, %rsp` cannot be proven safe (the save was before the and but the use is after it, and pre- and post-and traffic share one numbering while the and shifts rsp by a dynamic slack, so the same slot key names different addresses; legal shapes keep save and use on the same side — both before the and, or save after the and and use after it — or address the slot directly): {s}", .{st.raw orelse st.mnemonic orelse "?"}));
                }
            }
        }
    }

    // the prologue-prefix ands seed andDomOf (4050)
    var cur: ?f64 = null;
    for (body, 1..) |st, i| {
        if (st.kind == .insn and st.b2clone == null and st.localClone == null) {
            if (cur != null) {
                const g = a.andDomOf[i];
                if (g == null or g.? == .none) a.andDomOf[i] = .{ .num = cur.? };
            }
            if (st.x86.prologue orelse false) {
                const b0 = try baseOf(a, st);
                const o0 = st.operands.items;
                const din = a.depthIn[i - 1];
                if (eq(u8, b0, "and") and o0.len > 0 and rcIs(o0[0], .sp) and
                    o0.len > 1 and kindIs(o0[1], .imm) and
                    din != null and din.? == .num and
                    XF.isStackAlign(-XF.immVal(o0[1])))
                {
                    cur = din.?.num;
                }
            }
        }
    }
}
