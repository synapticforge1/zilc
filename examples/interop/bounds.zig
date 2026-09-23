// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! Zig side of the interop example: C-ABI functions that write through a
//! caller-supplied pointer.
//!
//! Built by zilc, these carry Fil-C capabilities, so an out-of-bounds index
//! traps HERE — with the Zig file, line and column named — even though the
//! memory was allocated by C. That is the whole point of the project.
//!
//! ⚠️ C owns `main`: Zig's start code trips Fil-C (cmem/known-issues.md KI-5).

/// Store `v` at `p[i]`. Fil-C checks the store against `p`'s capability.
export fn zig_add(p: [*]i32, i: usize, v: i32) void {
    p[i] = v;
}

/// Sum `n` elements. Reads are checked the same way stores are.
export fn zig_sum(p: [*]const i32, n: usize) i32 {
    var total: i32 = 0;
    var i: usize = 0;
    while (i < n) : (i += 1) total +%= p[i];
    return total;
}
