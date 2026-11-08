// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//! Iterated Register Coalescing, Appel & George (a port of projects/sarcasm/sarcasm/regalloc.luau,
//! Fil-C 0.687): liveness over a CFG built from labels and branches, the interference graph,
//! coloring with coalescing, freezing and optimistic spilling, and the soundness backstop.
//!
//! The coloring depends on the ITERATION ORDER of upstream's integer-keyed tables (the first
//! worklist move, the adjacency sets, the live sets, the caller's temps), so every table upstream
//! iterates is a Luau table here (luau_table, `Set`); tables upstream only indexes are hash maps.
//! Temp ids are numbers (f64) as in Luau; instruction and block indices are 1-based as upstream's.

const std = @import("std");
const err = @import("err.zig");
const lt = @import("luau_table.zig");
const prof = @import("prof.zig");
const u = @import("util.zig");

const Allocator = std.mem.Allocator;
const E = err.Error;

pub const Move = struct { dst: f64, src: f64, wide: ?bool = null };
pub const Insn = struct {
    defs: []const f64 = &.{},
    uses: []const f64 = &.{},
    move: ?Move = null,
    isLabelDef: ?[]const u8 = null,
    targets: ?[]const []const u8 = null,
    fallsThrough: ?bool = null,
};
pub const Temp = struct { precolor: ?[]const u8 = null, spillCost: ?f64 = null };

/// A Luau table used as a set (`t[x] = true` / `t[x] = nil`).
pub const Set = lt.Table(bool);
fn newSet(a: Allocator) E!Set {
    return Set.init(a, 0, 0) catch error.OutOfMemory;
}
fn has(s: *Set, x: f64) bool {
    return (s.get(.{ .num = x }) orelse false);
}
fn add(s: *Set, x: f64) E!void {
    s.set(.{ .num = x }, true) catch return error.OutOfMemory;
}
fn del(s: *Set, x: f64) E!void {
    s.set(.{ .num = x }, null) catch return error.OutOfMemory;
}
/// `next(s) ~= nil`
fn nonEmpty(s: *Set) bool {
    var it = s.iterator();
    return it.next() != null;
}
/// The keys of `s` in iteration order (snapshot: upstream's loops over these do not mutate them).
fn keys(a: Allocator, s: *Set) E![]f64 {
    var o: std.ArrayList(f64) = .empty;
    var it = s.iterator();
    while (it.next()) |e| try o.append(a, e.key.num);
    return o.items;
}

fn FMap(comptime V: type) type {
    return struct {
        m: std.AutoHashMapUnmanaged(u64, V) = .empty,
        fn get(s: *const @This(), k: f64) ?V {
            return s.m.get(@bitCast(k));
        }
        fn ptr(s: *@This(), k: f64) ?*V {
            return s.m.getPtr(@bitCast(k));
        }
        fn put(s: *@This(), a: Allocator, k: f64, v: V) E!void {
            try s.m.put(a, @bitCast(k), v);
        }
        fn remove(s: *@This(), k: f64) void {
            _ = s.m.remove(@bitCast(k));
        }
        fn has(s: *const @This(), k: f64) bool {
            return s.m.contains(@bitCast(k));
        }
    };
}

pub const Block = struct {
    first: usize,
    last: usize,
    insns: std.ArrayList(usize) = .empty,
    succ: std.ArrayList(usize) = .empty,
    useSet: Set = undefined,
    defSet: Set = undefined,
    liveIn: Set = undefined,
    liveOut: Set = undefined,
};

pub const CFG = struct {
    blocks: []*Block,
    labelToBlock: std.StringHashMapUnmanaged(usize),
    /// blockOfInsn[i - 1]
    blockOfInsn: []usize,
};

