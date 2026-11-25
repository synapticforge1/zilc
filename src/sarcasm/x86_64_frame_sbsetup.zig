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
//! x86_64_frame's stack-buffer scan set-up: upstream x86_64_frame.luau lines 4594–4695. The scan
//! (phase 1 of the `#! stack buffer (...)` lowering) resets sbLayout and runs only on the
//! REGION-CARRYING runs outside the driver's resolution pre-pass. Its set-up gathers the largest
//! outgoing stack-argument area (annotated callsites' integer words beyond the six register
//! arguments), the deepest outstanding push count (maxSaves, anyDynSaves) with the pad's top
//! (pushTop), and each localcall clone's entry depth. The span sets no mark and never rejects;
//! its results are Analysis.sbScan / sbOutgoing / maxSaves / anyDynSaves / pushTop /
//! cloneEntryDepth, read by the checks that follow (checkRangeFits, 4696).
//! sbLayout's reset (4636) is not modelled yet: the port has no sbLayout until its assignment
//! (6427) is ported, and no checkpoint can observe a reset of a module variable that is never
//! set before it.

const std = @import("std");
const err = @import("err.zig");
const sig = @import("sig.zig");
const XF = @import("x86_64_frame.zig");

const E = err.Error;
const A = XF.Analysis;

pub fn sbSetup(a: *A) E!void {
    const alloc = a.alloc;
    // 4636-4641: sbOutgoing / maxSaves / anyDynSaves start at 0 / 0 / false (Analysis defaults)
    if (!(a.regions != null and !XF.sbResolving)) return; // 4641
    a.sbScan = true;
    for (a.body, 1..) |st, i| { // 4647
        if (st.kind == .insn) if (st.annotation) |ann| if (std.mem.indexOfScalar(u8, ann, '(') != null) {
            // 4648: pcall — a rejected annotation is skipped
            if (sig.parseSignature(alloc, ann, st.loc())) |cs| {
                var intWords: f64 = 0; // 4650
                var k: usize = 0;
                while (k < cs.argWords) : (k += 1) {
                    if (!sig.isFpClass(cs.argTypes[k])) intWords += 1;
                }
                const stackWords = intWords - 6; // 4654
                if (stackWords > 0 and 8 * stackWords > a.sbOutgoing) a.sbOutgoing = 8 * stackWords;
            } else |e| switch (e) {
                error.Sarcasm => {},
                else => return e,
            }
        };
        // 4660: x86_saves is the annotation pass's mark, on instructions only
        if (st.kind == .insn) if (a.savesIn[i - 1]) |sv| {
            if (XF.isDynSaves(sv)) {
                a.anyDynSaves = true;
            } else if (sv.items.len > a.maxSaves) a.maxSaves = sv.items.len;
        };
    }
    a.pushTop = XF.D0 - 8 * @as(f64, @floatFromInt(a.maxSaves)); // 4667
    // 4673-4695: each clone's entry depth, the clone's first INSTRUCTION's depth
    for (a.body, 1..) |st, i| {
        if (!(st.localCloneEntry orelse false)) continue;
        var j = i;
        while (j <= a.body.len) : (j += 1) {
            const st2 = a.body[j - 1];
            if (st2.kind != .insn) continue;
            if (st2.localClone) |id| if (a.depthIn[j - 1]) |d| {
                if (!XF.isDynDepth(d) and !a.cloneEntryDepth.contains(@bitCast(id)))
                    try a.cloneEntryDepth.put(alloc, @bitCast(id), d.num);
            };
            break;
        }
    }
}
