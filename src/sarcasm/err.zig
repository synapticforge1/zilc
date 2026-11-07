// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//! sarcasm's diagnostics (a port of projects/sarcasm/sarcasm/err.luau, Fil-C 0.687; the port's
//! map: cmem/sarcasm-port.md). Every rejection is `sarcasm: <file>:<line>: <message>` (or without a
//! location); upstream raises it with `error(msg, 0)`, here it is stored in `message` and the
//! caller gets `error.Sarcasm`, which `main` prints as upstream's does. The module state below is
//! upstream's (reset per input by the driver).

const std = @import("std");

pub const Error = error{ Sarcasm, OutOfMemory };

/// A statement's location: what `err.locStr` reads from a statement table (`.file`, `.line`).
pub const Loc = struct { file: ?[]const u8 = null, line: ?u32 = null };

/// The raised message (valid until the next raise).
pub var message: []const u8 = "";
var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);

/// Fallback file for a statement with a line but no file (set by main: the input path).
var default_file: ?[]const u8 = null;
/// The parser's dynamic location (beginParse / atParseLine / endParse).
var parse_file: ?[]const u8 = null;
var parse_line: ?u32 = null;

pub fn setDefaultFile(f: ?[]const u8) void {
    default_file = f;
}
pub fn beginParse(f: ?[]const u8) void {
    parse_file = f;
    parse_line = null;
}
pub fn atParseLine(n: ?u32) void {
    parse_line = n;
}
pub fn endParse() void {
    parse_file = null;
    parse_line = null;
}

/// err.locStr: "file:line", or null when no location can be derived.
pub fn locStr(alloc: std.mem.Allocator, st: ?Loc) Error!?[]const u8 {
    const s = st orelse return null;
    const f = s.file orelse default_file orelse return null;
    const l = s.line orelse return null;
    return try std.fmt.allocPrint(alloc, "{s}:{d}", .{ f, l });
}

fn raise(comptime fmt: []const u8, args: anytype) Error {
    message = try std.fmt.allocPrint(arena_state.allocator(), fmt, args);
    return error.Sarcasm;
}

/// err.at: a rejection located at statement `st` (unlocated when it has none).
pub fn at(st: ?Loc, msg: []const u8) Error {
    if (try locStr(arena_state.allocator(), st)) |loc| return raise("sarcasm: {s}: {s}", .{ loc, msg });
    return raise("sarcasm: {s}", .{msg});
}

/// err.here: a rejection at the parser's current line.
pub fn here(msg: []const u8) Error {
    if (parse_file) |f| if (parse_line) |l| return raise("sarcasm: {s}:{d}: {s}", .{ f, l, msg });
    return raise("sarcasm: {s}", .{msg});
}

/// err.plain: a rejection with no location.
pub fn plain(msg: []const u8) Error {
    return raise("sarcasm: {s}", .{msg});
}
