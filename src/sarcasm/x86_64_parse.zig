// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//! The x86_64 assembly parser, AT&T and Intel syntax (a port of lines 1–946 of
//! projects/sarcasm/sarcasm/x86_64_parse.luau, Fil-C 0.687: parseString and everything it uses;
//! the `.byte` machine-code decoder, decodeByteInsns, is ported separately). Every string.match
//! goes through the ported Lua matcher with upstream's pattern, and every tonumber through the
//! ported luaO_str2d, so what is accepted, and how, is upstream's.

const std = @import("std");
const err = @import("err.zig");
const ir = @import("ir.zig");
const lp = @import("lua_pattern.zig");
const ln = @import("luau_number.zig");
const numlabel = @import("numlabel.zig");

const Allocator = std.mem.Allocator;
const E = err.Error;

// ---- helpers: C isspace, trim, string.lower, string.match
fn isspace(c: u8) bool {
    return c == ' ' or (c >= '\t' and c <= '\r');
}
/// trim: gsub(s, "^%s*(.-)%s*$", "%1").
fn trim(s: []const u8) []const u8 {
    var a: usize = 0;
    var b = s.len;
    while (a < b and isspace(s[a])) a += 1;
    while (b > a and isspace(s[b - 1])) b -= 1;
    return s[a..b];
}
fn lower(alloc: Allocator, s: []const u8) E![]u8 {
    const o = try alloc.dupe(u8, s);
    for (o) |*c| c.* = std.ascii.toLower(c.*);
    return o;
}
/// string.match(s, p [, init]): the captures (or the whole match), or null.
fn match(alloc: Allocator, s: []const u8, p: []const u8) E!?[]lp.Capture {
    return lp.matchStr(alloc, s, p, 1) catch |e| switch (e) {
        error.OutOfMemory => return error.OutOfMemory,
        else => @panic("sarcasm: an upstream pattern failed to compile"),
    };
}
fn str(c: lp.Capture) []const u8 {
    return c.str;
}
fn hasPlain(s: []const u8, needle: []const u8) bool {
    return std.mem.indexOf(u8, s, needle) != null;
}
fn fmt(alloc: Allocator, comptime f: []const u8, args: anytype) E![]u8 {
    return std.fmt.allocPrint(alloc, f, args);
}
fn newOp(alloc: Allocator, v: ir.Operand) E!*ir.Operand {
    const p = try alloc.create(ir.Operand);
    p.* = v;
    return p;
}

// ---- registers
const Reg = struct { num: f64, width: f64 };
const q_names = [_][]const u8{ "rax", "rcx", "rdx", "rbx", "rsp", "rbp", "rsi", "rdi", "r8", "r9", "r10", "r11", "r12", "r13", "r14", "r15" };
const d_names = [_][]const u8{ "eax", "ecx", "edx", "ebx", "esp", "ebp", "esi", "edi", "r8d", "r9d", "r10d", "r11d", "r12d", "r13d", "r14d", "r15d" };
const w_names = [_][]const u8{ "ax", "cx", "dx", "bx", "sp", "bp", "si", "di", "r8w", "r9w", "r10w", "r11w", "r12w", "r13w", "r14w", "r15w" };
const b_names = [_][]const u8{ "al", "cl", "dl", "bl", "spl", "bpl", "sil", "dil", "r8b", "r9b", "r10b", "r11b", "r12b", "r13b", "r14b", "r15b" };

/// REG[name] (with the parse-only high-byte aliases ah/ch/dh/bh).
fn regLookup(low: []const u8) ?Reg {
    for ([_]struct { names: []const []const u8, width: f64 }{ .{ .names = &q_names, .width = 64 }, .{ .names = &d_names, .width = 32 }, .{ .names = &w_names, .width = 16 }, .{ .names = &b_names, .width = 8 } }) |set| {
        for (set.names, 0..) |n, i| if (std.mem.eql(u8, n, low)) return .{ .num = @floatFromInt(i), .width = set.width };
    }
    for ([_][]const u8{ "ah", "ch", "dh", "bh" }, 0..) |n, i| if (std.mem.eql(u8, n, low)) return .{ .num = @floatFromInt(i), .width = 8 };
    return null;
}

/// SEG.
fn segLookup(low: []const u8) ?f64 {
    for ([_][]const u8{ "es", "cs", "ss", "ds", "fs", "gs" }, 0..) |n, i| if (std.mem.eql(u8, n, low)) return @floatFromInt(i);
    return null;
}

