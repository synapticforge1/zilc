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
//! x86_64_frame's annotation pass: upstream x86_64_frame.luau lines 3213–3749 (validateTeardown,
//! checkLostReload, retIsGpr, and the loop that sets x86_prologue / x86_spRecover / x86_spSave /
//! x86_saveStore / x86_carrierLoad / x86_aliasOff / x86_dropRestore / x86_leaSave / x86_spillPop /
//! x86_unpairedPop / x86_flagsPop / x86_teardownStart / x86_teardown / x86_midSp / x86_midAnd on
//! every instruction and updates frameAlignReq / frameAndDepth / frameAndSeen). Free functions over
//! x86_64_frame.Analysis, like the flow file.
//!
//! x86_depth / x86_fp / x86_saves / x86_smap are the fixpoint's arrays (Analysis.depthIn / fpIn /
//! savesIn / smapIn) and are not copied onto the statements. Upstream's table depths are
//! unreachable (x86_64_frame_flow.zig), so every branch needing `type(depthIn[i]) == "table"` is a
//! documented no-op here (upstream 3553–3563, and regionCarrierAccess at 3378–3387, which is
//! always false), as are the historical `allocaPlace` / `allocaOwned` marks (never set).

const std = @import("std");
const err = @import("err.zig");
const ir = @import("ir.zig");
const isa = @import("x86_64_isa.zig");
const sig = @import("sig.zig");
const u = @import("util.zig");
const XF = @import("x86_64_frame.zig");
const flow = @import("x86_64_frame_flow.zig");

const E = err.Error;
const Stmt = ir.Stmt;
const eq = std.mem.eql;
const A = XF.Analysis;
const SaveEntry = XF.SaveEntry;
const at = XF.at;
const rcIs = XF.rcIs;
const kindIs = XF.kindIs;
const nameIs = XF.nameIs;
const immVal = XF.immVal;

fn rawOf(st: *const Stmt) []const u8 {
    return st.raw orelse st.mnemonic orelse "?";
}

fn baseOf(a: *A, st: *const Stmt) E![]const u8 {
    return isa.baseMnemonic(a.alloc, try u.lower(a.alloc, st.mnemonic.?));
}

/// validateTeardown (3216): the insn indices covered from `afterIdx` to a `ret`, or null.
fn validateTeardown(a: *A, afterIdx: usize) E!?[]const usize {
    const alloc = a.alloc;
    var marks: std.ArrayList(usize) = .empty;
    var j = afterIdx;
    while (j <= a.body.len) : (j += 1) {
        const st = a.body[j - 1];
        if (st.kind == .label and a.targeted.contains(st.name.?)) return null;
        if (st.kind == .insn) {
            const m = try u.lower(alloc, st.mnemonic.?);
            const b = try isa.baseMnemonic(alloc, m);
            const ops = st.operands.items;
            if (st.localCall != null) return null;
            if (eq(u8, b, "ret")) {
                try marks.append(alloc, j);
                return marks.items;
            }
            if (eq(u8, b, "jmp") or eq(u8, b, "jcc") or eq(u8, b, "call") or std.mem.startsWith(u8, m, "loop")) return null;
            if (eq(u8, b, "leave")) {
                try marks.append(alloc, j);
            } else if (eq(u8, b, "pop") and kindIs(at(ops, 0), .reg) and isa.isCalleeSaved(ops[0].name orelse "")) {
                try marks.append(alloc, j);
            } else {
                if (eq(u8, b, "push") or eq(u8, b, "pop") or isa.isFlagStackXfer(m) or (try XF.insnWritesSp(alloc, st)) or
                    XF.insnTouchesFrame(st, a.usesRbp)) return null;
                try marks.append(alloc, j);
            }
        }
    }
    return null;
}

const DEFAULT_WHY = "transient-pad pop that restores its save (the register was redefined between its push and that pop, so the pop's reload cannot be modeled and this read would see the redefined value; read it before the pop or don't redefine it inside the pad)";

