// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! Fil-C's pizfix/os-include for a build that has no pizfix (a fresh clone: the sources `zig build`
//! fetched hold none, since Fil-C's own setup makes it). Upstream's build_os_include.sh, re-expressed
//! (third_party/LICENSES.md `libpas-recipe`): three links into the build host's kernel headers.
//!
//!   os-include <out dir>
//!
//! x86_64 only, as zilc is: `asm` is /usr/include/x86_64-linux-gnu/asm when that exists (Debian,
//! Ubuntu), else /usr/include/asm. The headers are the host's, as for upstream's release build
//! (Ubuntu: linux-libc-dev).

const std = @import("std");

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const gpa = arena_state.allocator();
    const args = try std.process.argsAlloc(gpa);
    if (args.len != 2) {
        std.debug.print("usage: os-include <out dir>\n", .{});
        std.process.exit(2);
    }
    std.fs.cwd().access("/usr/include/linux/version.h", .{}) catch {
        std.debug.print("os-include: no Linux kernel headers in /usr/include/linux (Debian/Ubuntu: apt install linux-libc-dev); Fil-C's runtime is compiled against the host's, as upstream's build does\n", .{});
        std.process.exit(1);
    };
    const asm_dir = if (std.fs.cwd().access("/usr/include/x86_64-linux-gnu/asm", .{})) |_| "/usr/include/x86_64-linux-gnu/asm" else |_| "/usr/include/asm";

    var out = try std.fs.cwd().makeOpenPath(args[1], .{});
    defer out.close();
    for ([_][2][]const u8{
        .{ "/usr/include/linux", "linux" },
        .{ asm_dir, "asm" },
        .{ "/usr/include/asm-generic", "asm-generic" },
    }) |l| {
        out.deleteFile(l[1]) catch {};
        try out.symLink(l[0], l[1], .{ .is_directory = true });
    }
}
