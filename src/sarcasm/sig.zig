// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//! Fil-C signature encoding and the parsing of `;!` function-signature annotations (a port of
//! projects/sarcasm/sarcasm/sig.luau, Fil-C 0.687). Numbers stay f64, as upstream's are: the
//! signature `1 + Ret + 133·Arg` is printed by tostring in symbol names.

const std = @import("std");
const err = @import("err.zig");
const lp = @import("lua_pattern.zig");

pub const TYPE_INT: u8 = 0;
pub const TYPE_FLOAT: u8 = 1;
pub const TYPE_DOUBLE: u8 = 2;
pub const TYPE_LONGDOUBLE: u8 = 3;
pub const TYPE_VEC4: u8 = 4;
pub const TYPE_VEC5: u8 = 5;
pub const TYPE_VEC6: u8 = 6;
pub const TYPE_PTR: u8 = 7;

/// INTEGER_WORDS.
const integer_words = [_][]const u8{
    "int",      "long",     "short",     "char",      "signed",  "unsigned", "bool",    "_bool",   "enum",
    "size_t",   "ssize_t",  "ptrdiff_t", "int8_t",    "int16_t", "int32_t",  "int64_t", "uint8_t", "uint16_t",
    "uint32_t", "uint64_t", "intptr_t",  "uintptr_t",
};

fn isIntegerWord(w: []const u8) bool {
    for (integer_words) |x| if (std.mem.eql(u8, x, w)) return true;
    return false;
}

/// string.lower (C locale).
fn lower(alloc: std.mem.Allocator, s: []const u8) ![]u8 {
    const o = try alloc.dupe(u8, s);
    for (o) |*c| c.* = std.ascii.toLower(c.*);
    return o;
}

fn reject(st: ?err.Loc, msg: []const u8) err.Error {
    return if (st != null) err.at(st, msg) else err.plain(msg);
}

/// classifyType: a C type token's class; null for void or empty.
pub fn classifyType(alloc: std.mem.Allocator, tok_in: []const u8, st: ?err.Loc) err.Error!?u8 {
    var tok = (lp.gsub(alloc, tok_in, "%s+", .{ .str = " " }, null) catch return error.OutOfMemory).text;
    tok = (lp.gsub(alloc, tok, "^%s*(.-)%s*$", .{ .str = "%1" }, null) catch return error.OutOfMemory).text;
    const low = try lower(alloc, tok);
    if (std.mem.eql(u8, low, "void") or low.len == 0) return null;
    if (std.mem.eql(u8, low, "ptr") or std.mem.indexOfScalar(u8, low, '*') != null) return TYPE_PTR;
    if (std.mem.eql(u8, low, "float")) return TYPE_FLOAT;
    if (std.mem.eql(u8, low, "double")) return TYPE_DOUBLE;
    if (std.mem.eql(u8, low, "long double")) return TYPE_LONGDOUBLE;
    if (std.mem.eql(u8, low, "vec4")) return TYPE_VEC4;
    if (std.mem.eql(u8, low, "vec5")) return TYPE_VEC5;
    if (std.mem.eql(u8, low, "vec6")) return TYPE_VEC6;
    var g = lp.gmatch(alloc, low, "%S+");
    while (g.next() catch return error.OutOfMemory) |caps| {
        if (!isIntegerWord(caps[0].str)) return reject(st, try std.fmt.allocPrint(alloc, "unknown type '{s}' in signature annotation", .{tok}));
    }
    return TYPE_INT;
}

/// encodeList: Σ 11^(i-1)·(1 + t_i), in doubles.
fn encodeList(types: []const u8) f64 {
    var acc: f64 = 0;
    var mult: f64 = 1;
    for (types) |t| {
        acc += mult * (1 + @as(f64, @floatFromInt(t)));
        mult *= 11;
    }
    return acc;
}

