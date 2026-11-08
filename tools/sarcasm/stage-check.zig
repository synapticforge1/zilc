// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! The Zig side of tools/sarcasm/check-stages.ts: one stage of the sarcasm port over a list of
//! inputs, dumped in the same canonical text the Luau harness prints for upstream's modules.
//!
//!   stage-check detect <files.txt>     each line a path: "arch syntax|nil"
//!   stage-check sig <annotations.hex>  each line "x" + a hex string: "ok …" or "err <message>"
//!   stage-check parse|isa <files.txt>, isasyn <lines.hex>, fplookup <names.txt>: check-stages.ts

const std = @import("std");
const s = @import("sarcasm");

fn writeList(out: *std.ArrayList(u8), gpa: std.mem.Allocator, xs: []const u8) !void {
    try out.append(gpa, '{');
    for (xs, 0..) |x, i| {
        if (i > 0) try out.append(gpa, ',');
        try out.print(gpa, "{d}", .{x});
    }
    try out.append(gpa, '}');
}

// ---- the canonical dump (the Luau harness's ser()): non-nil fields sorted by key repr
// ("name" for a string key, "#n" for an array index), strings quoted with control, quote,
// backslash and high bytes as \ddd, numbers by tostring, booleans true/false.
const Field = struct { key: []const u8, val: []const u8 };

fn qstr(gpa: std.mem.Allocator, x: []const u8) ![]const u8 {
    var o: std.ArrayList(u8) = .empty;
    try o.append(gpa, '"');
    for (x) |c| {
        if (c < 32 or c == 127 or c == '"' or c == '\\' or c >= 128) try o.print(gpa, "\\{d}", .{c}) else try o.append(gpa, c);
    }
    try o.append(gpa, '"');
    return o.items;
}

fn obj(gpa: std.mem.Allocator, fields: []Field) ![]const u8 {
    std.mem.sort(Field, fields, {}, struct {
        fn lt(_: void, a: Field, b: Field) bool {
            return std.mem.lessThan(u8, a.key, b.key);
        }
    }.lt);
    var o: std.ArrayList(u8) = .empty;
    try o.append(gpa, '{');
    for (fields, 0..) |f, i| {
        if (i > 0) try o.append(gpa, ',');
        try o.print(gpa, "{s}={s}", .{ f.key, f.val });
    }
    try o.append(gpa, '}');
    return o.items;
}

const Dump = struct {
    gpa: std.mem.Allocator,
    fields: std.ArrayList(Field) = .empty,
    fn putS(d: *Dump, k: []const u8, v: ?[]const u8) !void {
        if (v) |x| try d.fields.append(d.gpa, .{ .key = k, .val = try qstr(d.gpa, x) });
    }
    fn putN(d: *Dump, k: []const u8, v: ?f64) !void {
        var b: [64]u8 = undefined;
        if (v) |x| try d.fields.append(d.gpa, .{ .key = k, .val = try d.gpa.dupe(u8, s.luau_number.tostring(&b, x)) });
    }
    fn putB(d: *Dump, k: []const u8, v: ?bool) !void {
        if (v) |x| try d.fields.append(d.gpa, .{ .key = k, .val = if (x) "true" else "false" });
    }
    fn raw(d: *Dump, k: []const u8, v: []const u8) !void {
        try d.fields.append(d.gpa, .{ .key = k, .val = v });
    }
    fn done(d: *Dump) ![]const u8 {
        return obj(d.gpa, d.fields.items);
    }
};

fn dumpOp(gpa: std.mem.Allocator, op: *const s.ir.Operand) ![]const u8 {
    var d: Dump = .{ .gpa = gpa };
    try d.putS("kind", @tagName(op.kind));
    try d.putS("rc", if (op.rc) |r| @tagName(r) else null);
    if (op.kind == .numref) try d.putS("num", op.refNum) else try d.putN("num", op.num);
    try d.putN("width", op.width);
    try d.putS("name", op.name);
    try d.putS("pseudo", op.pseudo);
    try d.putB("indirect", op.indirect);
    try d.putS("text", op.text);
    try d.putN("value", op.value);
    try d.putB("absAddr", op.absAddr);
    try d.putS("reloc", op.reloc);
    try d.putS("dir", op.dir);
    if (op.base) |x| try d.raw("base", try dumpOp(gpa, x));
    if (op.index) |x| try d.raw("index", try dumpOp(gpa, x));
    try d.putN("scale", op.scale);
    try d.putN("dispVal", op.dispVal);
    try d.putS("dispSym", op.dispSym);
    try d.putS("dispReloc", op.dispReloc);
    try d.putN("size", op.size);
    try d.putS("deco", op.deco);
    try d.putN("bcastN", op.bcastN);
    try d.putB("implicit", op.implicit);
    try d.putS("fixedReg", op.fixedReg);
    try d.putB("isSlot", op.isSlot);
    return d.done();
}

// ---- the isa / isasyn / fplookup dump (check-stages.ts ISA_DUMP)
const Op = s.ir.Operand;

fn tsN(gpa: std.mem.Allocator, v: ?f64) ![]const u8 {
    var b: [64]u8 = undefined;
    return if (v) |x| gpa.dupe(u8, s.luau_number.tostring(&b, x)) else "nil";
}
fn tsS(v: ?[]const u8) []const u8 {
    return v orelse "nil";
}
fn tsB(v: bool) []const u8 {
    return if (v) "true" else "false";
}

fn lkSum(gpa: std.mem.Allocator, e_: ?s.x86_64_fp.Entry) ![]const u8 {
    const e = e_ orelse return "nil";
    const w: []const u8 = if (e.w) |w| switch (w) {
        .bytes => |x| try tsN(gpa, x),
        .vec => "vec",
        .pspd => "pspd",
        .func, .pmov, .pmovtr => "fn",
    } else "nil";
    const a: []const u8 = if (e.@"align") |x| switch (x) {
        .bytes => |y| try tsN(gpa, y),
        .vec => "vec",
    } else "nil";
    const g: []const u8 = if (e.gpr) |x| switch (x) {
        .dst => "dst",
        .src => "src",
        else => "fn",
    } else "nil";
    const m: []const u8 = if (e.memOk) |x| tsB(x) else "nil";
    return std.fmt.allocPrint(gpa, "w={s} a={s} g={s} m={s} r={s} n={s} c={s}", .{ w, a, g, m, tsB(e.reject != null), if (e.noCheck) "true" else "nil", tsB(e.claim) });
}

