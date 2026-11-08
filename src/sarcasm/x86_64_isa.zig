// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//! x86_64 instruction semantics (a port of projects/sarcasm/sarcasm/x86_64_isa.luau, Fil-C 0.687):
//! classify a parsed (dest-first) instruction into register defs / uses and control flow, the
//! EFLAGS use / def tables and masks, the lock / RMW predicates, and the register and
//! calling-convention configuration.
//!
//! Implicit register operands are FRESH operand tables exactly where upstream makes them (the
//! lift keys by table identity), and shared exactly where upstream shares one (loop's counter,
//! the string ops' rsi/rdi). Argument positions `k` in the CC functions are 1-based, as upstream's.

const std = @import("std");
const err = @import("err.zig");
const ir = @import("ir.zig");
const fp = @import("x86_64_fp.zig");
const sig = @import("sig.zig");
const ln = @import("luau_number.zig");
const u = @import("util.zig");

const Allocator = std.mem.Allocator;
const E = err.Error;
const Op = ir.Operand;
const Ops = []const *Op;
const List = std.ArrayList(*Op);
const eq = std.mem.eql;
const startsWith = std.mem.startsWith;

fn at(ops: Ops, i: usize) ?*Op {
    return if (i < ops.len) ops[i] else null;
}

// ---------------------------------------------------------------------------
// baseMnemonic

const base_names = [_][]const u8{ "mov", "add", "sub", "and", "or", "xor", "sal", "shl", "sar", "shr", "cmp", "test", "lea", "imul", "inc", "dec", "neg", "not", "push", "pop", "adc", "sbb", "mul", "idiv", "div", "ror", "rol" };
const base_kv = blk: {
    var out: [base_names.len * 5]struct { []const u8, []const u8 } = undefined;
    for (base_names, 0..) |m, i| for ([_][]const u8{ "", "b", "w", "l", "q" }, 0..) |s, j| {
        out[i * 5 + j] = .{ m ++ s, m };
    };
    break :blk out;
};
const BASE = std.StaticStringMap([]const u8).initComptime(base_kv);

const fixed_kv = [_]struct { []const u8, []const u8 }{
    .{ "movabs", "mov" },          .{ "movabsq", "mov" },
    .{ "movzx", "movzx" },         .{ "movsx", "movsx" },
    .{ "movsxd", "movsx" },        .{ "movzbl", "movzx" },
    .{ "movzbw", "movzx" },        .{ "movzbq", "movzx" },
    .{ "movzwl", "movzx" },        .{ "movzwq", "movzx" },
    .{ "movsbl", "movsx" },        .{ "movsbw", "movsx" },
    .{ "movsbq", "movsx" },        .{ "movswl", "movsx" },
    .{ "movswq", "movsx" },        .{ "movslq", "movsx" },
    .{ "cltq", "cltq" },           .{ "cdqe", "cltq" },
    .{ "cqo", "cqo" },             .{ "cqto", "cqo" },
    .{ "cbw", "cbw" },             .{ "cbtw", "cbw" },
    .{ "cwde", "cwde" },           .{ "cwtl", "cwde" },
    .{ "cwd", "cwd" },             .{ "cwtd", "cwd" },
    .{ "cdq", "cdq" },             .{ "cltd", "cdq" },
    .{ "mulx", "mulx" },           .{ "mulxl", "mulx" },
    .{ "mulxq", "mulx" },          .{ "cmpxchg", "cmpxchg" },
    .{ "cmpxchgb", "cmpxchg" },    .{ "cmpxchgw", "cmpxchg" },
    .{ "cmpxchgl", "cmpxchg" },    .{ "cmpxchgq", "cmpxchg" },
    .{ "cmpxchg8b", "cmpxchg8b" }, .{ "cmpxchg16b", "cmpxchg16b" },
    .{ "bt", "bt" },               .{ "btb", "bt" },
    .{ "btw", "bt" },              .{ "btl", "bt" },
    .{ "btq", "bt" },              .{ "bts", "bts" },
    .{ "btsb", "bts" },            .{ "btsw", "bts" },
    .{ "btsl", "bts" },            .{ "btsq", "bts" },
    .{ "btr", "btr" },             .{ "btrb", "btr" },
    .{ "btrw", "btr" },            .{ "btrl", "btr" },
    .{ "btrq", "btr" },            .{ "btc", "btc" },
    .{ "btcb", "btc" },            .{ "btcw", "btc" },
    .{ "btcl", "btc" },            .{ "btcq", "btc" },
    .{ "endbr64", "nop" },         .{ "nop", "nop" },
    .{ "ud2", "ud2" },             .{ "ret", "ret" },
    .{ "retq", "ret" },            .{ "leave", "leave" },
    .{ "nopw", "nop" },            .{ "nopl", "nop" },
    .{ "call", "call" },           .{ "callq", "call" },
    .{ "callw", "call" },          .{ "jmp", "jmp" },
    .{ "jmpq", "jmp" },            .{ "jmpw", "jmp" },
    .{ "lahf", "lahf" },           .{ "sahf", "sahf" },
    .{ "movbe", "movbe" },         .{ "movbew", "movbe" },
    .{ "movbel", "movbe" },        .{ "movbeq", "movbe" },
    .{ "movbeb", "movbe" },        .{ "shld", "shld" },
    .{ "shldw", "shld" },          .{ "shldl", "shld" },
    .{ "shldq", "shld" },          .{ "shrd", "shrd" },
    .{ "shrdw", "shrd" },          .{ "shrdl", "shrd" },
    .{ "shrdq", "shrd" },
};
const FIXED = std.StaticStringMap([]const u8).initComptime(fixed_kv);

test "BASE and FIXED have no duplicate keys" {
    const a = std.testing.allocator;
    inline for (.{ base_kv, fixed_kv }) |kvs| {
        var seen: std.StringHashMapUnmanaged(void) = .empty;
        defer seen.deinit(a);
        for (kvs) |kv| try std.testing.expect(!(try seen.getOrPut(a, kv[0])).found_existing);
    }
}

pub fn baseMnemonic(alloc: Allocator, m_in: []const u8) E![]const u8 {
    const m = try u.lower(alloc, m_in);
    if (FIXED.get(m)) |b| return b;
    if (BASE.get(m)) |b| return b;
    if (try u.matches(alloc, m, "^j%a+$")) return "jcc";
    if (try u.matches(alloc, m, "^set%a+$")) return "setcc";
    if (try u.matches(alloc, m, "^cmov%a+$")) return "cmov";
    return m;
}

const ALU2 = [_][]const u8{ "add", "sub", "and", "or", "xor", "sal", "shl", "sar", "shr", "imul", "adc", "sbb", "ror", "rol", "rcl", "rcr" };
const FLAGS_ONLY = [_][]const u8{ "cmp", "test" };
const DST_ONLY = [_][]const u8{ "inc", "dec", "neg", "not" };
const SHIFT_COUNT = [_][]const u8{ "sal", "shl", "sar", "shr", "ror", "rol", "rcl", "rcr" };
const LOCKABLE_ALU = [_][]const u8{ "add", "adc", "and", "or", "sbb", "sub", "xor" };
const TRAP_MNEM = [_][]const u8{ "ud2", "int3", "int", "hlt" };

fn mnemOf(st: *const ir.Stmt) []const u8 {
    return st.mnemonic.?;
}

pub fn lockAllows(alloc: Allocator, stmt: *const ir.Stmt) E!bool {
    const ops = stmt.operands.items;
    if (!(ops.len > 0 and ops[0].kind == .mem)) return false;
    const m = try baseMnemonic(alloc, mnemOf(stmt));
    if (u.in(m, &LOCKABLE_ALU) or u.in(m, &DST_ONLY) or u.in(m, &.{ "cmpxchg", "cmpxchg8b", "cmpxchg16b" })) return true;
    return u.matches(alloc, try u.lower(alloc, mnemOf(stmt)), "^xadd[bwlq]?$");
}

pub fn isMemRmw(alloc: Allocator, stmt: *const ir.Stmt) E!bool {
    const ops = stmt.operands.items;
    if (!(ops.len > 0 and ops[0].kind == .mem)) return false;
    const m = try baseMnemonic(alloc, mnemOf(stmt));
    if (u.in(m, &ALU2) or u.in(m, &DST_ONLY) or u.in(m, &.{ "cmpxchg", "cmpxchg8b", "cmpxchg16b", "shld", "shrd" })) return true;
    const raw = try u.lower(alloc, mnemOf(stmt));
    return (try u.matches(alloc, raw, "^xadd[bwlq]?$")) or (try u.matches(alloc, raw, "^adcx[lq]?$")) or
        (try u.matches(alloc, raw, "^adox[lq]?$")) or (try u.matches(alloc, raw, "^crc32[bwlq]?$"));
}