const PSEUDO_BASE: f64 = 2000;
var pseudo_nums: std.StringHashMapUnmanaged(f64) = .empty;
var num_pseudos: f64 = 0;

/// The per-file pseudo-register registry, as a capture replay finds it: cleared, then each
/// `fil_<ident>` name the captured statements carry bound to its number (a later pass classifying
/// one of those names gets upstream's number back).
pub fn resetPseudos() void {
    pseudo_nums = .empty;
    num_pseudos = 0;
}
pub fn seedPseudo(alloc: Allocator, canon: []const u8, num: f64) E!void {
    try pseudo_nums.put(alloc, canon, num);
    num_pseudos = @max(num_pseudos, num - PSEUDO_BASE);
}

/// classifyReg.
pub fn classifyReg(alloc: Allocator, name: []const u8) E!?*ir.Operand {
    const low = try lower(alloc, name);
    if (try match(alloc, name, "^%%?[Ff][Ii][Ll]_(.*)$")) |c| {
        const stripped = c[0].str;
        if (try match(alloc, stripped, "^[0-9a-zA-Z_]+$") == null)
            return err.here(try fmt(alloc, "bad pseudoregister name `{s}` (expected `%fil_<ident>` with <ident> matching [0-9a-zA-Z_]+)", .{name}));
        const canon = try fmt(alloc, "fil_{s}", .{stripped});
        const n = pseudo_nums.get(canon) orelse blk: {
            num_pseudos += 1;
            const v = PSEUDO_BASE + num_pseudos;
            try pseudo_nums.put(alloc, canon, v);
            break :blk v;
        };
        return try newOp(alloc, .{ .kind = .reg, .rc = .gpr, .num = n, .width = 64, .name = canon, .pseudo = stripped });
    }
    if (std.mem.eql(u8, low, "rip")) return try newOp(alloc, .{ .kind = .reg, .rc = .rip, .name = "rip", .width = 64 });
    if (segLookup(low)) |sn| return try newOp(alloc, .{ .kind = .reg, .rc = .seg, .num = sn, .width = 16, .name = low });
    const r = regLookup(low) orelse {
        if (try match(alloc, low, "^([xyz]?mm)(%d+)$")) |c| {
            const vec = c[0].str;
            const w: f64 = if (std.mem.eql(u8, vec, "xmm")) 128 else if (std.mem.eql(u8, vec, "ymm")) 256 else if (std.mem.eql(u8, vec, "zmm")) 512 else 64;
            return try newOp(alloc, .{ .kind = .reg, .rc = .xmm, .num = ln.tonumber(c[1].str), .width = w, .name = low });
        }
        if (try match(alloc, low, "^k([0-7])$")) |c| return try newOp(alloc, .{ .kind = .reg, .rc = .xmm, .num = ln.tonumber(c[0].str), .width = 64, .name = low });
        const stn = (try match(alloc, low, "^st%((%d+)%)$")) orelse (try match(alloc, low, "^st(%d+)$"));
        if (std.mem.eql(u8, low, "st") or stn != null) {
            const n: f64 = if (stn) |c| (ln.tonumber(c[0].str) orelse 0) else 0;
            return try newOp(alloc, .{ .kind = .reg, .rc = .xmm, .num = n, .width = 80, .name = low });
        }
        return null;
    };
    return try newOp(alloc, .{ .kind = .reg, .rc = if (r.num == 4) .sp else .gpr, .num = r.num, .width = r.width, .name = low });
}

/// regName(num, width): the canonical name, else "r" .. num.
pub fn regName(alloc: Allocator, num: f64, width: f64) E![]const u8 {
    const set: ?[]const []const u8 = if (width == 64) &q_names else if (width == 32) &d_names else if (width == 16) &w_names else if (width == 8) &b_names else null;
    if (set) |names| if (num >= 0 and num < 16 and @floor(num) == num) return names[@intFromFloat(num)];
    var b: [48]u8 = undefined;
    return fmt(alloc, "r{s}", .{ln.tostring(&b, num)});
}

/// PTRSIZE.
fn ptrSize(low: []const u8) ?f64 {
    const t = [_]struct { []const u8, f64 }{ .{ "byte", 1 }, .{ "word", 2 }, .{ "dword", 4 }, .{ "qword", 8 }, .{ "xmmword", 16 }, .{ "ymmword", 32 }, .{ "zmmword", 64 }, .{ "tbyte", 10 }, .{ "oword", 16 } };
    for (t) |e| if (std.mem.eql(u8, e[0], low)) return e[1];
    return null;
}