const Refs = struct {
    gpa: std.mem.Allocator,
    st: *const s.ir.Stmt,
    ids: std.AutoHashMapUnmanaged(*const Op, usize) = .empty,
    n: usize = 0,
    fn ref(r: *Refs, o: *const Op) ![]const u8 {
        for (r.st.operands.items, 1..) |x, i| {
            if (x == o) return std.fmt.allocPrint(r.gpa, "@{d}", .{i});
            if (x.kind == .mem) {
                if (x.base == o) return std.fmt.allocPrint(r.gpa, "@{d}b", .{i});
                if (x.index == o) return std.fmt.allocPrint(r.gpa, "@{d}x", .{i});
            }
        }
        if (r.ids.get(o)) |id| return std.fmt.allocPrint(r.gpa, "#{d}", .{id});
        r.n += 1;
        try r.ids.put(r.gpa, o, r.n);
        return std.fmt.allocPrint(r.gpa, "#{d}{s}", .{ r.n, try dumpOp(r.gpa, o) });
    }
    fn refs(r: *Refs, l: []const *Op) ![]const u8 {
        var o: std.ArrayList(u8) = .empty;
        try o.append(r.gpa, '[');
        for (l, 0..) |x, i| {
            if (i > 0) try o.append(r.gpa, ',');
            try o.appendSlice(r.gpa, try r.ref(x));
        }
        try o.append(r.gpa, ']');
        return o.items;
    }
};

fn dumpClass(gpa: std.mem.Allocator, st: *const s.ir.Stmt, c: s.ir.Class) ![]const u8 {
    var r: Refs = .{ .gpa = gpa, .st = st };
    var o: std.ArrayList(u8) = .empty;
    try o.print(gpa, "c={s} f={s}", .{ @tagName(c.control), tsB(c.fallsThrough) });
    try o.print(gpa, " d={s}", .{try r.refs(c.defs.items)});
    try o.print(gpa, " u={s}", .{try r.refs(c.uses.items)});
    try o.appendSlice(gpa, " r=[");
    for (c.rmw.items, 0..) |x, i| {
        if (i > 0) try o.append(gpa, ',');
        try o.appendSlice(gpa, try tsN(gpa, x));
    }
    try o.append(gpa, ']');
    if (c.targets) |t| {
        try o.appendSlice(gpa, " t=[");
        for (t, 0..) |x, i| {
            if (i > 0) try o.append(gpa, ',');
            try o.appendSlice(gpa, try qstr(gpa, x));
        }
        try o.append(gpa, ']');
    }
    if (c.pin) |p| {
        try o.print(gpa, " pu={s}", .{try r.refs(p.uses.items)});
        try o.print(gpa, " pd={s}", .{try r.refs(p.defs.items)});
    }
    if (c.rep) |p| {
        try o.print(gpa, " rep={s}/{s}/{s}", .{ p.kind, try tsN(gpa, p.elem), tsS(p.repPrefix) });
        for ([_]?*Op{ p.rsi, p.rdi, p.rax }) |x| try o.print(gpa, "/{s}", .{if (x) |y| try r.ref(y) else "-"});
        try o.print(gpa, "/{s}", .{try r.ref(p.rcxUse.?)});
        try o.print(gpa, "/{s}", .{try r.ref(p.rcxDef.?)});
    }
    if (c.flagsPush) try o.appendSlice(gpa, " fpush");
    if (c.flagsPop) try o.appendSlice(gpa, " fpop");
    if (c.unknown) try o.appendSlice(gpa, " unk");
    return o.items;
}

fn errOr(gpa: std.mem.Allocator, e: anyerror) ![]const u8 {
    if (e == error.Sarcasm) return std.fmt.allocPrint(gpa, "E {s}", .{s.err.message});
    return e;
}

fn aw(gpa: std.mem.Allocator, m: []const u8, st: *const s.ir.Stmt) ![]const u8 {
    const r = s.x86_64_fp.accessWidth(gpa, m, st.operands.items, st.raw, st.loc()) catch |e| return errOr(gpa, e);
    if (r) |x| return std.fmt.allocPrint(gpa, "{s},{s}", .{ try tsN(gpa, x.w), try tsN(gpa, x.@"align") });
    return "nil,nil";
}

fn fx(gpa: std.mem.Allocator, t: *s.luau_table.Table(f64)) ![]const u8 {
    var o: std.ArrayList(u8) = .empty;
    try o.append(gpa, '{');
    var it = t.iterator();
    var i: usize = 0;
    while (it.next()) |e| : (i += 1) {
        if (i > 0) try o.append(gpa, ',');
        try o.print(gpa, "{s}:{s}", .{ try tsN(gpa, e.key.num), try tsN(gpa, e.val) });
    }
    try o.append(gpa, '}');
    return o.items;
}

fn isaDump(gpa: std.mem.Allocator, st: *const s.ir.Stmt) ![]const u8 {
    const fp = s.x86_64_fp;
    const isa = s.x86_64_isa;
    const mn = st.mnemonic.?;
    const low = try gpa.dupe(u8, mn);
    for (low) |*ch| ch.* = std.ascii.toLower(ch.*);
    var o: std.ArrayList(u8) = .empty;
    try o.print(gpa, "base={s}", .{try isa.baseMnemonic(gpa, mn)});
    const cls = if (isa.classify(gpa, st)) |c| try dumpClass(gpa, st, c) else |e| try errOr(gpa, e);
    try o.print(gpa, " | cls={s}", .{cls});
    try o.print(gpa, " | lk={s}", .{try lkSum(gpa, try fp.lookup(gpa, low))});
    try o.print(gpa, " | aw={s}", .{try aw(gpa, low, st)});
    try o.print(gpa, " | aw2={s}", .{try aw(gpa, mn, st)});
    var ve = try fp.vecEffects(gpa, st);
    try o.print(gpa, " | ve=u{s} d{s}", .{ try fx(gpa, &ve.uses), try fx(gpa, &ve.defs) });
    if (try fp.maskedAccessInfo(gpa, low, st.operands.items)) |mi| {
        try o.print(gpa, " | mi={s},{s},{s},{s},{s},{s}", .{ try tsN(gpa, mi.elem), try tsN(gpa, mi.lanes), try tsN(gpa, mi.vecsize), tsB(mi.contiguous), @tagName(mi.extract), if (mi.movmskPd) "true" else "nil" });
    } else try o.appendSlice(gpa, " | mi=nil");
    try o.print(gpa, " | fl={s},{s},{s},{d},{d}", .{ tsB(try isa.flagUse(gpa, st)), tsB(try isa.flagDef(gpa, st)), tsB(try isa.flagWriteNoDef(gpa, st)), try isa.flagUseMask(gpa, st), try isa.flagDefMask(gpa, st) });
    try o.print(gpa, " | lr={s},{s},{s}", .{ tsB(try isa.lockAllows(gpa, st)), tsB(try isa.isMemRmw(gpa, st)), try tsN(gpa, try isa.gprAccessRegWidth(gpa, st)) });
    const mem = fp.memOperand(st.operands.items);
    try o.print(gpa, " | ns={s}", .{tsS(fp.narrowSuffix(low, if (mem) |m| m.size else null))});
    try o.print(gpa, " | ur={s}", .{tsS(try fp.unsafeReject(gpa, low, st))});
    try o.print(gpa, " | hf={s}", .{tsB(fp.hasFpReg(st))});
    return o.items;
}

