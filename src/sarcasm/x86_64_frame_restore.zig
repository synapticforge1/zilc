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
//! x86_64_frame's epilogue movq-restore loads (the perlasm shape): upstream x86_64_frame.luau
//! lines 4361–4422. A `mov` from an rsp / rbp-relative save slot whose register was redefined
//! after its push: the load is dead weight when the register is never read afterwards, so it is
//! proven unobservable (checkLostReload) and marked x86_dropRestore. The span sets only that mark
//! and rejects; a free function over x86_64_frame.Analysis, like the other phase files.

const std = @import("std");
const err = @import("err.zig");
const ir = @import("ir.zig");
const isa = @import("x86_64_isa.zig");
const sig = @import("sig.zig");
const u = @import("util.zig");
const XF = @import("x86_64_frame.zig");
const flow = @import("x86_64_frame_flow.zig");
const annotate = @import("x86_64_frame_annotate.zig");

const E = err.Error;
const Stmt = ir.Stmt;
const eq = std.mem.eql;
const A = XF.Analysis;

fn rawOf(st: *const Stmt) []const u8 {
    return st.raw orelse st.mnemonic orelse "?";
}

pub fn epilogueRestore(a: *A) E!void {
    const alloc = a.alloc;
    // retIsGpr (3300)
    const retIsGpr = if (a.sigDesc) |d| (!d.isVoid and !(d.retTypes.len > 0 and sig.isFpClass(d.retTypes[0]))) else false;
    for (a.body, 1..) |st, i| {
        if (st.kind != .insn) continue; // 4377
        const ops = st.operands.items;
        const lm = try u.lower(alloc, st.mnemonic.?);
        const b = try isa.baseMnemonic(alloc, lm);
        if (!eq(u8, b, "mov")) continue; // 4380
        const o0 = XF.at(ops, 0) orelse continue;
        if (!(o0.kind == .reg and o0.rc == .gpr)) continue;
        const mem = XF.at(ops, 1) orelse continue; // 4381
        if (!(mem.kind == .mem and mem.index == null and mem.dispSym == null)) continue;
        const base = mem.base orelse continue; // 4383
        if (!(base.rc == .sp or (a.usesRbp and XF.nameIs(base, "rbp")))) continue;
        if (try flow.gprStackWidth(alloc, lm, mem) != 8) continue; // 4384
        const sv = a.savesIn[i - 1] orelse continue; // 4385
        if (XF.isDynSaves(sv) or sv.items.len == 0) continue;
        var off: f64 = mem.dispVal orelse 0;
        if (base.rc == .sp) {
            // 4388-4397: EXACTLY the rewrite's normalization; an unknown depth never qualifies
            const d = a.depthIn[i - 1] orelse continue;
            if (XF.isDynDepth(d)) continue;
            off = off + XF.D0 - d.num;
        } else {
            off = XF.rbpNorm + off;
        }
        var hit: ?XF.SaveEntry = null; // 4400
        for (sv.items) |s| {
            // (spill slots are ordinary slots — never restore-load candidates)
            if (!(a.usesRbp and eq(u8, s.name, "rbp")) and !(s.spill orelse false)) {
                if (off == XF.D0 - s.depth and s.redefined) {
                    hit = s;
                    break;
                }
            }
        }
        if (hit == null) continue; // 4408
        if (retIsGpr and o0.num != null and o0.num.? == 0) {
            return err.at(st.loc(), try u.fmt(alloc, "epilogue restore load into the integer return register cannot be modeled (the register was redefined after its save, so the restore's value and the web's value disagree): {s}", .{rawOf(st)}));
        }
        try annotate.checkLostReload(a, i, .{ .name = o0.name.?, .num = o0.num, .depth = 0 }, "epilogue restore load of a save whose register was redefined after the push (the load cannot be modeled — the slot holds the pre-push value while the register's web holds the redefined one — and this read would observe the web's value)"); // 4415
        st.x86.dropRestore = true; // 4421
    }
}
