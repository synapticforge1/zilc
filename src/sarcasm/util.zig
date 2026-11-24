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
//! Small Luau idioms the sarcasm passes share: string.lower, string.match through the ported Lua
//! matcher (upstream's patterns, verbatim), string concatenation of a number (luai_num2str, the
//! same text as tostring), and a fresh operand table.

const std = @import("std");
const err = @import("err.zig");
const ir = @import("ir.zig");
const lp = @import("lua_pattern.zig");
const ln = @import("luau_number.zig");

const Allocator = std.mem.Allocator;
const E = err.Error;

/// string.lower (C locale: ASCII only).
pub fn lower(alloc: Allocator, s: []const u8) E![]u8 {
    const o = try alloc.dupe(u8, s);
    for (o) |*c| c.* = std.ascii.toLower(c.*);
    return o;
}

/// string.match(s, p): the captures (or the whole match), or null.
pub fn match(alloc: Allocator, s: []const u8, p: []const u8) E!?[]lp.Capture {
    return lp.matchStr(alloc, s, p, 1) catch |e| switch (e) {
        error.OutOfMemory => return error.OutOfMemory,
        else => @panic("sarcasm: an upstream pattern failed to compile"),
    };
}

/// string.match(s, p) ~= nil.
pub fn matches(alloc: Allocator, s: []const u8, p: []const u8) E!bool {
    return (try match(alloc, s, p)) != null;
}

/// The first capture of string.match(s, p) as a string, or null.
pub fn match1(alloc: Allocator, s: []const u8, p: []const u8) E!?[]const u8 {
    const c = try match(alloc, s, p) orelse return null;
    return c[0].str;
}

/// string.gsub(s, p, repl) (the first result).
pub fn gsub(alloc: Allocator, s: []const u8, p: []const u8, repl: []const u8) E![]const u8 {
    const r = lp.gsub(alloc, s, p, .{ .str = repl }, null) catch |e| switch (e) {
        error.OutOfMemory => return error.OutOfMemory,
        else => @panic("sarcasm: an upstream pattern failed to compile"),
    };
    return r.text;
}

/// A number as `..` and tostring render it.
pub fn num(alloc: Allocator, n: f64) E![]const u8 {
    var b: [64]u8 = undefined;
    return alloc.dupe(u8, ln.tostring(&b, n));
}

pub fn fmt(alloc: Allocator, comptime f: []const u8, args: anytype) E![]u8 {
    return std.fmt.allocPrint(alloc, f, args);
}

pub fn newOp(alloc: Allocator, v: ir.Operand) E!*ir.Operand {
    const p = try alloc.create(ir.Operand);
    p.* = v;
    return p;
}

pub fn eql(a: ?[]const u8, b: []const u8) bool {
    return if (a) |x| std.mem.eql(u8, x, b) else false;
}

/// `x in {…}` for a set of string keys.
pub fn in(x: []const u8, comptime set: []const []const u8) bool {
    inline for (set) |k| if (std.mem.eql(u8, x, k)) return true;
    return false;
}