// ---------------------------------------------------------------------------
// EFLAGS

const STRINGOP_BASE = [_][]const u8{ "movs", "stos" };
const FCMOV = [_][]const u8{ "fcmovb", "fcmove", "fcmovbe", "fcmovu", "fcmovnb", "fcmovne", "fcmovnbe", "fcmovnu" };
const FLAG_USE = [_][]const u8{ "adc", "sbb", "adcx", "adox", "rcl", "rcr", "cmc", "loope", "loopz", "loopne", "loopnz", "lahf" } ++ STRINGOP_BASE ++ FCMOV;
const FLAG_DEF = [_][]const u8{ "add", "sub", "and", "or", "xor", "cmp", "test", "neg", "shl", "sal", "shr", "sar", "mul", "imul", "xadd", "cmpxchg", "bsf", "bsr", "tzcnt", "lzcnt", "popcnt" };
const FLAG_WRITE_NO_DEF = [_][]const u8{ "adc", "sbb", "adcx", "adox", "rcl", "rcr", "inc", "dec", "rol", "ror", "shld", "shrd", "bt", "bts", "btr", "btc", "stc", "clc", "cmc", "cld", "std", "sahf" };
const SHIFT_FAMILY = [_][]const u8{ "shl", "sal", "shr", "sar", "rol", "ror", "rcl", "rcr" };

/// string.gsub(m, "[bwlq]$", "")
fn stripSuffix(m: []const u8) []const u8 {
    if (m.len > 0 and std.mem.indexOfScalar(u8, "bwlq", m[m.len - 1]) != null) return m[0 .. m.len - 1];
    return m;
}

fn isShiftCountZero(alloc: Allocator, stmt: ?*const ir.Stmt) E!bool {
    const st = stmt orelse return false;
    const raw = try u.lower(alloc, mnemOf(st));
    const b = try baseMnemonic(alloc, raw);
    const s = stripSuffix(b);
    const ops = st.operands.items;
    var count: ?*Op = null;
    if (u.in(b, &SHIFT_FAMILY) or u.in(s, &SHIFT_FAMILY)) {
        count = at(ops, 1);
    } else if (u.in(b, &.{ "shld", "shrd" }) or u.in(s, &.{ "shld", "shrd" })) {
        count = at(ops, 2);
    } else return false;
    const c = count orelse return false;
    if (c.kind != .imm) return false;
    if (c.value) |v| return v == 0;
    if (c.text) |t| {
        const v = ln.tonumber(try u.gsub(alloc, t, "^%$", ""));
        return v != null and v.? == 0;
    }
    return false;
}

const FLAG_PUSH = [_][]const u8{ "pushf", "pushfq", "pushfd" };
const FLAG_POP = [_][]const u8{ "popf", "popfq", "popfd" };
pub fn isFlagStackPush(m: []const u8) bool {
    return u.in(m, &FLAG_PUSH);
}
pub fn isFlagStackPop(m: []const u8) bool {
    return u.in(m, &FLAG_POP);
}
pub fn isFlagStackXfer(m: []const u8) bool {
    return isFlagStackPush(m) or isFlagStackPop(m);
}

pub const FLAGS_REG_NUM: f64 = 999999;
pub const FLAGS_REG_NAME = "__rflags";
pub fn flagsWordOperand(alloc: Allocator) E!*Op {
    return u.newOp(alloc, .{ .kind = .reg, .rc = .gpr, .num = FLAGS_REG_NUM, .width = 64, .name = FLAGS_REG_NAME, .implicit = true });
}

fn zeroOperandDword(raw: []const u8, st: *const ir.Stmt) bool {
    return (eq(u8, raw, "movsd") or eq(u8, raw, "stosd")) and st.operands.items.len == 0;
}

pub fn flagUse(alloc: Allocator, stmt: ?*const ir.Stmt) E!bool {
    const st = stmt orelse return false;
    const raw = try u.lower(alloc, mnemOf(st));
    if (u.in(raw, &FLAG_PUSH)) return true;
    var m = try baseMnemonic(alloc, raw);
    if (u.in(m, &.{ "jcc", "setcc", "cmov" })) return true;
    if (u.in(m, &FLAG_USE)) return true;
    m = stripSuffix(m);
    if (u.in(m, &FLAG_USE)) return true;
    return zeroOperandDword(raw, st);
}

pub fn flagDef(alloc: Allocator, stmt: ?*const ir.Stmt) E!bool {
    const st = stmt orelse return false;
    if (try isShiftCountZero(alloc, st)) return false;
    const raw = try u.lower(alloc, mnemOf(st));
    if (u.in(raw, &FLAG_POP)) return true;
    var m = try baseMnemonic(alloc, raw);
    if (u.in(m, &FLAG_DEF)) return true;
    m = stripSuffix(m);
    return u.in(m, &FLAG_DEF);
}

pub fn flagWriteNoDef(alloc: Allocator, stmt: ?*const ir.Stmt) E!bool {
    const st = stmt orelse return false;
    if (try isShiftCountZero(alloc, st)) return false;
    var m = try baseMnemonic(alloc, try u.lower(alloc, mnemOf(st)));
    if (u.in(m, &FLAG_WRITE_NO_DEF)) return true;
    m = stripSuffix(m);
    return u.in(m, &FLAG_WRITE_NO_DEF);
}

pub const FLAG_CF: u32 = 1;
pub const FLAG_PF: u32 = 4;
pub const FLAG_AF: u32 = 16;
pub const FLAG_ZF: u32 = 64;
pub const FLAG_SF: u32 = 128;
pub const FLAG_OF: u32 = 2048;
pub const FLAG_DF: u32 = 1024;
pub const FLAG_ALL: u32 = FLAG_CF + FLAG_PF + FLAG_AF + FLAG_ZF + FLAG_SF + FLAG_OF;

const COND_MASK = std.StaticStringMap(u32).initComptime(.{
    .{ "o", FLAG_OF },                      .{ "no", FLAG_OF },
    .{ "b", FLAG_CF },                      .{ "c", FLAG_CF },
    .{ "nae", FLAG_CF },                    .{ "ae", FLAG_CF },
    .{ "nb", FLAG_CF },                     .{ "nc", FLAG_CF },
    .{ "e", FLAG_ZF },                      .{ "z", FLAG_ZF },
    .{ "ne", FLAG_ZF },                     .{ "nz", FLAG_ZF },
    .{ "be", FLAG_CF + FLAG_ZF },           .{ "na", FLAG_CF + FLAG_ZF },
    .{ "a", FLAG_CF + FLAG_ZF },            .{ "nbe", FLAG_CF + FLAG_ZF },
    .{ "s", FLAG_SF },                      .{ "ns", FLAG_SF },
    .{ "p", FLAG_PF },                      .{ "pe", FLAG_PF },
    .{ "np", FLAG_PF },                     .{ "po", FLAG_PF },
    .{ "l", FLAG_SF + FLAG_OF },            .{ "nge", FLAG_SF + FLAG_OF },
    .{ "ge", FLAG_SF + FLAG_OF },           .{ "nl", FLAG_SF + FLAG_OF },
    .{ "le", FLAG_SF + FLAG_ZF + FLAG_OF }, .{ "ng", FLAG_SF + FLAG_ZF + FLAG_OF },
    .{ "g", FLAG_SF + FLAG_ZF + FLAG_OF },  .{ "nle", FLAG_SF + FLAG_ZF + FLAG_OF },
});

fn condOf(m: []const u8) ?[]const u8 {
    var s: []const u8 = undefined;
    if (startsWith(u8, m, "j")) s = m[1..] else if (startsWith(u8, m, "set")) s = m[3..] else if (startsWith(u8, m, "cmov")) s = m[4..] else return null;
    if (COND_MASK.get(s) != null) return s;
    // string.sub(s, 1, -2): all but the last character ("" for "")
    const t = if (s.len > 0) s[0 .. s.len - 1] else s;
    if (s.len > 0 and std.mem.indexOfScalar(u8, "wlq", s[s.len - 1]) != null and COND_MASK.get(t) != null) return t;
    return null;
}

fn loopZf(m: []const u8) bool {
    return u.in(m, &.{ "loope", "loopz", "loopne", "loopnz" });
}

