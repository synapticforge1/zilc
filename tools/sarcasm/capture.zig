// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! Captured upstream values (luau_value.zig) -> the port's types: statements and operands
//! (identity kept: one Luau table, one Zig object), sig descriptors, regions. A key the port does
//! not model is an ERROR naming it, never silently dropped.

const std = @import("std");
const s = @import("sarcasm");
const lv = @import("luau_value.zig");

const Alloc = std.mem.Allocator;
const Value = lv.Value;

const op_num = [_][]const u8{ "width", "value", "scale", "dispVal", "size", "bcastN" };
const op_str = [_][]const u8{ "name", "pseudo", "text", "reloc", "dir", "dispSym", "dispReloc", "deco", "fixedReg" };
const op_bool = [_][]const u8{ "indirect", "absAddr", "implicit", "isSlot", "retReg", "argReg", "resultReg" };
const st_num = [_][]const u8{ "opsize", "b2clone", "localClone" };
const st_str = [_][]const u8{ "file", "annotation", "name", "args", "text", "mnemonic", "raw", "syntax", "repPrefix" };
const st_bool = [_][]const u8{ "lockPrefix", "dotAlloca", "crossJumpEntry", "localCloneEntry", "tailCall", "tailRet" };

fn in(k: []const u8, comptime set: []const []const u8) bool {
    inline for (set) |x| if (std.mem.eql(u8, k, x)) return true;
    return false;
}

