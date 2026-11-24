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
