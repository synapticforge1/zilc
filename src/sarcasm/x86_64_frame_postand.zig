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
//! x86_64_frame's post-`and` frame extent: upstream x86_64_frame.luau lines 4545–4591. A prologue
//! `and $-N, %rsp` is dropped from the output (the synthesized frame is emitted N-aligned), so the
//! post-`and` traffic's keyed offsets ARE the frame's coordinates, and the input's `sub` may size
//! the frame shorter than that traffic reaches. The span grows frameSize to the widest post-`and`
//! plain rsp access (gated on frameAndSeen, not on frameAndDepth: a depth-0 note is a real note).
//! It sets no mark and never rejects; its only result is Analysis.frameSize.

const std = @import("std");
const err = @import("err.zig");
const ir = @import("ir.zig");
const isa = @import("x86_64_isa.zig");
const fp = @import("x86_64_fp.zig");
const u = @import("util.zig");
const XF = @import("x86_64_frame.zig");
const flow = @import("x86_64_frame_flow.zig");

const E = err.Error;
const A = XF.Analysis;

pub fn postAndExtent(a: *A) E!void {
    if (!XF.frameAndSeen) return; // 4565
    const alloc = a.alloc;
    for (a.body, 1..) |st, i| {
        if (st.kind != .insn) continue; // 4567
        if ((st.x86.prologue orelse false) or st.localClone != null or st.b2clone != null or st.x86.preAnd) continue;
        const d = a.depthIn[i - 1] orelse continue; // 4569: type(st.x86_depth) == "number"
        if (XF.isDynDepth(d) or !(d.num >= XF.frameAndDepth)) continue;
        var mem: ?*ir.Operand = null; // 4571: the LAST memory operand
        for (st.operands.items) |o| if (o.kind == .mem) {
            mem = o;
        };
        const mm = mem orelse continue; // 4572
        const base = mm.base orelse continue;
        if (!(base.kind == .reg and base.rc == .sp) or mm.index != null or mm.dispSym != null) continue;
        const m = try u.lower(alloc, st.mnemonic.?);
        if (std.mem.eql(u8, try isa.baseMnemonic(alloc, m), "lea")) continue;
        const fpe = try fp.lookup(alloc, m); // 4577
        var w: ?f64 = null;
        if (flow.isFpInsn(fpe, st)) { // 4578
            // 4579: pcall — a rejected access (or none) leaves w nil
            w = if (fp.accessWidth(alloc, m, st.operands.items, st.raw, st.loc())) |x| (if (x) |acc| acc.w else null) else |e| switch (e) {
                error.Sarcasm => null,
                else => return e,
            };
        } else {
            w = try flow.gprStackWidth(alloc, m, mm); // 4582
        }
        if (w) |ww| {
            const off = (mm.dispVal orelse 0) + XF.D0 - d.num; // 4585
            if (off + ww > a.frameSize) a.frameSize = off + ww; // 4586
        }
    }
}
