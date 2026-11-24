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
//! x86_64_frame's B2 shared-tail clone coordinate bands: upstream x86_64_frame.luau lines
//! 4424–4543. Each tailcall clone (st.b2clone = the clone index) gets a PRIVATE band base, laid
//! out cumulatively after the prologue frame (multiples of 64, 128 apart), so its rsp-relative
//! accesses (keyed off the perturbed depth) never overlap the jumper's frame slots or another
//! clone's. The span publishes the bases as x86_b2band marks, bands the clone's own carrier
//! accesses (x86_aliasOff), and leaves b2base (Analysis.b2base) for the later code that reads
//! it through b2band. It never rejects.

const std = @import("std");
const err = @import("err.zig");
const ir = @import("ir.zig");
const XF = @import("x86_64_frame.zig");

const E = err.Error;
const Stmt = ir.Stmt;
const A = XF.Analysis;

const Extent = struct { lo: f64, hi: f64 };

fn bodyAt(a: *const A, idx: f64) ?*Stmt {
    if (!(idx >= 1) or idx != @floor(idx) or idx > @as(f64, @floatFromInt(a.body.len))) return null;
    return a.body[@intFromFloat(idx - 1)];
}

/// The clone's own carrier access (4472–4475, 4536–4540): a carrier parked INSIDE clone code
/// addresses the clone's private frame, so it is banded like the rsp-relative spellings.
fn aliasBanded(a: *const A, st: *const Stmt) bool {
    const m = st.x86;
    if (m.aliasOff == null or m.dropRestore or m.regionCarrier) return false;
    const si = m.aliasSaveIdx orelse return false;
    const park = bodyAt(a, si) orelse return false;
    return park.b2clone != null;
}

fn key(idx: f64) u64 {
    return @bitCast(idx);
}

/// b2band (4514): the band base of a B2-clone statement (0 for anything else).
pub fn b2band(a: *const A, st: *const Stmt) f64 {
    const b = st.b2clone orelse return 0;
    return a.b2base.get(key(b)) orelse 0;
}

pub fn b2Bands(a: *A) E!void {
    const alloc = a.alloc;
    a.b2base = .empty;
    {
        // idx -> unbiased-off range (4459)
        var extents: std.AutoArrayHashMapUnmanaged(u64, Extent) = .empty;
        for (a.body, 1..) |st, i| {
            const idx = st.b2clone orelse continue; // 4461
            if (st.kind != .insn or (st.x86.prologue orelse false)) continue;
            const d = a.depthIn[i - 1] orelse continue; // 4463
            if (XF.isDynDepth(d)) continue;
            const alias = aliasBanded(a, st); // 4472
            for (st.operands.items) |o| { // 4476
                if (o.kind != .mem) continue;
                const base = o.base orelse continue;
                if (base.kind != .reg or o.index != null or o.dispSym != null) continue;
                if (!(base.rc == .sp or alias)) continue;
                if (!alias and a.regionOf(o.dispVal orelse 0, false) != null) continue;
                var off: f64 = undefined;
                if (alias) {
                    off = st.x86.aliasOff.?; // 4483
                } else {
                    off = o.dispVal orelse 0; // 4485
                    if (d.num != XF.D0) off = off + XF.D0 - d.num;
                }
                const gop = try extents.getOrPut(alloc, key(idx)); // 4488
                if (!gop.found_existing) {
                    gop.value_ptr.* = .{ .lo = off, .hi = off };
                } else {
                    if (off < gop.value_ptr.lo) gop.value_ptr.lo = off;
                    if (off > gop.value_ptr.hi) gop.value_ptr.hi = off;
                }
            }
        }
        // 4499: the clone indices in order (table.sort of numbers)
        var order: std.ArrayList(f64) = .empty;
        for (extents.keys()) |k| try order.append(alloc, @bitCast(k));
        std.mem.sort(f64, order.items, {}, std.sort.asc(f64));
        var cursor = a.frameSize + 128; // 4502
        for (order.items) |idx| {
            const e = extents.get(key(idx)).?;
            // multiple of 64 (alignment residues preserved); at or past the cursor (4505–4508)
            var base = cursor - e.lo;
            base = @ceil(base / 64) * 64;
            try a.b2base.put(alloc, key(idx), base); // 4509
            cursor = base + e.hi + 128;
        }
    }
    // 4520: publish bands as rewrite-visible marks
    for (a.body) |st| {
        if (st.kind == .insn) {
            if (st.b2clone) |b| st.x86.b2band = a.b2base.get(key(b)) orelse 0;
        }
    }
    // 4526: band the clone's own carrier accesses
    for (a.body) |st| {
        if (st.kind == .insn and st.b2clone != null and aliasBanded(a, st)) {
            st.x86.aliasOff = st.x86.aliasOff.? + (a.b2base.get(key(st.b2clone.?)) orelse 0);
        }
    }
}
