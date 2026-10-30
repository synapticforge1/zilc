// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! Every place that names the Fil-C release zilc builds on must name the same one (owner,
//! 2026-10-30: "all of these references should be updated each time Fil-C updates"). Run by
//! `zig build test` and `zig build check-pins`; a Fil-C move that leaves one behind fails here.
//!
//!   check-pins <repo root> <Fil-C release> <compiler commit>
//!
//! build.zig passes the release and commit from src/gen/signatures.zig (the tables imported from
//! that release). Each row below is a file and the exact text it must contain; a row that no
//! longer matches prints what was expected, so the fix is to bump the file, never this table
//! (unless the file's wording changed on purpose).

const std = @import("std");

const Pin = struct {
    file: []const u8,
    /// The text the file must contain; `{v}` = release, `{c}` = full commit, `{s}` = 7-character commit.
    text: []const u8,
};

const pins = [_]Pin{
    // What `zig build` fetches: Fil-C's sources at the commit (build.zig.zon, lazy dependency `filc`).
    // (cmake and ninja, also there, are pinned to their own releases, not to Fil-C's: the release
    // checklist re-checks them on each Fil-C move.)
    .{ .file = "build.zig.zon", .text = "llvm-project-deluge/archive/{c}.tar.gz" },
    .{ .file = "src/root.zig", .text = "pub const filc_release = \"{v}\";" },
    .{ .file = "tools/lib/tool.ts", .text = "export const FILC_VERSION = \"{v}\";" },
    .{ .file = "tools/lib/tool.ts", .text = "export const FILC_SHA = \"{c}\";" },
    // The prebuilt's SHA-256, recorded at download (the oracle; optional for a user's build).
    .{ .file = "tools/p1/setup-wsl.ts", .text = "\"{v}\": \"" },
    // The tables imported from the release's build rules.
    .{ .file = "src/runtime/libpas_sources.zig", .text = "Source: Fil-C {v} ({c})" },
    .{ .file = "src/runtime/yolomusl_sources.zig", .text = "Source: Fil-C {v} ({c})" },
    .{ .file = "src/runtime/compiler_rt_sources.zig", .text = "Source: Fil-C {v} ({c})" },
    .{ .file = "third_party/filc-patches/README.md", .text = "Current base: Fil-C {v}, commit `{s}`" },
    .{ .file = "Fil-C.md", .text = "| **Fil-C release** | **{v}**" },
    .{ .file = "Fil-C.md", .text = "| **Compiler commit** | `{c}`" },
};

fn expand(gpa: std.mem.Allocator, text: []const u8, release: []const u8, commit: []const u8) ![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .{};
    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        if (text[i] == '{' and i + 2 < text.len and text[i + 2] == '}') {
            switch (text[i + 1]) {
                'v' => try out.appendSlice(gpa, release),
                'c' => try out.appendSlice(gpa, commit),
                's' => try out.appendSlice(gpa, commit[0..7]),
                else => {
                    try out.append(gpa, text[i]);
                    continue;
                },
            }
            i += 2;
        } else try out.append(gpa, text[i]);
    }
    return out.items;
}

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena_state.deinit();
    const gpa = arena_state.allocator();

    const args = try std.process.argsAlloc(gpa);
    if (args.len != 4) {
        std.debug.print("usage: check-pins <repo root> <Fil-C release> <compiler commit>\n", .{});
        std.process.exit(2);
    }
    const root = args[1];
    const release = args[2];
    const commit = args[3];
    if (commit.len != 40) {
        std.debug.print("check-pins: '{s}' is not a full commit id\n", .{commit});
        std.process.exit(2);
    }

    var dir = try std.fs.cwd().openDir(root, .{});
    defer dir.close();
    var failed: usize = 0;
    for (pins) |p| {
        const want = try expand(gpa, p.text, release, commit);
        const body = dir.readFileAlloc(gpa, p.file, 16 << 20) catch |e| {
            std.debug.print("check-pins: FAIL {s}: cannot read ({s})\n", .{ p.file, @errorName(e) });
            failed += 1;
            continue;
        };
        if (std.mem.indexOf(u8, body, want) == null) {
            std.debug.print("check-pins: FAIL {s} does not contain: {s}\n", .{ p.file, want });
            failed += 1;
        }
    }
    if (failed != 0) {
        std.debug.print("check-pins: {d} of {d} pins do not name Fil-C {s} ({s}); bump them (cmem/releasing.md, Fil-C move checklist)\n", .{ failed, pins.len, release, commit });
        std.process.exit(1);
    }
    std.debug.print("check-pins: all {d} pins name Fil-C {s} ({s})\n", .{ pins.len, release, commit[0..7] });
}