fn dumpStmt(gpa: std.mem.Allocator, st: *const s.ir.Stmt) ![]const u8 {
    var d: Dump = .{ .gpa = gpa };
    try d.putS("kind", @tagName(st.kind));
    try d.putN("line", if (st.line) |l| @floatFromInt(l) else null);
    try d.putS("file", st.file);
    try d.putS("annotation", st.annotation);
    try d.putS("name", st.name);
    try d.putS("args", st.args);
    try d.putS("text", st.text);
    try d.putS("mnemonic", st.mnemonic);
    if (st.kind == .insn) {
        var ops: std.ArrayList(Field) = .empty;
        for (st.operands.items, 1..) |op, i| try ops.append(gpa, .{ .key = try std.fmt.allocPrint(gpa, "#{d}", .{i}), .val = try dumpOp(gpa, op) });
        try d.raw("operands", try obj(gpa, ops.items));
    }
    try d.putN("opsize", st.opsize);
    try d.putS("raw", st.raw);
    try d.putS("syntax", st.syntax);
    try d.putB("lockPrefix", st.lockPrefix);
    try d.putS("repPrefix", st.repPrefix);
    try d.putB("dotAlloca", st.dotAlloca);
    return d.done();
}

// ---- the lift / ptrflow / regalloc / frame dump (check-stages.ts LIFT_DUMP)
const Stmt = s.ir.Stmt;
const Alloc = std.mem.Allocator;

fn numList(gpa: Alloc, xs: []const f64) ![]const u8 {
    var o: std.ArrayList(u8) = .empty;
    try o.append(gpa, '[');
    for (xs, 0..) |x, i| {
        if (i > 0) try o.append(gpa, ',');
        try o.appendSlice(gpa, try tsN(gpa, x));
    }
    try o.append(gpa, ']');
    return o.items;
}
fn joinNums(gpa: Alloc, xs: []const usize, sep: []const u8) ![]const u8 {
    var o: std.ArrayList(u8) = .empty;
    for (xs, 0..) |x, i| {
        if (i > 0) try o.appendSlice(gpa, sep);
        try o.print(gpa, "{d}", .{x});
    }
    return o.items;
}
fn iterKV(gpa: Alloc, comptime V: type, t: *s.luau_table.Table(V)) ![]const u8 {
    var o: std.ArrayList(u8) = .empty;
    try o.append(gpa, '{');
    var it = t.iterator();
    var i: usize = 0;
    while (it.next()) |e| : (i += 1) {
        if (i > 0) try o.append(gpa, ',');
        const v: []const u8 = switch (V) {
            bool => tsB(e.val),
            f64 => try tsN(gpa, e.val),
            []const u8 => e.val,
            else => unreachable,
        };
        try o.print(gpa, "{s}:{s}", .{ try tsN(gpa, e.key.num), v });
    }
    try o.append(gpa, '}');
    return o.items;
}

fn classifyCb(_: ?*anyopaque, a: Alloc, st: *const Stmt) s.err.Error!s.ir.Class {
    return s.x86_64_isa.classify(a, st);
}
fn callInfoCb(_: ?*anyopaque, a: Alloc, st: *const Stmt) s.err.Error!?s.lift.CallInfo {
    _ = a;
    const ops = st.operands.items;
    if (ops.len > 0 and ops[0].kind == .sym) {
        const t = ops[0].text.?;
        const c: u32 = if (t.len > 0) t[0] else 0;
        if (c % 2 == 0) return .{ .argRegs = &.{ 7, 6 }, .resultReg = 0 };
        if (c % 3 == 0) return .{ .argRegs = &.{2} };
    }
    return null;
}
fn baseCb(_: ?*anyopaque, a: Alloc, m: []const u8) s.err.Error![]const u8 {
    return s.x86_64_isa.baseMnemonic(a, m);
}
const TempLog = struct {
    gpa: Alloc,
    nt: f64,
    log: std.ArrayList([]const u8) = .empty,
    fn cb(ctx: ?*anyopaque, info: s.ptrflow.TempInfo) s.err.Error!f64 {
        const l: *TempLog = @ptrCast(@alignCast(ctx.?));
        l.nt += 1;
        try l.log.append(l.gpa, try std.fmt.allocPrint(l.gpa, "{s}:{s}:{s}", .{ try tsN(l.gpa, l.nt), try tsN(l.gpa, info.forPtr), tsB(info.dynamicLower) }));
        return l.nt;
    }
};

fn isRegRegMov(gpa: Alloc, st: *const Stmt) !bool {
    const ops = st.operands.items;
    if (!std.mem.eql(u8, try s.x86_64_isa.baseMnemonic(gpa, st.mnemonic.?), "mov") or ops.len != 2) return false;
    return ops[0].kind == .reg and ops[0].rc == .gpr and ops[1].kind == .reg and ops[1].rc == .gpr;
}

