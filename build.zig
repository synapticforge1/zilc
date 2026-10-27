// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
const std = @import("std");
const pure_zig = @import("build/pure_zig.zig");

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

    // ---- Licences beside the binaries (third_party/LICENSES.md) -----------
    // zilc's own licence, the NOTICE, and the texts of what the installed binaries contain: Zig's
    // std (every Zig program), and in zilc-gen Fil-C's forwarder generator (BSD-2-Clause) and musl's
    // header rules (MIT).
    for ([_][2][]const u8{
        .{ "LICENSE-APACHE", "LICENSE-APACHE" },
        .{ "LICENSE-MIT", "LICENSE-MIT" },
        .{ "NOTICE", "NOTICE" },
        .{ "third_party/zig/LICENSE", "zig-LICENSE" },
        .{ "third_party/fil-c/PAS-LICENSE.txt", "fil-c-PAS-LICENSE.txt" },
        .{ "third_party/fil-c/MUSL-LICENSE.txt", "fil-c-MUSL-LICENSE.txt" },
    }) |f| b.installFile(f[0], b.fmt("share/licenses/zilc/{s}", .{f[1]}));

    // ---- zilc-gen: the pure-Zig track's generators (cmem/roadmap.md, Z1) ---
    // Fil-C's forwarder generator and musl's header install, in Zig (src/gen/; ported, see
    // third_party/LICENSES.md `forwarder-generator`, `musl-header-install`). Brought from zailc on
    // 2026-10-27, faithful to the Fil-C release in src/gen/signatures.zig.
    const gen = b.addExecutable(.{
        .name = "zilc-gen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/gen/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const gen_options = b.addOptions();
    gen_options.addOption([]const u8, "version", zonVersion(b));
    gen.root_module.addOptions("build_options", gen_options);
    b.installArtifact(gen);
    const run_gen = b.addRunArtifact(gen);
    if (b.args) |args| run_gen.addArgs(args);
    b.step("gen", "Run zilc-gen with the arguments after -- (header | forwarders | musl-headers | musl-genh | --version)").dependOn(&run_gen.step);

    // The runtime pieces built from Fil-C's sources (`zig build libpas | yolomusl | compiler-rt |
    // pure-zig -Dfilc-src=…`): build/pure_zig.zig.
    pure_zig.addSteps(b, gen);

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

        const gate_step = b.step("gate", "Build every example with zilc: bugs must trap, library mode must run (needs Fil-C)");
        gate_step.dependOn(&run_gate.step);

        // ---- The same gate with Fil-C's modules swapped for pure-Zig ones ----
        // `zig build gate-zig-modules -Dzig-modules=<dir> -Dzig-modules-filc=<release>` (owner,
        // 2026-10-27): after a Fil-C update has passed every checklist item, the pure-Zig builds
        // of the changed modules replace Fil-C's (tools/swap-modules.zig: a copy of the ZILC_FILC
        // toolchain with each same-named file of <dir>/lib/ swapped into pizfix/lib/), and the
        // gate above runs unchanged against the copy. It refuses when the declared release is not
        // the toolchain's, or when nothing would be swapped. The copy goes under
        // -Dzig-modules-out (default ~/zilc-work/zig-modules): the repo is on exFAT.
        const zig_modules = b.option([]const u8, "zig-modules", "Directory whose lib/ holds pure-Zig builds of Fil-C's runtime modules, named as in pizfix/lib/");
        const zig_modules_filc = b.option([]const u8, "zig-modules-filc", "The Fil-C release those modules were built from (must equal the ZILC_FILC toolchain's)");
        const zig_modules_out = b.option([]const u8, "zig-modules-out", "Where the swapped toolchain copy is made (default: ~/zilc-work/zig-modules)");
        const swap_step = b.step("gate-zig-modules", "The gate again, with Fil-C's modules swapped for pure-Zig ones (-Dzig-modules=<dir> -Dzig-modules-filc=<release>; needs Fil-C)");
        if (zig_modules) |dir| {
            const filc_clang = b.graph.env_map.get("ZILC_FILC") orelse "clang";
            const home = b.graph.env_map.get("HOME") orelse ".";
            const out = zig_modules_out orelse b.pathJoin(&.{ home, "zilc-work", "zig-modules" });
            const release = zig_modules_filc orelse "";
            const swap = b.addExecutable(.{
                .name = "swap-modules",
                .root_module = b.createModule(.{
                    .root_source_file = b.path("tools/swap-modules.zig"),
                    .target = target,
                    .optimize = optimize,
                }),
            });
            const run_swap = b.addRunArtifact(swap);
            run_swap.addArgs(&.{ filc_clang, dir, release, out });
            run_swap.has_side_effects = true;

            // The same gate executable, aimed at the copy. tools/swap-modules.zig names the copy
            // filc-<release>-zig-modules; it has already refused if <release> is not the tree's.
            const swapped_clang = b.pathJoin(&.{ out, b.fmt("filc-{s}-zig-modules", .{release}), "build", "bin", "clang" });
            const run_gate_zm = b.addRunArtifact(gate);
            run_gate_zm.addFileArg(exe.getEmittedBin());
            run_gate_zm.addArg(b.build_root.path orelse ".");
            run_gate_zm.setEnvironmentVariable("ZILC_FILC", swapped_clang);
            run_gate_zm.has_side_effects = true;
            run_gate_zm.step.dependOn(&run_swap.step);
            swap_step.dependOn(&run_gate_zm.step);
        } else {
            const no_dir = b.addFail("gate-zig-modules needs -Dzig-modules=<dir with lib/> and -Dzig-modules-filc=<release>, e.g. -Dzig-modules-filc=0.687");
            swap_step.dependOn(&no_dir.step);
        }
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
    // The generators: byte-identity with Ruby's output (SHA-256 pinned per Fil-C release) and the
    // musl header rules.
    for ([_][]const u8{ "src/gen/forwarders.zig", "src/gen/musl_headers.zig" }) |root| {
        const t = b.addTest(.{ .root_module = b.createModule(.{
            .root_source_file = b.path(root),
            .target = target,
            .optimize = optimize,
        }) });
        test_step.dependOn(&b.addRunArtifact(t).step);
    }
}

/// `.version` from build.zig.zon: exactly one line `    .version = "X.Y.Z",`, or the build fails.
fn zonVersion(b: *std.Build) []const u8 {
    const text = b.build_root.handle.readFileAlloc(b.allocator, "build.zig.zon", 1 << 20) catch |err|
        std.debug.panic("cannot read build.zig.zon: {s}", .{@errorName(err)});
    const prefix = "    .version = \"";
    var found: ?[]const u8 = null;
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trimRight(u8, raw, "\r");
        if (!std.mem.startsWith(u8, line, prefix) or !std.mem.endsWith(u8, line, "\",")) continue;
        if (found != null) std.debug.panic("build.zig.zon: more than one .version line", .{});
        found = line[prefix.len .. line.len - 2];
    }
    return found orelse std.debug.panic("build.zig.zon: no `    .version = \"X.Y.Z\",` line", .{});
}