/// splitArgs: "a, b, c" at top-level commas; a last piece of only whitespace is dropped.
fn splitArgs(alloc: std.mem.Allocator, s: []const u8) ![][]const u8 {
    var out: std.ArrayList([]const u8) = .empty;
    var depth: i32 = 0;
    var start: usize = 0;
    for (s, 0..) |c, i| {
        if (c == '(') depth += 1 else if (c == ')') depth -= 1 else if (c == ',' and depth == 0) {
            try out.append(alloc, s[start..i]);
            start = i + 1;
        }
    }
    const last = s[start..];
    for (last) |c| if (!(c == ' ' or (c >= '\t' and c <= '\r'))) {
        try out.append(alloc, last);
        break;
    };
    return out.items;
}

pub const Descriptor = struct {
    retTypes: []const u8,
    argTypes: []const u8,
    signature: f64,
    argWords: usize,
    retWords: usize,
    isVoid: bool,
    retIsPtr: bool,
};

/// sig.parseSignature: "RET(ARGS)".
pub fn parseSignature(alloc: std.mem.Allocator, ann: []const u8, st: ?err.Loc) err.Error!Descriptor {
    const caps = (lp.matchStr(alloc, ann, "^%s*(.-)%s*%((.*)%)%s*$", 1) catch return error.OutOfMemory) orelse
        return reject(st, try std.fmt.allocPrint(alloc, "cannot parse function signature annotation: {s}", .{ann}));
    var ret: std.ArrayList(u8) = .empty;
    if (try classifyType(alloc, caps[0].str, st)) |rc| try ret.append(alloc, rc);
    var args: std.ArrayList(u8) = .empty;
    for (try splitArgs(alloc, caps[1].str)) |a| if (try classifyType(alloc, a, st)) |c| try args.append(alloc, c);
    const r = encodeList(ret.items);
    const a = encodeList(args.items);
    return .{
        .retTypes = ret.items,
        .argTypes = args.items,
        .signature = 1 + r + 133 * a,
        .argWords = args.items.len,
        .retWords = ret.items.len,
        .isVoid = ret.items.len == 0,
        .retIsPtr = ret.items.len > 0 and ret.items[0] == TYPE_PTR,
    };
}

/// CLASS_NAME.
fn className(t: u8) ?[]const u8 {
    return switch (t) {
        TYPE_INT => "integer",
        TYPE_FLOAT => "float",
        TYPE_DOUBLE => "double",
        TYPE_LONGDOUBLE => "long double",
        TYPE_PTR => "ptr",
        TYPE_VEC4 => "vec4",
        TYPE_VEC5 => "vec5",
        TYPE_VEC6 => "vec6",
        else => null,
    };
}

pub fn isFpClass(t: u8) bool {
    return t == TYPE_FLOAT or t == TYPE_DOUBLE;
}

pub fn fpWidthBytes(t: u8) ?u8 {
    return if (t == TYPE_FLOAT) 4 else if (t == TYPE_DOUBLE) 8 else null;
}

/// sig.checkSupportedClasses (x86_64 unless `arm64`).
pub fn checkSupportedClasses(alloc: std.mem.Allocator, sd: Descriptor, where: ?[]const u8, arm64: bool, st: ?err.Loc) err.Error!void {
    const prefix = if (where) |w| try std.fmt.allocPrint(alloc, "{s}: ", .{w}) else "";
    const arch = if (arm64) "arm64" else "x86_64";
    for ([_][]const u8{ sd.retTypes, sd.argTypes }) |list| for (list) |t| {
        if (t == TYPE_INT or t == TYPE_PTR or t == TYPE_FLOAT or t == TYPE_DOUBLE) continue;
        if (t == TYPE_LONGDOUBLE) return reject(st, try std.fmt.allocPrint(alloc, "{s}only float and double floating-point types are supported in signatures on {s}: long double", .{ prefix, arch }));
        const name = className(t) orelse try std.fmt.allocPrint(alloc, "type class {d}", .{t});
        return reject(st, try std.fmt.allocPrint(alloc, "{s}vector types are not supported in signatures on {s} (SIMD signatures are not supported): {s}", .{ prefix, arch, name }));
    };
}

/// sig.PTR_ANNOTATIONS.
pub fn isPtrAnnotation(s: []const u8) bool {
    for ([_][]const u8{ "load ptr", "store ptr", "load store ptr", "atomic ptr", "atomic load ptr", "atomic store ptr", "atomic load store ptr" }) |x|
        if (std.mem.eql(u8, x, s)) return true;
    return false;
}
