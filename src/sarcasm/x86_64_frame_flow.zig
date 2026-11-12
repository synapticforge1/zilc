// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//! x86_64_frame's control-flow rsp-depth / save-pairing / saved-rsp-carrier analysis: upstream
//! x86_64_frame.luau lines 1191–3211 (transferCore, the carrier-map helpers, transfer, the
//! merges, successors, leaSaveUsesMemoryOnly, flagsDeadAfter, the fixpoint) and the helpers they
//! use from 180–257 and 448–661. Free functions over x86_64_frame.Analysis (upstream's closures
//! over analyzeFrame's locals).
//!
//! Upstream's TABLE depths ({anchored} / {dynreg} region scopes) are unreachable since the alloca
//! annotations went away (upstream's own comment at 200–204, and on the corpus: x86_depth is only
//! ever a number or "dyn" — cmem/sarcasm-port.md), so Depth is number | dyn and every branch that
//! requires `type(d) == "table"` is dead here; each such place says so.

const std = @import("std");
const err = @import("err.zig");
const ir = @import("ir.zig");
const frameShared = @import("frame.zig");
const isa = @import("x86_64_isa.zig");
const fp = @import("x86_64_fp.zig");
const xparse = @import("x86_64_parse.zig");
const sig = @import("sig.zig");
const u = @import("util.zig");
const XF = @import("x86_64_frame.zig");

const Allocator = std.mem.Allocator;
const E = err.Error;
const Op = ir.Operand;
const Stmt = ir.Stmt;
const eq = std.mem.eql;
const A = XF.Analysis;
const Depth = XF.Depth;
const Saves = XF.Saves;
const SaveEntry = XF.SaveEntry;
const SaveList = XF.SaveList;
const Smap = XF.Smap;
const SmapEntry = XF.SmapEntry;
const FpState = XF.FpState;
const at = XF.at;
const rcIs = XF.rcIs;
const kindIs = XF.kindIs;
const nameIs = XF.nameIs;
const width64OrNil = XF.width64OrNil;
const immVal = XF.immVal;

fn tr(b: ?bool) bool {
    return b orelse false;
}
fn depthNum(d: ?Depth) ?f64 {
    const x = d orelse return null;
    return if (x == .num) x.num else null;
}
fn isDyn(d: Depth) bool {
    return d == .dyn;
}
fn lower(a: *A, m: []const u8) E![]const u8 {
    return u.lower(a.alloc, m);
}
fn base(a: *A, st: *const Stmt) E![]const u8 {
    return isa.baseMnemonic(a.alloc, try lower(a, st.mnemonic.?));
}
fn memOf(st: *const Stmt) ?*Op {
    var m: ?*Op = null;
    for (st.operands.items) |o| if (o.kind == .mem) {
        m = o;
    };
    return m;
}

// ---------------------------------------------------------------------------
// helpers (upstream 149–257, 603–661)

/// isFpInsn (149).
pub fn isFpInsn(fpe: ?fp.Entry, st: *const Stmt) bool {
    if (fpe) |e| if (e.noCheck) return false;
    return fp.hasFpReg(st) or (fpe != null and fpe.?.claim);
}

/// gprStackWidth (180).
pub fn gprStackWidth(alloc: Allocator, m: []const u8, mem: *const Op) E!f64 {
    if (mem.size) |s| return s;
    if (eq(u8, try isa.baseMnemonic(alloc, m), "setcc")) return 1;
    if (try u.match1(alloc, m, "^mov[zs]([bwlq])")) |zs| return XF.widthLetter(zs[0]).?;
    if (try u.match1(alloc, m, "([bwlq])$")) |sf| return XF.widthLetter(sf[0]) orelse 8;
    return 8;
}

/// isSpSaveForm (236).
pub fn isSpSaveForm(a: *A, st: *const Stmt) E!bool {
    const ops = st.operands.items;
    if (!eq(u8, try base(a, st), "mov")) return false;
    const o0 = at(ops, 0) orelse return false;
    if (!(o0.kind == .reg and o0.rc == .gpr and !nameIs(o0, "rbp") and width64OrNil(o0))) return false;
    const o1 = at(ops, 1) orelse return false;
    return o1.rc == .sp and width64OrNil(o1);
}

/// isSpRecoverForm (250).
pub fn isSpRecoverForm(a: *A, st: *const Stmt, usesRbp: bool) E!bool {
    const ops = st.operands.items;
    if (!eq(u8, try base(a, st), "mov")) return false;
    const o0 = at(ops, 0) orelse return false;
    if (!(o0.rc == .sp and width64OrNil(o0))) return false;
    const o1 = at(ops, 1) orelse return false;
    return o1.kind == .reg and o1.rc == .gpr and (!nameIs(o1, "rbp") or !usesRbp) and width64OrNil(o1);
}

/// yoloArgSlotOf (603).
pub fn yoloArgSlotOf(a: *A, st: *const Stmt, baseName: []const u8, saveDepth: f64) E!?f64 {
    if (XF.yoloCount == 0) return null;
    const ops = st.operands.items;
    const mem = memOf(st) orelse return null;
    const b = mem.base orelse return null;
    if (!(u.eql(b.name, baseName) and b.kind == .reg)) return null;
    if (mem.index != null or mem.dispSym != null) return null;
    if (ops.len > 0 and ops[0] == mem) return null;
    if (try isa.isMemRmw(a.alloc, st)) return null;
    if (eq(u8, try base(a, st), "lea")) return null;
    var i = (mem.dispVal orelse 0) - saveDepth - 8 - (if (st.localClone != null and eq(u8, baseName, "rsp")) @as(f64, 8) else 0);
    if (i < 0 or @mod(i, 8) != 0) return null;
    i = i / 8;
    if (i >= XF.yoloCount) return null;
    return i;
}

/// isYoloLeaSave (635).
fn isYoloLeaSave(a: *A, st: *const Stmt, d: ?Depth) E!bool {
    if (XF.yoloCount == 0) return false;
    const dn = depthNum(d) orelse return false;
    const ops = st.operands.items;
    if (!eq(u8, try base(a, st), "lea")) return false;
    const o0 = at(ops, 0) orelse return false;
    if (!(o0.kind == .reg and o0.rc == .gpr and !nameIs(o0, "rbp"))) return false;
    const mem = at(ops, 1) orelse return false;
    const want: f64 = if (st.localClone != null) dn + 8 else 0;
    return mem.kind == .mem and rcIs(mem.base, .sp) and mem.index == null and mem.dispSym == null and (mem.dispVal orelse 0) == want;
}

/// slotOffSafe (657).
pub fn slotOffSafe(off: f64) bool {
    const n = frameShared.SLOT_BASE + off;
    return n < frameShared.YOLO_SLOT_BASE or n >= frameShared.YOLO_SLOT_BASE + 8 * XF.yoloCount;
}

fn rawOf(st: *const Stmt) []const u8 {
    return st.raw orelse st.mnemonic orelse "?";
}

const Range = struct { lo: f64, hi: f64 };

