// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! The safety gate: every example must trap, with the fault attributed to the
//! right source line.
//!
//! ⚠️ **Checking the exit status alone would accept a crash for the wrong
//! reason.** Fil-C prints a `semantic origin:` naming file:line:column, so the
//! gate asserts on that as well as on the kind of violation.
//!
//! Needs Fil-C and Zig 0.15.2 (`ZILC_FILC`, `ZILC_ZIG`). Where they are absent —
//! Windows, CI without the toolchain — it prints what is missing and exits 0,
//! rather than failing a build that never had a chance to pass.

const std = @import("std");

const Case = struct {
    name: []const u8,
    /// Passed to `zilc build`, relative to the repo root.
    inputs: []const []const u8,
    optimize: []const u8 = "ReleaseSafe",
    /// The `semantic origin:` the panic must name.
    origin: []const u8,
    /// A distinctive phrase from the expected violation.
    fault: []const u8,
};

const cases = [_]Case{
    .{
        .name = "interop: C allocates, Zig overflows",
        .inputs = &.{ "examples/interop/c_caller.c", "examples/interop/bounds.zig" },
        .origin = "bounds.zig:13:6",
        .fault = "ptr >= upper",
    },
    .{
        .name = "whole Zig program (generated entry shim)",
        .inputs = &.{"examples/whole_program/hello.zig"},
        .origin = "hello.zig:25:6",
        .fault = "ptr >= upper",
    },
    .{
        .name = "C out-of-bounds write",
        .inputs = &.{"examples/oob_write.c"},
        .origin = "oob_write.c:15",
        .fault = "ptr >= upper",
    },
    .{
        .name = "C use-after-free",
        .inputs = &.{"examples/use_after_free.c"},
        .origin = "use_after_free.c:13",
        .fault = "free object",
    },
};

/// Fil-C panics kill the process with SIGTRAP; a shell reports that as 133.
const sigtrap = 5;

fn isFilC(gpa: std.mem.Allocator, clang: []const u8) bool {
    const res = std.process.Child.run(.{
        .allocator = gpa,
        .argv = &.{ clang, "--version" },
    }) catch return false;
    defer gpa.free(res.stdout);
    defer gpa.free(res.stderr);
    return std.mem.indexOf(u8, res.stdout, "Fil-C") != null;
}

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena_state.deinit();
    const gpa = arena_state.allocator();

    const args = try std.process.argsAlloc(gpa);
    if (args.len < 3) {
        std.debug.print("usage: gate <zilc-exe> <repo-root>\n", .{});
        std.process.exit(2);
    }
    const zilc = args[1];
    const root = args[2];

    const zig_path = std.process.getEnvVarOwned(gpa, "ZILC_ZIG") catch @as([]u8, @constCast("zig"));
    const filc_path = std.process.getEnvVarOwned(gpa, "ZILC_FILC") catch @as([]u8, @constCast("clang"));

    if (!isFilC(gpa, filc_path)) {
        std.debug.print(
            \\gate: SKIPPED — no Fil-C toolchain here.
            \\
            \\  The examples must be compiled by Fil-C's clang, which exists only on
            \\  Linux x86_64. Point the gate at one and re-run:
            \\
            \\    export ZILC_FILC=/path/to/filc-<ver>-linux-x86_64/build/bin/clang
            \\    export ZILC_ZIG=/path/to/zig-0.15.2/zig
            \\    zig build gate
            \\
            \\  Setup: tools/p1/setup-wsl.sh. Background: cmem/known-issues.md KI-1.
            \\
        , .{});
        return; // exit 0: not a failure, an absence
    }

    const work = try std.fmt.allocPrint(gpa, "{s}/zig-out/gate", .{root});
    try std.fs.cwd().makePath(work);

    var failures: usize = 0;
    for (cases, 1..) |case, n| {
        std.debug.print("[{d}/{d}] {s}\n", .{ n, cases.len, case.name });

        const out_path = try std.fmt.allocPrint(gpa, "{s}/case{d}", .{ work, n });

        var argv: std.ArrayListUnmanaged([]const u8) = .{};
        try argv.appendSlice(gpa, &.{ zilc, "build", "-O", case.optimize, "-o", out_path });
        for (case.inputs) |in| {
            try argv.append(gpa, try std.fmt.allocPrint(gpa, "{s}/{s}", .{ root, in }));
        }

        const built = try std.process.Child.run(.{
            .allocator = gpa,
            .argv = argv.items,
            .env_map = null,
        });
        const build_ok = switch (built.term) {
            .Exited => |c| c == 0,
            else => false,
        };
        if (!build_ok) {
            std.debug.print("      FAIL: zilc build did not succeed\n{s}\n", .{built.stderr});
            failures += 1;
            continue;
        }

        const ran = try std.process.Child.run(.{ .allocator = gpa, .argv = &.{out_path} });
        const trapped = switch (ran.term) {
            .Signal => |sig| sig == sigtrap,
            .Exited => |c| c == 128 + sigtrap,
            else => false,
        };

        // Fil-C reports on stderr; keep stdout too, since the program prints
        // before it dies and that ordering is part of what is being checked.
        const report = try std.fmt.allocPrint(gpa, "{s}{s}", .{ ran.stdout, ran.stderr });

        var problems: usize = 0;
        if (!trapped) {
            std.debug.print("      FAIL: expected a SIGTRAP panic, got {any}\n", .{ran.term});
            problems += 1;
        }
        if (std.mem.indexOf(u8, report, "filc safety error") == null) {
            std.debug.print("      FAIL: no 'filc safety error' in the output\n", .{});
            problems += 1;
        }
        if (std.mem.indexOf(u8, report, case.origin) == null) {
            std.debug.print("      FAIL: panic did not name '{s}'\n", .{case.origin});
            problems += 1;
        }
        if (std.mem.indexOf(u8, report, case.fault) == null) {
            std.debug.print("      FAIL: expected fault '{s}'\n", .{case.fault});
            problems += 1;
        }

        if (problems == 0) {
            std.debug.print("      ok — trapped at {s}\n", .{case.origin});
        } else {
            std.debug.print("      --- output ---\n{s}\n", .{report});
            failures += 1;
        }
    }

    std.debug.print("\ngate: {d}/{d} cases passed", .{ cases.len - failures, cases.len });
    std.debug.print(" (zig={s}, filc={s})\n", .{ zig_path, filc_path });
    if (failures != 0) std.process.exit(1);
}
