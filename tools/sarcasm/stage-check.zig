// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! The Zig side of tools/sarcasm/check-stages.ts: one stage of the sarcasm port over a list of
//! inputs, dumped in the same canonical text the Luau harness prints for upstream's modules.
//!
//!   stage-check detect <files.txt>     each line a path: "arch syntax|nil"
//!   stage-check sig <annotations.hex>  each line a hex string: "ok …" or "err <message>"

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
    return d.done();
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
            const ann = try gpa.alloc(u8, line.len / 2);
            _ = try std.fmt.hexToBytes(ann, line);
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
        } else return error.UnknownStage;
    }
    try std.fs.File.stdout().writeAll(out.items);
}
