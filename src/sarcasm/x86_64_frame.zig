// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//! The x86_64 frame policy (a port of projects/sarcasm/sarcasm/x86_64_frame.luau, Fil-C 0.687,
//! IN PROGRESS — cmem/sarcasm-port.md "x86_64_frame"): frame geometry from the prologue prefix,
//! the control-flow rsp-depth / save-pairing analysis, the FP materialization, stack buffers,
//! and the per-statement rewrite.
//!
//! Upstream's analyzeFrame is one ~6,500-line function whose locals its closures share; here
//! they are the fields of `Analysis` and the closures its methods, run phase by phase in
//! upstream's order. Each phase ends at a CHECKPOINT (`Stop`) whose state the stage check dumps
//! against a patched copy of upstream stopped at the same line (tools/sarcasm/check-stages.ts,
//! stage xframe). Module state is upstream's (single-threaded discipline: analyzeFrame sets it,
//! rewrite reads it; the stack-buffer table lives for a file).
//!
//! Ported so far: upstream lines 128–339 (module state, the helpers the early phases use) and
//! 677–1189 (analyzeFrame up to the end of the prologue prefix scan: checkpoint 1).

const std = @import("std");
const err = @import("err.zig");
const ir = @import("ir.zig");
const frameShared = @import("frame.zig");
const isa = @import("x86_64_isa.zig");
const fp = @import("x86_64_fp.zig");
const sig = @import("sig.zig");
const ln = @import("luau_number.zig");
const u = @import("util.zig");

const Allocator = std.mem.Allocator;
const E = err.Error;
const Op = ir.Operand;
const Stmt = ir.Stmt;
const eq = std.mem.eql;

// ---------------------------------------------------------------------------
// helpers (upstream 137–257)

fn widthLetter(c: u8) ?f64 {
    return switch (c) {
        'b' => 1,
        'w' => 2,
        'l' => 4,
        'q' => 8,
        else => null,
    };
}

fn isStackReg(op: ?*const Op, usesRbp: bool) bool {
    const o = op orelse return false;
    return o.kind == .reg and (o.rc == .sp or (usesRbp and u.eql(o.name, "rbp")));
}

/// `op.value or tonumber(op.text) or 0` for an immediate, else 0.
fn immVal(op: ?*const Op) f64 {
    return frameShared.immVal(op);
}

/// A power of two >= 16 (an `and $-n, %rsp` alignment note).
fn isStackAlign(n_in: f64) bool {
    var n = n_in;
    if (n < 16) return false;
    while (@mod(n, 2) == 0) n = n / 2;
    return n == 1;
}

fn at(ops: []const *Op, i: usize) ?*Op {
    return if (i < ops.len) ops[i] else null;
}
fn rcIs(o: ?*const Op, rc: ir.RegClass) bool {
    const x = o orelse return false;
    return x.rc == rc;
}
fn kindIs(o: ?*const Op, k: ir.OpKind) bool {
    const x = o orelse return false;
    return x.kind == k;
}
fn nameIs(o: ?*const Op, n: []const u8) bool {
    const x = o orelse return false;
    return u.eql(x.name, n);
}
fn width64OrNil(o: *const Op) bool {
    return o.width == null or o.width.? == 64;
}

/// Reads or writes rsp (operand or memory base / index), or accesses memory through rbp while it
/// is the frame pointer.
fn insnTouchesFrame(st: *const Stmt, usesRbp: bool) bool {
    for (st.operands.items) |o| {
        if (o.kind == .reg) {
            if (o.rc == .sp) return true;
        } else if (o.kind == .mem) {
            if (rcIs(o.base, .sp) or rcIs(o.index, .sp)) return true;
            if (usesRbp and nameIs(o.base, "rbp")) return true;
        }
    }
    return false;
}

/// Writes rsp (destination operand, or the implicit push / pop write, the RFLAGS stack transfers
/// included).
fn insnWritesSp(alloc: Allocator, st: *const Stmt) E!bool {
    const ops = st.operands.items;
    if (kindIs(at(ops, 0), .reg) and rcIs(at(ops, 0), .sp)) return true;
    const m = try u.lower(alloc, st.mnemonic.?);
    const b = try isa.baseMnemonic(alloc, m);
    return eq(u8, b, "push") or eq(u8, b, "pop") or isa.isFlagStackXfer(m);
}