fn liftDump(gpa: Alloc, out: *std.ArrayList(u8), r: []*Stmt) !void {
    var body: std.ArrayList(*Stmt) = .empty;
    for (r) |st| {
        if (st.kind != .insn) {
            try body.append(gpa, st);
        } else if (s.x86_64_isa.classify(gpa, st)) |_| {
            try body.append(gpa, st);
        } else |e| if (e != error.Sarcasm) return e;
    }
    var lf = s.lift.liftFunction(gpa, body.items, .{ .classify = classifyCb, .returnRegs = &.{ 0, 2 }, .callInfo = callInfoCb }) catch |e| {
        if (e != error.Sarcasm) return e;
        try out.print(gpa, "lift err {s}\n", .{s.err.message});
        return;
    };
    try out.print(gpa, "L n={d} next={s}\n", .{ lf.flow.len, try tsN(gpa, lf.nextTemp) });
    try out.appendSlice(gpa, "T ");
    for (lf.temps, 0..) |t, i| {
        if (i > 0) try out.append(gpa, ',');
        try out.appendSlice(gpa, try tsN(gpa, t.reg));
    }
    try out.append(gpa, '\n');
    {
        var ks: std.ArrayList(f64) = .empty;
        var it = lf.entryTemp.iterator();
        while (it.next()) |e| try ks.append(gpa, @bitCast(e.key_ptr.*));
        std.mem.sort(f64, ks.items, {}, std.sort.asc(f64));
        try out.appendSlice(gpa, "E {");
        for (ks.items, 0..) |kk, i| {
            if (i > 0) try out.append(gpa, ',');
            try out.print(gpa, "{s}:{s}", .{ try tsN(gpa, kk), try tsN(gpa, lf.entryTempOf(kk).?) });
        }
        try out.appendSlice(gpa, "}\n");
    }
    for (lf.nodes) |nd| switch (nd.kind) {
        .insn => {
            var o: std.ArrayList(u8) = .empty;
            var first = true;
            for ([_][]const *Op{ nd.c.?.defs.items, nd.c.?.uses.items }) |lst| for (lst) |x| {
                if (!first) try o.append(gpa, ',');
                first = false;
                try o.appendSlice(gpa, if (nd.opTemp.get(x)) |t| try tsN(gpa, t) else "-");
            };
            var sc: std.ArrayList(f64) = .empty;
            for (lf.succ[nd.fi - 1]) |x| try sc.append(gpa, @floatFromInt(x));
            try out.print(gpa, "I {d} d={s} u={s} o=[{s}] s={s}\n", .{ nd.fi, try numList(gpa, nd.defTemps.items), try numList(gpa, nd.useTemps.items), o.items, try numList(gpa, sc.items) });
        },
        .label => try out.print(gpa, "B {s}\n", .{try qstr(gpa, nd.name.?)}),
        .other => try out.appendSlice(gpa, "O\n"),
    };
    {
        var ks: std.ArrayList([]const u8) = .empty;
        var it = lf.labelToFlow.keyIterator();
        while (it.next()) |x| try ks.append(gpa, x.*);
        std.mem.sort([]const u8, ks.items, {}, struct {
            fn lt(_: void, a: []const u8, b: []const u8) bool {
                return std.mem.lessThan(u8, a, b);
            }
        }.lt);
        try out.appendSlice(gpa, "F ");
        for (ks.items, 0..) |kk, i| {
            if (i > 0) try out.append(gpa, ',');
            try out.print(gpa, "{s}:{d}", .{ try qstr(gpa, kk), lf.labelToFlow.get(kk).? });
        }
        try out.append(gpa, '\n');
    }

    // ptrflow
    var argPtr: std.ArrayList(f64) = .empty;
    if (lf.entryTempOf(7)) |t| try argPtr.append(gpa, t);
    if (lf.entryTempOf(6)) |t| try argPtr.append(gpa, t);
    var loadPtr: s.ptrflow.NodeSet = .empty;
    var callPtr: s.ptrflow.NodeSet = .empty;
    var capSave: s.ptrflow.NodeVar = .empty;
    var capRestore: s.ptrflow.NodeVar = .empty;
    var lastSave: ?usize = null;
    for (lf.nodes) |nd| if (nd.kind == .insn) {
        const st = nd.stmt.?;
        const m = try s.x86_64_isa.baseMnemonic(gpa, st.mnemonic.?);
        const ops = st.operands.items;
        if (std.mem.eql(u8, m, "mov") and ops.len >= 2 and ops[0].kind == .reg and ops[1].kind == .mem and nd.fi % 2 == 0) try loadPtr.put(gpa, nd, {});
        if (nd.c.?.control == .call and nd.fi % 3 == 0) try callPtr.put(gpa, nd, {});
        if (try isRegRegMov(gpa, st) and nd.fi % 5 == 0) {
            try capSave.put(gpa, nd, try std.fmt.allocPrint(gpa, "v{d}", .{nd.fi}));
            lastSave = nd.fi;
        } else if (try isRegRegMov(gpa, st) and nd.fi % 7 == 0 and lastSave != null) {
            try capRestore.put(gpa, nd, try std.fmt.allocPrint(gpa, "v{d}", .{lastSave.?}));
        }
    };
    var log: TempLog = .{ .gpa = gpa, .nt = lf.nextTemp };
    if (s.ptrflow.analyze(gpa, &lf, .{ .argPtrTemps = argPtr.items, .loadPtrDefs = &loadPtr, .callPtrDefs = &callPtr, .capSave = &capSave, .capRestore = &capRestore }, .{ .ctx = &log, .f = TempLog.cb }, .{ .baseMnemonic = baseCb, .widenSwaps = true })) |pf_| {
        var pf = pf_;
        try out.print(gpa, "P {s} W {s} D {s}\n", .{ try iterKV(gpa, bool, &pf.isPtr), try iterKV(gpa, f64, &pf.lowerTemp), try iterKV(gpa, bool, &pf.dynamic) });
        try out.appendSlice(gpa, "Y ");
        var first = true;
        for (lf.nodes) |nd| if (pf.dynCopy.get(nd)) |dc| {
            if (!first) try out.append(gpa, ' ');
            first = false;
            try out.print(gpa, "{s}:{s}/{s}:[", .{ try tsN(gpa, @floatFromInt(nd.fi)), tsB(dc.xchg), tsB(dc.cmov) });
            for (dc.copies, 0..) |c, i| {
                if (i > 0) try out.append(gpa, ',');
                try out.print(gpa, "{s}>{s}", .{ try tsN(gpa, c.dst), try tsN(gpa, c.src) });
            }
            try out.append(gpa, ']');
        };
        try out.append(gpa, '\n');
        const hk = try gpa.dupe([]const u8, pf.capShot.keys());
        std.mem.sort([]const u8, hk, {}, struct {
            fn lt(_: void, a: []const u8, b: []const u8) bool {
                return std.mem.lessThan(u8, a, b);
            }
        }.lt);
        try out.appendSlice(gpa, "H ");
        for (hk, 0..) |kk, i| {
            if (i > 0) try out.append(gpa, ' ');
            const sh = pf.capShot.get(kk).?;
            try out.print(gpa, "{s}:{s},{s}", .{ kk, try tsN(gpa, sh.web), try tsN(gpa, sh.lo) });
        }
        try out.appendSlice(gpa, " N ");
        for (log.log.items, 0..) |x, i| {
            if (i > 0) try out.append(gpa, ' ');
            try out.appendSlice(gpa, x);
        }
        try out.append(gpa, '\n');
    } else |e| {
        if (e != error.Sarcasm) return e;
        try out.print(gpa, "pf err {s}\n", .{s.err.message});
    }
    if (s.ptrflow.analyze(gpa, &lf, .{ .argPtrTemps = argPtr.items, .loadPtrDefs = &loadPtr, .callPtrDefs = &callPtr, .capSave = &capSave, .capRestore = &capRestore }, .{ .ctx = &log, .f = TempLog.cb }, .{ .baseMnemonic = baseCb, .widenSwaps = false })) |pq_| {
        var pq = pq_;
        try out.print(gpa, "Q {s} W {s}\n", .{ try iterKV(gpa, bool, &pq.isPtr), try iterKV(gpa, f64, &pq.lowerTemp) });
    } else |e| {
        if (e != error.Sarcasm) return e;
        try out.print(gpa, "Q err {s}\n", .{s.err.message});
    }

    // regalloc
    const RA = s.regalloc;
    var insns: std.ArrayList(RA.Insn) = .empty;
    for (lf.nodes) |nd| switch (nd.kind) {
        .label => try insns.append(gpa, .{ .isLabelDef = nd.name }),
        .insn => {
            var ins: RA.Insn = .{ .defs = nd.defTemps.items, .uses = nd.useTemps.items, .targets = nd.c.?.targets, .fallsThrough = nd.c.?.fallsThrough };
            if (try isRegRegMov(gpa, nd.stmt.?) and nd.defTemps.items.len == 1 and nd.useTemps.items.len == 1)
                ins.move = .{ .dst = nd.defTemps.items[0], .src = nd.useTemps.items[0], .wide = (nd.stmt.?.operands.items[0].width orelse -1) == 64 };
            try insns.append(gpa, ins);
        },
        .other => {},
    };
    const small = [_][]const u8{ "rax", "rcx", "rdx", "rbx", "rbp" };
    const variants = [_]RA.Opts{ .{ .allocatable = &s.x86_64_isa.ALLOCATABLE }, .{ .allocatable = &small }, .{ .allocatable = &s.x86_64_isa.ALLOCATABLE, .reserved = &.{"rcx"} }, .{ .allocatable = &s.x86_64_isa.ALLOCATABLE } };
    for (variants, 1..) |o, vi| {
        var temps = try s.luau_table.Table(RA.Temp).init(gpa, 0, 0);
        var t: f64 = 1;
        while (t <= lf.nextTemp) : (t += 1) try temps.set(.{ .num = t }, .{ .spillCost = 1 + @mod(t, 3) });
        for ([_]struct { f64, []const u8 }{ .{ 7, "rdi" }, .{ 6, if (vi == 4) "rdi" else "rsi" } }) |p| if (lf.entryTempOf(p[0])) |et| {
            var d = temps.get(.{ .num = et }).?;
            d.precolor = p[1];
            try temps.set(.{ .num = et }, d);
        };
        if (RA.color(gpa, insns.items, &temps, o)) |cr_| {
            var cr = cr_;
            var b: std.ArrayList(u8) = .empty;
            for (cr.blocks, 0..) |bl, i| {
                if (i > 0) try b.append(gpa, ' ');
                try b.print(gpa, "{d}-{d}>{s}", .{ bl.first, bl.last, try joinNums(gpa, bl.succ.items, ".") });
            }
            var al: std.ArrayList(u8) = .empty;
            var tt: f64 = 1;
            var firstA = true;
            while (tt <= lf.nextTemp) : (tt += 1) {
                const a = cr.aliasOf(tt);
                if (a != tt) {
                    if (!firstA) try al.append(gpa, ' ');
                    firstA = false;
                    try al.print(gpa, "{s}>{s}", .{ try tsN(gpa, tt), try tsN(gpa, a) });
                }
            }
            try out.print(gpa, "R{d} C {s} S {s} K {s} A {s}\n", .{ vi, try iterKV(gpa, []const u8, &cr.color), try numList(gpa, cr.spilled), b.items, al.items });
        } else |e| {
            if (e != error.Sarcasm) return e;
            try out.print(gpa, "R{d} err {s}\n", .{ vi, s.err.message });
        }
    }
    const lo2 = try RA.liveOut(gpa, insns.items);
    try out.appendSlice(gpa, "V ");
    for (lo2, 0..) |*set, i| {
        if (i > 0) try out.append(gpa, ' ');
        var it = set.iterator();
        var j: usize = 0;
        while (it.next()) |e| : (j += 1) {
            if (j > 0) try out.append(gpa, '.');
            try out.appendSlice(gpa, try tsN(gpa, e.key.num));
        }
    }
    try out.append(gpa, '\n');
}

