// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//! GNU-as numeric local labels (`1:`, `1f`, `1b`), renamed to unique private symbols (a port of
//! projects/sarcasm/sarcasm/numlabel.luau, Fil-C 0.687).

const std = @import("std");
const err = @import("err.zig");
const ir = @import("ir.zig");

fn isNumericName(name: []const u8) bool {
    if (name.len == 0) return false;
    for (name) |c| if (!std.ascii.isDigit(c)) return false;
    return true;
}

const Def = struct { pos: usize, num: []const u8, uniq: []const u8 };

/// resolveRef: the next (f) / most recent previous (b) definition of `num`.
fn resolveRef(defs: []const Def, i: usize, num: []const u8, dir: []const u8) ?Def {
    if (std.mem.eql(u8, dir, "f")) {
        for (defs) |d| if (d.pos > i and std.mem.eql(u8, d.num, num)) return d;
    } else {
        var k = defs.len;
        while (k > 0) {
            k -= 1;
            if (defs[k].pos < i and std.mem.eql(u8, defs[k].num, num)) return defs[k];
        }
    }
    return null;
}

/// `^(%d+)([fb])$`.
fn splitRef(s: []const u8) ?struct { num: []const u8, dir: []const u8 } {
    if (s.len < 2) return null;
    const d = s[s.len - 1];
    if (d != 'f' and d != 'b') return null;
    if (!isNumericName(s[0 .. s.len - 1])) return null;
    return .{ .num = s[0 .. s.len - 1], .dir = s[s.len - 1 ..] };
}

fn rewriteOperand(alloc: std.mem.Allocator, defs: []const Def, i: usize, op: *ir.Operand, st: *const ir.Stmt) err.Error!void {
    var text: ?[]const u8 = null;
    var num: []const u8 = "";
    var dir: []const u8 = "";
    if (op.kind == .numref) {
        text = op.text;
        num = op.refNum.?;
        dir = op.dir.?;
    } else if (op.kind == .mem) {
        if (op.dispSym) |ds| if (splitRef(ds)) |r| {
            text = ds;
            num = r.num;
            dir = r.dir;
        };
    }
    const t = text orelse return;
    const d = resolveRef(defs, i, num, dir) orelse
        return err.at(st.loc(), try std.fmt.allocPrint(alloc, "unresolved numeric label reference '{s}'", .{t}));
    if (op.kind == .numref) {
        op.kind = .sym;
        op.text = d.uniq;
        op.refNum = null;
        op.dir = null;
    } else op.dispSym = d.uniq;
}

/// numlabel.resolve. `out` positions are 1-based in Luau; only their order matters here.
pub fn resolve(alloc: std.mem.Allocator, out: []const *ir.Stmt) err.Error!void {
    var has = false;
    gate: for (out) |st| {
        if (st.kind == .label and isNumericName(st.name.?)) {
            has = true;
            break;
        }
        if (st.kind == .insn) for (st.operands.items) |op| {
            if (op.kind == .numref) {
                has = true;
                break :gate;
            }
            if (op.kind == .mem) if (op.dispSym) |ds| if (splitRef(ds) != null) {
                has = true;
                break :gate;
            };
        };
    }
    if (!has) return;
    var defs: std.ArrayList(Def) = .empty;
    var counter: usize = 0;
    for (out, 0..) |st, i| {
        if (st.kind == .label and isNumericName(st.name.?)) {
            counter += 1;
            const uniq = try std.fmt.allocPrint(alloc, ".Lsarcasm_num{d}", .{counter});
            try defs.append(alloc, .{ .pos = i + 1, .num = st.name.?, .uniq = uniq });
            st.name = uniq;
        }
    }
    for (out, 0..) |st, i| {
        if (st.kind == .insn) for (st.operands.items) |op| try rewriteOperand(alloc, defs.items, i + 1, op, st);
    }
}