/// resolveBufRangeAt (448): the normalized range a statement's `#! stack buffer` declares.
pub fn resolveBufRangeAt(a: *A, st: *const Stmt, d: ?Depth, smap: ?*Smap, fpState: ?FpState, inPrologue: bool) E!?Range {
    const alloc = a.alloc;
    const sb = st.stackBufAnno orelse return null;
    var loN: f64 = undefined;
    var hiN: f64 = undefined;
    const L = st.loc();
    if (sb.short) {
        if (st.b2clone != null)
            return err.at(L, try u.fmt(alloc, "`stack buffer ({s})` short form on a shared-tail clone statement is not supported (a clone's buffer window is private to the clone's own frame context; declare it with the long form `#! stack buffer ({s}, %rsp, %rsp + N)` on an access inside the cloned region): {s}", .{ sb.id, sb.id, rawOf(st) }));
        const canon = XF.stackBufCanonOf(sb.id) orelse {
            if (XF.sbResolving) return null;
            return err.at(L, try u.fmt(alloc, "`stack buffer ({s})` short form has no long form anywhere in this file (declare the buffer with e.g. `#! stack buffer ({s}, %rsp, %rsp + N)` on a buffer access in some function): {s}", .{ sb.id, sb.id, rawOf(st) }));
        };
        if (tr(canon.sub) and st.localClone == null)
            return err.at(L, try u.fmt(alloc, "`stack buffer ({s})` is declared inside local subroutine '{s}' (its bytes live in that subroutine's own frame); only that subroutine's cloned code addresses it - declare a buffer in this function with the long form instead: {s}", .{ sb.id, canon.fn_ orelse "nil", rawOf(st) }));
        loN = canon.lo;
        hiN = canon.hi;
    } else {
        const dd = d orelse return err.at(L, try u.fmt(alloc, "`stack buffer` annotation on an unreachable (dead-code) statement cannot be resolved: {s}", .{rawOf(st)}));
        const sbBase = sb.base.?;
        if (st.localClone != null and !eq(u8, sbBase, "rsp"))
            return err.at(L, try u.fmt(alloc, "`stack buffer` annotation on a local subroutine clone statement must use %rsp as its base (%{s} names a register whose clone-context binding the analysis cannot attribute to the clone's own frame): {s}", .{ sbBase, rawOf(st) }));
        var k: f64 = undefined;
        if (eq(u8, sbBase, "rsp")) {
            if (isDyn(dd)) return err.at(L, try u.fmt(alloc, "`stack buffer` annotation at an unprovable (dynamic or unknown) stack depth cannot be resolved: {s}", .{rawOf(st)}));
            if (st.b2clone != null) {
                k = XF.D0 - dd.num;
            } else if (st.localClone != null) {
                k = XF.D0 - dd.num - 8;
            } else {
                if (inPrologue and dd.num != XF.D0)
                    return err.at(L, try u.fmt(alloc, "`stack buffer` annotation inside the prologue prefix at a perturbed stack depth is not supported: {s}", .{rawOf(st)}));
                k = XF.D0 - dd.num;
            }
        } else if (st.b2clone != null) {
            return err.at(L, try u.fmt(alloc, "`stack buffer` annotation on a shared-tail clone statement must use %rsp as its base (%{s} names a register whose clone-context binding the analysis cannot attribute to the clone's own frame): {s}", .{ sbBase, rawOf(st) }));
        } else if (eq(u8, sbBase, "rbp")) {
            if (fpState != null and fpState.? == .est) {
                k = XF.rbpNorm;
            } else {
                const e = if (smap) |m| m.get(.{ .str = "rbp" }) else null;
                if (!(e != null and !tr(e.?.redefined) and !tr(e.?.slot) and e.?.roff == null and !tr(e.?.conflict)))
                    return err.at(L, try u.fmt(alloc, "`stack buffer` annotation base %rbp is neither an established frame pointer nor a live saved-rsp carrier here: {s}", .{rawOf(st)}));
                k = XF.D0 - e.?.depth.?;
            }
        } else {
            const e = if (smap) |m| m.get(.{ .str = sbBase }) else null;
            if (!(e != null and !tr(e.?.redefined) and !tr(e.?.slot) and e.?.roff == null and !tr(e.?.conflict)))
                return err.at(L, try u.fmt(alloc, "`stack buffer` annotation base %{s} is not a live saved-rsp stack alias at this statement (create one with `mov %rsp, %{s}` or `lea K(%rsp), %{s}`): {s}", .{ sbBase, sbBase, sbBase, rawOf(st) }));
            k = XF.D0 - e.?.depth.?;
        }
        loN = k + sb.lo.?;
        hiN = k + sb.hi.?;
        if (st.b2clone == null and st.localClone == null) {
            if (XF.stackBufCanonOf(sb.id)) |canon| {
                if (canon.lo != loN or canon.hi != hiN) {
                    const firstLoc: ?[]const u8 = if (canon.st) |cs| try err.locStr(alloc, cs.loc()) else null;
                    return err.at(L, try u.fmt(alloc, "`stack buffer ({s})` long forms disagree: the declaration in function '{s}' at {s} resolves to [{s}, {s}) but this one resolves to [{s}, {s}) (the offsets must match): {s}", .{
                        sb.id,                 canon.fn_ orelse "nil", firstLoc orelse "?", try u.num(alloc, canon.lo), try u.num(alloc, canon.hi),
                        try u.num(alloc, loN), try u.num(alloc, hiN),  rawOf(st),
                    }));
                }
            } else if (!XF.sbResolving) {
                return err.at(L, try u.fmt(alloc, "`stack buffer ({s})` long form was not seen by the file-wide declaration scan (long forms inside local subroutine bodies are not supported): {s}", .{ sb.id, rawOf(st) }));
            }
        }
    }
    if (hiN <= loN) return err.at(L, try u.fmt(alloc, "`stack buffer ({s})` declares an empty range: {s}", .{ sb.id, rawOf(st) }));
    return .{ .lo = loN, .hi = hiN };
}

// ---------------------------------------------------------------------------
// the save stack (1217–1523)

fn newSaves(a: *A, items: []const SaveEntry) E!Saves {
    const l = try a.alloc.create(SaveList);
    l.* = .{ .items = try a.alloc.dupe(SaveEntry, items) };
    return l;
}

/// truncateSaves (1217).
fn truncateSaves(a: *A, sv: Saves, nd: f64) E!Saves {
    if (XF.isDynSaves(sv)) return sv;
    var c: std.ArrayList(SaveEntry) = .empty;
    for (sv.items) |e| {
        if (e.depth > nd) break;
        try c.append(a.alloc, e);
    }
    return newSaves(a, c.items);
}

fn classOf(a: *A, st: *const Stmt) E!*ir.Class {
    if (a.classCache.get(st)) |c| return c;
    const c = try a.alloc.create(ir.Class);
    c.* = try isa.classify(a.alloc, st);
    try a.classCache.put(a.alloc, st, c);
    return c;
}

fn defsHit(c: *const ir.Class, num: ?f64) bool {
    for (c.defs.items) |dd| if (dd.kind == .reg and dd.rc == .gpr and num != null and dd.num != null and dd.num.? == num.?) return true;
    return false;
}

/// The def-marking of transferCore's two sites: a new list marking every entry whose register
/// the instruction defines as redefined, or null when no unredefined entry is hit.
fn markRedefined(a: *A, sv: Saves, c: *const ir.Class) E!?Saves {
    if (c.defs.items.len == 0 or sv.items.len == 0) return null;
    var hit = false;
    for (sv.items) |e| {
        if (!e.redefined and defsHit(c, e.num)) {
            hit = true;
            break;
        }
    }
    if (!hit) return null;
    var out: std.ArrayList(SaveEntry) = .empty;
    for (sv.items) |e| {
        var x = e;
        if (!x.redefined and defsHit(c, e.num)) x.redefined = true;
        try out.append(a.alloc, .{ .name = x.name, .num = x.num, .depth = x.depth, .spill = x.spill, .redefined = x.redefined });
    }
    return try newSaves(a, out.items);
}

pub const Core = struct { d: Depth, sv: Saves, fp: FpState };