// ---------------------------------------------------------------------------
// module state (upstream 262–340, 365–367): set by analyzeFrame, read by the rewrite

pub var D0: f64 = 0;
pub var rbpNorm: f64 = 0;
pub var maskScratchNum: ?f64 = null;
pub var frameAlignReq: f64 = 16;
pub var frameAndDepth: f64 = 0;
pub var frameAndIdx: ?usize = null;
pub var frameAndSeen: bool = false;
/// normalized frame offset -> true (8-byte GPR slot traffic)
pub var slotGranules: std.AutoArrayHashMapUnmanaged(u64, void) = .empty;
pub var cloneRetProofRan: bool = false;
pub var yoloCount: f64 = 0;
pub var yoloBase: ?f64 = null;

pub const Canon = struct { lo: f64, hi: f64, fn_: ?[]const u8 = null, sub: ?bool = null, st: ?*const Stmt = null };
/// id -> the file-wide canonical normalized range (null: no table)
pub var sbCanon: ?std.StringArrayHashMapUnmanaged(Canon) = null;
pub var sbResolving: bool = false;

var state_arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);

pub fn beginStackBufResolution() void {
    sbCanon = .empty;
    sbResolving = true;
}
pub fn endStackBufResolution() void {
    sbResolving = false;
}
pub fn stackBufCanonOf(id: []const u8) ?Canon {
    if (sbCanon) |c| return c.get(id);
    return null;
}
pub fn recordStackBufCanon(id: []const u8, lo: f64, hi: f64, fnName: ?[]const u8, isSub: bool, st: ?*const Stmt) E!void {
    try sbCanon.?.put(state_arena.allocator(), id, .{ .lo = lo, .hi = hi, .fn_ = fnName, .sub = if (isSub) true else null, .st = st });
}

pub fn isDynDepth(d: Depth) bool {
    return d == .dyn;
}

// ---------------------------------------------------------------------------
// analyzeFrame's data

/// The abstract rsp depth: bytes below the entry rsp, or "dyn" (unknown). (Upstream's historical
/// table depths are unreachable; isDynDepth covers every non-numeric form.)
pub const Depth = union(enum) { num: f64, dyn };

pub const PSave = struct { name: []const u8, depth: f64 };
pub const ProbeRange = struct { lo: f64, hi: f64, id: []const u8 };

/// Where analyzeFrame stops (for the stage check's checkpoints); `none` runs to the end.
pub const Stop = enum { none, prologue };