/// checkLostReload (3265): walk forward from the pop (CFG, stopping at a fresh definition of the
/// register); reject at the first use.
fn checkLostReload(a: *A, popIdx: usize, save: SaveEntry, why: ?[]const u8) E!void {
    const alloc = a.alloc;
    var work: std.ArrayList(usize) = .empty;
    var seen: std.AutoHashMapUnmanaged(usize, void) = .empty;
    for (try flow.successors(a, popIdx)) |s| try work.append(alloc, s);
    while (work.items.len > 0) {
        const i = work.pop().?;
        if (seen.contains(i)) continue;
        try seen.put(alloc, i, {});
        // (upstream would index a nil statement past the body end and fail with a Lua error)
        if (i > a.body.len) return err.plain("internal error: checkLostReload reached past the body end");
        const st = a.body[i - 1];
        if (st.kind != .insn) continue;
        const c = try flow.classOf(a, st);
        for (c.uses.items) |uo| {
            if (uo.kind == .reg and uo.rc == .gpr and uo.num == save.num) {
                return err.at(st.loc(), try u.fmt(alloc, "register {s} is read after the {s}: {s}", .{ save.name, why orelse DEFAULT_WHY, rawOf(st) }));
            }
        }
        var defined = false;
        for (c.defs.items) |dd| {
            if (dd.kind == .reg and dd.rc == .gpr and dd.num == save.num) {
                defined = true;
                break;
            }
        }
        if (!defined) for (try flow.successors(a, i)) |s| try work.append(alloc, s);
    }
}

fn lastMem(st: *const Stmt) ?*ir.Operand {
    var m: ?*ir.Operand = null;
    for (st.operands.items) |o| if (o.kind == .mem) {
        m = o;
    };
    return m;
}

fn tr(b: ?bool) bool {
    return b orelse false;
}