pub const Conv = struct {
    a: Alloc,
    ops: std.AutoHashMapUnmanaged(u32, *s.ir.Operand) = .empty,
    stmts: std.AutoHashMapUnmanaged(u32, *s.ir.Stmt) = .empty,
    unknown: ?[]const u8 = null,

    fn bad(c: *Conv, what: []const u8, k: []const u8) error{UnknownField} {
        c.unknown = std.fmt.allocPrint(c.a, "{s}.{s}", .{ what, k }) catch "?";
        return error.UnknownField;
    }
    fn n(v: Value) ?f64 {
        return if (v == .num) v.num else null;
    }
    fn b(v: Value) ?bool {
        return if (v == .boolean) v.boolean else null;
    }
    fn st_(v: Value) ?[]const u8 {
        return if (v == .str) v.str else null;
    }
    fn strList(c: *Conv, v: Value) ![]const []const u8 {
        var o: std.ArrayList([]const u8) = .empty;
        for (try v.list(c.a)) |x| try o.append(c.a, x.str);
        return o.items;
    }

    pub fn operand(c: *Conv, v: Value) anyerror!*s.ir.Operand {
        const t = v.table;
        if (c.ops.get(t.id)) |o| return o;
        const o = try c.a.create(s.ir.Operand);
        o.* = .{ .kind = .reg };
        try c.ops.put(c.a, t.id, o);
        var numVal: ?Value = null;
        for (t.entries.items) |e| {
            const k = e.key.name;
            const x = e.val;
            if (std.mem.eql(u8, k, "kind")) {
                o.kind = std.meta.stringToEnum(s.ir.OpKind, x.str) orelse return c.bad("operand.kind", x.str);
            } else if (std.mem.eql(u8, k, "rc")) {
                o.rc = std.meta.stringToEnum(s.ir.RegClass, x.str) orelse return c.bad("operand.rc", x.str);
            } else if (std.mem.eql(u8, k, "num")) {
                numVal = x;
            } else if (std.mem.eql(u8, k, "base")) {
                o.base = try c.operand(x);
            } else if (std.mem.eql(u8, k, "index")) {
                o.index = try c.operand(x);
            } else if (in(k, &op_num)) {
                inline for (op_num) |f| if (std.mem.eql(u8, k, f)) {
                    @field(o, f) = n(x);
                };
            } else if (in(k, &op_str)) {
                inline for (op_str) |f| if (std.mem.eql(u8, k, f)) {
                    @field(o, f) = st_(x);
                };
            } else if (in(k, &op_bool)) {
                inline for (op_bool) |f| if (std.mem.eql(u8, k, f)) {
                    @field(o, f) = b(x);
                };
            } else return c.bad("operand", k);
        }
        // numref's num is the label's digits (a string), a register's its number
        if (numVal) |x| {
            if (x == .str) o.refNum = x.str else o.num = x.num;
        }
        return o;
    }

    pub fn stmt(c: *Conv, v: Value) anyerror!*s.ir.Stmt {
        const t = v.table;
        if (c.stmts.get(t.id)) |x| return x;
        const st = try c.a.create(s.ir.Stmt);
        st.* = .{ .kind = .blank };
        try c.stmts.put(c.a, t.id, st);
        for (t.entries.items) |e| {
            const k = e.key.name;
            const x = e.val;
            if (std.mem.eql(u8, k, "kind")) {
                st.kind = std.meta.stringToEnum(s.ir.StmtKind, x.str) orelse return c.bad("stmt.kind", x.str);
            } else if (std.mem.eql(u8, k, "line")) {
                st.line = @intFromFloat(x.num);
            } else if (std.mem.eql(u8, k, "operands")) {
                for (try x.list(c.a)) |o| try st.operands.append(c.a, try c.operand(o));
            } else if (std.mem.eql(u8, k, "localCall")) {
                st.localCall = .{ .entry = x.get("entry").?.str, .clone = if (x.get("clone")) |y| n(y) else null, .cont = if (x.get("cont")) |y| st_(y) else null };
            } else if (std.mem.eql(u8, k, "localRet")) {
                st.localRet = .{ .conts = try c.strList(x.get("conts").?), .clone = if (x.get("clone")) |y| n(y) else null, .entry = if (x.get("entry")) |y| st_(y) else null };
            } else if (std.mem.eql(u8, k, "cloneRet")) {
                st.cloneRet = .{ .entry = x.get("entry").?.str };
            } else if (std.mem.eql(u8, k, "stackBufAnno")) {
                st.stackBufAnno = .{ .id = x.get("id").?.str, .short = (x.get("short") orelse Value{ .boolean = false }).boolean, .base = if (x.get("base")) |y| st_(y) else null, .lo = if (x.get("lo")) |y| n(y) else null, .hi = if (x.get("hi")) |y| n(y) else null };
            } else if (in(k, &st_num)) {
                inline for (st_num) |f| if (std.mem.eql(u8, k, f)) {
                    @field(st, f) = n(x);
                };
            } else if (in(k, &st_str)) {
                inline for (st_str) |f| if (std.mem.eql(u8, k, f)) {
                    @field(st, f) = st_(x);
                };
            } else if (in(k, &st_bool)) {
                inline for (st_bool) |f| if (std.mem.eql(u8, k, f)) {
                    @field(st, f) = b(x);
                };
            } else return c.bad("stmt", k);
        }
        return st;
    }

    pub fn descriptor(c: *Conv, v: Value) !*s.sig.Descriptor {
        const d = try c.a.create(s.sig.Descriptor);
        var rt: std.ArrayList(u8) = .empty;
        var at_: std.ArrayList(u8) = .empty;
        for (try v.get("retTypes").?.list(c.a)) |x| try rt.append(c.a, @intFromFloat(x.num));
        for (try v.get("argTypes").?.list(c.a)) |x| try at_.append(c.a, @intFromFloat(x.num));
        d.* = .{
            .retTypes = rt.items,
            .argTypes = at_.items,
            .signature = v.get("signature").?.num,
            .argWords = @intFromFloat(v.get("argWords").?.num),
            .retWords = @intFromFloat(v.get("retWords").?.num),
            .isVoid = v.get("isVoid").?.boolean,
            .retIsPtr = v.get("retIsPtr").?.boolean,
        };
        for (v.table.entries.items) |e| {
            const k = e.key.name;
            if (!(std.mem.eql(u8, k, "retTypes") or std.mem.eql(u8, k, "argTypes") or std.mem.eql(u8, k, "signature") or std.mem.eql(u8, k, "argWords") or
                std.mem.eql(u8, k, "retWords") or std.mem.eql(u8, k, "isVoid") or std.mem.eql(u8, k, "retIsPtr"))) return c.bad("sigDesc", k);
        }
        return d;
    }

    pub fn region(c: *Conv, v: Value) !*s.frame.Region {
        const r = try c.a.create(s.frame.Region);
        r.* = .{ .base = 0, .size = 0 };
        for (v.table.entries.items) |e| {
            const k = e.key.name;
            const x = e.val;
            if (std.mem.eql(u8, k, "base")) {
                r.base = n(x) orelse return c.bad("region.base", "non-number");
            } else if (std.mem.eql(u8, k, "size")) {
                r.size = x.num;
            } else if (std.mem.eql(u8, k, "align")) {
                r.@"align" = n(x);
            } else if (std.mem.eql(u8, k, "anchored")) {
                r.anchored = b(x);
            } else if (std.mem.eql(u8, k, "frameRegion")) {
                r.frameRegion = b(x);
            } else return c.bad("region", k);
        }
        return r;
    }
};