/// splitOperands: top-level commas, outside () and []; each field trimmed; an empty last field
/// is dropped.
fn splitOperands(alloc: Allocator, s: []const u8) E![][]const u8 {
    var out: std.ArrayList([]const u8) = .empty;
    var depth: i32 = 0;
    var start: usize = 0;
    for (s, 0..) |c, i| {
        if (c == '(' or c == '[') depth += 1 else if (c == ')' or c == ']') depth -= 1 else if (c == ',' and depth == 0) {
            try out.append(alloc, trim(s[start..i]));
            start = i + 1;
        }
    }
    const last = trim(s[start..]);
    if (last.len != 0) try out.append(alloc, last);
    return out.items;
}

/// parseSym: `sym@RELOC`.
fn parseSym(alloc: Allocator, text: []const u8) E!*ir.Operand {
    if (std.mem.indexOfScalar(u8, text, '@')) |at| return newOp(alloc, .{ .kind = .sym, .text = text[0..at], .reloc = text[at + 1 ..] });
    return newOp(alloc, .{ .kind = .sym, .text = text });
}

fn intText(alloc: Allocator, v: f64) E![]const u8 {
    return ln.formatF0(alloc, v);
}

// ---- constant-expression folding (parseDispExpr)
pub const Disp = struct { sym: ?[]const u8 = null, @"const": f64 = 0, folded: bool = false };
const Tok = union(enum) { op: []const u8, num: f64, sym: []const u8 };

pub fn parseDispExpr(alloc: Allocator, text: []const u8, what: []const u8) E!Disp {
    if (try match(alloc, text, "^%d+[fb]$") != null) return .{ .sym = text, .@"const" = 0 };
    if (ln.tonumber(text)) |plain| return .{ .@"const" = plain };
    var tokens: std.ArrayList(Tok) = .empty;
    var i: usize = 0;
    const n = text.len;
    while (i < n) {
        const c = text[i];
        if (isspace(c)) {
            i += 1;
        } else if (std.ascii.isAlphabetic(c) or c == '_' or c == '.' or c == '$') {
            var j = i + 1;
            while (j < n and (std.ascii.isAlphanumeric(text[j]) or text[j] == '_' or text[j] == '.' or text[j] == '$')) j += 1;
            try tokens.append(alloc, .{ .sym = text[i..j] });
            i = j;
        } else if (std.ascii.isDigit(c)) {
            if (c == '0' and i + 2 < n + 1 and i + 1 < n and (text[i + 1] == 'x' or text[i + 1] == 'X') and i + 2 < n and std.ascii.isHex(text[i + 2])) {
                var j = i + 2;
                while (j < n and std.ascii.isHex(text[j])) j += 1;
                try tokens.append(alloc, .{ .num = ln.tonumber(text[i..j]).? });
                i = j;
            } else {
                var j = i;
                while (j < n and std.ascii.isDigit(text[j])) j += 1;
                const fb: u8 = if (j < n) text[j] else 0;
                if (fb == 'f' or fb == 'b') {
                    try tokens.append(alloc, .{ .sym = text[i .. j + 1] });
                    i = j + 1;
                } else {
                    try tokens.append(alloc, .{ .num = ln.tonumber(text[i..j]).? });
                    i = j;
                }
            }
        } else if (c == '<' or c == '>') {
            const next: u8 = if (i + 1 < n) text[i + 1] else 0;
            if (next != c) return err.here(try fmt(alloc, "unsupported operator '{c}' in {s} expression: {s}", .{ c, what, text }));
            try tokens.append(alloc, .{ .op = if (c == '<') "<<" else ">>" });
            i += 2;
        } else if (std.mem.indexOfScalar(u8, "+-*/%()~", c) != null) {
            try tokens.append(alloc, .{ .op = text[i .. i + 1] });
            i += 1;
        } else return err.here(try fmt(alloc, "unexpected character '{c}' in {s} expression: {s}", .{ c, what, text }));
    }
    if (tokens.items.len == 0) return err.here(try fmt(alloc, "empty {s} expression", .{what}));
    var p: Parser = .{ .alloc = alloc, .tokens = tokens.items, .text = text, .what = what };
    var result = try p.expr();
    if (p.pos != tokens.items.len) return err.here(try fmt(alloc, "unexpected trailing text in {s} expression: {s}", .{ what, text }));
    result.folded = true;
    return result;
}

