// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! KI-5: a whole Zig program reads `std.os.environ` directly. Zig's start code, which fills it,
//! cannot run under Fil-C, so zilc's generated entry fills it from libc's `environ` instead.
//! Before that (until 2026-10-02) it read as empty under zilc while native saw every variable.

const std = @import("std");

pub fn main() void {
    for (std.os.environ) |entry| {
        if (std.mem.startsWith(u8, std.mem.span(entry), "PATH=")) {
            std.debug.print("std.os.environ has PATH ({d} entries)\n", .{std.os.environ.len});
            return;
        }
    }
    std.debug.print("std.os.environ has no PATH ({d} entries)\n", .{std.os.environ.len});
}
