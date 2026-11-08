// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//! Pointer-flow analysis over the lifted IR (a port of projects/sarcasm/sarcasm/ptrflow.luau,
//! Fil-C 0.687): which temps hold pointers and which temp carries each one's `lower`
//! (capability), propagated through copies and address arithmetic; kills, dynamic (lockstep)
//! lowers for swaps and conflicting joins, and the save / restore capability phases.
//!
//! Temp-keyed results (isPtr, lowerTemp, dynamic) are Luau tables, as upstream's; the node-keyed
//! seeds and maps are hash maps (upstream keys them by table address, an order it never relies
//! on). Where upstream iterates a node-keyed table (`pairs(seeds.capSave)`, in address order),
//! the seeds' own insertion order is used, and the order cannot change the result: each save
//! writes only capShot[its variable], and no body reaching ptrflow has two save nodes for one
//! variable. transform rejects a second `save capability (v)` before recording it ("a name may
//! only be saved once per function"), and one annotation can carry only one save clause (both
//! in transform.luau; upstream's test sarcasm-reject-dup-save-capability, which upstream's
//! sarcasm rejects at the second save).

const std = @import("std");
const err = @import("err.zig");
const ir = @import("ir.zig");
const lift = @import("lift.zig");
const lt = @import("luau_table.zig");
const u = @import("util.zig");

const Allocator = std.mem.Allocator;
const E = err.Error;
const Node = lift.Node;

pub const NodeSet = std.AutoArrayHashMapUnmanaged(*const Node, void);
pub const NodeVar = std.AutoArrayHashMapUnmanaged(*const Node, []const u8);

pub const Seeds = struct {
    argPtrTemps: ?[]const f64 = null,
    loadPtrDefs: ?*const NodeSet = null,
    callPtrDefs: ?*const NodeSet = null,
    allocaResultDefs: ?*const NodeSet = null,
    capSave: ?*const NodeVar = null,
    capRestore: ?*const NodeVar = null,
};

pub const TempInfo = struct { isLower: bool = true, forPtr: f64, dynamicLower: bool = false };

pub const Opts = struct {
    ctx: ?*anyopaque = null,
    /// default: string.lower
    baseMnemonic: ?*const fn (ctx: ?*anyopaque, alloc: Allocator, m: []const u8) E![]const u8 = null,
    widenSwaps: bool = false,
};

pub const AllocTemp = struct {
    ctx: ?*anyopaque,
    f: *const fn (ctx: ?*anyopaque, info: TempInfo) E!f64,
};

pub const Copy = struct { dst: ?f64, src: ?f64 };
pub const DynCopy = struct { xchg: bool = false, copies: []const Copy, cmov: bool = false };
pub const Shot = struct { web: ?f64, lo: ?f64 };

pub const Result = struct {
    isPtr: lt.Table(bool),
    lowerTemp: lt.Table(f64),
    /// in node order
    dynCopy: std.AutoArrayHashMapUnmanaged(*const Node, DynCopy),
    dynamic: lt.Table(bool),
    capShot: std.StringArrayHashMapUnmanaged(Shot),
};

const TSet = std.AutoHashMapUnmanaged(u64, void);
fn k(x: f64) u64 {
    return @bitCast(x);
}

fn inSet(s: ?*const NodeSet, n: *const Node) bool {
    return if (s) |x| x.contains(n) else false;
}