const Parser = struct {
    alloc: Allocator,
    tokens: []const Tok,
    text: []const u8,
    what: []const u8,
    pos: usize = 0,

    fn peekOp(p: *Parser) ?[]const u8 {
        if (p.pos >= p.tokens.len) return null;
        return switch (p.tokens[p.pos]) {
            .op => |o| o,
            else => null,
        };
    }
    fn isOp(t: ?[]const u8, s: []const u8) bool {
        return t != null and std.mem.eql(u8, t.?, s);
    }
    fn constOf(p: *Parser, v: Disp, opname: []const u8) E!f64 {
        if (v.sym) |s| return err.here(try fmt(p.alloc, "symbol '{s}' cannot appear in a '{s}' {s} expression: {s}", .{ s, opname, p.what, p.text }));
        return v.@"const";
    }
    fn factor(p: *Parser) E!Disp {
        if (p.pos >= p.tokens.len) {
            p.pos += 1;
            return err.here(try fmt(p.alloc, "missing operand in {s} expression: {s}", .{ p.what, p.text }));
        }
        const t = p.tokens[p.pos];
        p.pos += 1;
        switch (t) {
            .op => |o| {
                if (std.mem.eql(u8, o, "(")) {
                    const v = try p.expr();
                    const close = p.pos < p.tokens.len and p.tokens[p.pos] == .op and std.mem.eql(u8, p.tokens[p.pos].op, ")");
                    p.pos += 1;
                    if (!close) return err.here(try fmt(p.alloc, "missing ')' in {s} expression: {s}", .{ p.what, p.text }));
                    return v;
                }
                if (std.mem.eql(u8, o, "-")) return .{ .@"const" = -(try p.constOf(try p.factor(), "-")) };
                if (std.mem.eql(u8, o, "+")) return .{ .@"const" = try p.constOf(try p.factor(), "+") };
                if (std.mem.eql(u8, o, "~")) return .{ .@"const" = -1 - (try p.constOf(try p.factor(), "~")) };
                return err.here(try fmt(p.alloc, "unexpected '{s}' in {s} expression: {s}", .{ o, p.what, p.text }));
            },
            .num => |x| return .{ .@"const" = x },
            .sym => |s| return .{ .sym = s, .@"const" = 0 },
        }
    }
    fn term(p: *Parser) E!Disp {
        var v = try p.factor();
        while (true) {
            const op = p.peekOp() orelse return v;
            if (!(isOp(op, "*") or isOp(op, "/") or isOp(op, "%") or isOp(op, "<<") or isOp(op, ">>"))) return v;
            p.pos += 1;
            const lhs = try p.constOf(v, op);
            const rhs = try p.constOf(try p.factor(), op);
            if (isOp(op, "*")) {
                v = .{ .@"const" = lhs * rhs };
            } else if (isOp(op, "<<") or isOp(op, ">>")) {
                if (rhs < 0) return err.here(try fmt(p.alloc, "negative shift count in {s} expression: {s}", .{ p.what, p.text }));
                const pw = std.math.pow(f64, 2, rhs);
                v = if (isOp(op, "<<")) .{ .@"const" = lhs * pw } else .{ .@"const" = @floor(lhs / pw) };
            } else if (rhs == 0) {
                return err.here(try fmt(p.alloc, "division by zero in {s} expression: {s}", .{ p.what, p.text }));
            } else {
                const q = lhs / rhs;
                const qt = if (q >= 0) @floor(q) else @ceil(q);
                v = if (isOp(op, "/")) .{ .@"const" = qt } else .{ .@"const" = lhs - qt * rhs };
            }
        }
    }
    fn expr(p: *Parser) E!Disp {
        var v = try p.term();
        while (true) {
            const op = p.peekOp() orelse return v;
            if (!(isOp(op, "+") or isOp(op, "-"))) return v;
            p.pos += 1;
            const rhs = try p.term();
            if (isOp(op, "+")) {
                if (v.sym != null and rhs.sym != null) return err.here(try fmt(p.alloc, "more than one symbol in {s} expression ('{s}', '{s}'): {s}", .{ p.what, v.sym.?, rhs.sym.?, p.text }));
                v = .{ .sym = v.sym orelse rhs.sym, .@"const" = v.@"const" + rhs.@"const" };
            } else {
                if (rhs.sym) |s| return err.here(try fmt(p.alloc, "subtracting symbol '{s}' in a {s} expression is not a displacement: {s}", .{ s, p.what, p.text }));
                v = .{ .sym = v.sym, .@"const" = v.@"const" - rhs.@"const" };
            }
        }
    }
};

