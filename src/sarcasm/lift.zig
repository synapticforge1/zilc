// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//! Lift a function body into register webs (a port of projects/sarcasm/sarcasm/lift.luau,
//! Fil-C 0.687): reaching definitions over the instruction CFG, def sites unioned at common uses
//! (and at read-modify-write registers), one temp per web.
//!
//! Order matters where upstream's output depends on it: the entry temps are numbered in the
//! iteration order of `entrySites`, a table keyed by register number built in the iteration
//! order of `usedRegs`; both are Luau tables here (luau_table). The reaching-definition sets
//! only decide which union-find root represents a web, never the webs or their numbering, so
//! they are bit sets. upstream's default classify is arm64's (not ported: zilc is x86_64 only),
//! so `classify` is required.

const std = @import("std");
const err = @import("err.zig");
const ir = @import("ir.zig");
const lt = @import("luau_table.zig");
const prof = @import("prof.zig");
const u = @import("util.zig");

const Allocator = std.mem.Allocator;
const E = err.Error;

pub const CallInfo = struct { argRegs: ?[]const f64 = null, resultReg: ?f64 = null };

pub const Opts = struct {
    ctx: ?*anyopaque = null,
    classify: *const fn (ctx: ?*anyopaque, alloc: Allocator, st: *const ir.Stmt) E!ir.Class,
    /// the registers `ret` reads
    returnRegs: ?[]const f64 = null,
    callInfo: ?*const fn (ctx: ?*anyopaque, alloc: Allocator, st: *const ir.Stmt) E!?CallInfo = null,
};

pub const NodeKind = enum { insn, label, other };
pub const Node = struct {
    kind: NodeKind,
    name: ?[]const u8 = null,
    stmt: ?*ir.Stmt = null,
    c: ?*ir.Class = null,
    fi: usize = 0,
    defTemps: std.ArrayList(f64) = .empty,
    useTemps: std.ArrayList(f64) = .empty,
    /// operand occurrence (by identity) -> temp
    opTemp: std.AutoHashMapUnmanaged(*const ir.Operand, f64) = .empty,
    // set by the transform: a node it synthesizes names its mnemonic directly, and
    // `#! use capability` stashes the resolved source temp
    mnemonic: ?[]const u8 = null,
    useCapTemp: ?f64 = null,
    newCapTemp: ?f64 = null,
};
pub const Flow = struct { stmt: *ir.Stmt, c: *ir.Class, fi: usize };
pub const Temp = struct { reg: f64 };

pub const Lifted = struct {
    nodes: []*Node,
    /// 1-based in upstream; flow[k - 1] here
    flow: []Flow,
    /// temps[t - 1] for temp t
    temps: []Temp,
    /// reg -> the live-in temp
    entryTemp: std.AutoHashMapUnmanaged(u64, f64),
    /// succ[fi - 1]: flow indices (1-based)
    succ: [][]usize,
    labelToFlow: std.StringHashMapUnmanaged(usize),
    nextTemp: f64,

    pub fn entryTempOf(l: *const Lifted, reg: f64) ?f64 {
        return l.entryTemp.get(@bitCast(reg));
    }
};

const SiteKey = struct { fi: usize, reg: u64 };
const Site = struct { fi: usize, reg: f64 };

fn regOp(alloc: Allocator, rn: f64, comptime flag: []const u8) E!*ir.Operand {
    var o: ir.Operand = .{ .kind = .reg, .rc = .gpr, .num = rn, .width = 64, .name = try u.fmt(alloc, "x{s}", .{try u.num(alloc, rn)}) };
    @field(o, flag) = true;
    return u.newOp(alloc, o);
}

