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
//! The Zig port of sarcasm, Fil-C's assembler (owner, 2026-11-06: "Port sarcasm to Zig";
//! cmem/sarcasm-port.md). The package root: each module is a port of the Luau module of the same
//! name in Fil-C 0.687's projects/sarcasm/sarcasm/, proven stage by stage against upstream by
//! tools/sarcasm/check-stages.ts and, as a whole, by tools/sarcasm/compare-sarcasm.ts.

pub const luau_table = @import("luau_table.zig");
pub const luau_number = @import("luau_number.zig");
pub const lua_pattern = @import("lua_pattern.zig");
pub const err = @import("err.zig");
pub const sig = @import("sig.zig");
pub const detect = @import("detect.zig");
pub const ir = @import("ir.zig");
pub const numlabel = @import("numlabel.zig");
pub const x86_64_parse = @import("x86_64_parse.zig");
pub const x86_64_fp = @import("x86_64_fp.zig");
pub const x86_64_isa = @import("x86_64_isa.zig");
pub const prof = @import("prof.zig");
pub const frame = @import("frame.zig");
pub const lift = @import("lift.zig");
pub const ptrflow = @import("ptrflow.zig");
pub const regalloc = @import("regalloc.zig");
pub const x86_64_frame = @import("x86_64_frame.zig");

test {
    _ = x86_64_fp;
    _ = x86_64_isa;
    _ = x86_64_parse;
}