// ---- AVX512 decorators
fn stripDecos(alloc: Allocator, field_in: []const u8) E!struct { field: []const u8, decos: [][]const u8 } {
    var field = field_in;
    var decos: std.ArrayList([]const u8) = .empty;
    while (true) {
        const c = (try match(alloc, field, "(%b{})$")) orelse break;
        const d = c[0].str;
        try decos.insert(alloc, 0, d);
        field = field[0 .. field.len - d.len];
    }
    return .{ .field = field, .decos = decos.items };
}

fn attachDecos(alloc: Allocator, op: *ir.Operand, decos: []const []const u8) E!*ir.Operand {
    if (decos.len == 0) return op;
    var parts: std.ArrayList(u8) = .empty;
    for (decos) |d0| {
        var d = d0;
        if (try match(alloc, d, "^{k([0-7])}$")) |c| d = try fmt(alloc, "{{%k{s}}}", .{c[0].str});
        if (op.kind == .mem) if (try match(alloc, d, "^{1to(%d+)}$")) |c| {
            op.bcastN = ln.tonumber(c[0].str);
        };
        try parts.appendSlice(alloc, d);
    }
    op.deco = parts.items;
    return op;
}

/// Set dispSym / dispVal from a folded displacement, as upstream: dispVal only when there is no
/// symbol or a nonzero constant rides alongside one.
fn setDisp(mem: *ir.Operand, e: Disp) void {
    mem.dispSym = e.sym;
    if (e.sym == null or e.@"const" != 0) mem.dispVal = e.@"const";
}

// ---- AT&T operands
fn parseAttOperandRaw(alloc: Allocator, field_in: []const u8) E!*ir.Operand {
    var field = field_in;
    var indirect = false;
    if (field.len > 0 and field[0] == '*') {
        indirect = true;
        field = field[1..];
    }
    if (field.len > 0 and field[0] == '$') {
        const t = field[1..];
        if (!hasPlain(t, "@")) {
            const e = try parseDispExpr(alloc, t, "immediate");
            if (e.sym == null) return newOp(alloc, .{ .kind = .imm, .text = if (e.folded) try intText(alloc, e.@"const") else t, .value = e.@"const" });
        }
        return newOp(alloc, .{ .kind = .imm, .text = t, .value = ln.tonumber(t) });
    }
    if (field.len > 0 and field[0] == '%' and (!hasPlain(field, "(") or try match(alloc, field, "^%%st%(%d+%)$") != null)) {
        if (try classifyReg(alloc, field[1..])) |r| {
            r.indirect = indirect;
            return r;
        }
    }
    if (try match(alloc, field, "^(.-)%((.*)%)$") != null) {
        while (true) {
            const g = lp.gsub(alloc, field, "%(([^()]*)%)%(", .{ .str = "%1(" }, null) catch return error.OutOfMemory;
            if (std.mem.eql(u8, g.text, field)) break;
            field = g.text;
        }
        const c = (try match(alloc, field, "^(.-)%((.*)%)$")).?;
        const mem = try newOp(alloc, .{ .kind = .mem, .scale = 1, .indirect = indirect });
        const pre = trim(c[0].str);
        const inside = c[1].str;
        if (pre.len != 0) {
            const ps = try parseSym(alloc, pre);
            if (ps.reloc) |rl| {
                mem.dispSym = ps.text;
                mem.dispReloc = rl;
            } else setDisp(mem, try parseDispExpr(alloc, ps.text.?, "displacement"));
        }
        var parts: std.ArrayList([]const u8) = .empty;
        var it = std.mem.splitScalar(u8, inside, ',');
        while (it.next()) |x| try parts.append(alloc, trim(x));
        const pt = parts.items;
        if (pt.len > 0 and pt[0].len != 0) {
            mem.base = try classifyReg(alloc, pt[0][1..]);
            if (mem.base == null) {
                if (ln.tonumber(pt[0])) |v| {
                    mem.dispVal = v;
                } else if (try match(alloc, pt[0], "^[%d%+%-%(]") != null) {
                    setDisp(mem, try parseDispExpr(alloc, pt[0], "displacement"));
                }
            }
        }
        if (pt.len > 1 and pt[1].len != 0) mem.index = try classifyReg(alloc, pt[1][1..]);
        if (pt.len > 2 and pt[2].len != 0) mem.scale = ln.tonumber(pt[2]) orelse 1;
        return mem;
    }
    if (try match(alloc, field, "^(%d+)([fb])$")) |c| return newOp(alloc, .{ .kind = .numref, .text = field, .refNum = c[0].str, .dir = c[1].str, .indirect = indirect });
    if (try match(alloc, field, "^-?%d") != null or try match(alloc, field, "^0[xX]") != null)
        return newOp(alloc, .{ .kind = .imm, .text = field, .value = ln.tonumber(field), .absAddr = true, .indirect = indirect });
    const s = try parseSym(alloc, field);
    s.indirect = indirect;
    return s;
}

