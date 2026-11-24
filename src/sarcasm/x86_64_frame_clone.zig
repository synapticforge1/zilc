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
//! x86_64_frame's anyMidAnd, parkPostOf and the clone subframe balance check: upstream
//! x86_64_frame.luau lines 4070–4359. A free function over x86_64_frame.Analysis, like the flow
//! file. anyMidAnd is an Analysis field and parkPostOf a function over it (later code reads
//! both); the balance check sets no marks and only rejects.

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
const Depth = XF.Depth;
const at = XF.at;
const rcIs = XF.rcIs;
const kindIs = XF.kindIs;

fn baseOf(a: *A, st: *const Stmt) E![]const u8 {
    return isa.baseMnemonic(a.alloc, try u.lower(a.alloc, st.mnemonic.?));
}

fn tr(b: ?bool) bool {
    return b orelse false;
}

fn rawOf(st: *const Stmt) []const u8 {
    return st.raw orelse st.mnemonic orelse "?";
}

/// depthIn[idx] (nil past the end: upstream indexes a table).
fn depthAt(a: *A, idx: usize) ?Depth {
    if (idx < 1 or idx > a.depthIn.len) return null;
    return a.depthIn[idx - 1];
}
fn savesAt(a: *A, idx: usize) ?XF.Saves {
    if (idx < 1 or idx > a.savesIn.len) return null;
    return a.savesIn[idx - 1];
}
fn smapAt(a: *A, idx: usize) ?*XF.Smap {
    if (idx < 1 or idx > a.smapIn.len) return null;
    return a.smapIn[idx - 1];
}

/// reachedFromAnd[k] (nil / out of range: false).
fn reachedAt(a: *A, k: f64) bool {
    if (k < 1 or k != @floor(k) or k >= @as(f64, @floatFromInt(a.reachedFromAnd.len))) return false;
    return a.reachedFromAnd[@intFromFloat(k)];
}

/// parkPostOf (4085): did the park site at body index `saveIdx` execute after the frame's
/// alignment `and`?
pub fn parkPostOf(a: *A, saveIdx: ?f64) bool {
    const s = saveIdx orelse return false;
    if (reachedAt(a, s)) return true;
    if (XF.frameAndIdx) |fi| {
        if (s > @as(f64, @floatFromInt(fi))) return true;
    }
    return false;
}

/// A live carrier entry: not redefined, not a slot, no roff, no conflict.
fn liveEntry(e: *const XF.SmapEntry) bool {
    return !tr(e.redefined) and !tr(e.slot) and e.roff == null and !tr(e.conflict);
}