/// The annotation loop (3302–3749).
pub fn annotate(a: *A) E!void {
    const alloc = a.alloc;
    const body = a.body;
    // retIsGpr (3300)
    const retIsGpr = if (a.sigDesc) |d| (!d.isVoid and !(d.retTypes.len > 0 and sig.isFpClass(d.retTypes[0]))) else false;
    for (body, 1..) |st, i| {
        if (st.kind != .insn) continue;
        const mx = &st.x86;
        mx.prologue = i < a.prologueEnd;
        const dI = a.depthIn[i - 1];
        const smapI = a.smapIn[i - 1];
        const svI = a.savesIn[i - 1];
        const ops = st.operands.items;
        const bm = try baseOf(a, st);

        // 3331: the mov recovery form
        if (try flow.isSpRecoverForm(a, st, a.usesRbp)) {
            const e = flow.sget(smapI, ops[1].name);
            if (e != null and !tr(e.?.redefined) and !tr(e.?.slot)) {
                mx.spRecover = true;
            }
        }
        // 3341: the lea recovery form
        if (eq(u8, bm, "lea") and kindIs(at(ops, 0), .reg) and rcIs(at(ops, 0), .sp) and kindIs(at(ops, 1), .mem) and
            ops[1].base != null and kindIs(ops[1].base, .reg) and !nameIs(ops[1].base, "rbp") and
            ops[1].index == null and ops[1].dispSym == null)
        {
            const e = flow.sget(smapI, ops[1].base.?.name);
            if (e != null and !tr(e.?.redefined) and !tr(e.?.slot) and e.?.depth != null and
                e.?.depth.? - (ops[1].dispVal orelse 0) >= 0)
            {
                mx.spRecover = true;
            }
        }

        if (dI != null) {
            const d = dI.?;
            const dyn = XF.isDynDepth(d);
            // 3361: a recorded `movq %rsp, %reg` save carrier
            if ((try flow.isSpSaveForm(a, st)) and !dyn and
                (isa.isCalleeSaved(ops[0].name orelse "") or XF.yoloCount > 0 or st.b2clone != null or
                    (a.regions != null and a.regionOf(0, false) == null)))
            {
                mx.spSave = true;
            }
            const smapOrEmpty = smapI orelse try flow.newSmap(a);
            const se = try flow.saveStoreOf(a, st, smapOrEmpty, d);
            if (se != null) {
                mx.saveStore = true;
            }
            if (se == null and (try flow.carrierLoadOf(a, st, smapOrEmpty, d)) != null) {
                mx.carrierLoad = true;
            }
            // 3378: regionCarrierAccess needs a table depth: always false, nothing is marked.
            // 3394: a stack access through a stack+offset alias carrier
            if (se == null) {
                if (lastMem(st)) |amem| if (kindIs(amem.base, .reg)) {
                    if (flow.sget(smapI, amem.base.?.name)) |ae| {
                        if (!tr(ae.redefined) and !tr(ae.slot) and ae.roff == null and !tr(ae.conflict) and
                            (try flow.yoloArgSlotOf(a, st, amem.base.?.name.?, ae.depth.?)) == null)
                        {
                            if (try flow.aliasSlotOf(a, st, amem, ae)) |ao2| {
                                mx.aliasOff = ao2;
                                mx.aliasSaveIdx = ae.saveIdx;
                            }
                        }
                    }
                };
            }
            // 3406: the dropped movq-restore loads
            if (try flow.restoreLoadOf(a, st, smapI.?, svI)) |rs| {
                if (rs.redefined) {
                    if (retIsGpr and ops[0].num != null and ops[0].num.? == 0) {
                        return err.at(st.loc(), try u.fmt(alloc, "epilogue restore load into the integer return register cannot be modeled (the register was redefined after its save, so the restore's value and the web's value disagree): {s}", .{rawOf(st)}));
                    }
                    try checkLostReload(a, i, rs, "epilogue restore load of a save whose register was redefined after the push (the load cannot be modeled — the slot holds the pre-push value while the register's web holds the redefined one — and this read would observe the web's value)");
                }
                mx.dropRestore = true;
            }
            // 3432: the general lea-save
            if (a.regions != null and !dyn and eq(u8, bm, "lea")) {
                const mem = at(ops, 1);
                if (kindIs(at(ops, 0), .reg) and rcIs(at(ops, 0), .gpr) and (!nameIs(at(ops, 0), "rbp") or !a.usesRbp) and
                    kindIs(mem, .mem) and mem.?.base != null and rcIs(mem.?.base, .sp) and mem.?.index == null and mem.?.dispSym == null)
                {
                    const dn = d.num;
                    const k = mem.?.dispVal orelse 0;
                    const pk = if (st.localClone != null) k - 8 else k;
                    const rkey = if (st.localClone != null)
                        k + XF.D0 - dn - 8
                    else if (st.b2clone == null and !tr(mx.prologue))
                        k + XF.D0 - dn
                    else
                        k;
                    const leaAny = (dn != XF.D0 or nameIs(ops[0], "rbp")) and st.b2clone == null and st.localClone == null;
                    var leaD0 = false;
                    if (dn == XF.D0 and st.localClone == null and !nameIs(ops[0], "rbp") and k > 0 and k != dn) {
                        leaD0 = try flow.leaSaveUsesMemoryOnly(a, st, i, dn - k);
                    }
                    if ((pk == dn or pk <= 0 or leaAny or leaD0) and a.regionOf(rkey, false) == null and
                        !(XF.yoloCount > 0 and k == 0))
                    {
                        var probe = false;
                        if (a.bufProbeRanges) |ranges| {
                            if (st.b2clone) |b2| {
                                if (a.bufB2DeclRaw) |raw| if (raw.get(@bitCast(b2))) |lst| {
                                    for (lst.items) |sba| {
                                        if (k >= sba.lo.? and k < sba.hi.?) {
                                            probe = true;
                                            break;
                                        }
                                    }
                                };
                            } else {
                                const loff = k + XF.D0 - dn - (if (st.localClone != null) @as(f64, 8) else 0);
                                for (ranges.items) |r| {
                                    if (loff >= r.lo and loff < r.hi) {
                                        probe = true;
                                        break;
                                    }
                                }
                            }
                        }
                        const repReg = if (ops[0].num) |n| a.bufRepRegs.contains(@bitCast(n)) else false;
                        if (probe and !repReg and (!(try flow.leaSaveUsesMemoryOnly(a, st, i, dn - k)) or st.localClone != null)) {
                            // a buffer-interior VALUE lea: no carrier mark
                        } else {
                            mx.leaSave = true;
                        }
                    }
                }
            }
            // 3525: derived stack carriers
            if (!mx.leaSave and a.regions != null and !dyn and eq(u8, bm, "lea")) {
                const dmem = at(ops, 1);
                if (kindIs(at(ops, 0), .reg) and rcIs(at(ops, 0), .gpr) and (!nameIs(at(ops, 0), "rbp") or !a.usesRbp) and
                    kindIs(dmem, .mem) and kindIs(dmem.?.base, .reg) and rcIs(dmem.?.base, .gpr) and
                    (!nameIs(dmem.?.base, "rbp") or !a.usesRbp) and dmem.?.index == null and dmem.?.dispSym == null)
                {
                    const de = flow.sget(smapI, dmem.?.base.?.name);
                    const dk = dmem.?.dispVal orelse 0;
                    if (de != null and !tr(de.?.redefined) and !tr(de.?.slot) and de.?.roff == null and
                        !tr(de.?.conflict) and de.?.depth != null and de.?.depth.? - dk >= 0)
                    {
                        mx.leaSave = true;
                    }
                }
            }
            // 3548: the restore-base leas. The {anchored}-scope form needs a table depth
            // (unreachable); the rbp-derived form:
            if (!mx.leaSave and a.regions != null and eq(u8, bm, "lea")) {
                const mem = at(ops, 1);
                if (a.usesRbp and a.fpIn[i - 1] != null and a.fpIn[i - 1].? == .est and
                    kindIs(at(ops, 0), .reg) and rcIs(at(ops, 0), .gpr) and !nameIs(at(ops, 0), "rbp") and
                    kindIs(mem, .mem) and kindIs(mem.?.base, .reg) and nameIs(mem.?.base, "rbp") and
                    mem.?.index == null and mem.?.dispSym == null)
                {
                    const k = mem.?.dispVal orelse 0;
                    const rkey = XF.rbpNorm + k;
                    if (a.fpDepth.? - k >= 0 and a.regionOf(rkey, false) == null and (rkey < 0 or rkey >= a.frameSize)) {
                        mx.leaSave = true;
                    }
                }
            }
        }
        // 3587: returning while %rax holds the saved stack pointer
        if (eq(u8, bm, "ret") and st.localRet == null and !tr(st.tailRet) and retIsGpr and smapI != null) {
            const e = flow.sget(smapI, "rax");
            if (e != null and !tr(e.?.redefined) and !tr(e.?.slot)) {
                return err.at(st.loc(), try u.fmt(alloc, "returning while %rax holds the saved stack pointer cannot be proven safe (the return value would be the live stack address; redefine %rax or recover %rsp from it first): {s}", .{rawOf(st)}));
            }
        }
        // 3608: a pop provably restores a matching save only against the save stack
        if (eq(u8, bm, "pop") and dI != null) {
            const sv = svI.?;
            const d = dI.?;
            const o0 = at(ops, 0);
            const n: []const u8 = if (kindIs(o0, .reg)) (o0.?.name orelse "?") else "?";
            const svDyn = XF.isDynSaves(sv);
            const top: ?SaveEntry = if (!svDyn and sv.items.len > 0) sv.items[sv.items.len - 1] else null;
            if (!XF.isDynDepth(d)) {
                if (top != null and tr(top.?.spill) and top.?.depth == d.num and
                    kindIs(o0, .reg) and rcIs(o0, .gpr) and !nameIs(o0, "rsp") and (o0.?.width == null or o0.?.width.? == 64))
                {
                    mx.spillPop = true;
                } else if (svDyn or top == null or !eq(u8, top.?.name, n) or top.?.depth != d.num or tr(top.?.spill)) {
                    mx.unpairedPop = true;
                } else if (top.?.redefined) {
                    try checkLostReload(a, i, top.?, null);
                }
            } else if (mx.teardown and top != null and eq(u8, top.?.name, n) and !tr(top.?.spill)) {
                if (top.?.redefined) {
                    try checkLostReload(a, i, top.?, null);
                }
            } else {
                mx.unpairedPop = true;
            }
        }
        // 3652: popf / popfq
        if (isa.isFlagStackPop(try u.lower(alloc, st.mnemonic.?)) and dI != null) {
            const sv = svI.?;
            if (!XF.isDynDepth(dI.?) and !XF.isDynSaves(sv) and sv.items.len > 0 and tr(sv.items[sv.items.len - 1].spill) and
                sv.items[sv.items.len - 1].depth == dI.?.num)
            {
                mx.flagsPop = true;
            }
        }
        if (!tr(mx.prologue)) {
            const o0 = at(ops, 0);
            const o1 = at(ops, 1);
            const isTeardownStart = (eq(u8, bm, "add") and o0 != null and rcIs(o0, .sp) and o1 != null and kindIs(o1, .imm)) or
                (eq(u8, bm, "mov") and o0 != null and rcIs(o0, .sp) and o1 != null and nameIs(o1, "rbp") and a.usesRbp) or
                (eq(u8, bm, "lea") and o0 != null and rcIs(o0, .sp) and o1 != null and kindIs(o1, .mem) and o1.?.base != null and
                    nameIs(o1.?.base, "rbp") and a.usesRbp and o1.?.index == null and o1.?.dispSym == null) or
                (eq(u8, bm, "lea") and o0 != null and rcIs(o0, .sp) and o1 != null and kindIs(o1, .mem) and o1.?.base != null and
                    rcIs(o1.?.base, .sp) and o1.?.index == null and o1.?.dispSym == null and (o1.?.dispVal orelse 0) >= 0) or
                (eq(u8, bm, "leave") and a.usesRbp);
            if (isTeardownStart) {
                if (try validateTeardown(a, a.nextInsn[i - 1])) |marks| {
                    mx.teardownStart = true;
                    for (marks) |j| body[j - 1].x86.teardown = true;
                }
            }
            // 3699: a constant mid-function rsp adjustment
            const dNum: ?f64 = if (dI != null and dI.? == .num) dI.?.num else null;
            if ((eq(u8, bm, "sub") or eq(u8, bm, "add")) and o0 != null and rcIs(o0, .sp) and o1 != null and kindIs(o1, .imm) and
                !mx.teardownStart and dNum != null)
            {
                const imm = immVal(o1);
                const nd = if (eq(u8, bm, "sub")) dNum.? + imm else dNum.? - imm;
                if (nd >= 0 and try flow.flagsDeadAfter(a, i)) {
                    mx.midSp = true;
                }
            }
            if (eq(u8, bm, "lea") and o0 != null and rcIs(o0, .sp) and o1 != null and kindIs(o1, .mem) and o1.?.base != null and
                rcIs(o1.?.base, .sp) and o1.?.index == null and o1.?.dispSym == null and !mx.teardownStart and dNum != null and
                dNum.? - (o1.?.dispVal orelse 0) >= 0)
            {
                mx.midSp = true;
            }
            // 3722: a mid-function `and $-N, %rsp`
            if (eq(u8, bm, "and") and o0 != null and rcIs(o0, .sp) and o1 != null and kindIs(o1, .imm) and !mx.teardownStart and
                dNum != null)
            {
                const an = -immVal(o1);
                if (XF.isStackAlign(an) and try flow.flagsDeadAfter(a, i)) {
                    mx.midAnd = true;
                    XF.frameAndSeen = true;
                    if (an > XF.frameAlignReq) {
                        XF.frameAlignReq = an;
                        XF.frameAndDepth = dNum.?;
                    } else if (an == 16 and XF.frameAlignReq == 16) {
                        XF.frameAndDepth = dNum.?;
                    }
                }
            }
        }
    }
}