fn parseAttOperand(alloc: Allocator, field: []const u8) E!*ir.Operand {
    const d = try stripDecos(alloc, field);
    return attachDecos(alloc, try parseAttOperandRaw(alloc, d.field), d.decos);
}

// ---- Intel operands
fn parseIntelOperandRaw(alloc: Allocator, field_in: []const u8) E!*ir.Operand {
    var field = field_in;
    if (try match(alloc, field, "[()]") != null and try match(alloc, try lower(alloc, field), "^st%(%d+%)$") == null)
        return err.here(try fmt(alloc, "AT&T-style operand in Intel-syntax input (use [bracket] memory operands): {s}", .{field}));
    const indirect = false;
    var size: ?f64 = null;
    if (try match(alloc, field, "^(%a+)%s+[Pp][Tt][Rr]%s+(.*)$")) |c| {
        if (ptrSize(try lower(alloc, c[0].str))) |sz| {
            size = sz;
            field = trim(c[1].str);
        }
    }
    if (try match(alloc, field, "^(.-)%[(.*)%]$")) |c| {
        const mem = try newOp(alloc, .{ .kind = .mem, .scale = 1, .size = size });
        const pre = trim(c[0].str);
        if (pre.len != 0) {
            if (!hasPlain(pre, "@")) setDisp(mem, try parseDispExpr(alloc, pre, "displacement")) else mem.dispSym = pre;
        }
        const inside = (lp.gsub(alloc, c[1].str, "%s+", .{ .str = "" }, null) catch return error.OutOfMemory).text;
        const Term = struct { sign: f64, tok: []const u8 };
        var terms: std.ArrayList(Term) = .empty;
        var sign: f64 = 1;
        var start: usize = 0;
        for (inside, 0..) |ch, k| {
            if (ch == '+' or ch == '-') {
                if (k > start) try terms.append(alloc, .{ .sign = sign, .tok = inside[start..k] });
                sign = if (ch == '+') 1 else -1;
                start = k + 1;
            }
        }
        if (inside.len > start) try terms.append(alloc, .{ .sign = sign, .tok = inside[start..] });
        for (terms.items) |tm| {
            const t = tm.tok;
            if (hasPlain(t, "*")) {
                const rs = try match(alloc, t, "^(.-)%*(%d+)$");
                const r = if (rs) |x| try classifyReg(alloc, x[0].str) else null;
                if (r) |reg| {
                    mem.index = reg;
                    mem.scale = ln.tonumber(rs.?[1].str) orelse 1;
                } else {
                    const e = try parseDispExpr(alloc, t, "displacement");
                    mem.dispVal = (mem.dispVal orelse 0) + tm.sign * e.@"const";
                }
            } else if (try classifyReg(alloc, t)) |r| {
                if (r.rc.? == .rip) mem.base = r else if (mem.base == null) mem.base = r else mem.index = r;
            } else if (hasPlain(t, "@")) {
                mem.dispSym = t;
            } else {
                const e = try parseDispExpr(alloc, t, "displacement");
                if (e.sym) |s| {
                    if (tm.sign < 0) return err.here(try fmt(alloc, "subtracting symbol '{s}' in a displacement expression is not a displacement: {s}", .{ s, field }));
                    if (mem.dispSym) |old| return err.here(try fmt(alloc, "more than one displacement symbol in memory operand ('{s}', '{s}'): {s}", .{ old, s, field }));
                    mem.dispSym = s;
                    if (e.@"const" != 0) mem.dispVal = (mem.dispVal orelse 0) + tm.sign * e.@"const";
                } else mem.dispVal = (mem.dispVal orelse 0) + tm.sign * e.@"const";
            }
        }
        return mem;
    }
    if (try classifyReg(alloc, field)) |r| {
        r.indirect = indirect;
        return r;
    }
    if (try match(alloc, field, "^(%d+)([fb])$")) |c| return newOp(alloc, .{ .kind = .numref, .text = field, .refNum = c[0].str, .dir = c[1].str, .indirect = indirect });
    if (try match(alloc, field, "^-?%d") != null or try match(alloc, field, "^0[xX]") != null) {
        if (!hasPlain(field, "@")) {
            const e = try parseDispExpr(alloc, field, "immediate");
            if (e.sym == null) return newOp(alloc, .{ .kind = .imm, .text = if (e.folded) try intText(alloc, e.@"const") else field, .value = e.@"const" });
        }
        return newOp(alloc, .{ .kind = .imm, .text = field, .value = ln.tonumber(field) });
    }
    return parseSym(alloc, field);
}