/// buildCFG: leaders are the first insn, every label definition and every insn after a branch.
pub fn buildCFG(alloc: Allocator, insns: []const Insn) E!CFG {
    const n = insns.len;
    var labelAt: std.StringHashMapUnmanaged(usize) = .empty;
    for (insns, 1..) |ins, i| if (ins.isLabelDef) |l| try labelAt.put(alloc, l, i);
    const isLeader = try alloc.alloc(bool, n + 2);
    @memset(isLeader, false);
    isLeader[1] = true;
    for (insns, 1..) |ins, i| {
        if (ins.isLabelDef != null) isLeader[i] = true;
        if (ins.targets != null or (ins.fallsThrough != null and !ins.fallsThrough.?)) {
            if (i + 1 <= n) isLeader[i + 1] = true;
        }
    }
    var blocks: std.ArrayList(*Block) = .empty;
    const blockOfInsn = try alloc.alloc(usize, n);
    var cur: ?*Block = null;
    for (1..n + 1) |i| {
        if (isLeader[i] or i == 1) {
            const b = try alloc.create(Block);
            b.* = .{ .first = i, .last = i };
            try blocks.append(alloc, b);
            cur = b;
        }
        cur.?.last = i;
        try cur.?.insns.append(alloc, i);
        blockOfInsn[i - 1] = blocks.items.len;
    }
    var labelToBlock: std.StringHashMapUnmanaged(usize) = .empty;
    var it = labelAt.iterator();
    while (it.next()) |e| try labelToBlock.put(alloc, e.key_ptr.*, blockOfInsn[e.value_ptr.* - 1]);
    for (blocks.items, 1..) |b, bi| {
        b.succ = .empty;
        const lastIns = insns[b.last - 1];
        var addFall = true;
        if (lastIns.targets) |ts| {
            for (ts) |t| if (labelToBlock.get(t)) |tb| try b.succ.append(alloc, tb);
            addFall = lastIns.fallsThrough == null or lastIns.fallsThrough.?;
        }
        if (lastIns.fallsThrough != null and !lastIns.fallsThrough.?) addFall = false;
        if (addFall and bi + 1 <= blocks.items.len) try b.succ.append(alloc, bi + 1);
    }
    return .{ .blocks = blocks.items, .labelToBlock = labelToBlock, .blockOfInsn = blockOfInsn };
}

fn differ(a: *Set, c: *Set) bool {
    var it = a.iterator();
    while (it.next()) |e| if (!has(c, e.key.num)) return true;
    var jt = c.iterator();
    while (jt.next()) |e| if (!has(a, e.key.num)) return true;
    return false;
}

/// computeLiveness: the live-out set of every instruction (liveOutOf[i - 1]).
pub fn computeLiveness(alloc: Allocator, insns: []const Insn, blocks: []*Block) E![]Set {
    for (blocks) |b| {
        var use = try newSet(alloc);
        var def = try newSet(alloc);
        for (b.insns.items) |i| {
            const ins = insns[i - 1];
            for (ins.uses) |x| if (!has(&def, x)) try add(&use, x);
            for (ins.defs) |d| try add(&def, d);
        }
        b.useSet = use;
        b.defSet = def;
        b.liveIn = try newSet(alloc);
        b.liveOut = try newSet(alloc);
    }
    var changed = true;
    while (changed) {
        changed = false;
        var bi = blocks.len;
        while (bi >= 1) : (bi -= 1) {
            const b = blocks[bi - 1];
            var newOut = try newSet(alloc);
            for (b.succ.items) |s| {
                var it = blocks[s - 1].liveIn.iterator();
                while (it.next()) |e| try add(&newOut, e.key.num);
            }
            var newIn = try newSet(alloc);
            var ut = b.useSet.iterator();
            while (ut.next()) |e| try add(&newIn, e.key.num);
            var ot = newOut.iterator();
            while (ot.next()) |e| if (!has(&b.defSet, e.key.num)) try add(&newIn, e.key.num);
            if (differ(&newIn, &b.liveIn) or differ(&newOut, &b.liveOut)) {
                changed = true;
                b.liveIn = newIn;
                b.liveOut = newOut;
            }
        }
    }
    const liveOutOf = try alloc.alloc(Set, insns.len);
    for (liveOutOf) |*s| s.* = try newSet(alloc);
    for (blocks) |b| {
        var live = try newSet(alloc);
        var lt0 = b.liveOut.iterator();
        while (lt0.next()) |e| try add(&live, e.key.num);
        var idx = b.insns.items.len;
        while (idx >= 1) : (idx -= 1) {
            const i = b.insns.items[idx - 1];
            const ins = insns[i - 1];
            var lo = try newSet(alloc);
            var it = live.iterator();
            while (it.next()) |e| try add(&lo, e.key.num);
            liveOutOf[i - 1] = lo;
            for (ins.defs) |d| try del(&live, d);
            for (ins.uses) |x| try add(&live, x);
        }
    }
    return liveOutOf;
}