/// transferCore (1232).
fn transferCore(a: *A, st: *const Stmt, d: Depth, sv_in: Saves, fpS: FpState, recoverDepth: ?f64) E!Core {
    var sv = sv_in;
    const m = try lower(a, st.mnemonic.?);
    const b = try isa.baseMnemonic(a.alloc, m);
    const ops = st.operands.items;
    const o0 = at(ops, 0);
    const o1 = at(ops, 1);
    if (eq(u8, b, "leave")) {
        if (!a.usesRbp or fpS != .est) return .{ .d = .dyn, .sv = &XF.dyn_saves, .fp = fpS };
        const nd = a.fpDepth.? - 8;
        return .{ .d = .{ .num = nd }, .sv = try truncateSaves(a, sv, nd), .fp = .no };
    }
    if (eq(u8, b, "mov") and rcIs(o0, .sp)) {
        if (a.usesRbp and fpS == .est and nameIs(o1, "rbp"))
            return .{ .d = .{ .num = a.fpDepth.? }, .sv = try truncateSaves(a, sv, a.fpDepth.?), .fp = fpS };
        if (recoverDepth) |rd| return .{ .d = .{ .num = rd }, .sv = try truncateSaves(a, sv, rd), .fp = fpS };
        return .{ .d = .dyn, .sv = &XF.dyn_saves, .fp = fpS };
    }
    if (eq(u8, b, "lea") and rcIs(o0, .sp) and kindIs(o1, .mem) and a.usesRbp and fpS == .est and nameIs(o1.?.base, "rbp") and
        o1.?.index == null and o1.?.dispSym == null)
    {
        const nd = a.fpDepth.? - (o1.?.dispVal orelse 0);
        return .{ .d = .{ .num = nd }, .sv = try truncateSaves(a, sv, nd), .fp = fpS };
    }
    if (eq(u8, b, "lea") and rcIs(o0, .sp) and kindIs(o1, .mem) and kindIs(o1.?.base, .reg) and (!nameIs(o1.?.base, "rbp") or !a.usesRbp) and
        o1.?.index == null and o1.?.dispSym == null and recoverDepth != null)
        return .{ .d = .{ .num = recoverDepth.? }, .sv = try truncateSaves(a, sv, recoverDepth.?), .fp = fpS };
    if (eq(u8, b, "mov") and nameIs(o0, "rbp") and rcIs(o1, .sp)) return .{ .d = d, .sv = sv, .fp = .est };
    if (eq(u8, b, "lea") and kindIs(o0, .reg) and nameIs(o0, "rbp") and kindIs(o1, .mem) and rcIs(o1.?.base, .sp) and
        o1.?.index == null and o1.?.dispSym == null and (o1.?.dispVal orelse 0) == 0)
        return .{ .d = d, .sv = sv, .fp = .est };
    if (isDyn(d) or XF.isDynSaves(sv)) {
        if (XF.isDynSaves(sv)) return .{ .d = .dyn, .sv = &XF.dyn_saves, .fp = fpS };
        if (eq(u8, b, "push") or isa.isFlagStackPush(m)) return .{ .d = .dyn, .sv = &XF.dyn_saves, .fp = fpS };
        if (eq(u8, b, "pop") or isa.isFlagStackPop(m)) {
            if (sv.items.len > 0) return .{ .d = .dyn, .sv = try newSaves(a, sv.items[0 .. sv.items.len - 1]), .fp = fpS };
            return .{ .d = .dyn, .sv = &XF.dyn_saves, .fp = fpS };
        }
        if ((eq(u8, b, "sub") or eq(u8, b, "add")) and rcIs(o0, .sp)) return .{ .d = .dyn, .sv = sv, .fp = fpS };
        const c = try classOf(a, st);
        if (try markRedefined(a, sv, c)) |out| sv = out;
        return .{ .d = d, .sv = sv, .fp = fpS };
    }
    const dn = d.num;
    if (isa.isFlagStackPush(m)) {
        var c: std.ArrayList(SaveEntry) = .empty;
        try c.appendSlice(a.alloc, sv.items);
        try c.append(a.alloc, .{ .name = isa.FLAGS_REG_NAME, .num = isa.FLAGS_REG_NUM, .depth = dn + 8, .spill = true, .redefined = false });
        return .{ .d = .{ .num = dn + 8 }, .sv = try newSaves(a, c.items), .fp = fpS };
    }
    if (isa.isFlagStackPop(m)) {
        if (sv.items.len > 0 and sv.items[sv.items.len - 1].depth == dn)
            return .{ .d = .{ .num = dn - 8 }, .sv = try newSaves(a, sv.items[0 .. sv.items.len - 1]), .fp = fpS };
        return .{ .d = .{ .num = dn - 8 }, .sv = &XF.dyn_saves, .fp = fpS };
    }
    if (eq(u8, b, "push")) {
        const isReg = kindIs(o0, .reg);
        var c: std.ArrayList(SaveEntry) = .empty;
        try c.appendSlice(a.alloc, sv.items);
        const spill: ?bool = if (isReg and o0.?.rc == .gpr and !isa.isCalleeSaved(o0.?.name orelse "")) true else null;
        try c.append(a.alloc, .{ .name = if (isReg) o0.?.name.? else "?", .num = if (isReg) o0.?.num else null, .depth = dn + 8, .spill = spill, .redefined = false });
        return .{ .d = .{ .num = dn + 8 }, .sv = try newSaves(a, c.items), .fp = fpS };
    }
    if (eq(u8, b, "pop")) {
        if (sv.items.len > 0 and sv.items[sv.items.len - 1].depth == dn) {
            const top = sv.items[sv.items.len - 1];
            const poppedFp = a.usesRbp and kindIs(o0, .reg) and (eq(u8, top.name, "rbp") or (tr(top.spill) and nameIs(o0, "rbp")));
            return .{ .d = .{ .num = dn - 8 }, .sv = try newSaves(a, sv.items[0 .. sv.items.len - 1]), .fp = if (poppedFp) .no else fpS };
        }
        return .{ .d = .{ .num = dn - 8 }, .sv = &XF.dyn_saves, .fp = fpS };
    }
    var nd = dn;
    if ((eq(u8, b, "sub") or eq(u8, b, "add")) and rcIs(o0, .sp)) {
        if (kindIs(o1, .imm)) {
            nd = if (eq(u8, b, "sub")) dn + immVal(o1) else dn - immVal(o1);
        } else return .{ .d = .dyn, .sv = &XF.dyn_saves, .fp = fpS };
    }
    if (eq(u8, b, "lea") and rcIs(o0, .sp) and kindIs(o1, .mem) and rcIs(o1.?.base, .sp) and o1.?.index == null and o1.?.dispSym == null)
        nd = dn - (o1.?.dispVal orelse 0);
    if (nd < dn) sv = try truncateSaves(a, sv, nd);
    if (eq(u8, b, "mov") and !XF.isDynSaves(sv) and sv.items.len > 0 and dn == XF.D0) {
        if (memOf(st)) |mem| if (mem.index == null and mem.dispSym == null and mem.base != null and (rcIs(mem.base, .sp) or (a.usesRbp and nameIs(mem.base, "rbp")))) {
            const w0 = try gprStackWidth(a.alloc, m, mem);
            var off = mem.dispVal orelse 0;
            if (!rcIs(mem.base, .sp)) off = XF.rbpNorm + off;
            if (w0 == 8) {
                var changed = false;
                for (sv.items) |e| if (e.redefined and off == dn - e.depth) {
                    changed = true;
                    break;
                };
                if (changed) {
                    var out: std.ArrayList(SaveEntry) = .empty;
                    for (sv.items) |e| {
                        if (e.redefined and off == dn - e.depth) {
                            try out.append(a.alloc, .{ .name = e.name, .num = e.num, .depth = e.depth, .spill = e.spill, .redefined = false });
                        } else try out.append(a.alloc, e);
                    }
                    sv = try newSaves(a, out.items);
                }
            }
        };
    }
    const c = try classOf(a, st);
    if (c.defs.items.len > 0 and !XF.isDynSaves(sv) and sv.items.len > 0) {
        if (try markRedefined(a, sv, c)) |out| return .{ .d = .{ .num = nd }, .sv = out, .fp = fpS };
    }
    return .{ .d = .{ .num = nd }, .sv = sv, .fp = fpS };
}

// ---------------------------------------------------------------------------
// the carrier map (1561–1748)

fn newEntry(a: *A, e: SmapEntry) E!*const SmapEntry {
    const p = try a.alloc.create(SmapEntry);
    p.* = e;
    return p;
}
fn newSmap(a: *A) E!*Smap {
    const p = try a.alloc.create(Smap);
    p.* = Smap.init(a.alloc, 0, 0) catch return error.OutOfMemory;
    return p;
}
/// `for k, v in pairs(src) do out[k] = v end` into a fresh table.
fn copySmap(a: *A, src: *Smap) E!*Smap {
    const o = try newSmap(a);
    var it = src.iterator();
    while (it.next()) |e| o.set(e.key, e.val) catch return error.OutOfMemory;
    return o;
}
fn sget(m: ?*Smap, k: ?[]const u8) ?*const SmapEntry {
    const mm = m orelse return null;
    const kk = k orelse return null;
    return mm.get(.{ .str = kk });
}
fn sset(m: *Smap, k: []const u8, v: ?*const SmapEntry) E!void {
    m.set(.{ .str = k }, v) catch return error.OutOfMemory;
}
fn liveCarrier(e: ?*const SmapEntry) bool {
    const x = e orelse return false;
    return !tr(x.redefined) and !tr(x.slot) and x.roff == null and !tr(x.conflict);
}
fn keyStr(a: *A, prefix: []const u8, n: f64) E![]const u8 {
    return u.fmt(a.alloc, "{s}{s}", .{ prefix, try u.num(a.alloc, n) });
}

const SlotKey = struct { key: []const u8, off: f64, space: []const u8 };

/// slotKeyOf (1561).
fn slotKeyOf(a: *A, mem: ?*const Op, d: ?Depth, st: ?*const Stmt) E!?SlotKey {
    const m = mem orelse return null;
    if (!(m.kind == .mem and m.base != null and m.base.?.kind == .reg and m.index == null and m.dispSym == null)) return null;
    const disp = m.dispVal orelse 0;
    const bias: f64 = if (st != null and st.?.localClone != null) 8 else 0;
    if (rcIs(m.base, .sp)) {
        const dd = d orelse return null;
        if (isDyn(dd)) {
            // (a {dynreg} table depth would add its bias: unreachable)
            const k = disp - bias;
            return .{ .key = try keyStr(a, "D", k), .off = k, .space = "D" };
        }
        const off = disp + XF.D0 - dd.num - bias;
        return .{ .key = try keyStr(a, "S", off), .off = off, .space = "S" };
    }
    if (a.usesRbp and nameIs(m.base, "rbp")) {
        const off = XF.rbpNorm + disp;
        return .{ .key = try keyStr(a, "S", off), .off = off, .space = "S" };
    }
    return null;
}

const RegionPtr = struct { roff: f64, rbase: f64, rspace: []const u8 };