const TestPolicy = struct {
    fn analyze(_: *anyopaque, _: Alloc, _: []const *Stmt, _: ?*const anyopaque, _: ?[]const *s.frame.Region) s.err.Error!s.frame.FrameInfo {
        return .{ .frameSize = 96, .fpOffset = 16, .usesFp = true };
    }
    fn mk(a: Alloc, m: []const u8, op: ?*Op, raw: ?[]const u8) !*Stmt {
        const st = try a.create(Stmt);
        st.* = .{ .kind = .insn, .mnemonic = m, .raw = raw };
        if (op) |o| try st.operands.append(a, o);
        return st;
    }
    fn rewrite(_: *anyopaque, a: Alloc, st: *Stmt, ctx: *s.frame.Ctx) s.err.Error!void {
        for (st.operands.items, 0..) |o, i| {
            if (o.kind == .mem and o.base != null and o.base.?.rc == .sp) {
                const off = o.dispVal orelse 0;
                if (std.mem.eql(u8, try s.x86_64_isa.baseMnemonic(a, st.mnemonic.?), "lea")) return ctx.rejectEscape(st.raw, if (@mod(off, 2) == 0) st else null);
                if (ctx.regionOf(off, i == 0)) |r| return ctx.emit(try mk(a, "region", try s.frame.slotReg(a, r.base, null), st.raw));
                try ctx.checkBounds(off, o.size orelse 8, i == 0, st.raw, -128, if (@mod(off, 16) == 0) st else null);
                return ctx.emit(try mk(a, "slot", try s.frame.slotReg(a, off, (o.size orelse 8) * 8), st.raw));
            }
            if (o.kind == .imm and s.frame.immVal(o) == 4096) return ctx.emit(try mk(a, "imm4096", null, st.raw));
        }
        try ctx.emit(st);
    }
};

fn frameDump(gpa: Alloc, out: *std.ArrayList(u8), r: []*Stmt) !void {
    var r1: s.frame.Region = .{ .base = 32, .size = 16, .anchored = false };
    var r2: s.frame.Region = .{ .base = 0, .size = 8, .anchored = true };
    const regions = [_]*s.frame.Region{ &r1, &r2 };
    var dummy: u8 = 0;
    const o = s.frame.preprocess(gpa, r, &regions, .{ .ptr = &dummy, .analyzeFrame = TestPolicy.analyze, .rewrite = TestPolicy.rewrite }, null) catch |e| {
        if (e != error.Sarcasm) return e;
        try out.print(gpa, "frame err {s}\n", .{s.err.message});
        return;
    };
    try out.print(gpa, "frame {d} ", .{o.len});
    for (o, 0..) |st, i| {
        if (i > 0) try out.append(gpa, ' ');
        try out.print(gpa, "{s}:{s}", .{ @tagName(st.kind), tsS(st.mnemonic) });
        if (st.mnemonic) |m| if (std.mem.eql(u8, m, "slot") or std.mem.eql(u8, m, "region")) try out.print(gpa, ":{s}", .{try dumpOp(gpa, st.operands.items[0])});
    }
    try out.append(gpa, '\n');
}