pub fn flagUseMask(alloc: Allocator, stmt: ?*const ir.Stmt) E!u32 {
    const st = stmt orelse return 0;
    const raw = try u.lower(alloc, mnemOf(st));
    if (u.in(raw, &FLAG_PUSH)) return FLAG_ALL;
    var m = try baseMnemonic(alloc, raw);
    if (u.in(m, &.{ "jcc", "setcc", "cmov" })) {
        if (condOf(raw)) |c| return COND_MASK.get(c).?;
        return FLAG_ALL;
    }
    if (u.in(m, &.{ "adc", "sbb", "adcx" })) return FLAG_CF;
    if (eq(u8, m, "adox")) return FLAG_OF;
    if (u.in(m, &.{ "rcl", "rcr", "cmc" })) return FLAG_CF;
    if (eq(u8, m, "lahf")) return FLAG_SF + FLAG_ZF + FLAG_AF + FLAG_PF + FLAG_CF;
    if (u.in(m, &FCMOV)) return FLAG_ALL;
    if (u.in(m, &STRINGOP_BASE)) return FLAG_DF;
    if (zeroOperandDword(raw, st)) return FLAG_DF;
    if (loopZf(m)) return FLAG_ZF;
    m = stripSuffix(m);
    if (u.in(m, &.{ "adc", "sbb", "adcx" })) return FLAG_CF;
    if (eq(u8, m, "adox")) return FLAG_OF;
    if (u.in(m, &.{ "rcl", "rcr", "cmc" })) return FLAG_CF;
    if (u.in(m, &STRINGOP_BASE)) return FLAG_DF;
    if (loopZf(m)) return FLAG_ZF;
    return 0;
}

fn defMaskOf(m: []const u8) ?u32 {
    if (u.in(m, &.{ "adc", "sbb" })) return FLAG_ALL;
    if (eq(u8, m, "adcx")) return FLAG_CF;
    if (eq(u8, m, "adox")) return FLAG_OF;
    if (u.in(m, &.{ "rcl", "rcr" })) return FLAG_CF + FLAG_OF;
    if (u.in(m, &.{ "inc", "dec" })) return FLAG_ALL - FLAG_CF;
    if (u.in(m, &.{ "rol", "ror" })) return FLAG_CF + FLAG_OF;
    if (u.in(m, &.{ "shld", "shrd" })) return FLAG_CF;
    if (u.in(m, &.{ "bt", "bts", "btr", "btc" })) return FLAG_CF;
    if (u.in(m, &.{ "stc", "clc", "cmc" })) return FLAG_CF;
    if (u.in(m, &.{ "cld", "std" })) return FLAG_DF;
    return null;
}

pub fn flagDefMask(alloc: Allocator, stmt: ?*const ir.Stmt) E!u32 {
    const st = stmt orelse return 0;
    if (try isShiftCountZero(alloc, st)) return 0;
    const raw = try u.lower(alloc, mnemOf(st));
    if (u.in(raw, &FLAG_POP)) return FLAG_ALL;
    var m = try baseMnemonic(alloc, raw);
    if (defMaskOf(m)) |x| return x;
    if (eq(u8, m, "sahf")) return FLAG_SF + FLAG_ZF + FLAG_AF + FLAG_PF + FLAG_CF;
    if (u.in(m, &FLAG_DEF)) return FLAG_ALL;
    m = stripSuffix(m);
    if (defMaskOf(m)) |x| return x;
    if (u.in(m, &FLAG_DEF)) return FLAG_ALL;
    return 0;
}

// ---------------------------------------------------------------------------
// classify helpers

const LABEL_TARGET_MNEM = [_][]const u8{ "loop", "loopq", "loopl", "loopb", "loopw", "loope", "loopz", "loopne", "loopnz", "xbegin" };

pub fn isGpr(op: ?*const Op) bool {
    const o = op orelse return false;
    return o.kind == .reg and o.rc == .gpr;
}

fn partialRegWrite(o: *const Op) bool {
    return (o.width orelse 64) < 32;
}

fn memRegs(alloc: Allocator, op: *const Op, uses: *List) E!void {
    if (op.base) |b| if (isGpr(b)) try uses.append(alloc, b);
    if (op.index) |x| if (isGpr(x)) try uses.append(alloc, x);
}

fn highByteNum(name: ?[]const u8) ?f64 {
    const nm = name orelse "";
    if (eq(u8, nm, "ah")) return 0;
    if (eq(u8, nm, "ch")) return 1;
    if (eq(u8, nm, "dh")) return 2;
    if (eq(u8, nm, "bh")) return 3;
    return null;
}
const HB_ENCLOSING_NAME = [_][]const u8{ "rax", "rcx", "rdx", "rbx" };

fn isHighByteOp(op: ?*const Op) bool {
    const o = op orelse return false;
    return o.kind == .reg and o.rc == .gpr and o.width != null and o.width.? == 8 and highByteNum(o.name) != null;
}

fn spelled(alloc: Allocator, insn: *const ir.Stmt, o: *const Op) E![]const u8 {
    if (u.eql(insn.syntax, "intel")) return o.name.?;
    return u.fmt(alloc, "%{s}", .{o.name.?});
}

fn rawOf(insn: *const ir.Stmt, rawMnem: []const u8) []const u8 {
    return insn.raw orelse rawMnem;
}

fn imp(alloc: Allocator, num: f64, w: f64, name: []const u8) E!*Op {
    return u.newOp(alloc, .{ .kind = .reg, .rc = .gpr, .num = num, .width = w, .name = name, .implicit = true });
}

fn width(o: *const Op) f64 {
    return o.width orelse std.math.nan(f64); // nil compares unequal to every width
}

