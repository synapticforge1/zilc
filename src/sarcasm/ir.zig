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

    pub fn loc(st: *const Stmt) @import("err.zig").Loc {
        return .{ .file = st.file, .line = st.line };
    }
};