/// analyzeFrame's locals. Field names are upstream's.
pub const Analysis = struct {
    alloc: Allocator,
    body: []const *Stmt,
    sigDesc: ?*const sig.Descriptor,
    regions: ?[]const *frameShared.Region,

    bufProbeRanges: ?std.ArrayList(ProbeRange) = null,
    bufProbeSuppress: bool = false,
    /// clone idx -> the long forms its statements declare (insertion-ordered)
    bufB2DeclRaw: ?std.AutoArrayHashMapUnmanaged(u64, std.ArrayList(*const ir.StackBufAnno)) = null,
    /// register number -> true
    bufRepRegs: std.AutoArrayHashMapUnmanaged(u64, void) = .empty,
    sigHasFp: bool = false,
    /// jump-target label names
    targeted: std.StringArrayHashMapUnmanaged(void) = .empty,
    /// label -> index (1-based) of the insn it precedes (#body + 1 past the end)
    labelAt: std.StringArrayHashMapUnmanaged(usize) = .empty,
    /// nextInsn[i - 1] for 1-based i
    nextInsn: []usize = &.{},

    depth: f64 = 0,
    subBytes: f64 = 0,
    spillBytes: f64 = 0,
    pstack: std.ArrayList(PSave) = .empty,
    fpDepth: ?f64 = null,
    usesRbp: bool = false,
    prologueEnd: usize = 0,
    frameSize: f64 = 0,

    fn st_(a: *Analysis, i: usize) *Stmt {
        return a.body[i - 1];
    }

    /// regionOf (upstream 827).
    pub fn regionOf(a: *Analysis, off: f64, dyn: bool) ?*frameShared.Region {
        for (a.regions orelse &.{}) |r| {
            if ((r.anchored orelse false) == dyn and off >= r.base and off < r.base + r.size) return r;
        }
        return null;
    }

    /// isSpillPushForm (upstream 939): a prologue push of a full-width caller-saved register.
    fn isSpillPushForm(a: *Analysis, st: *const Stmt) E!bool {
        const ops = st.operands.items;
        if (!eq(u8, try isa.baseMnemonic(a.alloc, try u.lower(a.alloc, st.mnemonic.?)), "push")) return false;
        const o = at(ops, 0) orelse return false;
        return o.kind == .reg and o.rc == .gpr and width64OrNil(o) and !isa.isCalleeSaved(o.name orelse "");
    }

    /// Upstream 685–868: clear the previous run's marks, reset the module state, the stack
    /// buffer probes, sigHasFp and the yolo count.
    fn setup(a: *Analysis) E!void {
        const alloc = a.alloc;
        for (a.body) |st| st.x86 = .{};
        frameAlignReq = 16;
        frameAndDepth = 0;
        frameAndIdx = null;
        frameAndSeen = false;
        slotGranules = .empty;
        cloneRetProofRan = a.regions != null;

        for (a.body) |st| {
            if (st.kind == .insn and st.stackBufAnno != null and st.repPrefix != null) {
                try a.bufRepRegs.put(alloc, @bitCast(@as(f64, 6)), {});
                try a.bufRepRegs.put(alloc, @bitCast(@as(f64, 7)), {});
            }
        }
        var hasDecl = false;
        for (a.body) |st| if (st.kind == .insn and st.stackBufAnno != null and !st.stackBufAnno.?.short) {
            hasDecl = true;
            break;
        };
        if (hasDecl) {
            a.bufProbeSuppress = sbResolving;
            for (a.body) |st| if (st.kind == .insn and st.stackBufAnno != null and !st.stackBufAnno.?.short) {
                if (stackBufCanonOf(st.stackBufAnno.?.id)) |canon| {
                    if (a.bufProbeRanges == null) a.bufProbeRanges = .empty;
                    try a.bufProbeRanges.?.append(alloc, .{ .lo = canon.lo, .hi = canon.hi, .id = st.stackBufAnno.?.id });
                }
            };
            for (a.body) |st| if (st.kind == .insn and st.stackBufAnno != null and !st.stackBufAnno.?.short and st.b2clone != null) {
                if (a.bufB2DeclRaw == null) a.bufB2DeclRaw = .empty;
                const g = try a.bufB2DeclRaw.?.getOrPut(alloc, @bitCast(st.b2clone.?));
                if (!g.found_existing) g.value_ptr.* = .empty;
                try g.value_ptr.append(alloc, &st.stackBufAnno.?);
            };
        }

        if (a.sigDesc) |sd| {
            if (sd.retTypes.len > 0 and sig.isFpClass(sd.retTypes[0])) {
                a.sigHasFp = true;
            } else for (sd.argTypes) |t| if (sig.isFpClass(t)) {
                a.sigHasFp = true;
                break;
            };
        }
        yoloCount = 0;
        yoloBase = null;
        if (a.sigDesc) |sd| {
            var nf: usize = 0;
            for (sd.argTypes) |t| if (!sig.isFpClass(t)) {
                nf += 1;
                if (nf > 6) yoloCount += 1;
            };
        }
    }

    /// Upstream 872–927: jump targets, labelAt, nextInsn (and the machine check of both).
    fn indexBody(a: *Analysis) E!void {
        const alloc = a.alloc;
        const body = a.body;
        for (body) |st| if (st.kind == .insn) {
            const b = try isa.baseMnemonic(alloc, try u.lower(alloc, st.mnemonic.?));
            if (eq(u8, b, "jmp") or eq(u8, b, "jcc")) {
                for (st.operands.items) |o| if (o.kind == .sym) try a.targeted.put(alloc, o.text.?, {});
            }
        };
        var pending: std.ArrayList([]const u8) = .empty;
        for (body, 1..) |st, i| {
            if (st.kind == .insn) {
                for (pending.items) |n| try a.labelAt.put(alloc, n, i);
                pending.clearRetainingCapacity();
            } else if (st.kind == .label) try pending.append(alloc, st.name.?);
        }
        for (pending.items) |n| try a.labelAt.put(alloc, n, body.len + 1);
        a.nextInsn = try alloc.alloc(usize, body.len);
        var nxt = body.len + 1;
        var i = body.len;
        while (i >= 1) : (i -= 1) {
            a.nextInsn[i - 1] = nxt;
            if (body[i - 1].kind == .insn) nxt = i;
        }
        for (a.labelAt.values()) |t| if (!(t == body.len + 1 or (t <= body.len and body[t - 1].kind == .insn)))
            @panic("sarcasm: internal error: label mapped to a non-insn statement");
        for (a.nextInsn) |n| if (!(n == body.len + 1 or (n <= body.len and body[n - 1].kind == .insn)))
            @panic("sarcasm: internal error: nextInsn mapped to a non-insn statement");
    }

    /// Upstream 947–1189: the prologue prefix scan, D0, rbpNorm, frameSize.
    fn prologueScan(a: *Analysis) E!void {
        const alloc = a.alloc;
        const body = a.body;
        a.prologueEnd = body.len + 1;
        var i: usize = 1;
        scan: while (i <= body.len) : (i += 1) {
            const st = body[i - 1];
            if (st.kind != .insn) {
                if (st.kind == .label and a.targeted.contains(st.name.?)) {
                    a.prologueEnd = i;
                    break :scan;
                }
                continue;
            }
            const m = try u.lower(alloc, st.mnemonic.?);
            const b = try isa.baseMnemonic(alloc, m);
            const ops = st.operands.items;
            const o0 = at(ops, 0);
            const o1 = at(ops, 1);
            if (eq(u8, b, "push") and kindIs(o0, .reg) and isa.isCalleeSaved(o0.?.name orelse "")) {
                a.depth += 8;
                try a.pstack.append(alloc, .{ .name = o0.?.name.?, .depth = a.depth });
            } else if (eq(u8, b, "pop") and kindIs(o0, .reg) and isa.isCalleeSaved(o0.?.name orelse "") and a.pstack.items.len > 0 and
                eq(u8, a.pstack.items[a.pstack.items.len - 1].name, o0.?.name.?) and a.pstack.items[a.pstack.items.len - 1].depth == a.depth and
                !(a.usesRbp and nameIs(o0, "rbp")))
            {
                a.depth -= 8;
                _ = a.pstack.pop();
            } else if (try a.isSpillPushForm(st)) {
                a.depth += 8;
                a.spillBytes += 8;
            } else if (eq(u8, b, "push") or eq(u8, b, "pop") or isa.isFlagStackXfer(m)) {
                a.prologueEnd = i;
                break :scan;
            } else if (eq(u8, b, "mov") and nameIs(o0, "rbp") and rcIs(o1, .sp) and !a.usesRbp) {
                a.usesRbp = true;
                a.fpDepth = a.depth;
            } else if (eq(u8, b, "lea") and kindIs(o0, .reg) and nameIs(o0, "rbp") and kindIs(o1, .mem) and rcIs(o1.?.base, .sp) and
                o1.?.index == null and o1.?.dispSym == null and (o1.?.dispVal orelse 0) == 0)
            {
                if (!a.usesRbp) {
                    a.usesRbp = true;
                    a.fpDepth = a.depth;
                } else {
                    a.prologueEnd = i;
                    break :scan;
                }
            } else if (eq(u8, b, "mov") and rcIs(o1, .sp) and rcIs(o0, .gpr) and !nameIs(o0, "rbp")) {
                // the prologue parked the stack pointer: transparent
            } else if (eq(u8, b, "sub") and rcIs(o0, .sp) and kindIs(o1, .imm)) {
                a.depth += immVal(o1);
                a.subBytes += immVal(o1);
            } else if (eq(u8, b, "add") and rcIs(o0, .sp) and kindIs(o1, .imm) and immVal(o1) <= a.subBytes) {
                const ni = a.nextInsn[i - 1];
                if (ni <= body.len and body[ni - 1].kind == .insn and eq(u8, try isa.baseMnemonic(alloc, try u.lower(alloc, body[ni - 1].mnemonic.?)), "ret")) {
                    a.prologueEnd = i;
                    break :scan;
                }
                a.depth -= immVal(o1);
                a.subBytes -= immVal(o1);
            } else if (eq(u8, b, "lea") and rcIs(o0, .sp) and kindIs(o1, .mem) and rcIs(o1.?.base, .sp) and o1.?.index == null and o1.?.dispSym == null) {
                const v = o1.?.dispVal orelse 0;
                if (v < 0) {
                    a.depth += -v;
                    a.subBytes += -v;
                } else if (v > 0 and v <= a.subBytes) {
                    a.depth -= v;
                    a.subBytes -= v;
                } else if (v != 0) {
                    a.prologueEnd = i;
                    break :scan;
                }
            } else if (eq(u8, b, "and") and rcIs(o0, .sp) and kindIs(o1, .imm)) {
                const n = -immVal(o1);
                if (isStackAlign(n)) {
                    frameAndSeen = true;
                    if (n > frameAlignReq) {
                        frameAlignReq = n;
                        frameAndDepth = a.depth;
                    } else if (n == 16 and frameAlignReq == 16) frameAndDepth = a.depth;
                    frameAndIdx = i;
                } else {
                    a.prologueEnd = i;
                    break :scan;
                }
            } else if (eq(u8, b, "lea") and kindIs(o0, .reg) and !rcIs(o0, .sp) and kindIs(o1, .mem) and
                ((o1.?.base != null and (rcIs(o1.?.base, .sp) or (a.usesRbp and nameIs(o1.?.base, "rbp")))) or rcIs(o1.?.index, .sp)))
            {
                const lm = o1.?;
                if (rcIs(lm.base, .sp) and lm.index == null and lm.dispSym == null and (lm.dispVal orelse 0) > 0 and (lm.dispVal orelse 0) < a.depth) {
                    a.prologueEnd = i;
                    break :scan;
                }
            } else if (eq(u8, b, "lea") and kindIs(o0, .reg) and rcIs(o0, .sp)) {
                a.prologueEnd = i;
                break :scan;
            } else if (try insnWritesSp(alloc, st)) {
                a.prologueEnd = i;
                break :scan;
            } else if (eq(u8, b, "nop")) {
                // endbr64 / padding: transparent
            } else if (eq(u8, b, "jcc")) {
                // a leading conditional branch guarding the frame setup: transparent
            } else if (eq(u8, b, "jmp") or eq(u8, b, "call") or eq(u8, b, "ret") or eq(u8, b, "leave") or std.mem.startsWith(u8, m, "loop")) {
                a.prologueEnd = i;
                break :scan;
            } else if (st.repPrefix != null or (ops.len == 0 and ((try u.matches(alloc, m, "^movs[bwlqd]?$")) or (try u.matches(alloc, m, "^stos[bwlqd]?$"))))) {
                a.prologueEnd = i;
                break :scan;
            } else if (insnTouchesFrame(st, a.usesRbp)) {
                a.prologueEnd = i;
                break :scan;
            } else if (a.usesRbp and kindIs(o0, .reg) and nameIs(o0, "rbp")) {
                a.prologueEnd = i;
                break :scan;
            }
        }
        D0 = a.depth;
        rbpNorm = if (a.usesRbp) a.depth - a.fpDepth.? else 0;
        a.frameSize = if (a.usesRbp) @max(rbpNorm, a.subBytes + a.spillBytes) else a.subBytes + a.spillBytes;
    }
};

/// analyzeFrame, up to `stop` (the stage check's checkpoints). Returns the analysis.
pub fn analyzeFrameTo(alloc: Allocator, body: []const *Stmt, sigDesc: ?*const sig.Descriptor, regions: ?[]const *frameShared.Region, stop: Stop) E!*Analysis {
    const a = try alloc.create(Analysis);
    a.* = .{ .alloc = alloc, .body = body, .sigDesc = sigDesc, .regions = regions };
    try a.setup();
    try a.indexBody();
    try a.prologueScan();
    if (stop == .prologue) return a;
    @panic("x86_64_frame: analyzeFrame is ported only to the prologue checkpoint");
}
