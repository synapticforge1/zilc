// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//! The parse IR shared by sarcasm's passes: statements and operands, as upstream's Luau tables
//! carry them (projects/sarcasm/sarcasm/x86_64_parse.luau's operand model). Each Luau field is an
//! optional field of the same name (nil = null), so a pass that sets or clears one does the same
//! here; numbers are f64 as in Luau. Fields later passes add (the frame pass's `x86_*`, …) are
//! added here as those passes are ported.

const std = @import("std");

pub const OpKind = enum { reg, imm, sym, mem, numref };
pub const RegClass = enum { gpr, sp, rip, seg, xmm };

pub const Operand = struct {
    kind: OpKind,
    // reg
    rc: ?RegClass = null,
    num: ?f64 = null,
    width: ?f64 = null,
    name: ?[]const u8 = null,
    pseudo: ?[]const u8 = null,
    indirect: ?bool = null,
    // imm / sym / numref
    text: ?[]const u8 = null,
    value: ?f64 = null,
    absAddr: ?bool = null,
    reloc: ?[]const u8 = null,
    /// numref's `num` (a STRING in Luau: the label's digits) and `dir` ("f" / "b")
    refNum: ?[]const u8 = null,
    dir: ?[]const u8 = null,
    // mem
    base: ?*Operand = null,
    index: ?*Operand = null,
    scale: ?f64 = null,
    dispVal: ?f64 = null,
    dispSym: ?[]const u8 = null,
    dispReloc: ?[]const u8 = null,
    size: ?f64 = null,
    deco: ?[]const u8 = null,
    bcastN: ?f64 = null,
    // set on the operands x86_64_isa.classify makes (implicit registers), and by the frame pass
    implicit: ?bool = null,
    fixedReg: ?[]const u8 = null,
    isSlot: ?bool = null,
};

/// localcall.luau's marks on a call / ret statement.
pub const LocalCall = struct { entry: []const u8 };
pub const LocalRet = struct { conts: []const []const u8 };
/// x86_64_frame's routing marker on a narrow slot access.
pub const SlotPartial = struct { write: ?bool = null };

/// What x86_64_isa.classify (and x86_64_fp.classify) returns for an instruction: upstream's
/// `{ defs, uses, rmw, control, targets, fallsThrough, pin, rep, flagsPush, flagsPop, unknown }`.
/// defs / uses hold the statement's own operand tables or fresh implicit ones; which is which
/// matters (the lift keys by table identity), so they are pointers as in Luau.
pub const Control = enum { none, branch, condbranch, call, indcall, indirect, @"return" };
pub const Pin = struct { uses: std.ArrayList(*Operand) = .empty, defs: std.ArrayList(*Operand) = .empty };
pub const Rep = struct {
    kind: []const u8,
    elem: ?f64,
    repPrefix: ?[]const u8,
    rsi: ?*Operand = null,
    rdi: ?*Operand = null,
    rax: ?*Operand = null,
    rcxUse: ?*Operand = null,
    rcxDef: ?*Operand = null,
};
pub const Class = struct {
    defs: std.ArrayList(*Operand) = .empty,
    uses: std.ArrayList(*Operand) = .empty,
    rmw: std.ArrayList(f64) = .empty,
    control: Control = .none,
    /// nil, or a list (jmp / jcc / loop: possibly empty)
    targets: ?[]const []const u8 = null,
    fallsThrough: bool = true,
    pin: ?Pin = null,
    rep: ?Rep = null,
    flagsPush: bool = false,
    flagsPop: bool = false,
    unknown: bool = false,
};

pub const StmtKind = enum { insn, label, directive, blank };

pub const Stmt = struct {
    kind: StmtKind,
    line: ?u32 = null,
    file: ?[]const u8 = null,
    annotation: ?[]const u8 = null,
    // label / directive
    name: ?[]const u8 = null,
    args: ?[]const u8 = null,
    // blank
    text: ?[]const u8 = null,
    // insn (and directive's raw)
    mnemonic: ?[]const u8 = null,
    operands: std.ArrayList(*Operand) = .empty,
    opsize: ?f64 = null,
    raw: ?[]const u8 = null,
    syntax: ?[]const u8 = null,
    lockPrefix: ?bool = null,
    repPrefix: ?[]const u8 = null,
    dotAlloca: ?bool = null,
    // later passes' marks
    localCall: ?LocalCall = null,
    localRet: ?LocalRet = null,
    x86_slotPartial: ?SlotPartial = null,

    pub fn loc(st: *const Stmt) @import("err.zig").Loc {
        return .{ .file = st.file, .line = st.line };
    }
};