/// regionLeaOf (1596). (Its table-depth branches are unreachable.)
fn regionLeaOf(a: *A, st: *const Stmt, d: ?Depth) E!?RegionPtr {
    const ops = st.operands.items;
    if (!eq(u8, try base(a, st), "lea")) return null;
    const o0 = at(ops, 0) orelse return null;
    if (!(o0.kind == .reg and o0.rc == .gpr and !nameIs(o0, "rbp"))) return null;
    const mem = at(ops, 1) orelse return null;
    if (!(mem.kind == .mem and mem.base != null and mem.base.?.kind == .reg and mem.index == null and mem.dispSym == null)) return null;
    const disp = mem.dispVal orelse 0;
    const dn = depthNum(d) orelse return null;
    var off = disp;
    if (!rcIs(mem.base, .sp)) {
        if (a.usesRbp and nameIs(mem.base, "rbp")) off = XF.rbpNorm + disp else return null;
    } else if (st.localClone != null) {
        off = off + XF.D0 - dn - 8;
    } else if (st.b2clone == null and !tr(st.x86.prologue)) {
        off = off + XF.D0 - dn;
    }
    if (a.regionOf(off, false)) |r| return .{ .roff = off - r.base, .rbase = r.base, .rspace = "S" };
    return null;
}

/// roffCopyOf (1654).
fn roffCopyOf(a: *A, st: *const Stmt, smap: *Smap) E!?*const SmapEntry {
    const ops = st.operands.items;
    if (!eq(u8, try base(a, st), "mov")) return null;
    const o0 = at(ops, 0) orelse return null;
    if (!(o0.kind == .reg and o0.rc == .gpr and !nameIs(o0, "rbp") and width64OrNil(o0))) return null;
    const o1 = at(ops, 1) orelse return null;
    if (!(o1.kind == .reg and o1.rc == .gpr and !nameIs(o1, "rbp") and width64OrNil(o1))) return null;
    const e = sget(smap, o1.name) orelse return null;
    if (e.roff != null and !tr(e.redefined)) return e;
    return null;
}

/// aliasSlotOf (1674).
pub fn aliasSlotOf(a: *A, st: *const Stmt, mem: ?*const Op, e: *const SmapEntry) E!?f64 {
    const m = mem orelse return null;
    const b = m.base orelse return null;
    if (!(b.kind == .reg and u.eql(b.name, e.name orelse ""))) return null;
    if (e.name == null) return null;
    if (m.index != null or m.dispSym != null) return null;
    if (eq(u8, try base(a, st), "lea")) return null;
    return (m.dispVal orelse 0) + XF.D0 - e.depth.? - (if (st.localClone != null) @as(f64, 8) else 0);
}

/// memSlotKey (1686).
fn memSlotKey(a: *A, mem: ?*const Op, d: ?Depth, smap: ?*Smap, st: ?*const Stmt) E!?SlotKey {
    const m = mem orelse return null;
    if (!(m.kind == .mem and m.base != null and m.base.?.kind == .reg and m.index == null and m.dispSym == null)) return null;
    if (rcIs(m.base, .sp) or (a.usesRbp and nameIs(m.base, "rbp"))) return slotKeyOf(a, m, d, st);
    const e = sget(smap, m.base.?.name) orelse return null;
    if (e.roff != null and !tr(e.redefined)) {
        const off = e.rbase.? + e.roff.? + (m.dispVal orelse 0);
        return .{ .key = try keyStr(a, e.rspace.?, off), .off = off, .space = e.rspace.? };
    }
    return null;
}

fn gprFull(a: *A, o: ?*const Op) bool {
    const x = o orelse return false;
    return x.kind == .reg and x.rc == .gpr and (!nameIs(x, "rbp") or !a.usesRbp) and width64OrNil(x);
}

/// carrierCopyOf (1701).
fn carrierCopyOf(a: *A, st: *const Stmt, smap: *Smap) E!?*const SmapEntry {
    const ops = st.operands.items;
    if (!eq(u8, try base(a, st), "mov")) return null;
    if (!gprFull(a, at(ops, 0)) or !gprFull(a, at(ops, 1))) return null;
    const e = sget(smap, ops[1].name);
    if (liveCarrier(e)) return e;
    return null;
}

const StoreSrc = struct { e: *const SmapEntry, key: SlotKey };

/// saveStoreOf (1716).
fn saveStoreOf(a: *A, st: *const Stmt, smap: *Smap, d: ?Depth) E!?StoreSrc {
    const ops = st.operands.items;
    if (!eq(u8, try base(a, st), "mov")) return null;
    const mem = at(ops, 0) orelse return null;
    if (mem.kind != .mem) return null;
    if (!gprFull(a, at(ops, 1))) return null;
    const e = sget(smap, ops[1].name);
    if (!liveCarrier(e)) return null;
    const key = (try memSlotKey(a, mem, d, smap, st)) orelse return null;
    return .{ .e = e.?, .key = key };
}

/// carrierLoadOf (1732).
fn carrierLoadOf(a: *A, st: *const Stmt, smap: *Smap, d: ?Depth) E!?*const SmapEntry {
    const ops = st.operands.items;
    if (!eq(u8, try base(a, st), "mov")) return null;
    if (!gprFull(a, at(ops, 0))) return null;
    const key = (try memSlotKey(a, at(ops, 1), d, smap, st)) orelse return null;
    const e = sget(smap, key.key) orelse return null;
    if (!tr(e.redefined) and !tr(e.conflict)) return e;
    return null;
}

/// restoreLoadOf (1749).
fn restoreLoadOf(a: *A, st: *const Stmt, smap: *Smap, sv: ?Saves) E!?SaveEntry {
    const ops = st.operands.items;
    if (!eq(u8, try base(a, st), "mov")) return null;
    const o0 = at(ops, 0) orelse return null;
    if (!(o0.kind == .reg and o0.rc == .gpr and width64OrNil(o0))) return null;
    const mem = at(ops, 1) orelse return null;
    if (!(mem.kind == .mem and mem.base != null and mem.base.?.kind == .reg and mem.index == null and mem.dispSym == null)) return null;
    const s = sv orelse return null;
    if (XF.isDynSaves(s)) return null;
    const e = sget(smap, mem.base.?.name);
    if (!liveCarrier(e)) return null;
    const sdepth = e.?.depth.? - (mem.dispVal orelse 0);
    for (s.items) |x| {
        if (x.depth == sdepth) {
            if (u.eql(o0.name, x.name)) return x;
            return null;
        }
    }
    return null;
}

// ---------------------------------------------------------------------------
// transfer (1806)

pub const Out = struct { d: Depth, sv: Saves, smap: *Smap, fp: FpState };

fn copyEntry(a: *A, e: *const SmapEntry) E!*SmapEntry {
    const p = try a.alloc.create(SmapEntry);
    p.* = e.*;
    return p;
}

/// clearDynSlots: an rsp write drops the "D"-space slot carriers.
fn clearDynSlots(a: *A, st: *const Stmt, out: *Smap) E!*Smap {
    if (!(try XF.insnWritesSp(a.alloc, st))) return out;
    var cleaned: ?*Smap = null;
    var it = out.iterator();
    while (it.next()) |e| {
        if (tr(e.val.slot) and u.eql(e.val.space, "D")) {
            if (cleaned == null) cleaned = try copySmap(a, out);
            cleaned.?.set(e.key, null) catch return error.OutOfMemory;
        }
    }
    return cleaned orelse out;
}