fn classifyHighByte(alloc: Allocator, insn: *const ir.Stmt, m: []const u8, ops: Ops) E!ir.Class {
    const rawMnem = try u.lower(alloc, mnemOf(insn));
    const raw = rawOf(insn, rawMnem);
    var hbOp: ?*Op = null;
    for (ops) |o| if (isHighByteOp(o) and hbOp == null) {
        hbOp = o;
    };
    const hb = try spelled(alloc, insn, hbOp.?);
    const generic = try u.fmt(alloc, "high-byte register {s} is not supported in '{s}' (supported: movb, movzbl/movzbw/movsbl/movsbw reads, byte ALU/cmp/test/inc/dec/neg/not forms, setcc, xchgb; use a low-byte sequence for anything else): {s}", .{ hb, rawMnem, raw });
    for (ops) |o| {
        if (o.kind == .mem)
            return err.at(insn.loc(), try u.fmt(alloc, "high-byte register {s} with a memory operand is not supported (the bounds-check rewrite addresses memory through an allocated register that may require a REX prefix, which a high-byte register cannot combine with; rewrite with a low-byte sequence): {s}", .{ hb, raw }));
        if (o.kind == .sym or (o.kind == .imm and (o.absAddr orelse false))) return err.at(insn.loc(), generic);
        if (isGpr(o) and !isHighByteOp(o)) {
            const w = width(o);
            if (w == 8) {
                if (o.num.? > 3)
                    return err.at(insn.loc(), try u.fmt(alloc, "high-byte register {s} cannot be combined with {s} (a byte register other than %al/%cl/%dl/%bl requires a REX prefix, which a high-byte register cannot combine with): {s}", .{ hb, try spelled(alloc, insn, o), raw }));
            } else if (w == 16 or w == 32) {
                if (o.num.? > 7)
                    return err.at(insn.loc(), try u.fmt(alloc, "high-byte register {s} cannot be combined with {s} (a register numbered 8 or above requires a REX prefix, which a high-byte register cannot combine with): {s}", .{ hb, try spelled(alloc, insn, o), raw }));
            } else {
                return err.at(insn.loc(), try u.fmt(alloc, "high-byte register {s} cannot be combined with a 64-bit register operand (a REX.W prefix is required, which a high-byte register cannot combine with): {s}", .{ hb, raw }));
            }
        }
    }

    const B = struct {
        alloc: Allocator,
        c: ir.Class = .{},
        pin: ir.Pin = .{},
        fn hbUse(b: *@This(), o: *const Op) E!void {
            const x = try imp(b.alloc, o.num.?, 64, HB_ENCLOSING_NAME[@intFromFloat(o.num.?)]);
            try b.c.uses.append(b.alloc, x);
            try b.pin.uses.append(b.alloc, x);
        }
        fn hbDef(b: *@This(), o: *const Op) E!void {
            const x = try imp(b.alloc, o.num.?, 64, HB_ENCLOSING_NAME[@intFromFloat(o.num.?)]);
            try b.c.defs.append(b.alloc, x);
            try b.pin.defs.append(b.alloc, x);
        }
        fn hbRmw(b: *@This(), o: *const Op) E!void {
            try b.hbUse(o);
            try b.hbDef(o);
            try b.c.rmw.append(b.alloc, o.num.?);
        }
        fn pinUse(b: *@This(), o: *Op) E!void {
            try b.c.uses.append(b.alloc, o);
            try b.pin.uses.append(b.alloc, o);
        }
        fn pinDef(b: *@This(), o: *Op) E!void {
            try b.c.defs.append(b.alloc, o);
            try b.pin.defs.append(b.alloc, o);
        }
        fn pinRmw(b: *@This(), o: *Op) E!void {
            try b.c.defs.append(b.alloc, o);
            try b.pin.defs.append(b.alloc, o);
            try b.c.uses.append(b.alloc, o);
            try b.pin.uses.append(b.alloc, o);
            try b.c.rmw.append(b.alloc, o.num.?);
        }
        fn writeOp(b: *@This(), o: *Op) E!void {
            if (isHighByteOp(o)) try b.hbRmw(o) else try b.pinRmw(o);
        }
        fn readOp(b: *@This(), o: ?*Op) E!void {
            if (isHighByteOp(o)) try b.hbUse(o.?) else if (isGpr(o)) try b.pinUse(o.?);
        }
    };
    var b: B = .{ .alloc = alloc };

    if (eq(u8, m, "mov")) {
        if (ops.len != 2 or !isGpr(ops[0]) or width(ops[0]) != 8 or (isGpr(ops[1]) and width(ops[1]) != 8)) return err.at(insn.loc(), generic);
        try b.writeOp(ops[0]);
        try b.readOp(ops[1]);
    } else if (eq(u8, m, "movzx") or eq(u8, m, "movsx")) {
        if (isHighByteOp(at(ops, 0)))
            return err.at(insn.loc(), try u.fmt(alloc, "a high-byte register cannot be the destination of movzx/movsx (the destination is a 16/32-bit register; that encoding does not exist): {s}", .{raw}));
        if (!isHighByteOp(at(ops, 1))) return err.at(insn.loc(), generic);
        const srcLetter = try u.match1(alloc, rawMnem, "^mov[zs]([bw])");
        if (!u.eql(insn.syntax, "intel") and !u.eql(srcLetter, "b"))
            return err.at(insn.loc(), try u.fmt(alloc, "{s} with a high-byte source is not encodable (only the byte-source, 16/32-bit-destination forms movzbl/movzbw/movsbl/movsbw are; {s} requires a REX prefix): {s}", .{ rawMnem, rawMnem, raw }));
        if (!isGpr(at(ops, 0)) or (width(ops[0]) != 32 and width(ops[0]) != 16))
            return err.at(insn.loc(), try u.fmt(alloc, "{s} with a high-byte source requires a 16-bit or 32-bit register destination (a 64-bit destination requires a REX.W prefix): {s}", .{ rawMnem, raw }));
        try b.pinDef(ops[0]);
        try b.readOp(ops[1]);
    } else if (u.in(m, &FLAGS_ONLY) or u.in(m, &DST_ONLY) or u.in(m, &ALU2)) {
        if (u.in(m, &SHIFT_COUNT) and isGpr(at(ops, 1)))
            return err.at(insn.loc(), try u.fmt(alloc, "a shift/rotate count can only come from %cl (the only register-count encoding); a high-byte register cannot encode it: {s}", .{raw}));
        if (u.in(m, &FLAGS_ONLY)) {
            for (ops) |o| try b.readOp(o);
        } else if (u.in(m, &DST_ONLY)) {
            if (!isGpr(at(ops, 0))) return err.at(insn.loc(), generic);
            try b.writeOp(ops[0]);
        } else {
            if (!isGpr(at(ops, 0))) return err.at(insn.loc(), generic);
            try b.writeOp(ops[0]);
            for (ops[1..]) |o| try b.readOp(o);
        }
    } else if (eq(u8, m, "setcc")) {
        if (!isHighByteOp(at(ops, 0))) return err.at(insn.loc(), generic);
        try b.writeOp(ops[0]);
    } else return err.at(insn.loc(), generic);
    b.c.pin = b.pin;
    return b.c;
}

fn stringElem(m: []const u8) ?f64 {
    const T = std.StaticStringMap(f64).initComptime(.{
        .{ "movsb", 1 }, .{ "movsw", 2 }, .{ "movsl", 4 }, .{ "movsd", 4 }, .{ "movsq", 8 },
        .{ "stosb", 1 }, .{ "stosw", 2 }, .{ "stosl", 4 }, .{ "stosd", 4 }, .{ "stosq", 8 },
    });
    return T.get(m);
}

pub fn classifyStringOp(alloc: Allocator, insn: *const ir.Stmt) E!?ir.Class {
    const rawMnem = try u.lower(alloc, mnemOf(insn));
    const raw = rawOf(insn, rawMnem);
    const rep = insn.repPrefix;
    const ops = insn.operands.items;
    var kind: ?[]const u8 = null;
    var elem: ?f64 = null;
    if (eq(u8, rawMnem, "movsd")) {
        if (ops.len == 0) {
            kind = "movs";
            elem = 4;
        }
    } else if (stringElem(rawMnem)) |e| {
        elem = e;
        kind = if (startsWith(u8, rawMnem, "movs")) "movs" else "stos";
    } else if (eq(u8, rawMnem, "movs") or eq(u8, rawMnem, "stos")) {
        kind = rawMnem;
    }
    if (kind) |k| {
        if (ops.len > 0) {
            const regs: []const u8 = if (u.eql(insn.syntax, "intel")) "rsi/rdi" else "%rsi/%rdi";
            return err.at(insn.loc(), try u.fmt(alloc, "'{s}' takes no explicit operands (its source and destination are the implicit {s} registers; write the bare form): {s}", .{ rawMnem, regs, raw }));
        }
        if (u.eql(insn.syntax, "intel")) {
            if (eq(u8, rawMnem, "movsl") or eq(u8, rawMnem, "stosl"))
                return err.at(insn.loc(), try u.fmt(alloc, "'{s}' is not encodable in Intel syntax (use {s} for the dword string move): {s}", .{ rawMnem, try u.gsub(alloc, rawMnem, "l$", "d"), raw }));
        } else if (eq(u8, rawMnem, "stosd")) {
            return err.at(insn.loc(), try u.fmt(alloc, "'stosd' is not encodable in AT&T syntax (use stosl for the dword string store): {s}", .{raw}));
        }
        if (elem == null)
            return err.at(insn.loc(), try u.fmt(alloc, "cannot determine the element width of '{s}' (use an explicit size form: movsb/movsw/movsl/movsq or stosb/stosw/stosl/stosq): {s}", .{ rawMnem, raw }));
        if (u.eql(rep, "repne") or u.eql(rep, "repnz"))
            return err.at(insn.loc(), try u.fmt(alloc, "`{s}` prefix is not supported on '{s}' (only `rep`/`repe`/`repz`, which repeat while %rcx != 0): {s}", .{ rep.?, rawMnem, raw }));
        if (insn.annotation) |ann| if (!(try u.matches(alloc, ann, "^%s*stack%s+buffer")))
            return err.at(insn.loc(), try u.fmt(alloc, "annotation `{s}` is not supported on '{s}' (string instructions need no annotation — their accesses are capability-checked against %rsi/%rdi): {s}", .{ ann, rawMnem, raw }));
        if (insn.lockPrefix orelse false)
            return err.at(insn.loc(), try u.fmt(alloc, "`lock` prefix is not supported on '{s}' (lock requires a memory-destination read-modify-write instruction sarcasm models exactly): {s}", .{ rawMnem, raw }));
        var c: ir.Class = .{};
        var r: ir.Rep = .{ .kind = k, .elem = elem, .repPrefix = rep };
        const R = struct {
            fn rmwReg(a: Allocator, cc: *ir.Class, num: f64, nm: []const u8) E!*Op {
                const x = try imp(a, num, 64, nm);
                try cc.uses.append(a, x);
                try cc.defs.append(a, x);
                try cc.rmw.append(a, num);
                return x;
            }
        };
        if (eq(u8, k, "movs")) {
            r.rsi = try R.rmwReg(alloc, &c, 6, "rsi");
            r.rdi = try R.rmwReg(alloc, &c, 7, "rdi");
        } else {
            r.rdi = try R.rmwReg(alloc, &c, 7, "rdi");
            const rax = try imp(alloc, 0, 64, "rax");
            try c.uses.append(alloc, rax);
            r.rax = rax;
        }
        const rcxUse = try imp(alloc, 1, 64, "rcx");
        try c.uses.append(alloc, rcxUse);
        r.rcxUse = rcxUse;
        const rcxDef = try imp(alloc, 1, 64, "rcx");
        try c.defs.append(alloc, rcxDef);
        r.rcxDef = rcxDef;
        c.rep = r;
        return c;
    }
    if (rep) |rp| {
        if (eq(u8, rawMnem, "ret") or eq(u8, rawMnem, "nop")) return null;
        return err.at(insn.loc(), try u.fmt(alloc, "`{s}` prefix is not supported on '{s}' (only rep movs* / rep stos* — including movsb/movsw/movsl/movsq and stosb/stosw/stosl/stosq — plus `rep ret`): {s}", .{ rp, rawMnem, raw }));
    }
    return null;
}