/// regalloc.liveOut: per-instruction live-out sets of a generic instruction list.
pub fn liveOut(alloc: Allocator, insns: []const Insn) E![]Set {
    const cfg = try buildCFG(alloc, insns);
    return computeLiveness(alloc, insns, cfg.blocks);
}

pub const Opts = struct {
    allocatable: []const []const u8,
    reserved: ?[]const []const u8 = null,
};

pub const Result = struct {
    color: lt.Table([]const u8),
    spilled: []f64,
    blocks: []*Block,
    coalesced: *Set,
    alias: *FMap(f64),

    /// aliasOf (getAlias).
    pub fn aliasOf(r: *const Result, t_in: f64) f64 {
        var t = t_in;
        while (has(r.coalesced, t)) t = r.alias.get(t).?;
        return t;
    }
};

fn inArray(arr: []const f64, x: f64) ?usize {
    for (arr, 0..) |v, i| if (v == x) return i;
    return null;
}
fn removeFrom(arr: *std.ArrayList(f64), x: f64) void {
    if (inArray(arr.items, x)) |i| _ = arr.orderedRemove(i);
}

/// regalloc.color: the IRC coloring of `insns` over `temps` (tempId -> descriptor).
pub fn color(alloc: Allocator, insns: []const Insn, temps: *lt.Table(Temp), opts: Opts) E!Result {
    var reservedSet: std.StringHashMapUnmanaged(void) = .empty;
    for (opts.reserved orelse &.{}) |r| try reservedSet.put(alloc, r, {});
    var pool: std.ArrayList([]const u8) = .empty;
    for (opts.allocatable) |r| if (!reservedSet.contains(r)) try pool.append(alloc, r);
    const K: f64 = @floatFromInt(pool.items.len);
    const cfg = try buildCFG(alloc, insns);
    const blocks = cfg.blocks;
    prof.mark("    [ra {d} insns] buildCFG", .{insns.len});
    const liveOutOf = try computeLiveness(alloc, insns, blocks);
    prof.mark("    [ra] computeLiveness", .{});

    const G = struct {
        a: Allocator,
        temps: *lt.Table(Temp),
        K: f64,
        insns: []const Insn,
        adj: FMap(std.AutoHashMapUnmanaged(u64, void)) = .{},
        adjList: FMap(std.ArrayList(f64)) = .{},
        degree: FMap(f64) = .{},
        moveList: FMap(Set) = .{},
        worklistMoves: Set,
        alias: FMap(f64) = .{},
        nodes: Set,
        onStack: FMap(void) = .{},
        coalescedNodes: Set,
        activeMoves: FMap(void) = .{},
        frozenMoves: FMap(void) = .{},
        constrainedMoves: FMap(void) = .{},
        coalescedMoves: FMap(void) = .{},
        simplifyWorklist: std.ArrayList(f64) = .empty,
        freezeWorklist: std.ArrayList(f64) = .empty,
        spillWorklist: std.ArrayList(f64) = .empty,
        selectStack: std.ArrayList(f64) = .empty,
        spillDen: FMap(f64) = .{},
        reservedSet: *std.StringHashMapUnmanaged(void),
        nSimplify: usize = 0,
        nCoalesce: usize = 0,
        nFreeze: usize = 0,
        nSpill: usize = 0,
        nScan: usize = 0,
        nDec: usize = 0,

        fn temp(g: *@This(), t: f64) ?Temp {
            return g.temps.get(.{ .num = t });
        }
        fn precolored(g: *@This(), t: f64) bool {
            const d = g.temp(t) orelse return false;
            return d.precolor != null;
        }
        fn ensureNode(g: *@This(), t: f64) E!void {
            if (has(&g.nodes, t)) return;
            try add(&g.nodes, t);
            try g.adj.put(g.a, t, .empty);
            try g.adjList.put(g.a, t, .empty);
            try g.degree.put(g.a, t, 0);
            try g.moveList.put(g.a, t, try newSet(g.a));
        }
        fn adjHas(g: *@This(), x: f64, y: f64) bool {
            return g.adj.ptr(x).?.contains(@bitCast(y));
        }
        fn addEdge(g: *@This(), x: f64, y: f64) E!void {
            if (x == y or g.adjHas(x, y)) return;
            try g.adj.ptr(x).?.put(g.a, @bitCast(y), {});
            try g.adj.ptr(y).?.put(g.a, @bitCast(x), {});
            if (!g.precolored(x)) {
                try g.adjList.ptr(x).?.append(g.a, y);
                g.degree.ptr(x).?.* += 1;
            }
            if (!g.precolored(y)) {
                try g.adjList.ptr(y).?.append(g.a, x);
                g.degree.ptr(y).?.* += 1;
            }
        }
        fn deg(g: *@This(), t: f64) f64 {
            return g.degree.get(t).?;
        }
        fn nodeMoves(g: *@This(), t: f64) E!Set {
            var out = try newSet(g.a);
            var it = g.moveList.ptr(t).?.iterator();
            while (it.next()) |e| {
                const m = e.key.num;
                if (g.activeMoves.has(m) or has(&g.worklistMoves, m)) try add(&out, m);
            }
            return out;
        }
        fn moveRelated(g: *@This(), t: f64) E!bool {
            var s = try g.nodeMoves(t);
            return nonEmpty(&s);
        }
        fn adjacent(g: *@This(), t: f64) E!Set {
            var out = try newSet(g.a);
            for (g.adjList.ptr(t).?.items) |v| {
                if (!g.onStack.has(v) and !has(&g.coalescedNodes, v)) try add(&out, v);
            }
            return out;
        }
        fn enableMoves(g: *@This(), nodesSet: *Set) E!void {
            for (try keys(g.a, nodesSet)) |t| {
                var nm = try g.nodeMoves(t);
                for (try keys(g.a, &nm)) |m| {
                    if (g.activeMoves.has(m)) {
                        g.activeMoves.remove(m);
                        try add(&g.worklistMoves, m);
                    }
                }
            }
        }
        fn decrementDegree(g: *@This(), t: f64) E!void {
            g.nDec += 1;
            const d = g.deg(t);
            g.degree.ptr(t).?.* = d - 1;
            if (d == g.K and !g.precolored(t)) {
                var s = try g.adjacent(t);
                try add(&s, t);
                try g.enableMoves(&s);
                removeFrom(&g.spillWorklist, t);
                if (try g.moveRelated(t)) try g.freezeWorklist.append(g.a, t) else try g.simplifyWorklist.append(g.a, t);
            }
        }
        fn simplify(g: *@This()) E!void {
            g.nSimplify += 1;
            const t = g.simplifyWorklist.pop().?;
            try g.selectStack.append(g.a, t);
            try g.onStack.put(g.a, t, {});
            var s = try g.adjacent(t);
            for (try keys(g.a, &s)) |v| try g.decrementDegree(v);
        }
        fn getAlias(g: *@This(), t_in: f64) f64 {
            var t = t_in;
            while (has(&g.coalescedNodes, t)) t = g.alias.get(t).?;
            return t;
        }
        fn addWorklist(g: *@This(), t: f64) E!void {
            if (!g.precolored(t) and !(try g.moveRelated(t)) and g.deg(t) < g.K) {
                removeFrom(&g.freezeWorklist, t);
                try g.simplifyWorklist.append(g.a, t);
            }
        }
        fn ok(g: *@This(), t: f64, r: f64) bool {
            return g.deg(t) < g.K or g.precolored(t) or g.adjHas(t, r);
        }
        fn conservative(g: *@This(), x: f64, y: f64) E!bool {
            var seen: FMap(void) = .{};
            var cnt: f64 = 0;
            for ([_]f64{ x, y }) |z| {
                var s = try g.adjacent(z);
                for (try keys(g.a, &s)) |w| {
                    if (!seen.has(w)) {
                        try seen.put(g.a, w, {});
                        if (g.deg(w) >= g.K) cnt += 1;
                    }
                }
            }
            return cnt < g.K;
        }
        fn combine(g: *@This(), x: f64, y: f64) E!void {
            removeFrom(&g.freezeWorklist, y);
            removeFrom(&g.spillWorklist, y);
            try add(&g.coalescedNodes, y);
            try g.alias.put(g.a, y, x);
            for (try keys(g.a, g.moveList.ptr(y).?)) |m| try add(g.moveList.ptr(x).?, m);
            var s = try g.adjacent(y);
            for (try keys(g.a, &s)) |w| {
                try g.addEdge(w, x);
                try g.decrementDegree(w);
            }
            if (g.deg(x) >= g.K and inArray(g.freezeWorklist.items, x) != null) {
                removeFrom(&g.freezeWorklist, x);
                try g.spillWorklist.append(g.a, x);
            }
        }
        fn coalesce(g: *@This()) E!void {
            g.nCoalesce += 1;
            var it = g.worklistMoves.iterator();
            const m = it.next().?.key.num;
            try del(&g.worklistMoves, m);
            const mv = g.insns[@as(usize, @intFromFloat(m)) - 1].move.?;
            const x = g.getAlias(mv.dst);
            const y = g.getAlias(mv.src);
            var uu = x;
            var vv = y;
            if (g.precolored(y)) {
                uu = y;
                vv = x;
            }
            if (uu == vv) {
                try g.coalescedMoves.put(g.a, m, {});
                try g.addWorklist(uu);
            } else if (g.precolored(vv) or g.adjHas(uu, vv)) {
                try g.constrainedMoves.put(g.a, m, {});
                try g.addWorklist(uu);
                try g.addWorklist(vv);
            } else {
                var canCoalesce: bool = undefined;
                if (g.precolored(uu)) {
                    canCoalesce = !g.reservedSet.contains(g.temp(uu).?.precolor.?);
                    if (canCoalesce) {
                        var s = try g.adjacent(vv);
                        for (try keys(g.a, &s)) |w| {
                            if (!g.ok(w, uu)) {
                                canCoalesce = false;
                                break;
                            }
                        }
                    }
                } else canCoalesce = try g.conservative(uu, vv);
                if (canCoalesce) {
                    try g.coalescedMoves.put(g.a, m, {});
                    try g.combine(uu, vv);
                    try g.addWorklist(uu);
                } else try g.activeMoves.put(g.a, m, {});
            }
        }
        fn freezeMoves(g: *@This(), x: f64) E!void {
            var nm = try g.nodeMoves(x);
            for (try keys(g.a, &nm)) |m| {
                g.activeMoves.remove(m);
                try del(&g.worklistMoves, m);
                try g.frozenMoves.put(g.a, m, {});
                const mv = g.insns[@as(usize, @intFromFloat(m)) - 1].move.?;
                const other = if (g.getAlias(mv.dst) == g.getAlias(x)) g.getAlias(mv.src) else g.getAlias(mv.dst);
                if (!(try g.moveRelated(other)) and g.deg(other) < g.K and !g.precolored(other)) {
                    removeFrom(&g.freezeWorklist, other);
                    try g.simplifyWorklist.append(g.a, other);
                }
            }
        }
        fn freeze(g: *@This()) E!void {
            g.nFreeze += 1;
            const x = g.freezeWorklist.pop().?;
            try g.simplifyWorklist.append(g.a, x);
            try g.freezeMoves(x);
        }
        fn selectSpill(g: *@This()) E!void {
            g.nSpill += 1;
            var best: f64 = 0;
            var bestIdx: usize = 0;
            var bestScore: ?f64 = null;
            for (g.spillWorklist.items, 0..) |t, idx| {
                g.nScan += 1;
                const den = g.spillDen.get(t) orelse blk: {
                    const cost = if (g.temp(t)) |d| d.spillCost orelse 1 else 1;
                    const dd = @max(cost, 0.0001);
                    try g.spillDen.put(g.a, t, dd);
                    break :blk dd;
                };
                const score = g.deg(t) / den;
                if (bestScore == null or score > bestScore.?) {
                    bestScore = score;
                    best = t;
                    bestIdx = idx;
                }
            }
            _ = g.spillWorklist.orderedRemove(bestIdx);
            try g.simplifyWorklist.append(g.a, best);
            try g.freezeMoves(best);
        }
    };

    var g: G = .{ .a = alloc, .temps = temps, .K = K, .insns = insns, .worklistMoves = try newSet(alloc), .nodes = try newSet(alloc), .coalescedNodes = try newSet(alloc), .reservedSet = &reservedSet };
    {
        var it = temps.iterator();
        while (it.next()) |e| try g.ensureNode(e.key.num);
    }
    for (insns) |ins| {
        for (ins.defs) |d| try g.ensureNode(d);
        for (ins.uses) |x| try g.ensureNode(x);
    }

    for (insns, 1..) |ins, i| {
        var live = try newSet(alloc);
        {
            var it = liveOutOf[i - 1].iterator();
            while (it.next()) |e| try add(&live, e.key.num);
        }
        const fi: f64 = @floatFromInt(i);
        if (ins.move) |mv| {
            if (mv.wide == null or mv.wide.?) {
                for (ins.uses) |x| try del(&live, x);
            }
            try add(g.moveList.ptr(mv.dst).?, fi);
            try add(g.moveList.ptr(mv.src).?, fi);
            try add(&g.worklistMoves, fi);
        }
        for (ins.defs) |d| try add(&live, d);
        for (ins.defs) |d| {
            for (try keys(alloc, &live)) |l| try g.addEdge(l, d);
        }
    }
    if (prof.enabled()) {
        var ne: usize = 0;
        var maxdeg: usize = 0;
        var maxlive: usize = 0;
        for (try keys(alloc, &g.nodes)) |t| {
            const l = g.adjList.get(t).?.items.len;
            ne += l;
            maxdeg = @max(maxdeg, l);
        }
        for (liveOutOf) |*s| maxlive = @max(maxlive, (try keys(alloc, s)).len);
        prof.mark("    [ra] interference edges={d} maxdeg={d} maxlive={d}", .{ ne, maxdeg, maxlive });
    }

    var precoloredSet = try newSet(alloc);
    var initial: std.ArrayList(f64) = .empty;
    for (try keys(alloc, &g.nodes)) |t| {
        if (g.precolored(t)) try add(&precoloredSet, t) else try initial.append(alloc, t);
    }
    for (initial.items) |t| {
        if (g.deg(t) >= K) {
            try g.spillWorklist.append(alloc, t);
        } else if (try g.moveRelated(t)) {
            try g.freezeWorklist.append(alloc, t);
        } else try g.simplifyWorklist.append(alloc, t);
    }

    while (true) {
        if (g.simplifyWorklist.items.len > 0) {
            try g.simplify();
        } else if (nonEmpty(&g.worklistMoves)) {
            try g.coalesce();
        } else if (g.freezeWorklist.items.len > 0) {
            try g.freeze();
        } else if (g.spillWorklist.items.len > 0) {
            try g.selectSpill();
        } else break;
    }
    prof.mark("    [ra] IRC main loop simp={d} coal={d} frz={d} spill={d} scan={d} dec={d}", .{ g.nSimplify, g.nCoalesce, g.nFreeze, g.nSpill, g.nScan, g.nDec });

    var colorT = lt.Table([]const u8).init(alloc, 0, 0) catch return error.OutOfMemory;
    for (try keys(alloc, &precoloredSet)) |t| colorT.set(.{ .num = t }, g.temp(t).?.precolor.?) catch return error.OutOfMemory;
    var coloredNodes: FMap(void) = .{};
    var actualSpills: std.ArrayList(f64) = .empty;
    while (g.selectStack.items.len > 0) {
        const t = g.selectStack.pop().?;
        g.onStack.remove(t);
        var okColors: std.StringHashMapUnmanaged(void) = .empty;
        for (pool.items) |r| try okColors.put(alloc, r, {});
        for (g.adjList.get(t).?.items) |w| {
            const aw = g.getAlias(w);
            if (coloredNodes.has(aw) or has(&precoloredSet, aw)) {
                if (colorT.get(.{ .num = aw })) |c| _ = okColors.remove(c);
            }
        }
        var chosen: ?[]const u8 = null;
        for (pool.items) |r| if (okColors.contains(r)) {
            chosen = r;
            break;
        };
        if (chosen) |c| {
            try coloredNodes.put(alloc, t, {});
            colorT.set(.{ .num = t }, c) catch return error.OutOfMemory;
        } else try actualSpills.append(alloc, t);
    }
    for (try keys(alloc, &g.coalescedNodes)) |t| {
        colorT.set(.{ .num = t }, colorT.get(.{ .num = g.getAlias(t) })) catch return error.OutOfMemory;
    }
    prof.mark("    [ra] assign colors", .{});

    // the soundness backstop
    var spilledSet: FMap(void) = .{};
    for (actualSpills.items) |t| try spilledSet.put(alloc, t, {});
    var occurs = try newSet(alloc);
    for (insns) |ins| {
        for (ins.defs) |d| try add(&occurs, d);
        for (ins.uses) |x| try add(&occurs, x);
    }
    for (try keys(alloc, &occurs)) |t| {
        if (colorT.get(.{ .num = t }) == null and !has(&precoloredSet, t) and !spilledSet.has(t) and !has(&g.coalescedNodes, t))
            return err.plain(try u.fmt(alloc, "register allocation left a value without a register (temp {s}); refusing to emit a mis-colored function", .{try u.num(alloc, t)}));
    }
    for (insns, 1..) |ins, i| {
        const defs = ins.defs;
        const live = &liveOutOf[i - 1];
        if (defs.len == 0) continue;
        for (defs) |d| {
            const cd = colorT.get(.{ .num = d }) orelse continue;
            for (try keys(alloc, live)) |t| {
                if (t != d) if (colorT.get(.{ .num = t })) |ct| if (std.mem.eql(u8, ct, cd)) {
                    const exempt = if (ins.move) |mv| (mv.wide == null or mv.wide.?) and t == mv.src else false;
                    if (!exempt) return err.plain(try u.fmt(alloc, "register allocation assigned the same register to two simultaneously-live values (temps {s} and {s} in {s}); refusing to emit a mis-colored function", .{ try u.num(alloc, d), try u.num(alloc, t), cd }));
                };
            }
        }
        for (defs, 0..) |d, di| {
            const cd = colorT.get(.{ .num = d }) orelse continue;
            for (defs[di + 1 ..]) |d2| {
                if (d2 != d) if (colorT.get(.{ .num = d2 })) |c2| if (std.mem.eql(u8, c2, cd))
                    return err.plain(try u.fmt(alloc, "register allocation assigned the same register to two simultaneously-live values (temps {s} and {s} in {s}); refusing to emit a mis-colored function", .{ try u.num(alloc, d), try u.num(alloc, d2), cd }));
            }
        }
    }
    prof.mark("    [ra] soundness backstop", .{});

    const coalesced = try alloc.create(Set);
    coalesced.* = g.coalescedNodes;
    const alias = try alloc.create(FMap(f64));
    alias.* = g.alias;
    return .{ .color = colorT, .spilled = actualSpills.items, .blocks = blocks, .coalesced = coalesced, .alias = alias };
}
