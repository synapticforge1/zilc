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

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const gpa = arena_state.allocator();
    const args = try std.process.argsAlloc(gpa);
    const stage = args[1];
    const list = try std.fs.cwd().readFileAlloc(gpa, args[2], 1 << 30);
    var out: std.ArrayList(u8) = .empty;
    var lines = std.mem.tokenizeScalar(u8, list, '\n');
    var nb: [64]u8 = undefined;
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