fn transfer(a: *A, st: *Stmt, d: Depth, sv: Saves, smap: *Smap, fpS: FpState, idx: usize) E!Out {
    const alloc = a.alloc;
    const ops = st.operands.items;
    const o0 = at(ops, 0);
    const o1 = at(ops, 1);
    const lm = try lower(a, st.mnemonic.?);
    const bm = try isa.baseMnemonic(alloc, lm);
    const dn: ?f64 = if (d == .num) d.num else null;

    const isSave = (try isSpSaveForm(a, st)) and dn != null and
        (isa.isCalleeSaved(o0.?.name orelse "") or XF.yoloCount > 0 or st.b2clone != null or (a.regions != null and a.regionOf(0, false) == null));
    var isLeaSave = try isYoloLeaSave(a, st, d);
    var leaSaveForm: ?[]const u8 = null;
    var leaSaveParked: ?f64 = null;
    if (!isLeaSave and a.regions != null and dn != null and eq(u8, bm, "lea")) {
        const mem = o1;
        if (kindIs(o0, .reg) and o0.?.rc == .gpr and (!nameIs(o0, "rbp") or !a.usesRbp) and kindIs(mem, .mem) and rcIs(mem.?.base, .sp) and
            mem.?.index == null and mem.?.dispSym == null)
        {
            const k = mem.?.dispVal orelse 0;
            const pk = if (st.localClone != null) k - 8 else k;
            const rkey = if (st.localClone != null) k + XF.D0 - dn.? - 8 else if (st.b2clone == null and !tr(st.x86.prologue)) k + XF.D0 - dn.? else k;
            const leaAny = (dn.? != XF.D0 or nameIs(o0, "rbp")) and st.localClone == null;
            var leaD0: bool = false;
            if (dn.? == XF.D0 and st.localClone == null and !nameIs(o0, "rbp") and k > 0 and k != dn.?)
                leaD0 = try leaSaveUsesMemoryOnly(a, st, idx, dn.? - k);
            var inBufProbe = false;
            if (a.bufProbeRanges) |pr| {
                if (st.b2clone) |bc| {
                    if (a.bufB2DeclRaw) |b2| if (b2.get(@bitCast(bc))) |lst| for (lst.items) |sba| if (k >= sba.lo.? and k < sba.hi.?) {
                        inBufProbe = true;
                        break;
                    };
                } else {
                    const loff = k + XF.D0 - dn.? - (if (st.localClone != null) @as(f64, 8) else 0);
                    for (pr.items) |r| if (loff >= r.lo and loff < r.hi) {
                        inBufProbe = true;
                        break;
                    };
                }
            }
            const repReg = if (o0.?.num) |nn| a.bufRepRegs.contains(@bitCast(nn)) else false;
            if (inBufProbe and !isLeaSave and !repReg and !(try leaSaveUsesMemoryOnly(a, st, idx, dn.? - k)))
                st.x86.stackBufLeaValueComputed = true;
            if ((pk == dn.? or pk <= 0 or leaAny or leaD0) and a.regionOf(rkey, false) == null) {
                if (inBufProbe and !repReg and !(try leaSaveUsesMemoryOnly(a, st, idx, dn.? - k))) {
                    st.x86.stackBufLeaValueComputed = true;
                } else if (inBufProbe and st.localClone != null) {
                    // a buffer-interior lea in a localcall clone: the value-lea form
                } else {
                    isLeaSave = true;
                    leaSaveForm = try u.fmt(alloc, "leaq {s}(%rsp)", .{try u.num(alloc, k)});
                }
            }
        }
    }
    // (the {anchored}-scope restore-base lea, 2047–2064, needs a table depth: unreachable)
    if (!isLeaSave and a.regions != null and a.usesRbp and fpS == .est and eq(u8, bm, "lea")) {
        const mem = o1;
        if (kindIs(o0, .reg) and o0.?.rc == .gpr and !nameIs(o0, "rbp") and kindIs(mem, .mem) and kindIs(mem.?.base, .reg) and
            nameIs(mem.?.base, "rbp") and mem.?.index == null and mem.?.dispSym == null)
        {
            const k = mem.?.dispVal orelse 0;
            const parked = a.fpDepth.? - k;
            const rkey = XF.rbpNorm + k;
            if (parked >= 0 and a.regionOf(rkey, false) == null and (rkey < 0 or rkey >= a.frameSize)) {
                isLeaSave = true;
                leaSaveForm = try u.fmt(alloc, "leaq {s}(%rbp)", .{try u.num(alloc, k)});
                leaSaveParked = parked;
            }
        }
    }
    // derived stack carriers
    var derivedDepth: ?f64 = null;
    if (eq(u8, bm, "lea") and kindIs(o0, .reg) and o0.?.rc == .gpr and (!nameIs(o0, "rbp") or !a.usesRbp) and width64OrNil(o0.?) and
        kindIs(o1, .mem) and o1.?.base != null and o1.?.base.?.kind == .reg and o1.?.base.?.rc == .gpr and
        (!nameIs(o1.?.base, "rbp") or !a.usesRbp) and o1.?.index == null and o1.?.dispSym == null)
    {
        const e = sget(smap, o1.?.base.?.name);
        const k = o1.?.dispVal orelse 0;
        if (liveCarrier(e) and e.?.depth != null and e.?.depth.? - k >= 0) derivedDepth = e.?.depth.? - k;
    }
    if (derivedDepth) |dd| {
        const out = try copySmap(a, smap);
        try sset(out, o0.?.name.?, try newEntry(a, .{ .name = o0.?.name, .num = o0.?.num, .depth = dd, .saveIdx = @floatFromInt(idx), .redefined = false }));
        const c0 = try transferCore(a, st, d, sv, fpS, null);
        return .{ .d = c0.d, .sv = c0.sv, .smap = out, .fp = c0.fp };
    }
    var recoverDepth: ?f64 = null;
    if (try isSpRecoverForm(a, st, a.usesRbp)) {
        const e = sget(smap, o1.?.name);
        if (liveCarrier(e)) recoverDepth = e.?.depth;
    }
    if (recoverDepth == null and eq(u8, bm, "lea") and kindIs(o0, .reg) and o0.?.rc == .sp and width64OrNil(o0.?) and kindIs(o1, .mem) and
        o1.?.base != null and o1.?.base.?.kind == .reg and (!nameIs(o1.?.base, "rbp") or !a.usesRbp) and o1.?.index == null and o1.?.dispSym == null)
    {
        const e = sget(smap, o1.?.base.?.name);
        if (liveCarrier(e)) {
            const rd = e.?.depth.? - (o1.?.dispVal orelse 0);
            if (rd >= 0) recoverDepth = rd;
        }
    }
    const copySrc = try carrierCopyOf(a, st, smap);
    var storeSrc: ?StoreSrc = null;
    if (copySrc == null) storeSrc = try saveStoreOf(a, st, smap, d);
    const loadSrc = if (copySrc == null and storeSrc == null) try carrierLoadOf(a, st, smap, d) else null;
    const restoreSave = try restoreLoadOf(a, st, smap, sv);
    var rptr: ?RegionPtr = null;
    if (copySrc == null and storeSrc == null and loadSrc == null) rptr = try regionLeaOf(a, st, d);
    const roffCopySrc = if (rptr == null) try roffCopyOf(a, st, smap) else null;
    const core = try transferCore(a, st, d, sv, fpS, recoverDepth);

    if (isSave or isLeaSave) {
        const out = try copySmap(a, smap);
        var parkedDepth = dn.?;
        if (leaSaveParked) |p| {
            parkedDepth = p;
        } else if (isLeaSave) {
            parkedDepth = dn.? + (if (st.localClone != null) @as(f64, 8) else 0) - (o1.?.dispVal orelse 0);
        }
        try sset(out, o0.?.name.?, try newEntry(a, .{ .name = o0.?.name, .num = o0.?.num, .depth = parkedDepth, .saveIdx = @floatFromInt(idx), .redefined = false, .form = leaSaveForm orelse (if (isLeaSave) "leaq 0(%rsp)" else null) }));
        return .{ .d = core.d, .sv = core.sv, .smap = try clearDynSlots(a, st, out), .fp = core.fp };
    }
    if (recoverDepth != null) return .{ .d = core.d, .sv = core.sv, .smap = try clearDynSlots(a, st, smap), .fp = core.fp };
    if (copySrc) |cs| {
        const out = try copySmap(a, smap);
        try sset(out, o0.?.name.?, try newEntry(a, .{ .name = o0.?.name, .num = o0.?.num, .depth = cs.depth, .saveIdx = @floatFromInt(idx), .redefined = false, .form = cs.form }));
        return .{ .d = core.d, .sv = core.sv, .smap = try clearDynSlots(a, st, out), .fp = core.fp };
    }
    if (storeSrc) |ss| {
        const out = try copySmap(a, smap);
        try sset(out, ss.key.key, try newEntry(a, .{ .slot = true, .name = "the frame slot", .depth = ss.e.depth, .saveIdx = ss.e.saveIdx, .redefined = false, .off = ss.key.off, .space = ss.key.space }));
        return .{ .d = core.d, .sv = core.sv, .smap = try clearDynSlots(a, st, out), .fp = core.fp };
    }
    if (loadSrc) |ls| {
        const out = try copySmap(a, smap);
        try sset(out, o0.?.name.?, try newEntry(a, .{ .name = o0.?.name, .num = o0.?.num, .depth = ls.depth, .saveIdx = ls.saveIdx, .redefined = false }));
        return .{ .d = core.d, .sv = core.sv, .smap = try clearDynSlots(a, st, out), .fp = core.fp };
    }
    if (rptr) |rp| {
        const out = try copySmap(a, smap);
        try sset(out, o0.?.name.?, try newEntry(a, .{ .name = o0.?.name, .num = o0.?.num, .roff = rp.roff, .rbase = rp.rbase, .rspace = rp.rspace, .redefined = false }));
        return .{ .d = core.d, .sv = core.sv, .smap = try clearDynSlots(a, st, out), .fp = core.fp };
    }
    if (roffCopySrc) |rc| {
        const out = try copySmap(a, smap);
        try sset(out, o0.?.name.?, try newEntry(a, .{ .name = o0.?.name, .num = o0.?.num, .roff = rc.roff, .rbase = rc.rbase, .rspace = rc.rspace, .redefined = false }));
        return .{ .d = core.d, .sv = core.sv, .smap = try clearDynSlots(a, st, out), .fp = core.fp };
    }

    // any other instruction
    const c = try classOf(a, st);
    var out = smap;
    if (eq(u8, bm, "call") and st.localCall == null) {
        var it = smap.iterator();
        while (it.next()) |pe| {
            const e = pe.val;
            if (!tr(e.redefined) and !tr(e.slot) and e.roff == null and !tr(e.conflict) and !isa.isCalleeSaved(e.name orelse "")) {
                if (out == smap) out = try copySmap(a, smap);
                const ne = try copyEntry(a, e);
                ne.redefined = true;
                out.set(pe.key, ne) catch return error.OutOfMemory;
            }
        }
    }
    st.x86.carrierCallArg = null;
    var it = smap.iterator();
    while (it.next()) |pe| {
        const name = pe.key.str;
        const e = pe.val;
        if (liveCarrier(e)) {
            var zeroing = false;
            if ((eq(u8, bm, "xor") or eq(u8, bm, "sub")) and o0 != null and o1 != null and o0.?.kind == .reg and o1.?.kind == .reg and
                o0.?.num != null and o1.?.num != null and e.num != null and o0.?.num.? == e.num.? and o1.?.num.? == e.num.?) zeroing = true;
            var nUses: usize = 0;
            for (c.uses.items) |uu| if (uu.kind == .reg and uu.rc == .gpr and uu.num != null and e.num != null and uu.num.? == e.num.?) {
                nUses += 1;
            };
            if (eq(u8, bm, "call") and st.localCall == null and st.annotation != null) {
                const cs = try sig.parseSignature(alloc, st.annotation.?, st.loc());
                var kk: usize = 1;
                while (kk <= cs.argWords) : (kk += 1) {
                    if (isa.CC.yoloArg(kk, cs.argTypes)) |yr| if (e.num != null and yr == e.num.?) {
                        st.x86.carrierCallArg = .{ .name = name, .form = e.form };
                    };
                }
            }
            var aliasOk = false;
            if (nUses == 1 and !eq(u8, bm, "call") and !eq(u8, bm, "jmp")) {
                const amem = memOf(st);
                const ao = if (amem != null) try aliasSlotOf(a, st, amem, e) else null;
                if (ao != null and (try yoloArgSlotOf(a, st, name, e.depth.?)) == null) {
                    const afpe = try fp.lookup(alloc, lm);
                    var aw: ?f64 = null;
                    if (isFpInsn(afpe, st)) {
                        aw = if (try fp.accessWidth(alloc, lm, ops, st.raw, st.loc())) |x| x.w else null;
                    } else aw = try gprStackWidth(alloc, lm, amem.?);
                    var lowA: f64 = -128;
                    if (dn) |x| lowA = @min(-128, XF.D0 - x - 128);
                    if (aw != null and ao.? >= lowA and (st.b2clone != null or ao.? + aw.? <= a.frameSize) and a.regionOf(ao.?, false) == null) aliasOk = true;
                }
            }
            var idxBufOk = false;
            if (nUses == 1 and st.stackBufAnno != null and !eq(u8, bm, "call") and !eq(u8, bm, "jmp")) {
                if (memOf(st)) |amem| if (amem.index != null and amem.base != null and amem.base.?.kind == .reg and u.eql(amem.base.?.name, name)) {
                    idxBufOk = true;
                };
            }
            var repSide = false;
            if (nUses == 1 and st.stackBufAnno != null and c.rep != null and st.localClone != null)
                return err.at(st.loc(), try u.fmt(alloc, "`stack buffer` annotation on a rep string op inside a local subroutine clone is not supported (the clone's return-address compensation would need its own rep alias model): {s}", .{rawOf(st)}));
            if (nUses == 1 and st.stackBufAnno != null and c.rep != null) {
                var sideNum: ?f64 = null;
                var isWrite = false;
                if (eq(u8, c.rep.?.kind, "movs")) {
                    if (e.num.? == 6) {
                        sideNum = 6;
                        isWrite = false;
                    } else if (e.num.? == 7) {
                        sideNum = 7;
                        isWrite = true;
                    }
                } else if (e.num.? == 7) {
                    sideNum = 7;
                    isWrite = true;
                }
                if (sideNum) |sn| {
                    if (try resolveBufRangeAt(a, st, d, smap, fpS, idx < a.prologueEnd)) |rg| {
                        const k = XF.D0 - e.depth.?;
                        if (k < rg.lo)
                            return err.at(st.loc(), try u.fmt(alloc, "rep string's stack-alias side %{s} (stack offset {s}) is below the stack buffer ({s}) range [{s}, {s}): {s}", .{ name, try u.num(alloc, k), st.stackBufAnno.?.id, try u.num(alloc, rg.lo), try u.num(alloc, rg.hi), rawOf(st) }));
                        st.x86.stackBufRep = .{ .lo = rg.lo, .hi = rg.hi, .id = st.stackBufAnno.?.id, .side = .{ .name = name, .K = k, .num = sn, .isWrite = isWrite } };
                        repSide = true;
                    } else repSide = XF.sbResolving;
                }
            }
            if (nUses > 0 and !zeroing and !repSide and !idxBufOk and !(nUses == 1 and (try yoloArgSlotOf(a, st, name, e.depth.?)) != null) and
                !(restoreSave != null and nUses == 1) and !aliasOk)
            {
                // (regionCarrierAccess needs a table depth: always false)
                if (!(a.bufProbeSuppress and e.form != null))
                    return err.at(st.loc(), try u.fmt(alloc, "reading %{s} while it holds the prologue `{s}, %{s}` save cannot be proven safe (the save is dropped by the rewrite — the register's stack value does not exist in the output; recover %rsp from it first or redefine it): {s}", .{ name, e.form orelse "movq %rsp", name, rawOf(st) }));
            }
        }
        if (!tr(e.redefined) and !tr(e.slot)) {
            if (defsHit(c, e.num)) {
                if (out == smap) out = try copySmap(a, smap);
                try sset(out, name, try newEntry(a, .{ .name = e.name, .num = e.num, .depth = e.depth, .saveIdx = e.saveIdx, .redefined = true }));
            }
        }
    }
    for (ops) |o| {
        if (o.kind != .mem) continue;
        const key = (try memSlotKey(a, o, d, smap, st)) orelse continue;
        const fpe = try fp.lookup(alloc, lm);
        var w: ?f64 = null;
        if (isFpInsn(fpe, st)) {
            w = if (try fp.accessWidth(alloc, lm, ops, st.raw, st.loc())) |x| x.w else null;
        } else w = try gprStackWidth(alloc, lm, o);
        var jt = smap.iterator();
        while (jt.next()) |pe| {
            const e = pe.val;
            if (tr(e.slot) and !tr(e.redefined) and u.eql(e.space, key.space) and w != null and key.off < e.off.? + 8 and key.off + w.? > e.off.?) {
                const isWrite = ops[0] == o and !eq(u8, bm, "call") and !eq(u8, bm, "jmp");
                if (isWrite) {
                    if (out == smap) out = try copySmap(a, smap);
                    out.set(pe.key, null) catch return error.OutOfMemory;
                } else return err.at(st.loc(), try u.fmt(alloc, "stack access into a frame slot that holds the saved stack pointer cannot be proven safe (the save is phantom — the slot's value does not exist in the output; overwrite the slot first): {s}", .{rawOf(st)}));
            }
        }
    }
    return .{ .d = core.d, .sv = core.sv, .smap = try clearDynSlots(a, st, out), .fp = core.fp };
}

