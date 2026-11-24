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
    // set on the operands lift adds to a classification (the return / call marshalling registers)
    retReg: ?bool = null,
    argReg: ?bool = null,
    resultReg: ?bool = null,
};

/// localcall.luau's marks on a call / ret statement.
pub const LocalCall = struct { entry: []const u8, clone: ?f64 = null, cont: ?[]const u8 = null };
pub const LocalRet = struct { conts: []const []const u8, clone: ?f64 = null, entry: ?[]const u8 = null };
/// x86_64_frame.analyzeFrame's per-statement marks (upstream's `st.x86_*` fields): its OUTPUT,
/// cleared at the start of every run. Fields are added as the analysis is ported.
pub const FrameMarks = struct {
    /// x86_prologue (set by the annotation pass, after the fixpoint; nil during it)
    prologue: ?bool = null,
    // set by the depth fixpoint's transfer
    stackBufLeaValueComputed: ?bool = null,
    carrierCallArg: ?CarrierCallArg = null,
    stackBufRep: ?BufRep = null,
};
/// x86_carrierCallArg: a call reading a live carrier as a yolo argument register.
pub const CarrierCallArg = struct { name: []const u8, form: ?[]const u8 };
/// x86StackBufRep: an annotated rep's buffer range and its stack-alias side (upstream rebuilds
/// the table for each side, so one side — the last — survives).
pub const BufRep = struct { lo: f64, hi: f64, id: []const u8, side: ?BufRepSide = null };
pub const BufRepSide = struct { name: []const u8, K: f64, num: f64, isWrite: bool };

/// tailcall.luau's mark on a cloned `ret`.
pub const CloneRet = struct { entry: []const u8 };
/// transform's parsed `#! stack buffer (...)` annotation: the long form carries base / lo / hi.
pub const StackBufAnno = struct { id: []const u8, short: bool, base: ?[]const u8 = null, lo: ?f64 = null, hi: ?f64 = null };
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
    // transform's (tailcall / localcall / stack-buffer) marks, read by x86_64_frame
    b2clone: ?f64 = null,
    cloneRet: ?CloneRet = null,
    crossJumpEntry: ?bool = null,
    localClone: ?f64 = null,
    localCloneEntry: ?bool = null,
    stackBufAnno: ?StackBufAnno = null,
    tailCall: ?bool = null,
    tailRet: ?bool = null,
    /// x86_64_frame's marks
    x86: FrameMarks = .{},

    pub fn loc(st: *const Stmt) @import("err.zig").Loc {
        return .{ .file = st.file, .line = st.line };
    }
};
