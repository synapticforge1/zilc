// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//! Frame preprocessing, the architecture-independent skeleton (a port of
//! projects/sarcasm/sarcasm/frame.luau, Fil-C 0.687): the input's own stack frame becomes
//! virtual slot registers. The per-statement rewrite is the architecture's `Policy`
//! (x86_64_frame), given a `Ctx` with the slot constructor, region lookup, bounds check, escape
//! rejection and the output sink, exactly the closures upstream's ctx carries.

const std = @import("std");
const err = @import("err.zig");
const ir = @import("ir.zig");
const ln = @import("luau_number.zig");
const u = @import("util.zig");

const Allocator = std.mem.Allocator;
const E = err.Error;

/// Slot pseudo-registers: SLOT_BASE + byte offset (never a real GPR, never precolored).
pub const SLOT_BASE: f64 = 1000;
/// The yolo incoming stack-argument slots (x86_64): a band below the frame slots.
pub const YOLO_SLOT_BASE: f64 = 500;

pub fn yoloSlotNum(index: f64) f64 {
    return YOLO_SLOT_BASE + 8 * index;
}

pub fn yoloSlotReg(alloc: Allocator, index: f64, width: ?f64) E!*ir.Operand {
    return u.newOp(alloc, .{ .kind = .reg, .rc = .gpr, .num = yoloSlotNum(index), .width = width orelse 64, .name = try u.fmt(alloc, "__yoloarg{s}", .{try u.num(alloc, index)}), .isSlot = true });
}

pub fn slotReg(alloc: Allocator, off: f64, width: ?f64) E!*ir.Operand {
    return u.newOp(alloc, .{ .kind = .reg, .rc = .gpr, .num = SLOT_BASE + off, .width = width orelse 64, .name = try u.fmt(alloc, "__slot{s}", .{try u.num(alloc, off)}), .isSlot = true });
}

/// `op.value or tonumber(op.text) or 0` for an immediate, else 0.
pub fn immVal(op: ?*const ir.Operand) f64 {
    const o = op orelse return 0;
    if (o.kind != .imm) return 0;
    if (o.value) |v| return v;
    if (o.text) |t| if (ln.tonumber(t)) |v| return v;
    return 0;
}

/// A GC-allocation region (transform's): the fields frame reads, and the transform's own data.
pub const Region = struct {
    base: f64,
    size: f64,
    anchored: ?bool = null,
    // transform's region fields (x86_64_frame reads them)
    @"align": ?f64 = null,
    frameRegion: ?bool = null,
    ext: ?*anyopaque = null,
};

/// What policy.analyzeFrame returns: frameSize, fpOffset, usesFp[, fpInfo].
pub const FrameInfo = struct {
    frameSize: f64,
    fpOffset: ?f64 = null,
    usesFp: ?bool = null,
    fpInfo: ?*anyopaque = null,
};

pub const Policy = struct {
    ptr: *anyopaque,
    analyzeFrame: *const fn (ptr: *anyopaque, alloc: Allocator, body: []const *ir.Stmt, sigDesc: ?*const anyopaque, regions: ?[]const *Region) E!FrameInfo,
    rewrite: *const fn (ptr: *anyopaque, alloc: Allocator, st: *ir.Stmt, ctx: *Ctx) E!void,
};

pub const Ctx = struct {
    alloc: Allocator,
    frameSize: f64,
    fpOffset: ?f64,
    usesFp: ?bool,
    fpInfo: ?*anyopaque,
    regions: ?[]const *Region,
    out: std.ArrayList(*ir.Stmt) = .empty,

    pub fn emit(c: *Ctx, n: *ir.Stmt) E!void {
        try c.out.append(c.alloc, n);
    }

    /// The region containing `off` in one coordinate space: `dyn` the alignment-anchored regions,
    /// else the lea / mov-anchored ones.
    pub fn regionOf(c: *Ctx, off: f64, dyn: bool) ?*Region {
        for (c.regions orelse &.{}) |r| {
            if ((r.anchored orelse false) == dyn and off >= r.base and off < r.base + r.size) return r;
        }
        return null;
    }

    fn raise(st: ?*const ir.Stmt, msg: []const u8) E {
        if (st) |s| return err.at(s.loc(), msg);
        return err.plain(msg);
    }

    /// `lowBound` overrides the lowest legal offset (default 0); `st` locates the rejection.
    pub fn checkBounds(c: *Ctx, off: f64, width: f64, isWrite: bool, raw: ?[]const u8, lowBound: ?f64, st: ?*const ir.Stmt) E!void {
        const a = c.alloc;
        const rw = raw orelse "?";
        if (off < (lowBound orelse 0)) return raise(st, try u.fmt(a, "stack access below frame (sp offset {s}): {s}", .{ try u.num(a, off), rw }));
        if (off + width > c.frameSize) {
            if (isWrite) return raise(st, try u.fmt(a, "store into the caller's argument area / outside the frame (sp offset {s}, frame size {s}): {s}", .{ try u.num(a, off), try u.num(a, c.frameSize), rw }));
            return raise(st, try u.fmt(a, "stack access outside the frame (sp offset {s}, frame size {s}): {s}", .{ try u.num(a, off), try u.num(a, c.frameSize), rw }));
        }
    }

    pub fn rejectEscape(c: *Ctx, raw: ?[]const u8, st: ?*const ir.Stmt) E {
        return raise(st, try u.fmt(c.alloc, "taking address of stack frame is not supported (cannot prove safety): {s}", .{raw orelse "?"}));
    }
};

/// frame.preprocess: rewrite `body` with the architecture `policy`.
pub fn preprocess(alloc: Allocator, body: []const *ir.Stmt, regions: ?[]const *Region, policy: Policy, sigDesc: ?*const anyopaque) E![]*ir.Stmt {
    const fi = try policy.analyzeFrame(policy.ptr, alloc, body, sigDesc, regions);
    var ctx: Ctx = .{ .alloc = alloc, .frameSize = fi.frameSize, .fpOffset = fi.fpOffset, .usesFp = fi.usesFp, .fpInfo = fi.fpInfo, .regions = regions };
    for (body) |st| {
        if (st.kind != .insn) try ctx.emit(st) else try policy.rewrite(policy.ptr, alloc, st, &ctx);
    }
    return ctx.out.items;
}