// ---------------------------------------------------------------------------
// merges (2596–2679)

fn mergeSaves(a: *A, x: ?Saves, y: Saves) E!Saves {
    const p = x orelse return y;
    if (XF.isDynSaves(p) or XF.isDynSaves(y)) return &XF.dyn_saves;
    if (p.items.len != y.items.len) return &XF.dyn_saves;
    var grew = false;
    for (p.items, y.items) |e, f| {
        if (!eq(u8, e.name, f.name) or e.depth != f.depth or tr(e.spill) != tr(f.spill)) return &XF.dyn_saves;
        if (f.redefined and !e.redefined) grew = true;
    }
    if (!grew) return p;
    var c: std.ArrayList(SaveEntry) = .empty;
    for (p.items, y.items) |e, f| try c.append(a.alloc, .{ .name = e.name, .num = e.num, .depth = e.depth, .spill = e.spill, .redefined = e.redefined or f.redefined });
    return newSaves(a, c.items);
}

fn optEq(comptime T: type, x: ?T, y: ?T) bool {
    if (x == null or y == null) return x == null and y == null;
    if (T == []const u8) return eq(u8, x.?, y.?);
    return x.? == y.?;
}

fn mergeSmaps(a: *A, x: ?*Smap, y: ?*Smap) E!?*Smap {
    const p = x orelse return y;
    const q = y orelse return p;
    if (p == q) return p;
    var out = p;
    var it = p.iterator();
    while (it.next()) |pe| {
        const e = pe.val;
        const f = q.get(pe.key);
        const disagree = f == null or !optEq(f64, f.?.depth, e.depth) or !optEq(bool, f.?.redefined, e.redefined) or !optEq(f64, f.?.roff, e.roff) or
            !optEq(f64, f.?.rbase, e.rbase) or !optEq([]const u8, f.?.rspace, e.rspace) or !optEq(bool, f.?.conflict, e.conflict);
        if (disagree) {
            if (out == p) out = try copySmap(a, p);
            if (liveCarrier(e) or liveCarrier(f) or tr(e.conflict) or (f != null and tr(f.?.conflict))) {
                out.set(pe.key, try newEntry(a, .{ .conflict = true, .name = pe.key.str, .num = e.num orelse (if (f) |ff| ff.num else null) })) catch return error.OutOfMemory;
            } else out.set(pe.key, null) catch return error.OutOfMemory;
        } else {
            const es = e.saveIdx;
            const fs = f.?.saveIdx;
            if (!optEq(f64, es, fs)) {
                const mn = @min(es orelse 0, fs orelse 0);
                if ((es orelse 0) != mn) {
                    if (out == p) out = try copySmap(a, p);
                    const ne = try copyEntry(a, e);
                    ne.saveIdx = mn;
                    out.set(pe.key, ne) catch return error.OutOfMemory;
                }
            }
        }
    }
    return out;
}