fn symTargets(alloc: Allocator, ops: Ops) E![]const []const u8 {
    var t: std.ArrayList([]const u8) = .empty;
    for (ops) |o| if (o.kind == .sym) try t.append(alloc, o.text.?);
    return t.items;
}

fn isFrameSlotMem(o: *const Op) bool {
    const b = o.base orelse return false;
    return b.rc == .sp or u.eql(b.name, "rbp");
}

// ---------------------------------------------------------------------------
// classify

pub fn classify(alloc: Allocator, insn: *const ir.Stmt) E!ir.Class {
    const rawMnem = try u.lower(alloc, mnemOf(insn));
    const raw = rawOf(insn, rawMnem);
    const L = insn.loc();

    if (try classifyStringOp(alloc, insn)) |rep| return rep;
    if (try fp.unsafeReject(alloc, rawMnem, insn)) |why| return err.at(L, try u.fmt(alloc, "{s}: {s}", .{ why, raw }));

    if ((insn.lockPrefix orelse false) and !(try lockAllows(alloc, insn)))
        return err.at(L, try u.fmt(alloc, "lock prefix not allowed on '{s}' (lock requires a memory-destination read-modify-write instruction sarcasm models exactly: add/adc/and/or/sbb/sub/xor, inc/dec/neg/not, xadd, cmpxchg, cmpxchg8b/cmpxchg16b): {s}", .{ rawMnem, raw }));

    if (insn.localCall) |lc| {
        const t = try alloc.alloc([]const u8, 1);
        t[0] = lc.entry;
        return .{ .control = .branch, .targets = t, .fallsThrough = false };
    }
    if (insn.localRet) |lr| return .{ .control = .branch, .targets = lr.conts, .fallsThrough = false };

    const m = try baseMnemonic(alloc, mnemOf(insn));
    const ops = insn.operands.items;
    var trapHasMem = false;
    if (u.in(m, &TRAP_MNEM) and !eq(u8, m, "ud2")) {
        for (ops) |o| if (o.kind == .mem) {
            trapHasMem = true;
            break;
        };
    }

    const codeTarget = u.in(m, &.{ "call", "jmp", "jcc", "lea" }) or eq(u8, rawMnem, "int") or u.in(rawMnem, &LABEL_TARGET_MNEM);
    var hasHighByte = false;
    for (ops) |o| if (isHighByteOp(o)) {
        hasHighByte = true;
        break;
    };
    if (hasHighByte and !(try u.matches(alloc, m, "^xchg[bwlq]?$"))) return classifyHighByte(alloc, insn, m, ops);
    for (ops) |o| if (o.kind == .mem) {
        for ([_]?*Op{ o.base, o.index }) |r| if (isHighByteOp(r))
            return err.at(L, try u.fmt(alloc, "high-byte register {s} cannot be a memory operand base/index (only 64-bit registers may address memory): {s}", .{ try spelled(alloc, insn, r.?), raw }));
        if (o.base) |b| if (b.rc == .seg)
            return err.at(L, try u.fmt(alloc, "segment register cannot be a memory operand base (fs/gs-relative addressing cannot be bounds-checked): {s}", .{raw}));
        if (o.base == null and o.index == null)
            return err.at(L, try u.fmt(alloc, "memory access with an absolute address cannot be bounds-checked (a memory operand with no base register is a displacement-only absolute address; global data access is not yet supported): {s}", .{raw}));
    };
    for (ops) |o| {
        const indirect = o.indirect orelse false;
        if (!codeTarget or indirect) {
            if (o.kind == .sym) {
                const t = try u.lower(alloc, o.text.?);
                var seg = false;
                if (!indirect) {
                    seg = if (u.eql(insn.syntax, "intel")) try u.matches(alloc, t, "^[cdefgs]s$") else try u.matches(alloc, t, "^%%[cdefgs]s$");
                }
                if (!seg) return err.at(L, try u.fmt(alloc, "memory access with a symbolic address cannot be bounds-checked (global data access is not yet supported): {s}", .{raw}));
            }
            if (o.kind == .imm and (o.absAddr orelse false))
                return err.at(L, try u.fmt(alloc, "memory access with an absolute address cannot be bounds-checked (global data access is not yet supported): {s}", .{raw}));
        }
    }

    if (try fp.classify(alloc, insn)) |fpc| return fpc;
    var c: ir.Class = .{};

    const U = struct {
        fn useOperand(a: Allocator, cc: *ir.Class, o: ?*Op) E!void {
            if (isGpr(o)) try cc.uses.append(a, o.?) else if (o) |x| if (x.kind == .mem) try memRegs(a, x, &cc.uses);
        }
        fn rmwFirst(a: Allocator, cc: *ir.Class, os: Ops) E!void {
            if (isGpr(at(os, 0))) {
                try cc.defs.append(a, os[0]);
                try cc.uses.append(a, os[0]);
                try cc.rmw.append(a, os[0].num.?);
            } else if (at(os, 0)) |x| if (x.kind == .mem) try memRegs(a, x, &cc.uses);
        }
    };

    if (eq(u8, m, "alloca")) {
        if (!(insn.dotAlloca orelse false)) return err.at(L, try u.fmt(alloc, "`alloca` is only supported as the `.alloca size, alignment, result` directive: {s}", .{raw}));
        if (ops.len != 3) return err.at(L, try u.fmt(alloc, "`.alloca` takes exactly 3 operands (size, alignment, result): {s}", .{raw}));
        for ([_]struct { *Op, []const u8 }{ .{ ops[0], "size" }, .{ ops[1], "alignment" } }) |p| {
            const o, const what = p;
            if (o.indirect orelse false) return err.at(L, try u.fmt(alloc, "`.alloca` {s} has an indirect (`*`) marker, which is not supported: {s}", .{ what, raw }));
            if (o.kind == .imm) continue;
            if (isGpr(o)) {
                if (width(o) != 64 and width(o) != 32) return err.at(L, try u.fmt(alloc, "`.alloca` {s} must be a 32/64-bit register (narrow writes do not define the full value): {s}", .{ what, raw }));
                try c.uses.append(alloc, o);
                continue;
            }
            if (o.kind == .mem and isFrameSlotMem(o)) continue;
            return err.at(L, try u.fmt(alloc, "`.alloca` {s} must be an immediate, a GPR (including a pseudoregister), or a frame spill slot: {s}", .{ what, raw }));
        }
        const o = ops[2];
        if (o.indirect orelse false) return err.at(L, try u.fmt(alloc, "`.alloca` result has an indirect (`*`) marker, which is not supported: {s}", .{raw}));
        if (isGpr(o)) {
            if (width(o) != 64) return err.at(L, try u.fmt(alloc, "`.alloca` result must be a 64-bit register (a narrower destination would truncate the pointer): {s}", .{raw}));
            try c.defs.append(alloc, o);
        } else if (o.kind == .mem and isFrameSlotMem(o)) {
            // spill-slot result: converted by the frame rewrite; provisionally unmodeled
        } else return err.at(L, try u.fmt(alloc, "`.alloca` result must be a 64-bit register, a pseudoregister, or a frame spill slot: {s}", .{raw}));
        return c;
    }

    if (eq(u8, m, "jmp")) {
        c.control = .branch;
        c.fallsThrough = false;
        c.targets = try symTargets(alloc, ops);
        if (at(ops, 0)) |o| if (isGpr(o) or o.kind == .mem) {
            c.control = .indirect;
            try U.useOperand(alloc, &c, o);
        };
    } else if (eq(u8, m, "jcc")) {
        c.control = .condbranch;
        c.targets = try symTargets(alloc, ops);
        if (eq(u8, rawMnem, "jrcxz") or eq(u8, rawMnem, "jecxz")) {
            const w: f64 = if (eq(u8, rawMnem, "jecxz")) 32 else 64;
            const x = try u.newOp(alloc, .{ .kind = .reg, .rc = .gpr, .num = 1, .width = w, .name = if (w == 32) "ecx" else "rcx", .implicit = true, .fixedReg = "rcx" });
            try c.uses.append(alloc, x);
        }
    } else if (eq(u8, m, "call")) {
        c.control = .call;
        if (at(ops, 0)) |o| if (isGpr(o) or o.kind == .mem) {
            c.control = .indcall;
            try U.useOperand(alloc, &c, o);
        };
    } else if (eq(u8, m, "ret")) {
        c.control = .@"return";
        c.fallsThrough = false;
    } else if (eq(u8, m, "nop") or eq(u8, m, "leave")) {
        // no gpr effects we model
    } else if (eq(u8, m, "ud2") or (u.in(m, &TRAP_MNEM) and !trapHasMem)) {
        c.fallsThrough = false;
    } else if (try u.matches(alloc, m, "^loop[bwlq]?$")) {
        if (eq(u8, m, "loopb") or eq(u8, m, "loopw"))
            return err.at(L, try u.fmt(alloc, "{s} is a 16-bit-counter form that is not encodable in 64-bit mode (use loop, loopq or loopl): {s}", .{ rawMnem, raw }));
        const w: f64 = if (eq(u8, m, "loopl")) 32 else 64;
        const cnt = try u.newOp(alloc, .{ .kind = .reg, .rc = .gpr, .num = 1, .width = w, .name = if (w == 32) "ecx" else "rcx", .implicit = true, .fixedReg = "rcx" });
        try c.uses.append(alloc, cnt);
        try c.defs.append(alloc, cnt);
        try c.rmw.append(alloc, 1);
        c.control = .condbranch;
        c.targets = try symTargets(alloc, ops);
    } else if (u.in(m, &.{ "cltq", "cbw", "cwde" })) {
        try c.defs.append(alloc, try u.newOp(alloc, .{ .kind = .reg, .rc = .gpr, .num = 0, .width = 64, .name = "rax" }));
        try c.uses.append(alloc, try u.newOp(alloc, .{ .kind = .reg, .rc = .gpr, .num = 0, .width = 64, .name = "rax" }));
        try c.rmw.append(alloc, 0);
    } else if (u.in(m, &.{ "cqo", "cdq", "cwd" })) {
        const axU = try imp(alloc, 0, 64, "rax");
        const dxD = try imp(alloc, 2, 64, "rdx");
        try c.uses.append(alloc, axU);
        try c.defs.append(alloc, dxD);
        var pin: ir.Pin = .{};
        try pin.uses.append(alloc, axU);
        if (eq(u8, m, "cwd")) {
            const dxU = try imp(alloc, 2, 64, "rdx");
            try c.uses.append(alloc, dxU);
            try c.rmw.append(alloc, 2);
            try pin.uses.append(alloc, dxU);
        }
        try pin.defs.append(alloc, dxD);
        c.pin = pin;
        return c;
    } else if (u.in(m, &.{ "div", "idiv", "mul" }) or (eq(u8, m, "imul") and ops.len == 1)) {
        var w = insn.opsize;
        if (w == null) {
            for (ops) |o| if (isGpr(o)) {
                w = @max(1, @floor((o.width orelse 64) / 8));
                break;
            };
        }
        if (w == null) {
            for (ops) |o| if (o.kind == .mem and o.size != null) {
                w = o.size;
                break;
            };
        }
        const ww = w orelse return err.at(L, try u.fmt(alloc, "cannot determine the memory access width of '{s}' (unsized memory operand is ambiguous; use a size suffix or PTR annotation): {s}", .{ rawMnem, raw }));
        for (ops) |o| try U.useOperand(alloc, &c, o);
        const I = struct {
            fn mk(a: Allocator, num: f64, wb: f64) E!*Op {
                return imp(a, num, wb * 8, if (num == 0) "rax" else "rdx");
            }
        };
        var pin: ir.Pin = .{};
        if (ww == 1) {
            const axU = try I.mk(alloc, 0, ww);
            const axD = try I.mk(alloc, 0, ww);
            try c.uses.append(alloc, axU);
            try c.defs.append(alloc, axD);
            try pin.uses.append(alloc, axU);
            try pin.defs.append(alloc, axD);
        } else if (eq(u8, m, "mul") or eq(u8, m, "imul")) {
            const axU = try I.mk(alloc, 0, ww);
            const axD = try I.mk(alloc, 0, ww);
            const dxD = try I.mk(alloc, 2, ww);
            try c.uses.append(alloc, axU);
            try c.defs.append(alloc, axD);
            try c.defs.append(alloc, dxD);
            try pin.uses.append(alloc, axU);
            if (ww == 2) {
                const dxU = try I.mk(alloc, 2, ww);
                try c.uses.append(alloc, dxU);
                try c.rmw.append(alloc, 2);
                try pin.uses.append(alloc, dxU);
            }
            try pin.defs.append(alloc, axD);
            try pin.defs.append(alloc, dxD);
        } else {
            const axU = try I.mk(alloc, 0, ww);
            const dxU = try I.mk(alloc, 2, ww);
            const axD = try I.mk(alloc, 0, ww);
            const dxD = try I.mk(alloc, 2, ww);
            try c.uses.append(alloc, axU);
            try c.uses.append(alloc, dxU);
            try c.defs.append(alloc, axD);
            try c.defs.append(alloc, dxD);
            try pin.uses.append(alloc, axU);
            try pin.uses.append(alloc, dxU);
            try pin.defs.append(alloc, axD);
            try pin.defs.append(alloc, dxD);
        }
        c.pin = pin;
        return c;
    } else if (eq(u8, m, "mulx")) {
        const dx = try imp(alloc, 2, 64, "rdx");
        if (isGpr(at(ops, 0))) try c.defs.append(alloc, ops[0]);
        if (isGpr(at(ops, 1))) try c.defs.append(alloc, ops[1]);
        if (ops.len > 2) for (ops[2..]) |o| try U.useOperand(alloc, &c, o);
        try c.uses.append(alloc, dx);
        var pin: ir.Pin = .{};
        try pin.uses.append(alloc, dx);
        c.pin = pin;
        return c;
    } else if (eq(u8, m, "cmpxchg")) {
        var w = insn.opsize;
        if (w == null) {
            for (ops) |o| if (isGpr(o)) {
                w = @max(1, @floor((o.width orelse 64) / 8));
                break;
            };
        }
        const aw = (w orelse 64) * 8;
        const accU = try imp(alloc, 0, aw, "rax");
        const accD = try imp(alloc, 0, aw, "rax");
        try U.rmwFirst(alloc, &c, ops);
        if (ops.len > 1) for (ops[1..]) |o| try U.useOperand(alloc, &c, o);
        try c.uses.append(alloc, accU);
        try c.defs.append(alloc, accD);
        var pin: ir.Pin = .{};
        try pin.uses.append(alloc, accU);
        try pin.defs.append(alloc, accD);
        c.pin = pin;
        return c;
    } else if (eq(u8, m, "cmpxchg8b") or eq(u8, m, "cmpxchg16b")) {
        if (!(ops.len > 0 and ops[0].kind == .mem))
            return err.at(L, try u.fmt(alloc, "{s} requires a memory operand (it has no register form): {s}", .{ rawMnem, raw }));
        try memRegs(alloc, ops[0], &c.uses);
        const axU = try imp(alloc, 0, 64, "rax");
        const dxU = try imp(alloc, 2, 64, "rdx");
        const bxU = try imp(alloc, 3, 64, "rbx");
        const cxU = try imp(alloc, 1, 64, "rcx");
        const axD = try imp(alloc, 0, 64, "rax");
        const dxD = try imp(alloc, 2, 64, "rdx");
        var pin: ir.Pin = .{};
        for ([_]*Op{ axU, dxU, bxU, cxU }) |x| {
            try c.uses.append(alloc, x);
            try pin.uses.append(alloc, x);
        }
        for ([_]*Op{ axD, dxD }) |x| {
            try c.defs.append(alloc, x);
            try pin.defs.append(alloc, x);
        }
        c.pin = pin;
        return c;
    } else if (u.in(m, &.{ "bt", "bts", "btr", "btc" })) {
        if (at(ops, 0)) |o| if (o.kind == .mem)
            return err.at(L, try u.fmt(alloc, "{s} with a memory base is not supported (a bit-string access of unbounded extent cannot be bounds-checked; load the value into a register first): {s}", .{ rawMnem, raw }));
        if (isGpr(at(ops, 0))) {
            try c.uses.append(alloc, ops[0]);
            if (!eq(u8, m, "bt")) {
                try c.defs.append(alloc, ops[0]);
                try c.rmw.append(alloc, ops[0].num.?);
            }
        }
        if (ops.len > 1) for (ops[1..]) |o| try U.useOperand(alloc, &c, o);
        return c;
    } else if (u.in(m, &.{ "cpuid", "rdtsc", "rdtscp", "xgetbv", "rdpkru", "wrpkru", "monitor", "mwait" })) {
        if (ops.len != 0)
            return err.at(L, try u.fmt(alloc, "{s} takes no explicit operands (gas's operand decorations like `monitor %rax, %ecx, %edx` are not supported; write the bare mnemonic): {s}", .{ rawMnem, raw }));
        var pin: ir.Pin = .{};
        const P = struct {
            fn use(a: Allocator, cc: *ir.Class, p: *ir.Pin, num: f64, nm: []const u8, w: f64) E!void {
                const r = try imp(a, num, w, nm);
                try cc.uses.append(a, r);
                try p.uses.append(a, r);
            }
            fn def(a: Allocator, cc: *ir.Class, p: *ir.Pin, num: f64, nm: []const u8, w: f64) E!void {
                const r = try imp(a, num, w, nm);
                try cc.defs.append(a, r);
                try p.defs.append(a, r);
            }
        };
        if (eq(u8, m, "cpuid")) {
            try P.use(alloc, &c, &pin, 0, "rax", 32);
            try P.use(alloc, &c, &pin, 1, "rcx", 32);
            try P.def(alloc, &c, &pin, 0, "rax", 32);
            try P.def(alloc, &c, &pin, 3, "rbx", 32);
            try P.def(alloc, &c, &pin, 1, "rcx", 32);
            try P.def(alloc, &c, &pin, 2, "rdx", 32);
        } else if (eq(u8, m, "rdtsc")) {
            try P.def(alloc, &c, &pin, 0, "rax", 32);
            try P.def(alloc, &c, &pin, 2, "rdx", 32);
        } else if (eq(u8, m, "rdtscp")) {
            try P.def(alloc, &c, &pin, 0, "rax", 32);
            try P.def(alloc, &c, &pin, 2, "rdx", 32);
            try P.def(alloc, &c, &pin, 1, "rcx", 32);
        } else if (eq(u8, m, "xgetbv") or eq(u8, m, "rdpkru")) {
            try P.use(alloc, &c, &pin, 1, "rcx", 32);
            try P.def(alloc, &c, &pin, 0, "rax", 32);
            try P.def(alloc, &c, &pin, 2, "rdx", 32);
        } else if (eq(u8, m, "wrpkru")) {
            try P.use(alloc, &c, &pin, 0, "rax", 32);
            try P.use(alloc, &c, &pin, 1, "rcx", 32);
            try P.use(alloc, &c, &pin, 2, "rdx", 32);
        } else if (eq(u8, m, "monitor")) {
            try P.use(alloc, &c, &pin, 0, "rax", 64);
            try P.use(alloc, &c, &pin, 1, "rcx", 32);
            try P.use(alloc, &c, &pin, 2, "rdx", 32);
        } else {
            try P.use(alloc, &c, &pin, 0, "rax", 32);
            try P.use(alloc, &c, &pin, 1, "rcx", 32);
        }
        c.pin = pin;
        return c;
    } else if (eq(u8, m, "lahf") or eq(u8, m, "sahf")) {
        if (ops.len != 0)
            return err.at(L, try u.fmt(alloc, "{s} takes no explicit operands (its only operand is the implicit %ah / flag byte): {s}", .{ rawMnem, raw }));
        const axU = try imp(alloc, 0, 64, "rax");
        try c.uses.append(alloc, axU);
        var pin: ir.Pin = .{};
        try pin.uses.append(alloc, axU);
        if (eq(u8, m, "lahf")) {
            const axD = try imp(alloc, 0, 64, "rax");
            try c.defs.append(alloc, axD);
            try c.rmw.append(alloc, 0);
            try pin.defs.append(alloc, axD);
        }
        c.pin = pin;
        return c;
    } else if (u.in(m, &FLAGS_ONLY)) {
        for (ops) |o| try U.useOperand(alloc, &c, o);
    } else if (u.in(m, &ALU2)) {
        try U.rmwFirst(alloc, &c, ops);
        if (ops.len > 1) for (ops[1..]) |o| try U.useOperand(alloc, &c, o);
        if (u.in(m, &SHIFT_COUNT) and isGpr(at(ops, 1))) {
            if (width(ops[1]) != 8 or ops[1].num.? != 1)
                return err.at(L, try u.fmt(alloc, "a shift/rotate count register must be %cl (the only register-count encoding in the ISA): {s}", .{raw}));
            var pin: ir.Pin = .{};
            try pin.uses.append(alloc, ops[1]);
            c.pin = pin;
            return c;
        }
    } else if (u.in(m, &DST_ONLY)) {
        try U.rmwFirst(alloc, &c, ops);
    } else if (try u.matches(alloc, m, "^bswap[bwlq]?$")) {
        if (ops.len != 1)
            return err.at(L, try u.fmt(alloc, "bswap takes exactly one register operand (it has no two-operand form): {s}", .{raw}));
        if (!(ops[0].kind == .reg and ops[0].rc == .gpr))
            return err.at(L, try u.fmt(alloc, "bswap takes exactly one register operand (it has no memory or immediate form): {s}", .{raw}));
        if (width(ops[0]) != 32 and width(ops[0]) != 64)
            return err.at(L, try u.fmt(alloc, "bswap requires a 32-bit or 64-bit register operand (bswapw/bswapb are not encodable): {s}", .{raw}));
        try c.defs.append(alloc, ops[0]);
        try c.uses.append(alloc, ops[0]);
        try c.rmw.append(alloc, ops[0].num.?);
    } else if (eq(u8, m, "movbe")) {
        if (ops.len != 2)
            return err.at(L, try u.fmt(alloc, "movbe takes exactly two operands (a byte-swapping move between a register and memory): {s}", .{raw}));
        const dst = ops[0];
        const src = ops[1];
        const notb = "movbeb is not encodable (movbe exists only in 16/32/64-bit forms; an 8-bit byte swap is a plain movb): {s}";
        if (dst.kind == .mem and isGpr(src)) {
            if (width(src) == 8) return err.at(L, try u.fmt(alloc, notb, .{raw}));
            try memRegs(alloc, dst, &c.uses);
            try c.uses.append(alloc, src);
        } else if (isGpr(dst) and src.kind == .mem) {
            if (width(dst) == 8) return err.at(L, try u.fmt(alloc, notb, .{raw}));
            try c.defs.append(alloc, dst);
            if (partialRegWrite(dst)) {
                try c.uses.append(alloc, dst);
                try c.rmw.append(alloc, dst.num.?);
            }
            try memRegs(alloc, src, &c.uses);
        } else return err.at(L, try u.fmt(alloc, "movbe requires a memory operand (the register-to-register spelling is not a baseline x86-64 encoding; use a mov plus bswap sequence instead): {s}", .{raw}));
    } else if (eq(u8, m, "shld") or eq(u8, m, "shrd")) {
        if (ops.len != 3)
            return err.at(L, try u.fmt(alloc, "{s} takes exactly three operands (destination, source, count): {s}", .{ rawMnem, raw }));
        try U.rmwFirst(alloc, &c, ops);
        try U.useOperand(alloc, &c, ops[1]);
        if (isGpr(ops[2])) {
            if (width(ops[2]) != 8 or ops[2].num.? != 1)
                return err.at(L, try u.fmt(alloc, "a shift/rotate count register must be %cl (the only register-count encoding in the ISA): {s}", .{raw}));
            try c.uses.append(alloc, ops[2]);
            var pin: ir.Pin = .{};
            try pin.uses.append(alloc, ops[2]);
            c.pin = pin;
            return c;
        }
    } else if (try u.matches(alloc, m, "^xchg[bwlq]?$")) {
        if ((at(ops, 0) != null and ops[0].kind == .mem) or (at(ops, 1) != null and ops[1].kind == .mem))
            return err.at(L, try u.fmt(alloc, "xchg with a memory operand is an implicitly locked read-modify-write (the hardware locks it even without a `lock` prefix; it is not one of the exactly-modeled memory RMWs; cannot prove memory safety): {s}", .{raw}));
        if (!(isGpr(at(ops, 0)) and isGpr(at(ops, 1))))
            return err.at(L, try u.fmt(alloc, "xchg needs two general registers (stack-pointer and vector-register exchanges are not supported): {s}", .{raw}));
        for (ops) |o| if (isHighByteOp(o)) {
            const partner = if (o == ops[0]) ops[1] else ops[0];
            const pw = width(partner);
            const pn = partner.num.?;
            const bad = (pw == 8 and pn > 3) or (pw == 16 and pn > 7) or (pw == 32 and pn > 7) or (pw != 8 and pw != 16 and pw != 32);
            if (bad)
                return err.at(L, try u.fmt(alloc, "high-byte register {s} cannot be combined with {s} (the partner requires a REX prefix, which a high-byte register cannot combine with): {s}", .{ try spelled(alloc, insn, o), try spelled(alloc, insn, partner), raw }));
        };
        const d1 = try imp(alloc, ops[0].num.?, 64, ops[0].name.?);
        const d2 = try imp(alloc, ops[1].num.?, 64, ops[1].name.?);
        try c.defs.append(alloc, d1);
        try c.defs.append(alloc, d2);
        try c.uses.append(alloc, ops[0]);
        try c.uses.append(alloc, ops[1]);
        var pin: ir.Pin = .{};
        try pin.uses.append(alloc, ops[0]);
        try pin.uses.append(alloc, ops[1]);
        try pin.defs.append(alloc, d1);
        try pin.defs.append(alloc, d2);
        c.pin = pin;
        return c;
    } else if (u.in(m, &.{ "mov", "movzx", "movsx", "lea", "cmov", "setcc" })) {
        const o0 = at(ops, 0);
        const dstMem = o0 != null and o0.?.kind == .mem;
        if (isGpr(o0)) try c.defs.append(alloc, o0.?) else if (dstMem) try memRegs(alloc, o0.?, &c.uses);
        if (dstMem and isGpr(at(ops, 1))) try c.uses.append(alloc, ops[1]);
        if (eq(u8, m, "cmov") and isGpr(o0)) {
            try c.uses.append(alloc, o0.?);
            try c.rmw.append(alloc, o0.?.num.?);
        }
        if (!eq(u8, m, "cmov") and isGpr(o0) and partialRegWrite(o0.?) and !(eq(u8, m, "setcc") and !(o0.?.isSlot orelse false))) {
            try c.uses.append(alloc, o0.?);
            try c.rmw.append(alloc, o0.?.num.?);
        }
        if (eq(u8, m, "mov") and isGpr(o0) and (o0.?.isSlot orelse false) and insn.x86_slotPartial != null and (insn.x86_slotPartial.?.write orelse false)) {
            try c.uses.append(alloc, try u.newOp(alloc, .{ .kind = .reg, .rc = .gpr, .num = o0.?.num, .width = 64, .name = o0.?.name, .isSlot = true, .implicit = true }));
            try c.rmw.append(alloc, o0.?.num.?);
        }
        if (ops.len > 1) for (ops[1..]) |o| {
            if (o.kind == .mem) try memRegs(alloc, o, &c.uses) else if (isGpr(o) and !dstMem) try c.uses.append(alloc, o);
        };
    } else if (eq(u8, m, "push")) {
        try U.useOperand(alloc, &c, at(ops, 0));
    } else if (eq(u8, m, "pop")) {
        if (isGpr(at(ops, 0))) {
            try c.defs.append(alloc, ops[0]);
            if (partialRegWrite(ops[0])) {
                try c.uses.append(alloc, ops[0]);
                try c.rmw.append(alloc, ops[0].num.?);
            }
        }
    } else if (eq(u8, m, "cld") or eq(u8, m, "std")) {
        if (ops.len != 0)
            return err.at(L, try u.fmt(alloc, "{s} takes no operands (it operates on the implicit direction flag): {s}", .{ rawMnem, raw }));
    } else if (u.in(rawMnem, &FLAG_PUSH)) {
        if (ops.len != 0)
            return err.at(L, try u.fmt(alloc, "{s} takes no operands (it pushes the implicit RFLAGS): {s}", .{ rawMnem, raw }));
        try c.defs.append(alloc, try flagsWordOperand(alloc));
        c.flagsPush = true;
        return c;
    } else if (u.in(rawMnem, &FLAG_POP)) {
        if (ops.len != 0)
            return err.at(L, try u.fmt(alloc, "{s} takes no operands (it pops the implicit RFLAGS): {s}", .{ rawMnem, raw }));
        try c.uses.append(alloc, try flagsWordOperand(alloc));
        c.flagsPop = true;
        return c;
    } else {
        for (ops) |o| if (o.kind == .mem)
            return err.at(L, try u.fmt(alloc, "cannot determine the memory access width of '{s}' (cannot prove memory safety): {s}", .{ rawMnem, raw }));
        var firstReg = true;
        for (ops) |o| {
            if (isGpr(o)) {
                if (firstReg) {
                    try c.defs.append(alloc, o);
                    if (partialRegWrite(o)) {
                        try c.uses.append(alloc, o);
                        try c.rmw.append(alloc, o.num.?);
                    }
                    firstReg = false;
                } else try c.uses.append(alloc, o);
            } else if (o.kind == .mem) try memRegs(alloc, o, &c.uses);
        }
        c.unknown = true;
        return c;
    }
    return c;
}

