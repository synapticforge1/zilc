// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ---- Core runtime module (`zilc_runtime`) ------------------------------
    // The Zig implementation of the Fil-C runtime model. Empty for now; see
    // cmem/architecture.md.
    const mod = b.addModule("zilc", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    // ---- CLI driver --------------------------------------------------------
    const exe = b.addExecutable(.{
        .name = "zilc",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "zilc", .module = mod }},
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Run the CLI (zig build run -- <args>)");
    run_step.dependOn(&run_cmd.step);

    // ---- Runtime as a static C-ABI library (`include/zilc.h`) --------------
    const rt = b.addLibrary(.{
        .name = "zilc_runtime",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/capi.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "zilc", .module = mod }},
        }),
    });
    rt.installHeader(b.path("include/zilc.h"), "zilc.h");
    b.installArtifact(rt);

    // ---- C smoke test (`zig build capi-smoke`) -----------------------------
    // Links a C client against the runtime through `zilc.h`. Uses a gnu-abi
    // target so the C side has a libc without MSVC.
    {
        const gnu = b.resolveTargetQuery(.{ .abi = .gnu });
        const rt_gnu = b.addLibrary(.{
            .name = "zilc_runtime_smoke",
            .linkage = .static,
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/capi.zig"),
                .target = gnu,
                .optimize = optimize,
                .imports = &.{.{ .name = "zilc", .module = mod }},
            }),
        });
        const smoke_mod = b.createModule(.{ .target = gnu, .optimize = optimize, .link_libc = true });
        smoke_mod.addCSourceFile(.{ .file = b.path("tests/capi_smoke.c"), .flags = &.{ "-Wall", "-Wextra" } });
        smoke_mod.addIncludePath(b.path("include"));
        smoke_mod.linkLibrary(rt_gnu);
        const smoke = b.addExecutable(.{ .name = "capi_smoke", .root_module = smoke_mod });
        const run_smoke = b.addRunArtifact(smoke);
        const step = b.step("capi-smoke", "Build + run the C ABI smoke test");
        step.dependOn(&run_smoke.step);
    }

    // ---- Unsafe baseline (`zig build baseline`) ----------------------------
    // Compiles examples/*.c with PLAIN `zig cc` — no zilc pass. These bugs are
    // undefined behavior here and may appear to work. Once the pass exists, a
    // `safe` counterpart must turn each of them into a deterministic panic.
    {
        const baseline_step = b.step("baseline", "Build the bug examples with plain zig cc (no safety)");
        const examples = [_][]const u8{ "oob_write", "use_after_free" };
        for (examples) |name| {
            const m = b.createModule(.{ .target = target, .optimize = optimize, .link_libc = true });
            m.addCSourceFile(.{ .file = b.path(b.fmt("examples/{s}.c", .{name})) });
            const e = b.addExecutable(.{ .name = b.fmt("baseline_{s}", .{name}), .root_module = m });
            baseline_step.dependOn(&b.addInstallArtifact(e, .{}).step);
        }
    }

    // ---- The safety gate (`zig build gate`) --------------------------------
    // Builds every example with the zilc driver and asserts that each one traps
    // at the right source line. Needs Fil-C, so it SKIPS (exit 0) with guidance
    // where the toolchain is absent — a build that never had a chance to pass
    // should not read as a failure.
    {
        const gate = b.addExecutable(.{
            .name = "gate",
            .root_module = b.createModule(.{
                .root_source_file = b.path("tools/gate.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        const run_gate = b.addRunArtifact(gate);
        run_gate.addFileArg(exe.getEmittedBin()); // the zilc driver to exercise
        run_gate.addArg(b.build_root.path orelse ".");
        // The examples and the driver's output both change what this proves.
        run_gate.has_side_effects = true;

        const gate_step = b.step("gate", "Build every example with zilc and assert it traps (needs Fil-C)");
        gate_step.dependOn(&run_gate.step);
    }

    // ---- Tests -------------------------------------------------------------
    const mod_tests = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    }) });
    const exe_tests = b.addTest(.{ .root_module = exe.root_module });
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(mod_tests).step);
    test_step.dependOn(&b.addRunArtifact(exe_tests).step);
}