// ---- framecalls: replay upstream's logged frame-context calls into frame.zig's Ctx
fn unhexOpt(gpa: Alloc, f: []const u8) !?[]const u8 {
    if (std.mem.eql(u8, f, "-")) return null;
    const o = try gpa.alloc(u8, (f.len - 1) / 2);
    _ = try std.fmt.hexToBytes(o, f[1..]);
    return o;
}
fn numOpt(f: []const u8) ?f64 {
    if (std.mem.eql(u8, f, "-")) return null;
    return s.luau_number.tonumber(f).?;
}
fn stOpt(gpa: Alloc, file: []const u8, line: []const u8) !?*Stmt {
    if (std.mem.eql(u8, file, "-") and std.mem.eql(u8, line, "-")) return null;
    const st = try gpa.create(Stmt);
    st.* = .{ .kind = .insn, .file = try unhexOpt(gpa, file), .line = if (numOpt(line)) |n| @intFromFloat(n) else null };
    return st;
}

const Replay = struct {
    gpa: Alloc,
    ctx: ?s.frame.Ctx = null,
    regions: []*s.frame.Region = &.{},

    fn line(r: *Replay, out: *std.ArrayList(u8), l: []const u8) !void {
        const gpa = r.gpa;
        const tab = std.mem.indexOfScalar(u8, l, '\t');
        const rec = if (tab) |t| l[0..t] else l;
        var f: std.ArrayList([]const u8) = .empty;
        var it = std.mem.splitScalar(u8, rec, ' ');
        while (it.next()) |x| try f.append(gpa, x);
        const F = f.items;
        switch (rec[0]) {
            'F' => {
                s.err.setDefaultFile(try unhexOpt(gpa, F[1]));
                return out.print(gpa, "{s}\n", .{l});
            },
            'O' => return out.print(gpa, "{s}\n", .{l}),
            'P' => {
                var regs: std.ArrayList(*s.frame.Region) = .empty;
                if (!std.mem.eql(u8, F[2], "-")) {
                    var ri = std.mem.splitScalar(u8, F[2], ';');
                    while (ri.next()) |rs| {
                        var p = std.mem.splitScalar(u8, rs, ',');
                        const reg = try gpa.create(s.frame.Region);
                        reg.* = .{ .base = numOpt(p.next().?).?, .size = numOpt(p.next().?).?, .anchored = std.mem.eql(u8, p.next().?, "true") };
                        try regs.append(gpa, reg);
                    }
                }
                r.regions = regs.items;
                r.ctx = .{ .alloc = gpa, .frameSize = numOpt(F[1]).?, .fpOffset = null, .usesFp = null, .fpInfo = null, .regions = r.regions };
                return out.print(gpa, "{s}\n", .{l});
            },
            else => {},
        }
        const ctx = &r.ctx.?;
        try out.print(gpa, "{s}\t", .{rec});
        switch (rec[0]) {
            'R' => {
                const reg = ctx.regionOf(numOpt(F[1]).?, std.mem.eql(u8, F[2], "true"));
                if (reg) |x| {
                    for (r.regions, 1..) |y, i| if (y == x) try out.print(gpa, "{d}", .{i});
                } else try out.appendSlice(gpa, "nil");
            },
            'C' => {
                if (ctx.checkBounds(numOpt(F[1]).?, numOpt(F[2]).?, std.mem.eql(u8, F[3], "true"), try unhexOpt(gpa, F[4]), numOpt(F[5]), try stOpt(gpa, F[6], F[7]))) |_| {
                    try out.appendSlice(gpa, "ok");
                } else |e| {
                    if (e != error.Sarcasm) return e;
                    try out.print(gpa, "E {s}", .{s.err.message});
                }
            },
            'X' => {
                const e = ctx.rejectEscape(try unhexOpt(gpa, F[1]), try stOpt(gpa, F[2], F[3]));
                if (e != error.Sarcasm) return e;
                try out.print(gpa, "E {s}", .{s.err.message});
            },
            'S' => try out.appendSlice(gpa, try dumpOp(gpa, try s.frame.slotReg(gpa, numOpt(F[1]).?, numOpt(F[2])))),
            else => return error.UnknownRecord,
        }
        try out.append(gpa, '\n');
    }
};

// ---- xframe: run the port's analyzeFrame on each captured call, print its checkpoint state
const lvx = @import("luau_value.zig");
const capx = @import("capture.zig");

fn qsOpt(gpa: Alloc, v: ?[]const u8) ![]const u8 {
    return if (v) |x| qstr(gpa, x) else "nil";
}

