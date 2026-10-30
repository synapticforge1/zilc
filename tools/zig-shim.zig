// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! One of `zig cc`, `zig c++`, `zig ar`, `zig ranlib` as a single executable, for CMake, whose
//! CMAKE_C_COMPILER / CMAKE_AR take one path (`zig build patched-clang -Dclang-cc=zig`,
//! tools/patched-clang.zig). build.zig compiles one per subcommand with the Zig that runs the build.
//!
//! The compilers get an explicit target: without one `zig cc` builds for the host CPU
//! (-march=native), and the clang it builds must run on any x86_64 Linux, as the prebuilt does.

const std = @import("std");
const options = @import("shim_options");

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const gpa = arena_state.allocator();
    const args = try std.process.argsAlloc(gpa);

    var argv: std.ArrayListUnmanaged([]const u8) = .{};
    try argv.appendSlice(gpa, &.{ options.zig_exe, options.subcommand });
    const compiler = std.mem.eql(u8, options.subcommand, "cc") or std.mem.eql(u8, options.subcommand, "c++");
    if (compiler) try argv.appendSlice(gpa, &.{ "-target", "x86_64-linux-gnu", "-mcpu=baseline" });
    try argv.appendSlice(gpa, args[1..]);
    return std.process.execv(gpa, argv.items);
}