fn parseIntelOperand(alloc: Allocator, field: []const u8) E!*ir.Operand {
    const d = try stripDecos(alloc, field);
    return attachDecos(alloc, try parseIntelOperandRaw(alloc, d.field), d.decos);
}

/// attMnemonic's opsize: a trailing b/w/l/q after at least two characters.
fn attOpsize(m: []const u8) ?f64 {
    if (m.len < 3) return null;
    return switch (m[m.len - 1]) {
        'b' => 1,
        'w' => 2,
        'l' => 4,
        'q' => 8,
        else => null,
    };
}

// ---- comments and annotations
fn stripComment(s: []const u8) []const u8 {
    var in_str = false;
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        const c = s[i];
        if (c == '"') {
            in_str = !in_str;
        } else if (in_str and c == '\\') {
            i += 1;
        } else if (!in_str and c == '#') return s[0..i];
    }
    return s;
}

fn splitAnnotation(s: []const u8) struct { code: []const u8, ann: ?[]const u8 } {
    var in_str = false;
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        const c = s[i];
        if (c == '"') {
            in_str = !in_str;
        } else if (in_str and c == '\\') {
            i += 1;
        } else if (!in_str) {
            const d: u8 = if (i + 1 < s.len) s[i + 1] else 0;
            if ((c == ';' or c == '#') and d == '!') return .{ .code = s[0..i], .ann = trim(stripComment(s[@min(i + 2, s.len)..])) };
            if (c == '#') return .{ .code = s[0..i], .ann = null };
        }
    }
    return .{ .code = s, .ann = null };
}

const mnem_pat = "^([%.%w_][%w_.]*)%s*(.*)$";

/// parseInsnText.
pub fn parseInsnText(alloc: Allocator, t_in: []const u8, syntax: []const u8) E!*ir.Stmt {
    var t = t_in;
    while (try match(alloc, t, "^(%b{})%s*(.*)$")) |c| {
        const pfx = c[0].str;
        const inner = try lower(alloc, pfx[1 .. pfx.len - 1]);
        var ok = false;
        for ([_][]const u8{ "vex", "vex2", "vex3", "evex", "np" }) |x| if (std.mem.eql(u8, x, inner)) {
            ok = true;
        };
        if (!ok) return err.here(try fmt(alloc, "unsupported encoding-hint prefix '{s}' (only {{vex}}/{{vex2}}/{{vex3}}/{{evex}}/{{np}} are recognized): {s}", .{ pfx, t }));
        t = c[1].str;
    }
    const c0 = (try match(alloc, t, mnem_pat)) orelse return err.here(try fmt(alloc, "cannot parse line: {s}", .{t}));
    var mnem = c0[0].str;
    var rest = trim(c0[1].str);
    var lock_prefix = false;
    if (std.mem.eql(u8, try lower(alloc, mnem), "lock")) {
        const r2 = (lp.gsub(alloc, rest, "^%s*;%s*", .{ .str = "" }, null) catch return error.OutOfMemory).text;
        const c2 = (try match(alloc, r2, mnem_pat)) orelse return err.here(try fmt(alloc, "`lock` prefix with no following instruction: {s}", .{t}));
        mnem = c2[0].str;
        rest = trim(c2[1].str);
        lock_prefix = true;
    }
    var rep_prefix: ?[]const u8 = null;
    {
        const low = try lower(alloc, mnem);
        for ([_][]const u8{ "rep", "repe", "repne", "repz", "repnz" }) |x| if (std.mem.eql(u8, x, low)) {
            const r2 = (lp.gsub(alloc, rest, "^%s*;%s*", .{ .str = "" }, null) catch return error.OutOfMemory).text;
            const c2 = (try match(alloc, r2, mnem_pat)) orelse return err.here(try fmt(alloc, "`{s}` prefix with no following instruction: {s}", .{ low, t }));
            mnem = c2[0].str;
            rest = trim(c2[1].str);
            rep_prefix = low;
            break;
        };
    }
    const att = std.mem.eql(u8, syntax, "att");
    const st = try alloc.create(ir.Stmt);
    st.* = .{ .kind = .insn, .mnemonic = try lower(alloc, mnem), .opsize = if (att) attOpsize(mnem) else null, .raw = t, .syntax = syntax, .lockPrefix = if (lock_prefix) true else null, .repPrefix = rep_prefix };
    for (try splitOperands(alloc, rest)) |f| if (f.len != 0) try st.operands.append(alloc, if (att) try parseAttOperand(alloc, f) else try parseIntelOperand(alloc, f));
    if (att and st.operands.items.len >= 2) std.mem.reverse(*ir.Operand, st.operands.items);
    return st;
}