pub fn analyze(alloc: Allocator, lf: *const lift.Lifted, seeds: Seeds, allocTemp: AllocTemp, opts: Opts) E!Result {
    const nodes = lf.nodes;
    const tbl = struct {
        fn b(a: Allocator) E!lt.Table(bool) {
            return lt.Table(bool).init(a, 0, 0) catch error.OutOfMemory;
        }
    };
    const A = struct {
        a: Allocator,
        opts: Opts,
        allocTemp: AllocTemp,
        nodes: []*Node,
        isPtr: lt.Table(bool),
        lowerTemp: lt.Table(f64),
        dynamic: lt.Table(bool),
        widen: bool,
        killed: TSet = .empty,
        seedWeb: TSet = .empty,
        memAddrWeb: TSet = .empty,

        fn ptr(s: *@This(), t: ?f64) bool {
            const x = t orelse return false;
            return s.isPtr.get(.{ .num = x }) orelse false;
        }
        fn setPtr(s: *@This(), t: f64, v: ?bool) E!void {
            s.isPtr.set(.{ .num = t }, v) catch return error.OutOfMemory;
        }
        fn lo(s: *@This(), t: ?f64) ?f64 {
            const x = t orelse return null;
            return s.lowerTemp.get(.{ .num = x });
        }
        fn setLo(s: *@This(), t: f64, v: ?f64) E!void {
            s.lowerTemp.set(.{ .num = t }, v) catch return error.OutOfMemory;
        }
        fn dyn(s: *@This(), t: ?f64) bool {
            const x = t orelse return false;
            return s.dynamic.get(.{ .num = x }) orelse false;
        }
        fn base(s: *@This(), nd: *const Node) E![]const u8 {
            const m = if (nd.stmt) |st| st.mnemonic orelse "" else nd.mnemonic orelse "";
            if (s.opts.baseMnemonic) |f| return f(s.opts.ctx, s.a, m);
            return u.lower(s.a, m);
        }
        fn ensureLower(s: *@This(), t: f64) E!f64 {
            if (s.lo(t)) |x| return x;
            const x = try s.allocTemp.f(s.allocTemp.ctx, .{ .forPtr = t });
            try s.setLo(t, x);
            return x;
        }
        fn isXchg(s: *@This(), m: []const u8) E!bool {
            return u.matches(s.a, m, "^xchg[bwlq]?$");
        }
        fn dynamicize(s: *@This(), d: f64) E!bool {
            if (s.dyn(d) or !s.widen) return s.dyn(d);
            s.dynamic.set(.{ .num = d }, true) catch return error.OutOfMemory;
            try s.setPtr(d, true);
            try s.setLo(d, try s.allocTemp.f(s.allocTemp.ctx, .{ .forPtr = d, .dynamicLower = true }));
            for (s.nodes) |node| {
                if (node.kind != .insn) continue;
                if (try s.isXchg(try s.base(node))) {
                    const defs = node.defTemps.items;
                    const d1: ?f64 = if (defs.len > 0) defs[0] else null;
                    const d2: ?f64 = if (defs.len > 1) defs[1] else null;
                    if (d1 != null and d1.? == d and d2 != null and s.ptr(d2)) _ = try s.dynamicize(d2.?);
                    if (d2 != null and d2.? == d and d1 != null and s.ptr(d1)) _ = try s.dynamicize(d1.?);
                }
            }
            return true;
        }
        fn killWeb(s: *@This(), d_: ?f64) E!bool {
            const d = d_ orelse return false;
            if (s.dyn(d) or s.killed.contains(k(d)) or s.seedWeb.contains(k(d)) or s.memAddrWeb.contains(k(d))) return false;
            try s.killed.put(s.a, k(d), {});
            var changedNow = false;
            if (s.ptr(d)) {
                try s.setPtr(d, null);
                changedNow = true;
            }
            if (s.lo(d) != null) {
                try s.setLo(d, null);
                changedNow = true;
            }
            return changedNow;
        }
        const AddrInfo = struct { memSrc: bool, aus: ?TSet };
        fn capAddrInfo(s: *@This(), nd: *const Node, m: []const u8) E!AddrInfo {
            var r: AddrInfo = .{ .memSrc = false, .aus = null };
            const st = nd.stmt orelse return r;
            for (st.operands.items) |op| {
                if (op.kind != .mem) continue;
                r.memSrc = true;
                if (!std.mem.eql(u8, m, "lea")) {
                    for ([_]?*ir.Operand{ op.base, op.index }) |x| if (x) |reg| if (nd.opTemp.get(reg)) |t| {
                        if (r.aus == null) r.aus = .empty;
                        try r.aus.?.put(s.a, k(t), {});
                    };
                }
            }
            return r;
        }
        fn addrUse(ai: *const AddrInfo, t: f64) bool {
            return if (ai.aus) |x| x.contains(k(t)) else false;
        }
        const AluSrc = struct { ptrSrc: ?f64, intCount: usize };
        fn capAluSrc(s: *@This(), nd: *const Node, m: []const u8, us: []const f64, ai: *const AddrInfo) AluSrc {
            var r: AluSrc = .{ .ptrSrc = null, .intCount = 0 };
            for (us) |t| {
                if (addrUse(ai, t)) {} else if (s.ptr(t)) r.ptrSrc = t else r.intCount += 1;
            }
            if (std.mem.eql(u8, m, "lea") and s.widen) if (nd.stmt) |st| {
                for (st.operands.items) |op| {
                    if (op.kind == .mem and op.base != null and op.base != op.index) {
                        if (nd.opTemp.get(op.base.?)) |bt| if (s.ptr(bt)) {
                            r.ptrSrc = bt;
                        };
                    }
                }
            };
            return r;
        }
        fn isAlu(m: []const u8) bool {
            return u.in(m, &.{ "add", "sub", "orr", "lea", "and", "or" });
        }
        fn firstDef(nd: *const Node) ?f64 {
            return if (nd.defTemps.items.len > 0) nd.defTemps.items[0] else null;
        }
        fn capSaveSource(s: *@This(), sn: *const Node) E!?f64 {
            const m = try s.base(sn);
            const us = sn.useTemps.items;
            const d = firstDef(sn);
            const ai = try s.capAddrInfo(sn, m);
            var src: ?f64 = null;
            if (std.mem.eql(u8, m, "mov")) {
                if (us.len == 1 and !ai.memSrc) src = us[0];
            } else if (std.mem.eql(u8, m, "cmov")) {
                for (us) |t| if ((d == null or t != d.?) and !addrUse(&ai, t)) {
                    src = t;
                    break;
                };
            } else if (isAlu(m)) {
                const r = s.capAluSrc(sn, m, us, &ai);
                if (r.ptrSrc != null and !(std.mem.eql(u8, m, "sub") and r.intCount == 0)) src = r.ptrSrc;
            }
            if (src != null and s.ptr(src)) return src;
            return d;
        }
    };
    var s: A = .{ .a = alloc, .opts = opts, .allocTemp = allocTemp, .nodes = nodes, .isPtr = try tbl.b(alloc), .lowerTemp = lt.Table(f64).init(alloc, 0, 0) catch return error.OutOfMemory, .dynamic = try tbl.b(alloc), .widen = opts.widenSwaps };

    const seedNode = struct {
        fn f(sd: Seeds, n: *const Node) bool {
            return inSet(sd.loadPtrDefs, n) or inSet(sd.callPtrDefs, n) or inSet(sd.allocaResultDefs, n);
        }
    }.f;
    for (seeds.argPtrTemps orelse &.{}) |t| {
        try s.setPtr(t, true);
        _ = try s.ensureLower(t);
    }
    for (nodes) |node| if (node.kind == .insn and seedNode(seeds, node)) if (A.firstDef(node)) |d| {
        try s.setPtr(d, true);
        _ = try s.ensureLower(d);
    };
    for (seeds.argPtrTemps orelse &.{}) |t| try s.seedWeb.put(alloc, k(t), {});
    for (nodes) |node| if (node.kind == .insn and seedNode(seeds, node)) if (A.firstDef(node)) |d| {
        try s.seedWeb.put(alloc, k(d), {});
    };
    for (nodes) |node| {
        if (node.kind != .insn) continue;
        const m = try s.base(node);
        if (std.mem.eql(u8, m, "lea")) continue;
        const st = node.stmt orelse continue;
        for (st.operands.items) |op| if (op.kind == .mem) {
            for ([_]?*ir.Operand{ op.base, op.index }) |x| if (x) |reg| if (node.opTemp.get(reg)) |t| {
                try s.memAddrWeb.put(alloc, k(t), {});
            };
        };
    }

    var dynSrc: std.AutoHashMapUnmanaged(*const Node, std.AutoArrayHashMapUnmanaged(u64, f64)) = .empty;
    var capShot: std.StringArrayHashMapUnmanaged(Shot) = .empty;
    const KILL_SHIFT = [_][]const u8{ "shl", "shr", "sal", "sar", "rol", "ror", "rcl", "rcr", "shld", "shrd", "rclb", "rclw", "rcll", "rclq", "rcrb", "rcrw", "rcrl", "rcrq" };
    var pinned: TSet = .empty;
    for ([_]?*const NodeVar{ seeds.capSave, seeds.capRestore }) |mm| if (mm) |m| {
        for (m.keys()) |pn| if (pn.kind == .insn) if (A.firstDef(pn)) |pd| try pinned.put(alloc, k(pd), {});
    };
    var phase2 = false;

    var seenStates: std.StringHashMapUnmanaged(void) = .empty;
    var changed = true;
    while (changed) {
        changed = false;
        var reassigned: TSet = .empty;
        for (nodes) |node| {
            const seeded = inSet(seeds.loadPtrDefs, node) or inSet(seeds.allocaResultDefs, node);
            if (node.kind == .insn and !seeded) {
                const m = try s.base(node);
                const us = node.useTemps.items;
                const MF = struct {
                    s: *A,
                    node: *const Node,
                    changed: *bool,
                    reassigned: *TSet,
                    dynSrc: *std.AutoHashMapUnmanaged(*const Node, std.AutoArrayHashMapUnmanaged(u64, f64)),
                    phase2: bool,
                    seeds: Seeds,
                    pinned: *TSet,
                    fn rec(f: @This(), d: f64, src: f64) E!void {
                        const g = try f.dynSrc.getOrPut(f.s.a, f.node);
                        if (!g.found_existing) g.value_ptr.* = .empty;
                        try g.value_ptr.put(f.s.a, k(d), src);
                    }
                    fn markFrom(f: @This(), d_: ?f64, srcPtr: ?f64) E!void {
                        const ss = f.s;
                        const d = d_ orelse return;
                        if (!ss.ptr(srcPtr)) return;
                        const sp = srcPtr.?;
                        if (ss.killed.contains(k(d))) return;
                        if (ss.dyn(sp) and !ss.dyn(d)) {
                            _ = try ss.dynamicize(d);
                            f.changed.* = true;
                        }
                        if (ss.dyn(d)) {
                            try f.rec(d, sp);
                            return;
                        }
                        if (f.phase2 and f.pinned.contains(k(d)) and !(if (f.seeds.capSave) |cs| cs.contains(f.node) else false)) return;
                        if (!ss.ptr(d)) {
                            try ss.setPtr(d, true);
                            f.changed.* = true;
                        }
                        const lo = ss.lo(sp);
                        if (lo != null and (ss.lo(d) == null or ss.lo(d).? != lo.?)) {
                            if (ss.lo(d) != null and ss.widen) {
                                if (try ss.dynamicize(d)) try f.rec(d, sp);
                            } else if (ss.lo(d) != null) {
                                try f.reassigned.put(ss.a, k(d), {});
                                try ss.setLo(d, lo);
                            } else try ss.setLo(d, lo);
                            f.changed.* = true;
                        }
                    }
                };
                const mf: MF = .{ .s = &s, .node = node, .changed = &changed, .reassigned = &reassigned, .dynSrc = &dynSrc, .phase2 = phase2, .seeds = seeds, .pinned = &pinned };
                const ai = try s.capAddrInfo(node, m);
                if (try s.isXchg(m)) {
                    const defs = node.defTemps.items;
                    if (defs.len == 2 and us.len == 2) {
                        const loopCarried = (defs[0] == us[0] or defs[0] == us[1]) and (defs[1] == us[0] or defs[1] == us[1]);
                        const l0 = s.lo(us[0]);
                        const l1 = s.lo(us[1]);
                        const loDiffer = !((l0 == null and l1 == null) or (l0 != null and l1 != null and l0.? == l1.?));
                        if (s.widen and loopCarried and s.ptr(us[0]) and s.ptr(us[1]) and loDiffer and !(s.dyn(defs[0]) and s.dyn(defs[1]))) {
                            _ = try s.dynamicize(defs[0]);
                            _ = try s.dynamicize(defs[1]);
                            changed = true;
                        }
                        try mf.markFrom(defs[0], us[1]);
                        try mf.markFrom(defs[1], us[0]);
                    }
                } else if (A.firstDef(node)) |d| {
                    if (std.mem.eql(u8, m, "mov") and us.len == 1 and !ai.memSrc) {
                        try mf.markFrom(d, us[0]);
                    } else if (std.mem.eql(u8, m, "cmov")) {
                        var src: ?f64 = null;
                        for (us) |t| if (t != d and !A.addrUse(&ai, t)) {
                            src = t;
                            break;
                        };
                        if (src != null and s.ptr(src)) {
                            const sv = src.?;
                            const ld = s.lo(d);
                            const ls = s.lo(sv);
                            const sameLo = (ld == null and ls == null) or (ld != null and ls != null and ld.? == ls.?);
                            if (s.dyn(d)) {
                                try mf.rec(d, sv);
                            } else if (s.ptr(d) and !sameLo) {
                                if (try s.dynamicize(d)) {
                                    try mf.rec(d, sv);
                                    changed = true;
                                } else try mf.markFrom(d, sv);
                            } else if (!s.ptr(d)) try mf.markFrom(d, sv);
                        }
                    } else if (A.isAlu(m)) {
                        const ov = node.useCapTemp orelse node.newCapTemp;
                        if (ov) |o| {
                            try mf.markFrom(d, o);
                        } else if (std.mem.eql(u8, m, "sub")) {
                            const r = s.capAluSrc(node, m, us, &ai);
                            if (r.ptrSrc != null and r.intCount == 0) {
                                var nptr: usize = 0;
                                for (us) |t| if (!A.addrUse(&ai, t) and s.ptr(t)) {
                                    nptr += 1;
                                };
                                if (nptr >= 2) if (try s.killWeb(d)) {
                                    changed = true;
                                };
                            } else if (r.ptrSrc) |p| try mf.markFrom(d, p);
                        } else {
                            const r = s.capAluSrc(node, m, us, &ai);
                            if (r.ptrSrc) |p| try mf.markFrom(d, p);
                        }
                    } else if (u.in(m, &KILL_SHIFT)) {
                        if (try s.killWeb(d)) changed = true;
                    }
                }
            }
            if (phase2 and node.kind == .insn) {
                if (seeds.capRestore) |cr| if (cr.get(node)) |rv| {
                    const rd = A.firstDef(node);
                    const shot = capShot.get(rv);
                    const slo: ?f64 = if (shot) |x| x.lo else null;
                    const sweb: ?f64 = if (shot) |x| x.web else null;
                    if (rd != null and slo != null and sweb != null and !s.dyn(sweb) and !s.dyn(rd)) {
                        if (!s.ptr(rd)) {
                            try s.setPtr(rd.?, true);
                            changed = true;
                        }
                        if (s.lo(rd) == null or s.lo(rd).? != slo.?) {
                            try s.setLo(rd.?, slo);
                            changed = true;
                        }
                    }
                };
            }
        }
        if (changed) {
            var parts: std.ArrayList([]const u8) = .empty;
            var it = s.lowerTemp.iterator();
            while (it.next()) |e| try parts.append(alloc, try u.fmt(alloc, "{s}={s}", .{ try u.num(alloc, e.key.num), try u.num(alloc, e.val) }));
            var ip = s.isPtr.iterator();
            while (ip.next()) |e| if (e.val) try parts.append(alloc, try u.fmt(alloc, "{s}=ptr", .{try u.num(alloc, e.key.num)}));
            var id = s.dynamic.iterator();
            while (id.next()) |e| if (e.val) try parts.append(alloc, try u.fmt(alloc, "{s}=dyn", .{try u.num(alloc, e.key.num)}));
            var ik = s.killed.keyIterator();
            while (ik.next()) |x| try parts.append(alloc, try u.fmt(alloc, "{s}=killed", .{try u.num(alloc, @bitCast(x.*))}));
            std.mem.sort([]const u8, parts.items, {}, struct {
                fn lt_(_: void, a: []const u8, b: []const u8) bool {
                    return std.mem.lessThan(u8, a, b);
                }
            }.lt_);
            const key = try std.mem.join(alloc, ";", parts.items);
            if (seenStates.contains(key)) {
                var widened: std.ArrayList(f64) = .empty;
                var rk = reassigned.keyIterator();
                while (rk.next()) |x| try widened.append(alloc, @bitCast(x.*));
                std.mem.sort(f64, widened.items, {}, std.sort.asc(f64));
                var any = false;
                for (widened.items) |d| if (try s.dynamicize(d)) {
                    any = true;
                };
                if (!any) {
                    const msg = "pointer-flow analysis does not converge: a register web has conflicting pointer sources (one temp cannot carry two capabilities)";
                    if (lf.flow.len > 0) return err.at(lf.flow[0].stmt.loc(), msg);
                    return err.plain(msg);
                }
                seenStates = .empty;
            } else try seenStates.put(alloc, key, {});
        } else {
            if (!phase2) if (seeds.capSave) |cs| if (cs.count() > 0) {
                for (cs.keys(), cs.values()) |sn, v| {
                    if (sn.kind != .insn) continue;
                    const sw = try s.capSaveSource(sn);
                    try capShot.put(alloc, v, .{ .web = sw, .lo = if (sw) |w| s.lo(w) else null });
                }
                if (seeds.capRestore) |cr| if (cr.count() > 0) {
                    phase2 = true;
                    seenStates = .empty;
                    changed = true;
                };
            };
        }
    }

    var dynCopy: std.AutoArrayHashMapUnmanaged(*const Node, DynCopy) = .empty;
    for (nodes) |node| {
        const dm = dynSrc.getPtr(node) orelse continue;
        const m = try s.base(node);
        const defs = node.defTemps.items;
        if (try s.isXchg(m)) {
            var cc: [2]?Copy = .{ null, null };
            for (0..2) |j| {
                if (j < defs.len) if (dm.get(k(defs[j]))) |srcW| {
                    cc[j] = .{ .dst = s.lo(defs[j]), .src = s.lo(srcW) };
                };
                if (cc[j]) |c| {
                    const same = (c.dst == null and c.src == null) or (c.dst != null and c.src != null and c.dst.? == c.src.?);
                    if (same) cc[j] = null;
                }
            }
            for (&cc) |*c| if (c.* != null and c.*.?.src == null) {
                c.* = null;
            };
            var copies: std.ArrayList(Copy) = .empty;
            for (cc) |c| if (c) |x| try copies.append(alloc, x);
            if (copies.items.len > 0) try dynCopy.put(alloc, node, .{ .xchg = true, .copies = copies.items });
        } else {
            var copies: std.ArrayList(Copy) = .empty;
            for (defs) |d| {
                const srcPtr = dm.get(k(d));
                const dstLo = s.lo(d);
                const srcLo = s.lo(srcPtr);
                if (dstLo != null and srcLo != null and dstLo.? != srcLo.?) try copies.append(alloc, .{ .dst = dstLo, .src = srcLo });
            }
            if (copies.items.len > 0) try dynCopy.put(alloc, node, .{ .copies = copies.items, .cmov = std.mem.eql(u8, m, "cmov") });
        }
    }

    return .{ .isPtr = s.isPtr, .lowerTemp = s.lowerTemp, .dynCopy = dynCopy, .dynamic = s.dynamic, .capShot = capShot };
}