/// carrierToZeroOk (4143): the direct-carrier-to-entry-rsp hatch.
fn carrierToZeroOk(a: *A, retIdx: usize, entryIdx: ?usize, retSt: *const Stmt) E!bool {
    const dR = depthAt(a, retIdx);
    const dE: ?Depth = if (entryIdx) |e| depthAt(a, e) else null;
    if (dR == null or dR.? != .num or dR.?.num != 0) return false;
    if (dE == null or dE.? != .num or dE.?.num == 0) return false;
    const svR = savesAt(a, retIdx) orelse return false;
    const svE = (if (entryIdx) |e| savesAt(a, e) else null) orelse return false;
    if (XF.isDynSaves(svR) or XF.isDynSaves(svE)) return false;
    if (svR.items.len != 0 or svE.items.len != 0) return false;
    const cidx = retSt.b2clone orelse return false;
    for (a.body, 1..) |cst, j| {
        if (cst.b2clone != null and cst.b2clone.? == cidx) {
            // (a nil entry: an unreachable clone point, dead code needs no proof)
            if (savesAt(a, j)) |sv| {
                if (XF.isDynSaves(sv)) return false;
                if (sv.items.len != 0) return false;
            }
            if (cst.kind == .insn) {
                const b = try baseOf(a, cst);
                if (eq(u8, b, "push") or eq(u8, b, "pop")) return false;
            }
        }
    }
    var recoverSaveIdx: ?f64 = null;
    for (a.body, 1..) |cst, j| {
        if (cst.b2clone != null and cst.b2clone.? == cidx and cst.x86.spRecover and cst.kind == .insn) {
            const ops = cst.operands.items;
            const b = try baseOf(a, cst);
            if (smapAt(a, j)) |sm| {
                if (eq(u8, b, "mov") and rcIs(at(ops, 0), .sp) and kindIs(at(ops, 1), .reg)) {
                    if (flow.sget(sm, ops[1].name)) |ee| {
                        if (liveEntry(ee) and ee.depth != null and ee.depth.? == 0 and ee.saveIdx != null) {
                            recoverSaveIdx = ee.saveIdx;
                            break;
                        }
                    }
                } else if (eq(u8, b, "lea") and rcIs(at(ops, 0), .sp) and kindIs(at(ops, 1), .mem) and
                    ops[1].base != null and ops[1].base.?.kind == .reg and ops[1].index == null and
                    ops[1].dispSym == null)
                {
                    if (flow.sget(sm, ops[1].base.?.name)) |ee| {
                        if (liveEntry(ee) and ee.depth != null and ee.saveIdx != null) {
                            const rd = ee.depth.? - (ops[1].dispVal orelse 0);
                            if (rd == 0) {
                                recoverSaveIdx = ee.saveIdx;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    const rsi = recoverSaveIdx orelse return false;
    const smR = smapAt(a, retIdx) orelse return false;
    var it = smR.iterator();
    while (it.next()) |en| {
        const ee = en.val;
        if (liveEntry(ee) and ee.saveIdx != null and ee.saveIdx.? == rsi and ee.depth != null) return true;
    }
    return false;
}

/// depthEq (4212): for number | dyn depths, equality.
fn depthEq(x: Depth, y: Depth) bool {
    return switch (x) {
        .num => |p| y == .num and y.num == p,
        .dyn => y == .dyn,
    };
}

pub fn cloneBalance(a: *A) E!void {
    const alloc = a.alloc;
    const body = a.body;
    const n = body.len;

    // 4081
    a.anyMidAnd = false;
    for (body) |st0| if (st0.kind == .insn and st0.x86.midAnd) {
        a.anyMidAnd = true;
        break;
    };

    // CFG reachability for the fail-closed nil check (4225)
    const reachable = try alloc.alloc(bool, n + 2);
    @memset(reachable, false);
    var firstInsn: ?usize = null;
    for (body, 1..) |s, idx| if (s.kind == .insn) {
        firstInsn = idx;
        break;
    };
    if (firstInsn) |fi| {
        reachable[fi] = true;
        var work: std.ArrayList(usize) = .empty;
        try work.append(alloc, fi);
        while (work.pop()) |cur| {
            if (cur > n) @panic("x86_64_frame: the CFG reachability walk reached the end of the body (upstream indexes nil there)");
            for (try flow.successors(a, cur)) |s| if (!reachable[s]) {
                reachable[s] = true;
                try work.append(alloc, s);
            };
        }
    }

    // the balance check (4242, 4271)
    for (body, 1..) |st, i| {
        if (st.kind == .insn and (st.localRet != null or (st.cloneRet != null and a.regions != null))) {
            const isClone = st.cloneRet != null;
            const entry: ?[]const u8 = if (st.localRet) |lr| lr.entry else st.cloneRet.?.entry;
            const e: ?usize = if (entry) |en| a.labelAt.get(en) else null;
            const dRet = depthAt(a, i);
            const dEntry: ?Depth = if (e) |x| depthAt(a, x) else null;
            if (dRet == null) {
                // Unreached ret (dead code) needs no balance proof; a CFG-reachable ret with no
                // depth is an analysis gap: fail closed.
                if (reachable[i]) {
                    return err.at(st.loc(), try u.fmt(alloc, "{s}{s}", .{
                        if (isClone)
                            "shared-tail clone returns with an unprovable stack-pointer depth (no depth could be proven for the `ret` itself): "
                        else
                            "local subroutine returns with an unprovable stack-pointer depth (no depth could be proven for the `ret` itself): ",
                        rawOf(st),
                    }));
                } else continue;
            }
            if (dEntry == null) {
                return err.at(st.loc(), try u.fmt(alloc, "{s}{s}", .{
                    if (isClone)
                        "shared-tail clone returns with an unprovable clone-entry depth (cannot prove the clone's inner frame was torn down before `ret`): "
                    else
                        "local subroutine returns with an unprovable clone-entry depth (cannot prove the subroutine's scratch frame was torn down before `ret`): ",
                    rawOf(st),
                }));
            }
            const dr = dRet.?;
            const de = dEntry.?;
            if (XF.isDynDepth(dr) or XF.isDynDepth(de) or
                (!depthEq(dr, de) and
                    !(isClone and dr == .num and dr.num == 0 and st.x86.teardown) and
                    !(isClone and try carrierToZeroOk(a, i, e, st))))
            {
                if (XF.isDynDepth(dr) or XF.isDynDepth(de)) {
                    return err.at(st.loc(), try u.fmt(alloc, "{s}{s}", .{
                        if (isClone)
                            "shared-tail clone returns with an unknown stack-pointer depth (cannot prove the clone's inner frame was torn down before `ret`): "
                        else
                            "local subroutine returns with an unknown stack-pointer depth (cannot prove the subroutine's scratch frame was torn down before `ret`): ",
                        rawOf(st),
                    }));
                } else {
                    return err.at(st.loc(), try u.fmt(alloc, "{s}{s}", .{
                        if (isClone)
                            "shared-tail clone returns with an unbalanced stack frame (the clone must undo every `sub $N,%rsp` on every path before `ret` — back to its clone-entry depth, or all the way to the entry rsp inside a verified epilogue teardown span (one constant `add` plus paired callee-saved pops leading straight to `ret`) when it carries its owner's whole epilogue): "
                        else
                            "local subroutine returns with an unbalanced stack frame (a `sub $N,%rsp` scratch frame inside the subroutine must be torn down with a matching `add $N,%rsp` on every path before `ret`; the continuation resumes at the caller's depth): ",
                        rawOf(st),
                    }));
                }
            }
        }
    }
}