pub fn gprAccessRegWidth(alloc: Allocator, stmt: *const ir.Stmt) E!?f64 {
    const b = try baseMnemonic(alloc, mnemOf(stmt));
    if (u.in(b, &.{ "lea", "movzx", "movsx" })) return null;
    if (stmt.opsize) |s| return s;
    for (stmt.operands.items) |o| if (isGpr(o)) return @max(1, @floor((o.width orelse 64) / 8));
    return null;
}

// ---------------------------------------------------------------------------
// register / calling-convention configuration (SysV AMD64 + the Fil-C fast entrypoint)

pub const ALLOCATABLE = [_][]const u8{ "rax", "rcx", "rdx", "rbx", "rbp", "rsi", "rdi", "r8", "r9", "r10", "r12", "r13", "r14", "r15" };
pub const CALLEE_SAVED_ORDER = [_][]const u8{ "rbx", "rbp", "r12", "r13", "r14", "r15" };
pub fn isCalleeSaved(r: []const u8) bool {
    return u.in(r, &CALLEE_SAVED_ORDER);
}
pub fn isCallerSaved(r: []const u8) bool {
    return u.in(r, &.{ "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10" });
}
pub fn isArgReg(num: f64) bool {
    return num == 7 or num == 6 or num == 2 or num == 1 or num == 8 or num == 9;
}
pub const SCRATCH = "r11";
pub const SCRATCH_NUM: f64 = 11;
pub const CALLER_SAVED_NUMS = [_]f64{ 0, 1, 2, 6, 7, 8, 9, 10 };
pub const SYSV = [_]f64{ 7, 6, 2, 1, 8, 9 };

