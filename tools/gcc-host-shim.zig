// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! GCC's host compiler for `zig build gcc-reference` (MAINTAINER-ONLY): `zig cc` / `zig c++` / `zig
//! ar` / `zig ranlib` as one executable each, like tools/zig-shim.zig, plus one rule GCC's build
//! needs: GCC 11 names its C++ sources `*.c` (libcpp/errors.c, …) and compiles them with $(CXX).
//! g++ and clang++ then treat a `.c` input as C++; `zig c++` picks the language from the extension
//! and compiled them as C ("unknown type name 'bool'", 2026-11-04). So, as `c++`, each `.c` input
//! is wrapped in `-x c++ … -x none` (measured: `-x` holds for the next inputs, `-x none` restores
//! detection by extension). Kept apart from zig-shim.zig on purpose: changing that file
//! would move the shim patched-clang's build is configured with and force a full clang rebuild.

const std = @import("std");
const options = @import("shim_options");

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const gpa = arena_state.allocator();
    const args = try std.process.argsAlloc(gpa);

    var argv: std.ArrayListUnmanaged([]const u8) = .{};
    try argv.appendSlice(gpa, &.{ options.zig_exe, options.subcommand });
    const cxx = std.mem.eql(u8, options.subcommand, "c++");
    if (cxx or std.mem.eql(u8, options.subcommand, "cc")) try argv.appendSlice(gpa, &.{ "-target", "x86_64-linux-gnu", "-mcpu=baseline" });
    var takes_value = false; // the argument after -o, -MF, -MT, -MQ, -include is not an input
    for (args[1..]) |a| {
        if (cxx and !takes_value and std.mem.endsWith(u8, a, ".c") and a[0] != '-') {
            try argv.appendSlice(gpa, &.{ "-x", "c++", a, "-x", "none" });
        } else try argv.append(gpa, a);
        takes_value = for ([_][]const u8{ "-o", "-MF", "-MT", "-MQ", "-include", "-I", "-isystem" }) |f| {
            if (std.mem.eql(u8, a, f)) break true;
        } else false;
    }
    return std.process.execv(gpa, argv.items);
}