/// parseDotAlloca: `.alloca size, alignment, result`, operands in written order.
fn parseDotAlloca(alloc: Allocator, rest: []const u8, syntax: []const u8, t: []const u8) E!*ir.Stmt {
    const fields = try splitOperands(alloc, rest);
    const msg = "`.alloca` takes exactly 3 operands (size, alignment, result): ";
    if (fields.len != 3) return err.here(try fmt(alloc, "{s}{s}", .{ msg, t }));
    const st = try alloc.create(ir.Stmt);
    st.* = .{ .kind = .insn, .mnemonic = "alloca", .raw = t, .syntax = syntax, .dotAlloca = true };
    for (fields) |f| {
        if (f.len == 0) return err.here(try fmt(alloc, "{s}{s}", .{ msg, t }));
        const op = if (std.mem.eql(u8, syntax, "att")) try parseAttOperand(alloc, f) else try parseIntelOperand(alloc, f);
        if (op.kind == .imm) op.absAddr = null;
        if (op.kind == .sym or op.kind == .numref)
            return err.here(try fmt(alloc, "`.alloca` operand is a symbol, but size/alignment must be a register, spill slot, or immediate and result a register, pseudo-register, or spill slot: {s}", .{t}));
        try st.operands.append(alloc, op);
    }
    return st;
}

/// x86parse.parseString.
pub fn parseString(alloc: Allocator, text_in: []const u8, syntax: []const u8, file_name: []const u8) E![]*ir.Stmt {
    err.beginParse(file_name);
    pseudo_nums = .empty;
    num_pseudos = 0;
    var out: std.ArrayList(*ir.Stmt) = .empty;
    const text = try std.mem.replaceOwned(u8, alloc, text_in, "\r\n", "\n");
    var line_no: u32 = 0;
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |raw| {
        line_no += 1;
        err.atParseLine(line_no);
        const sa = splitAnnotation(raw);
        var t = trim(sa.code);
        const before = out.items.len;
        if (t.len == 0) {
            const st = try alloc.create(ir.Stmt);
            st.* = .{ .kind = .blank, .text = raw, .annotation = sa.ann };
            try out.append(alloc, st);
        } else {
            while (try match(alloc, t, "^([%w_.$][%w_.$@]*):%s*(.*)$")) |c| {
                const st = try alloc.create(ir.Stmt);
                st.* = .{ .kind = .label, .name = c[0].str };
                try out.append(alloc, st);
                t = trim(c[1].str);
                if (t.len == 0) break;
            }
            if (t.len != 0) {
                var c = try match(alloc, t, mnem_pat);
                if (c == null and t[0] == '{') c = try match(alloc, t, "^%b{}%s*([%.%w_][%w_.]*)%s*(.*)$");
                const cc = c orelse return err.here(try fmt(alloc, "cannot parse line: {s}", .{t}));
                const mnem = cc[0].str;
                const rest = trim(cc[1].str);
                if (mnem[0] == '.') {
                    if (std.mem.eql(u8, try lower(alloc, mnem), ".alloca")) {
                        try out.append(alloc, try parseDotAlloca(alloc, rest, syntax, t));
                    } else {
                        const st = try alloc.create(ir.Stmt);
                        st.* = .{ .kind = .directive, .name = mnem, .args = rest, .raw = t };
                        try out.append(alloc, st);
                    }
                } else try out.append(alloc, try parseInsnText(alloc, t, syntax));
            }
        }
        if (sa.ann) |a| if (out.items.len > before) {
            out.items[out.items.len - 1].annotation = a;
        };
        for (out.items[before..]) |st| {
            if (st.line == null) st.line = line_no;
            if (st.file == null) st.file = file_name;
        }
    }
    err.endParse();
    try numlabel.resolve(alloc, out.items);
    return out.items;
}