fn dumpK1(gpa: Alloc, an: *s.x86_64_frame.Analysis) ![]const u8 {
    const XF = s.x86_64_frame;
    var o: std.ArrayList(u8) = .empty;
    const idx: ?f64 = if (XF.frameAndIdx) |x| @floatFromInt(x) else null;
    try o.print(gpa, "K1 D0={s} rbpNorm={s} frameSize={s} prologueEnd={d} usesRbp={s} fpDepth={s} depth={s} subBytes={s} spillBytes={s} frameAlignReq={s} frameAndDepth={s} frameAndIdx={s} frameAndSeen={s} cloneRetProofRan={s} yoloCount={s} yoloBase={s} sigHasFp={s} bufProbeSuppress={s}", .{
        try tsN(gpa, XF.D0),         try tsN(gpa, XF.rbpNorm),       try tsN(gpa, an.frameSize),     an.prologueEnd,
        tsB(an.usesRbp),             try tsN(gpa, an.fpDepth),       try tsN(gpa, an.depth),         try tsN(gpa, an.subBytes),
        try tsN(gpa, an.spillBytes), try tsN(gpa, XF.frameAlignReq), try tsN(gpa, XF.frameAndDepth), try tsN(gpa, idx),
        tsB(XF.frameAndSeen),        tsB(XF.cloneRetProofRan),       try tsN(gpa, XF.yoloCount),     try tsN(gpa, XF.yoloBase),
        tsB(an.sigHasFp),            tsB(an.bufProbeSuppress),
    });
    try o.appendSlice(gpa, " pstack=[");
    for (an.pstack.items, 0..) |e, i| {
        if (i > 0) try o.append(gpa, ',');
        try o.print(gpa, "{s}@{s}", .{ e.name, try tsN(gpa, e.depth) });
    }
    try o.appendSlice(gpa, "] rep=[");
    {
        var ks: std.ArrayList(f64) = .empty;
        for (an.bufRepRegs.keys()) |k| try ks.append(gpa, @bitCast(k));
        std.mem.sort(f64, ks.items, {}, std.sort.asc(f64));
        for (ks.items, 0..) |k, i| {
            if (i > 0) try o.append(gpa, ',');
            try o.appendSlice(gpa, try tsN(gpa, k));
        }
    }
    try o.append(gpa, ']');
    if (an.bufProbeRanges) |pr| {
        try o.appendSlice(gpa, " probe=[");
        for (pr.items, 0..) |r, i| {
            if (i > 0) try o.append(gpa, ';');
            try o.print(gpa, "{s},{s},{s}", .{ try tsN(gpa, r.lo), try tsN(gpa, r.hi), try qstr(gpa, r.id) });
        }
        try o.append(gpa, ']');
    } else try o.appendSlice(gpa, " probe=nil");
    if (an.bufB2DeclRaw) |b2| {
        var ks: std.ArrayList(f64) = .empty;
        for (b2.keys()) |k| try ks.append(gpa, @bitCast(k));
        std.mem.sort(f64, ks.items, {}, std.sort.asc(f64));
        try o.appendSlice(gpa, " b2=[");
        for (ks.items, 0..) |k, i| {
            if (i > 0) try o.append(gpa, ' ');
            try o.print(gpa, "{s}:[", .{try tsN(gpa, k)});
            for (b2.get(@bitCast(k)).?.items, 0..) |sb, j| {
                if (j > 0) try o.append(gpa, ';');
                try o.print(gpa, "{s},{s},{s},{s}", .{ try qstr(gpa, sb.id), try tsN(gpa, sb.lo), try tsN(gpa, sb.hi), try qsOpt(gpa, sb.base) });
            }
            try o.append(gpa, ']');
        }
        try o.append(gpa, ']');
    } else try o.appendSlice(gpa, " b2=nil");
    const lessStr = struct {
        fn lt(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lt;
    {
        const ks = try gpa.dupe([]const u8, an.targeted.keys());
        std.mem.sort([]const u8, ks, {}, lessStr);
        try o.appendSlice(gpa, " targeted=[");
        for (ks, 0..) |k, i| {
            if (i > 0) try o.append(gpa, ',');
            try o.appendSlice(gpa, try qstr(gpa, k));
        }
        try o.append(gpa, ']');
    }
    {
        const ks = try gpa.dupe([]const u8, an.labelAt.keys());
        std.mem.sort([]const u8, ks, {}, lessStr);
        try o.appendSlice(gpa, " labelAt=[");
        for (ks, 0..) |k, i| {
            if (i > 0) try o.append(gpa, ',');
            try o.print(gpa, "{s}:{d}", .{ try qstr(gpa, k), an.labelAt.get(k).? });
        }
        try o.append(gpa, ']');
    }
    try o.appendSlice(gpa, " nextInsn=[");
    for (an.nextInsn, 0..) |x, i| {
        if (i > 0) try o.append(gpa, ',');
        try o.print(gpa, "{d}", .{x});
    }
    try o.append(gpa, ']');
    return o.items;
}

fn xframeRecord(gpa: Alloc, out: *std.ArrayList(u8), rec: []const u8) !void {
    const XF = s.x86_64_frame;
    var p: lvx.Parser = .{ .a = gpa, .s = rec };
    const v = try p.value();
    var c: capx.Conv = .{ .a = gpa };
    const conv = struct {
        fn run(cc: *capx.Conv, a: Alloc, vv: lvx.Value) !struct { body: []*Stmt, sd: ?*s.sig.Descriptor, regions: ?[]*s.frame.Region } {
            var body: std.ArrayList(*Stmt) = .empty;
            for (try vv.get("body").?.list(a)) |x| try body.append(a, try cc.stmt(x));
            const sd: ?*s.sig.Descriptor = if (vv.get("sigDesc")) |x| (if (x == .table) try cc.descriptor(x) else null) else null;
            var regions: ?[]*s.frame.Region = null;
            if (vv.get("regions")) |x| if (x == .table) {
                var rl: std.ArrayList(*s.frame.Region) = .empty;
                for (try x.list(a)) |r| try rl.append(a, try cc.region(r));
                regions = rl.items;
            };
            XF.sbCanon = null;
            if (vv.get("canon")) |x| if (x == .table) {
                XF.sbCanon = .empty;
                for (x.table.entries.items) |e| {
                    const ce = e.val;
                    try XF.sbCanon.?.put(a, e.key.name, .{
                        .lo = ce.get("lo").?.num,
                        .hi = ce.get("hi").?.num,
                        .fn_ = if (ce.get("fn")) |y| (if (y == .str) y.str else null) else null,
                        .sub = if (ce.get("sub")) |y| (if (y == .boolean) y.boolean else null) else null,
                        .st = if (ce.get("st")) |y| (if (y == .table) try cc.stmt(y) else null) else null,
                    });
                }
            };
            XF.sbResolving = if (vv.get("resolving")) |x| (x == .boolean and x.boolean) else false;
            return .{ .body = body.items, .sd = sd, .regions = regions };
        }
    };
    const in = conv.run(&c, gpa, v) catch |e| {
        if (e == error.UnknownField) {
            try out.print(gpa, "K capture: unmodeled field {s}\n", .{c.unknown.?});
            return;
        }
        return e;
    };
    const regs: ?[]const *s.frame.Region = if (in.regions) |r| r else null;
    if (XF.analyzeFrameTo(gpa, in.body, in.sd, regs, .prologue)) |an| {
        try out.print(gpa, "{s}\n", .{try dumpK1(gpa, an)});
    } else |e| {
        if (e != error.Sarcasm) return e;
        try out.print(gpa, "K err {s}\n", .{s.err.message});
    }
}

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const gpa = arena_state.allocator();
    const args = try std.process.argsAlloc(gpa);
    const stage = args[1];
    const list = try std.fs.cwd().readFileAlloc(gpa, args[2], 1 << 30);
    var out: std.ArrayList(u8) = .empty;
    var lines = std.mem.tokenizeScalar(u8, list, '\n');
    var nb: [64]u8 = undefined;
    if (std.mem.eql(u8, stage, "xframe")) {
        var rec_arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
        while (lines.next()) |l| {
            if (l.len < 2) continue;
            if (l[0] == 'F') {
                var p: lvx.Parser = .{ .a = gpa, .s = l[2..] };
                const fv = try p.value();
                s.err.setDefaultFile(fv.str);
                try out.print(gpa, "{s}\n", .{l});
            } else if (l[0] == 'A') {
                _ = rec_arena.reset(.retain_capacity);
                var tmp: std.ArrayList(u8) = .empty;
                try xframeRecord(rec_arena.allocator(), &tmp, l[2..]);
                try out.appendSlice(gpa, tmp.items);
            }
        }
        try std.fs.File.stdout().writeAll(out.items);
        return;
    }
    if (std.mem.eql(u8, stage, "framecalls")) {
        var rp: Replay = .{ .gpa = gpa };
        while (lines.next()) |l| try rp.line(&out, l);
        try std.fs.File.stdout().writeAll(out.items);
        return;
    }
    if (std.mem.eql(u8, stage, "lift")) try out.print(gpa, "yolo {s} {s} {s}\n", .{
        try dumpOp(gpa, try s.frame.yoloSlotReg(gpa, 3, 32)),
        try dumpOp(gpa, try s.frame.yoloSlotReg(gpa, 0, null)),
        try dumpOp(gpa, try s.frame.slotReg(gpa, -8, null)),
    });
    while (lines.next()) |line| {
        if (std.mem.eql(u8, stage, "detect")) {
            const text = try std.fs.cwd().readFileAlloc(gpa, line, 1 << 30);
            const r = try s.detect.detect(gpa, text);
            try out.print(gpa, "{s} {s}\n", .{ @tagName(r.arch), if (r.syntax) |x| @tagName(x) else "nil" });
        } else if (std.mem.eql(u8, stage, "sig")) {
            const ann = try gpa.alloc(u8, (line.len - 1) / 2);
            _ = try std.fmt.hexToBytes(ann, line[1..]); // "x" + hex
            const loc: s.err.Loc = .{ .file = "<in>", .line = 7 };
            if (s.sig.parseSignature(gpa, ann, loc)) |d| {
                if (s.sig.checkSupportedClasses(gpa, d, "call to 'f'", false, loc)) |_| {
                    try out.print(gpa, "ok {s} ", .{s.luau_number.tostring(&nb, d.signature)});
                    try writeList(&out, gpa, d.retTypes);
                    try writeList(&out, gpa, d.argTypes);
                    try out.print(gpa, " {d} {d} {} {}\n", .{ d.argWords, d.retWords, d.isVoid, d.retIsPtr });
                } else |e| switch (e) {
                    error.Sarcasm => try out.print(gpa, "err {s}\n", .{s.err.message}),
                    else => return e,
                }
            } else |e| switch (e) {
                error.Sarcasm => try out.print(gpa, "err {s}\n", .{s.err.message}),
                else => return e,
            }
        } else if (std.mem.eql(u8, stage, "parse")) {
            // as main runs it with --x86_64: the detected syntax, else AT&T
            const text = try std.fs.cwd().readFileAlloc(gpa, line, 1 << 30);
            const det = try s.detect.detect(gpa, text);
            const syntax: []const u8 = if (det.syntax) |x| @tagName(x) else "att";
            if (s.x86_64_parse.parseString(gpa, text, syntax, "<in>")) |stmts| {
                try out.print(gpa, "file {d}\n", .{stmts.len});
                for (stmts) |st| try out.print(gpa, "{s}\n", .{try dumpStmt(gpa, st)});
            } else |e| switch (e) {
                error.Sarcasm => try out.print(gpa, "file err {s}\n", .{s.err.message}),
                else => return e,
            }
        } else if (std.mem.eql(u8, stage, "isa")) {
            const text = try std.fs.cwd().readFileAlloc(gpa, line, 1 << 30);
            const det = try s.detect.detect(gpa, text);
            const syntax: []const u8 = if (det.syntax) |x| @tagName(x) else "att";
            if (s.x86_64_parse.parseString(gpa, text, syntax, "<in>")) |stmts| {
                var n: usize = 0;
                for (stmts) |st| n += @intFromBool(st.kind == .insn);
                try out.print(gpa, "file {d}\n", .{n});
                for (stmts) |st| if (st.kind == .insn) try out.print(gpa, "{s}\n", .{try isaDump(gpa, st)});
            } else |e| switch (e) {
                error.Sarcasm => try out.print(gpa, "file err\n", .{}),
                else => return e,
            }
        } else if (std.mem.eql(u8, stage, "lift")) {
            const text = try std.fs.cwd().readFileAlloc(gpa, line, 1 << 30);
            const det = try s.detect.detect(gpa, text);
            const syntax: []const u8 = if (det.syntax) |x| @tagName(x) else "att";
            if (s.x86_64_parse.parseString(gpa, text, syntax, "<in>")) |stmts| {
                try out.appendSlice(gpa, "file\n");
                try frameDump(gpa, &out, stmts);
                try liftDump(gpa, &out, stmts);
            } else |e| switch (e) {
                error.Sarcasm => try out.print(gpa, "file err\n", .{}),
                else => return e,
            }
        } else if (std.mem.eql(u8, stage, "isasyn")) {
            const in = try gpa.alloc(u8, (line.len - 1) / 2);
            _ = try std.fmt.hexToBytes(in, line[1..]); // "x" + hex
            const tab = std.mem.indexOfScalar(u8, in, '\t').?;
            if (s.x86_64_parse.parseString(gpa, in[tab + 1 ..], in[0..tab], "<in>")) |stmts| {
                var n: usize = 0;
                for (stmts) |st| if (st.kind == .insn) {
                    if (n > 0) try out.appendSlice(gpa, " || ");
                    try out.appendSlice(gpa, try isaDump(gpa, st));
                    n += 1;
                };
                try out.appendSlice(gpa, if (n > 0) "\n" else "none\n");
            } else |e| switch (e) {
                error.Sarcasm => try out.print(gpa, "perr {s}\n", .{s.err.message}),
                else => return e,
            }
        } else if (std.mem.eql(u8, stage, "fplookup")) {
            const st = try gpa.create(s.ir.Stmt);
            st.* = .{ .kind = .insn, .mnemonic = line, .raw = line, .syntax = "att", .file = "<in>", .line = 1 };
            const nf = s.x86_64_fp.narrowFamily(line);
            var sufb: [1]u8 = undefined;
            var suf: []const u8 = "nil";
            if (nf) |x| if (x.suf) |c| {
                sufb[0] = c;
                suf = &sufb;
            };
            try out.print(gpa, "{s} | nf={s}/{s}/{s} | {s}\n", .{
                try lkSum(gpa, try s.x86_64_fp.lookup(gpa, line)),
                if (nf) |x| @tagName(x.fam) else "nil",
                suf,
                if (nf) |x| x.base else "nil",
                try isaDump(gpa, st),
            });
        } else return error.UnknownStage;
    }
    try std.fs.File.stdout().writeAll(out.items);
}
