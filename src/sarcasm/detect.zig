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
//! Auto-detection of the target architecture and, for x86_64, the syntax (a port of
//! projects/sarcasm/sarcasm/detect.luau, Fil-C 0.687): the same sanitising and the same Lua
//! patterns, in the same order, through src/sarcasm/lua_pattern.zig.

const std = @import("std");
const lp = @import("lua_pattern.zig");

pub const Arch = enum { arm64, x86_64 };
pub const Syntax = enum { att, intel };
pub const Result = struct { arch: Arch, syntax: ?Syntax };

/// detect.sanitize: comments and string contents blanked out, newlines kept.
pub fn sanitize(alloc: std.mem.Allocator, text: []const u8) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    var state: enum { code, str, line, block } = .code;
    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        const c = text[i];
        const d: u8 = if (i + 1 < text.len) text[i + 1] else 0;
        switch (state) {
            .code => {
                if (c == '"') {
                    state = .str;
                } else if (c == '/' and d == '/') {
                    state = .line;
                    i += 1;
                } else if (c == '/' and d == '*') {
                    state = .block;
                    i += 1;
                } else if (c == '#') {
                    state = .line;
                } else try out.append(alloc, c);
            },
            .str => {
                if (c == '\\') {
                    i += 1;
                } else if (c == '"') {
                    state = .code;
                } else if (c == '\n') {
                    state = .code;
                    try out.append(alloc, c);
                }
            },
            .line => if (c == '\n') {
                state = .code;
                try out.append(alloc, c);
            },
            .block => {
                if (c == '*' and d == '/') {
                    state = .code;
                    i += 1;
                } else if (c == '\n') try out.append(alloc, c);
            },
        }
    }
    return out.items;
}

fn has(alloc: std.mem.Allocator, s: []const u8, p: []const u8) !bool {
    return (lp.find(alloc, s, p, 1, false) catch return error.OutOfMemory) != null;
}

/// detect.detect.
pub fn detect(alloc: std.mem.Allocator, raw: []const u8) !Result {
    const text = try sanitize(alloc, raw);
    if (try has(alloc, text, "%.intel_syntax")) return .{ .arch = .x86_64, .syntax = .intel };
    if (try has(alloc, text, "%.att_syntax")) return .{ .arch = .x86_64, .syntax = .att };
    if (try has(alloc, text, "%.arch%s+armv8")) return .{ .arch = .arm64, .syntax = null };
    if (try has(alloc, text, "%%r[a-z0-9]") or try has(alloc, text, "%%e[a-z][a-z]") or try has(alloc, text, "%%rip") or
        (lp.find(alloc, text, "endbr64", 1, true) catch return error.OutOfMemory) != null)
        return .{ .arch = .x86_64, .syntax = .att };

    const anchored = try std.mem.concat(alloc, u8, &.{ "\n", text });
    var att = false;
    for ([_][]const u8{ "%%xmm%d", "%%ymm%d", "%%zmm%d", "%%k[0-7]", "%%st", "\n[ \t]*movz[bwlq][bwlq]%f[^%w:]", "\n[ \t]*movs[bwlq][bwlq]%f[^%w:]", "\n[ \t]*movabs%f[^%w:]" }) |p| {
        if (!att and try has(alloc, anchored, p)) att = true;
    }
    for ([_][]const u8{ "cltq", "cdqe", "cqto", "cltd", "cwde", "cbtw", "cwtl", "cwtd", "cdq", "cwd", "cbw" }) |ext| {
        if (!att and try has(alloc, anchored, try std.mem.concat(alloc, u8, &.{ "\n[ \t]*", ext, "%f[^%w:]" }))) att = true;
    }
    for ([_][]const u8{ "mov", "add", "sub", "and", "or", "xor", "cmp", "test", "lea", "shl", "shr", "sar", "sal", "imul", "neg", "not", "inc", "dec", "adc", "sbb", "push", "pop", "xadd", "div", "idiv", "mul" }) |m| {
        if (!att and try has(alloc, anchored, try std.mem.concat(alloc, u8, &.{ "\n[ \t]*", m, "q%f[^%w:]" }))) att = true;
    }
    for ([_][]const u8{ "\n%s*rep%s", "\n%s*repe%s", "\n%s*repz%s", "\n%s*repne%s", "\n%s*repnz%s", "\n%s*lock%s" }) |p| {
        if (!att and try has(alloc, anchored, p)) att = true;
    }
    if (att) return .{ .arch = .x86_64, .syntax = .att };

    for ([_][]const u8{ "%f[%w]xmm%d%f[^%w_:]", "%f[%w]ymm%d%f[^%w_:]", "%f[%w]zmm%d%f[^%w_:]", "%f[%w]k[0-7]%f[^%w_:]" }) |p|
        if (try has(alloc, text, p)) return .{ .arch = .x86_64, .syntax = .intel };

    if (try has(alloc, text, " PTR ") or try has(alloc, text, "%[")) {
        if (try has(alloc, text, "[ \t,%[]r[abcds][xip][ \t,%]%+%-*]") or try has(alloc, text, "[ \t,%[]r%d%d?[ \t,%]%+%-*]") or try has(alloc, text, " PTR "))
            return .{ .arch = .x86_64, .syntax = .intel };
    }
    if (try has(alloc, text, "[ \t,]r[abcds][xip][ \t,\n]") or try has(alloc, text, "[ \t,]e[abcds][xip][ \t,\n]"))
        return .{ .arch = .x86_64, .syntax = .intel };
    return .{ .arch = .arm64, .syntax = null };
}
