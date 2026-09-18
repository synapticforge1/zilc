// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! `zilc` CLI — placeholder driver. Eventually: a front end that runs
//! `zig cc` / `zig c++` / `zig build-exe` with the zilc pass and runtime.

const std = @import("std");
const zilc = @import("zilc");

const usage =
    \\zilc {s} — a Fil-C-style memory-safe target for the Zig toolchain
    \\
    \\usage: zilc [-h | --help] [-v | --version]
    \\
    \\(No compilation modes yet — this is the project scaffold.)
    \\
;

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_file_writer.interface;
    defer out.flush() catch {};

    const args = try std.process.argsAlloc(arena);
    if (args.len > 1) {
        const a = args[1];
        if (std.mem.eql(u8, a, "-v") or std.mem.eql(u8, a, "--version")) {
            try out.print("zilc {s}\n", .{zilc.version_string});
            return;
        }
    }
    try out.print(usage, .{zilc.version_string});
}
