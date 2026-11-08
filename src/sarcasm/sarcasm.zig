// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
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

test {
    _ = x86_64_fp;
    _ = x86_64_isa;
}