// ---------------------------------------------------------------------------
// the CFG (2701)

pub fn successors(a: *A, i: usize) E![]const usize {
    const st = a.st_(i);
    const alloc = a.alloc;
    if (st.localCall) |lc| {
        if (a.labelAt.get(lc.entry)) |t| return alloc.dupe(usize, &.{t});
        return &.{};
    }
    if (st.localRet) |lr| {
        var o: std.ArrayList(usize) = .empty;
        for (lr.conts) |cont| if (a.labelAt.get(cont)) |t| try o.append(alloc, t);
        return o.items;
    }
    const m = try lower(a, st.mnemonic.?);
    const b = try isa.baseMnemonic(alloc, m);
    const nxt = a.nextInsn[i - 1];
    var o: std.ArrayList(usize) = .empty;
    if (eq(u8, b, "ret")) return o.items;
    if (eq(u8, m, "ud2") or eq(u8, m, "int3") or eq(u8, m, "int") or eq(u8, m, "hlt")) return o.items;
    const ops = st.operands.items;
    if (eq(u8, b, "jmp")) {
        if (at(ops, 0)) |x| if (x.kind == .sym) if (a.labelAt.get(x.text.?)) |t| return alloc.dupe(usize, &.{t});
        return o.items;
    }
    if (eq(u8, b, "jcc") or std.mem.startsWith(u8, m, "loop")) {
        if (at(ops, 0)) |x| if (x.kind == .sym) if (a.labelAt.get(x.text.?)) |t| try o.append(alloc, t);
    }
    if (nxt <= a.body.len) try o.append(alloc, nxt);
    return o.items;
}

// ---------------------------------------------------------------------------
// leaSaveUsesMemoryOnly (2800)

const CDepth = union(enum) { num: f64, dyn };
const Work = struct { i: usize, s: u8, dv: CDepth };

fn leaSaveUsesMemoryOnly(a: *A, st: *const Stmt, idx: usize, parkedDepth: f64) E!bool {
    if (a.leaMemOnlyCache.get(st)) |x| return x;
    const res = try leaMemOnlyScan(a, st, idx, parkedDepth);
    try a.leaMemOnlyCache.put(a.alloc, st, res);
    return res;
}

fn cdEq(x: ?CDepth, y: ?CDepth) bool {
    if (x == null or y == null) return x == null and y == null;
    if (x.? == .dyn or y.? == .dyn) return x.? == .dyn and y.? == .dyn;
    return x.?.num == y.?.num;
}

fn leaMemOnlyScan(a: *A, st: *const Stmt, idx: usize, parkedDepth: f64) E!bool {
    const alloc = a.alloc;
    const body = a.body;
    const dest = at(st.operands.items, 0) orelse return false;
    if (!(dest.kind == .reg and dest.rc == .gpr)) return false;
    const parsed = (try xparse.classifyReg(alloc, dest.name.?)) orelse return false;
    if (parsed.rc != .gpr) return false;
    const regNum = parsed.num.?;
    const regName = dest.name.?;
    const retIsGpr = a.sigDesc != null and !a.sigDesc.?.isVoid and !(a.sigDesc.?.retTypes.len > 0 and sig.isFpClass(a.sigDesc.?.retTypes[0]));
    var firstInsn: ?usize = null;
    for (body, 1..) |s0, i| if (s0.kind == .insn) {
        firstInsn = i;
        break;
    };
    const fi = firstInsn orelse return false;
    var seen: std.StringHashMapUnmanaged(void) = .empty;
    const instateC = try alloc.alloc(?u8, body.len + 2);
    @memset(instateC, null);
    const instateD = try alloc.alloc(?CDepth, body.len + 2);
    @memset(instateD, null);
    var work: std.ArrayList(Work) = .empty;
    try work.append(alloc, .{ .i = fi, .s = 0, .dv = .{ .num = 0 } });
    instateC[fi] = 0;
    instateD[fi] = .{ .num = 0 };
    while (work.items.len > 0) {
        const item = work.pop().?;
        const i = item.i;
        const s = item.s;
        const dv = item.dv;
        const key = try u.fmt(alloc, "{d}:{d}:{s}", .{ i, s, if (dv == .num) try u.num(alloc, dv.num) else "dyn" });
        if (seen.contains(key)) continue;
        try seen.put(alloc, key, {});
        // (a trailing label maps one past the body end: not an insn)
        if (i > body.len) return false;
        const st2 = body[i - 1];
        if (st2.kind != .insn) return false;
        const c = classOf(a, st2) catch |e| switch (e) {
            error.Sarcasm => return false,
            else => return e,
        };
        const bm = try lower(a, st2.mnemonic.?);
        const bb = try isa.baseMnemonic(alloc, bm);
        const ops2 = st2.operands.items;
        var out = s;
        const isMyLea = i == idx;
        if (!isMyLea and eq(u8, bb, "lea") and kindIs(at(ops2, 0), .reg) and ops2[0].rc == .gpr and ops2[0].num != null and ops2[0].num.? == regNum and
            kindIs(at(ops2, 1), .mem) and ops2[1].base != null and rcIs(ops2[1].base, .sp) and ops2[1].index == null and ops2[1].dispSym == null)
        {
            if (dv == .num) {
                const pdf = dv.num - (ops2[1].dispVal orelse 0);
                out = if (pdf == parkedDepth) 1 else 2;
            } else out = 2;
        } else if (isMyLea) {
            out = 1;
        } else if (defsHit(c, regNum)) out = 0;
        if (eq(u8, bb, "call")) {
            if ((s == 1 or s == 3) and isa.isArgReg(regNum)) return false;
            if (st2.localCall == null and (out == 1 or out == 2) and !isa.isCalleeSaved(regName)) out = 0;
        }
        var ndv = dv;
        if (dv == .num) {
            const o0 = at(ops2, 0);
            const o1 = at(ops2, 1);
            if (eq(u8, bb, "push")) {
                ndv = .{ .num = dv.num + 8 };
            } else if (eq(u8, bb, "pop")) {
                ndv = .{ .num = dv.num - 8 };
            } else if (isa.isFlagStackPush(bm)) {
                ndv = .{ .num = dv.num + 8 };
            } else if (isa.isFlagStackPop(bm)) {
                ndv = .{ .num = dv.num - 8 };
            } else if ((eq(u8, bb, "sub") or eq(u8, bb, "add")) and rcIs(o0, .sp) and kindIs(o1, .imm)) {
                ndv = .{ .num = if (eq(u8, bb, "sub")) dv.num + immVal(o1) else dv.num - immVal(o1) };
            } else if (eq(u8, bb, "lea") and rcIs(o0, .sp) and kindIs(o1, .mem) and rcIs(o1.?.base, .sp) and o1.?.index == null and o1.?.dispSym == null) {
                ndv = .{ .num = dv.num - (o1.?.dispVal orelse 0) };
            } else if (eq(u8, bb, "and") and rcIs(o0, .sp)) {
                // the depth propagates unchanged
            } else if (eq(u8, bb, "leave") or try XF.insnWritesSp(alloc, st2)) ndv = .dyn;
        }
        if (s == 1 or s == 3) {
            var nUses: usize = 0;
            for (c.uses.items) |uu| if (uu.kind == .reg and uu.rc == .gpr and uu.num != null and uu.num.? == regNum) {
                nUses += 1;
            };
            if (nUses > 0) {
                const zeroing = (eq(u8, bb, "xor") or eq(u8, bb, "sub")) and ops2.len >= 2 and ops2[0].kind == .reg and ops2[1].kind == .reg and
                    ops2[0].num != null and ops2[1].num != null and ops2[0].num.? == regNum and ops2[1].num.? == regNum;
                if (!zeroing) {
                    var mem2: ?*Op = null;
                    var memCount2: usize = 0;
                    for (ops2) |o| if (o.kind == .mem) {
                        mem2 = o;
                        memCount2 += 1;
                    };
                    if (s == 3) {
                        if (mem2) |mm| if (mm.base != null and mm.base.?.kind == .reg and mm.base.?.rc == .gpr and mm.base.?.num != null and mm.base.?.num.? == regNum) return false;
                    } else {
                        const baseOk = mem2 != null and memCount2 == 1 and mem2.?.base != null and mem2.?.base.?.kind == .reg and mem2.?.base.?.rc == .gpr and
                            mem2.?.base.?.num != null and mem2.?.base.?.num.? == regNum and mem2.?.index == null and mem2.?.dispSym == null;
                        if (!(baseOk and nUses == 1) or eq(u8, bb, "call") or eq(u8, bb, "jmp")) return false;
                        if ((try yoloArgSlotOf(a, st2, regName, parkedDepth)) == null) {
                            const ao = (mem2.?.dispVal orelse 0) + XF.D0 - parkedDepth;
                            const afpe = try fp.lookup(alloc, bm);
                            var aw: ?f64 = null;
                            if (isFpInsn(afpe, st2)) {
                                const r = fp.accessWidth(alloc, bm, ops2, st2.raw, null) catch |e2| switch (e2) {
                                    error.Sarcasm => return false,
                                    else => return e2,
                                };
                                aw = if (r) |x| x.w else return false;
                            } else aw = try gprStackWidth(alloc, bm, mem2.?);
                            if (ao < -128 or ao + aw.? > a.frameSize or a.regionOf(ao, false) != null) return false;
                        }
                    }
                }
            }
        }
        if (eq(u8, bb, "ret") and st2.localRet == null and st2.tailRet == null and retIsGpr and regNum == 0 and (s == 1 or s == 3)) return false;
        for (try successors(a, i)) |s2| {
            const curC = instateC[s2];
            const curD = instateD[s2];
            var mergedC: u8 = undefined;
            if (curC == null) {
                mergedC = out;
            } else if (curC.? == 3 or out == 3) {
                mergedC = 3;
            } else if (curC.? == 0 and out == 0) {
                mergedC = 0;
            } else if (curC.? == out) {
                mergedC = curC.?;
            } else mergedC = 3;
            var mergedD: CDepth = undefined;
            if (curD == null) {
                mergedD = ndv;
            } else if (curD.? == .dyn or ndv == .dyn) {
                mergedD = .dyn;
            } else if (curD.?.num == ndv.num) {
                mergedD = curD.?;
            } else mergedD = .dyn;
            if (curC == null or mergedC != curC.? or !cdEq(mergedD, curD)) {
                instateC[s2] = mergedC;
                instateD[s2] = mergedD;
                try work.append(alloc, .{ .i = s2, .s = mergedC, .dv = mergedD });
            }
        }
    }
    return true;
}