pub fn liftFunction(alloc: Allocator, body: []const *ir.Stmt, opts: Opts) E!Lifted {
    var nodes: std.ArrayList(*Node) = .empty;
    var flow: std.ArrayList(Flow) = .empty;
    var labelToFlow: std.StringHashMapUnmanaged(usize) = .empty;
    var pending: std.ArrayList([]const u8) = .empty;
    for (body) |st| {
        if (st.kind == .label) {
            try pending.append(alloc, st.name.?);
            const nd = try alloc.create(Node);
            nd.* = .{ .kind = .label, .name = st.name };
            try nodes.append(alloc, nd);
        } else if (st.kind == .insn) {
            const c = try alloc.create(ir.Class);
            c.* = try opts.classify(opts.ctx, alloc, st);
            if (c.control == .@"return") if (opts.returnRegs) |rr| {
                for (rr) |rn| try c.uses.append(alloc, try regOp(alloc, rn, "retReg"));
            };
            if ((c.control == .call or c.control == .indcall) and opts.callInfo != null) {
                if (try opts.callInfo.?(opts.ctx, alloc, st)) |ci| {
                    for (ci.argRegs orelse &.{}) |rn| try c.uses.append(alloc, try regOp(alloc, rn, "argReg"));
                    if (ci.resultReg) |rr| try c.defs.append(alloc, try regOp(alloc, rr, "resultReg"));
                }
            }
            const fi = flow.items.len + 1;
            try flow.append(alloc, .{ .stmt = st, .c = c, .fi = fi });
            for (pending.items) |l| try labelToFlow.put(alloc, l, fi);
            pending.clearRetainingCapacity();
            const nd = try alloc.create(Node);
            nd.* = .{ .kind = .insn, .stmt = st, .c = c, .fi = fi };
            try nodes.append(alloc, nd);
        } else {
            const nd = try alloc.create(Node);
            nd.* = .{ .kind = .other, .stmt = st };
            try nodes.append(alloc, nd);
        }
    }
    const n = flow.items.len;
    const F = flow.items;

    // CFG successors over flow indices; 0 is the virtual entry.
    const succ = try alloc.alloc([]usize, n);
    for (0..n) |k| {
        const i = k + 1;
        const c = F[k].c;
        var s: std.ArrayList(usize) = .empty;
        if (c.targets) |ts| for (ts) |t| if (labelToFlow.get(t)) |ti| try s.append(alloc, ti);
        if (c.fallsThrough and i + 1 <= n) try s.append(alloc, i + 1);
        succ[k] = s.items;
    }
    // predecessors (pred[0..n]); upstream inserts the entry edge into pred[1] twice
    const pred = try alloc.alloc(std.ArrayList(usize), n + 1);
    for (pred) |*p| p.* = .empty;
    if (n >= 1) {
        try pred[1].append(alloc, 0);
        try pred[1].append(alloc, 0);
    }
    for (0..n) |k| for (succ[k]) |s| try pred[s].append(alloc, k + 1);

    // def sites
    var sites: std.ArrayList(Site) = .empty;
    var siteId: std.AutoHashMapUnmanaged(SiteKey, usize) = .empty;
    const S = struct {
        fn add(a: Allocator, ss: *std.ArrayList(Site), ids: *std.AutoHashMapUnmanaged(SiteKey, usize), fi: usize, reg: f64) E!usize {
            const k: SiteKey = .{ .fi = fi, .reg = @bitCast(reg) };
            if (ids.get(k)) |id| return id;
            try ss.append(a, .{ .fi = fi, .reg = reg });
            const id = ss.items.len;
            try ids.put(a, k, id);
            return id;
        }
    };
    var usedRegs = lt.Table(bool).init(alloc, 0, 0) catch return error.OutOfMemory;
    for (0..n) |k| {
        const st = F[k].stmt;
        for (F[k].c.uses.items) |r| {
            if (r.num == null) return err.at(st.loc(), try u.fmt(alloc, "internal error: unnumbered register use (rc={s}) in '{s}'", .{ if (r.rc) |x| @tagName(x) else "nil", st.raw orelse "?" }));
            usedRegs.set(.{ .num = r.num.? }, true) catch return error.OutOfMemory;
        }
        for (F[k].c.defs.items) |r| {
            if (r.num == null) return err.at(st.loc(), try u.fmt(alloc, "internal error: unnumbered register def (rc={s}) in '{s}'", .{ if (r.rc) |x| @tagName(x) else "nil", st.raw orelse "?" }));
            usedRegs.set(.{ .num = r.num.? }, true) catch return error.OutOfMemory;
        }
    }
    var entrySites = lt.Table(f64).init(alloc, 0, 0) catch return error.OutOfMemory;
    {
        var it = usedRegs.iterator();
        while (it.next()) |e| {
            const id = try S.add(alloc, &sites, &siteId, 0, e.key.num);
            entrySites.set(e.key, @floatFromInt(id)) catch return error.OutOfMemory;
        }
    }
    for (0..n) |k| for (F[k].c.defs.items) |r| {
        _ = try S.add(alloc, &sites, &siteId, k + 1, r.num.?);
    };
    const nsites = sites.items.len;

    // GEN and the registers defined, per flow index
    const Bits = std.DynamicBitSetUnmanaged;
    const gen = try alloc.alloc(Bits, n + 1);
    const defRegs = try alloc.alloc(std.AutoHashMapUnmanaged(u64, void), n + 1);
    for (gen, defRegs) |*g, *d| {
        g.* = try Bits.initEmpty(alloc, nsites + 1);
        d.* = .empty;
    }
    {
        var it = entrySites.iterator();
        while (it.next()) |e| {
            gen[0].set(@intFromFloat(e.val));
            try defRegs[0].put(alloc, @bitCast(e.key.num), {});
        }
    }
    for (0..n) |k| for (F[k].c.defs.items) |r| {
        gen[k + 1].set(try S.add(alloc, &sites, &siteId, k + 1, r.num.?));
        try defRegs[k + 1].put(alloc, @bitCast(r.num.?), {});
    };

    // reaching definitions
    const IN = try alloc.alloc(Bits, n + 1);
    const OUT = try alloc.alloc(Bits, n + 1);
    for (IN, OUT) |*a, *b| {
        a.* = try Bits.initEmpty(alloc, nsites + 1);
        b.* = try Bits.initEmpty(alloc, nsites + 1);
    }
    OUT[0].setUnion(gen[0]);
    var newIn = try Bits.initEmpty(alloc, nsites + 1);
    var newOut = try Bits.initEmpty(alloc, nsites + 1);
    var changed = true;
    var rounds: usize = 0;
    while (changed) {
        changed = false;
        for (1..n + 1) |i| {
            newIn.unsetAll();
            for (pred[i].items) |p| newIn.setUnion(OUT[p]);
            newOut.unsetAll();
            newOut.setUnion(gen[i]);
            var it = newIn.iterator(.{});
            while (it.next()) |id| {
                if (!defRegs[i].contains(@bitCast(sites.items[id - 1].reg))) newOut.set(id);
            }
            if (!newIn.eql(IN[i]) or !newOut.eql(OUT[i])) {
                changed = true;
                IN[i].unsetAll();
                IN[i].setUnion(newIn);
                OUT[i].unsetAll();
                OUT[i].setUnion(newOut);
            }
        }
        rounds += 1;
    }
    prof.mark("    [lift {d} flow] reaching-defs rounds={d} sites={d}", .{ n, rounds, sites.items.len });

    // webs: union-find over site ids (parent[x] null = x itself)
    var parent: std.AutoHashMapUnmanaged(usize, usize) = .empty;
    const UF = struct {
        p: *std.AutoHashMapUnmanaged(usize, usize),
        a: Allocator,
        fn find(f: @This(), x_in: usize) E!usize {
            var x = x_in;
            while (f.p.get(x)) |px| {
                if (px == x) break;
                const gp = f.p.get(px) orelse px;
                try f.p.put(f.a, x, gp);
                x = gp;
            }
            return x;
        }
        fn @"union"(f: @This(), a: usize, b: usize) E!usize {
            const ra = try f.find(a);
            const rb = try f.find(b);
            if (ra != rb) try f.p.put(f.a, rb, ra);
            return f.find(a);
        }
    };
    const uf: UF = .{ .p = &parent, .a = alloc };
    for (1..nsites + 1) |id| try parent.put(alloc, id, id);

    var useWeb: std.AutoHashMapUnmanaged(SiteKey, usize) = .empty;
    for (0..n) |k| {
        const i = k + 1;
        for (F[k].c.uses.items) |r| {
            var root: ?usize = null;
            var it = IN[i].iterator(.{});
            while (it.next()) |id| {
                if (sites.items[id - 1].reg == r.num.?) root = if (root) |x| try uf.@"union"(x, id) else id;
            }
            if (root) |x| try useWeb.put(alloc, .{ .fi = i, .reg = @bitCast(r.num.?) }, try uf.find(x));
        }
    }
    for (0..n) |k| {
        const i = k + 1;
        for (F[k].c.rmw.items) |rn| {
            const uw = useWeb.get(.{ .fi = i, .reg = @bitCast(rn) });
            const dw = try uf.find(try S.add(alloc, &sites, &siteId, i, rn));
            if (uw) |w| _ = try uf.@"union"(w, dw);
        }
    }

    // temps per web root, numbered in first-use order
    var temps: std.ArrayList(Temp) = .empty;
    var rootToTemp: std.AutoHashMapUnmanaged(usize, f64) = .empty;
    const TF = struct {
        fn get(a: Allocator, r2t: *std.AutoHashMapUnmanaged(usize, f64), ts: *std.ArrayList(Temp), ss: []const Site, root: usize) E!f64 {
            if (r2t.get(root)) |t| return t;
            try ts.append(a, .{ .reg = ss[root - 1].reg });
            const t: f64 = @floatFromInt(ts.items.len);
            try r2t.put(a, root, t);
            return t;
        }
    };
    var entryTemp: std.AutoHashMapUnmanaged(u64, f64) = .empty;
    {
        var it = entrySites.iterator();
        while (it.next()) |e| {
            const t = try TF.get(alloc, &rootToTemp, &temps, sites.items, try uf.find(@intFromFloat(e.val)));
            try entryTemp.put(alloc, @bitCast(e.key.num), t);
        }
    }

    for (nodes.items) |node| {
        if (node.kind != .insn) continue;
        const i = node.fi;
        const c = node.c.?;
        for (c.defs.items) |r| {
            const t = try TF.get(alloc, &rootToTemp, &temps, sites.items, try uf.find(try S.add(alloc, &sites, &siteId, i, r.num.?)));
            try node.defTemps.append(alloc, t);
            try node.opTemp.put(alloc, r, t);
        }
        for (c.uses.items) |r| {
            const uw = useWeb.get(.{ .fi = i, .reg = @bitCast(r.num.?) });
            const t: ?f64 = if (uw) |w| try TF.get(alloc, &rootToTemp, &temps, sites.items, try uf.find(w)) else entryTemp.get(@bitCast(r.num.?));
            if (t) |x| {
                try node.useTemps.append(alloc, x);
                try node.opTemp.put(alloc, r, x);
            }
        }
    }

    return .{
        .nodes = nodes.items,
        .flow = flow.items,
        .temps = temps.items,
        .entryTemp = entryTemp,
        .succ = succ,
        .labelToFlow = labelToFlow,
        .nextTemp = @floatFromInt(temps.items.len),
    };
}