const DENSE_ARG_REGS = [_]f64{ 2, 1, 8, 9 };
const DENSE_ARG_REG_COUNT = 4;

/// argTypes[k] (1-based), nil past the end.
fn argType(argTypes: []const u8, k: usize) ?u8 {
    return if (k >= 1 and k <= argTypes.len) argTypes[k - 1] else null;
}
fn isFp(t: ?u8) bool {
    return if (t) |x| sig.isFpClass(x) else false;
}

fn denseArgSlot(argTypes: []const u8, k: usize) usize {
    var slot: usize = 1;
    var i: usize = 1;
    while (i + 1 <= k) : (i += 1) {
        const t = argType(argTypes, i);
        if (isFp(t)) {} else if (t != null and t.? == sig.TYPE_PTR) slot += 2 else slot += 1;
    }
    return slot;
}
fn denseReg(slot: usize) ?f64 {
    return if (slot >= 1 and slot <= DENSE_ARG_REGS.len) DENSE_ARG_REGS[slot - 1] else null;
}

pub const CC = struct {
    pub const myth: f64 = 7;
    pub const fo: f64 = 6;
    pub const argRegCount = DENSE_ARG_REG_COUNT;
    pub const yoloRegCount = 6;
    pub const retFlag: f64 = 0;
    pub const retIv: f64 = 2;
    pub const retLo: f64 = 1;
    pub fn argIv(argTypes: []const u8, k: usize) ?f64 {
        return denseReg(denseArgSlot(argTypes, k));
    }
    pub fn argLo(argTypes: []const u8, k: usize) ?f64 {
        return denseReg(denseArgSlot(argTypes, k) + 1);
    }
    pub fn denseSlot(argTypes: []const u8, k: usize) usize {
        return denseArgSlot(argTypes, k) - 1;
    }
    pub fn yoloArg(k: usize, argTypes: ?[]const u8) ?f64 {
        if (argTypes) |at_| if (isFp(argType(at_, k))) return null;
        var nn: usize = 0;
        if (argTypes) |at_| {
            var i: usize = 1;
            while (i + 1 <= k) : (i += 1) {
                if (!isFp(argType(at_, i))) nn += 1;
            }
        } else nn = k - 1;
        return if (nn < SYSV.len) SYSV[nn] else null;
    }
    pub fn fpArgOrdinal(argTypes: []const u8, k: usize) usize {
        var mm: usize = 0;
        var i: usize = 1;
        while (i + 1 <= k) : (i += 1) {
            if (isFp(argType(argTypes, i))) mm += 1;
        }
        return mm;
    }
};