/// flagsDeadAfter (3055).
pub fn flagsDeadAfter(a: *A, i: usize) E!bool {
    const alloc = a.alloc;
    const start = try isa.flagDefMask(alloc, a.st_(i));
    if (start == 0) return true;
    var seen: std.AutoHashMapUnmanaged(usize, u32) = .empty;
    const W = struct { j: usize, pend: u32 };
    var work: std.ArrayList(W) = .empty;
    for (try successors(a, i)) |s| try work.append(alloc, .{ .j = s, .pend = start });
    while (work.items.len > 0) {
        const item = work.pop().?;
        const j = item.j;
        var pend = item.pend;
        if (pend == 0) continue;
        const prev = seen.get(j) orelse 0;
        if (pend & ~prev == 0) continue;
        try seen.put(alloc, j, prev | pend);
        if (j > a.body.len) continue;
        const st = a.st_(j);
        if (st.kind == .insn) {
            if (try isa.flagUseMask(alloc, st) & pend != 0) return false;
            pend = pend & ~(try isa.flagDefMask(alloc, st));
            if (pend != 0) for (try successors(a, j)) |s| try work.append(alloc, .{ .j = s, .pend = pend });
        } else {
            for (try successors(a, j)) |s| try work.append(alloc, .{ .j = s, .pend = pend });
        }
    }
    return true;
}

// ---------------------------------------------------------------------------
// the fixpoint (3087–3211)

fn depthEq(x: ?Depth, y: ?Depth) bool {
    if (x == null or y == null) return x == null and y == null;
    if (x.? == .dyn or y.? == .dyn) return x.? == .dyn and y.? == .dyn;
    return x.?.num == y.?.num;
}

pub fn fixpoint(a: *A) E!void {
    const alloc = a.alloc;
    const n = a.body.len;
    // one slot past the end: a trailing label maps to #body + 1 (upstream's tables take it)
    a.depthIn = try alloc.alloc(?Depth, n + 1);
    @memset(a.depthIn, null);
    a.savesIn = try alloc.alloc(?Saves, n + 1);
    @memset(a.savesIn, null);
    a.fpIn = try alloc.alloc(?FpState, n + 1);
    @memset(a.fpIn, null);
    a.smapIn = try alloc.alloc(?*Smap, n + 1);
    @memset(a.smapIn, null);

    var localRetByEntry: std.AutoHashMapUnmanaged(usize, std.ArrayList(usize)) = .empty;
    for (a.body, 1..) |st, i| if (st.kind == .insn) if (st.localRet) |lr| if (lr.entry) |en| if (a.labelAt.get(en)) |e| {
        const g = try localRetByEntry.getOrPut(alloc, e);
        if (!g.found_existing) g.value_ptr.* = .empty;
        try g.value_ptr.append(alloc, i);
    };
    var firstInsn: ?usize = null;
    for (a.body, 1..) |st, i| if (st.kind == .insn) {
        firstInsn = i;
        break;
    };
    const fi = firstInsn orelse return;
    a.depthIn[fi - 1] = .{ .num = 0 };
    a.savesIn[fi - 1] = try newSaves(a, &.{});
    a.smapIn[fi - 1] = try newSmap(a);
    a.fpIn[fi - 1] = .no;
    var worklist: std.ArrayList(usize) = .empty;
    try worklist.append(alloc, fi);
    const inq = try alloc.alloc(bool, n + 2);
    @memset(inq, false);
    inq[fi] = true;
    while (worklist.items.len > 0) {
        const i = worklist.pop().?;
        inq[i] = false;
        // (upstream would index a nil statement here and fail with a Lua error)
        if (i > n) return err.plain("internal error: the depth fixpoint reached past the body end");
        const r = try transfer(a, a.st_(i), a.depthIn[i - 1].?, a.savesIn[i - 1].?, a.smapIn[i - 1].?, a.fpIn[i - 1].?, i);
        var od: ?Depth = r.d;
        var osv = r.sv;
        var osmap = r.smap;
        var ofp = r.fp;
        const st = a.st_(i);
        if (st.localRet) |lr| {
            if (lr.entry) |en| if (a.labelAt.get(en)) |e| if (a.depthIn[i - 1] != null) {
                // the clone entry's state (all four are set together, or none)
                od = a.depthIn[e - 1];
                if (od != null) {
                    osv = a.savesIn[e - 1].?;
                    ofp = a.fpIn[e - 1].?;
                }
                if (a.smapIn[e - 1]) |esmap| {
                    const o2 = try newSmap(a);
                    var it = osmap.iterator();
                    while (it.next()) |pe| if (esmap.get(pe.key) != null) o2.set(pe.key, pe.val) catch return error.OutOfMemory;
                    osmap = o2;
                }
            };
        }
        if (od == null) continue;
        for (try successors(a, i)) |s| {
            const cur = a.depthIn[s - 1];
            var merged: Depth = undefined;
            if (cur == null) {
                merged = od.?;
            } else if (cur.? == .dyn or od.? == .dyn) {
                merged = .dyn;
            } else if (cur.?.num == od.?.num) {
                merged = cur.?;
            } else merged = .dyn;
            const mergedSv = try mergeSaves(a, a.savesIn[s - 1], osv);
            const mergedSmap = try mergeSmaps(a, a.smapIn[s - 1], osmap);
            const curFp = a.fpIn[s - 1];
            var mergedFp: FpState = undefined;
            if (curFp == null) {
                mergedFp = ofp;
            } else if (curFp.? == .dyn or ofp == .dyn) {
                mergedFp = .dyn;
            } else if (curFp.? == ofp) {
                mergedFp = curFp.?;
            } else mergedFp = .dyn;
            if (!depthEq(merged, cur) or a.savesIn[s - 1] == null or mergedSv != a.savesIn[s - 1].? or mergedSmap != a.smapIn[s - 1] or curFp == null or mergedFp != curFp.?) {
                a.depthIn[s - 1] = merged;
                a.savesIn[s - 1] = mergedSv;
                a.smapIn[s - 1] = mergedSmap;
                a.fpIn[s - 1] = mergedFp;
                if (!inq[s]) {
                    inq[s] = true;
                    try worklist.append(alloc, s);
                }
                if (localRetByEntry.get(s)) |lrs| for (lrs.items) |lr| {
                    if (a.depthIn[lr - 1] != null and !inq[lr]) {
                        inq[lr] = true;
                        try worklist.append(alloc, lr);
                    }
                };
            }
        }
    }
}
