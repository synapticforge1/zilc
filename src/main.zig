// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! `zilc` — compile Zig and C into one memory-safe binary via Fil-C.
//!
//! Stock Zig emits LLVM IR; zilc rewrites its data layout into Fil-C's dialect;
//! Fil-C's clang runs the GIMSO pass and links. See cmem/roadmap.md P2.

const std = @import("std");
const zilc = @import("zilc");
const driver = @import("driver.zig");

const usage =
    \\zilc {s} — a Fil-C-style memory-safe target for the Zig toolchain
    \\
    \\usage: zilc build [options] <inputs...>
    \\
    \\  Inputs: .zig go through Zig, then the Fil-C pass.
    \\          .c .cc .cpp .o .a .s .ll go straight to Fil-C.
    \\
    \\options:
    \\  -o <path>        output (default: a.out)
    \\  -O <mode>        Zig optimize mode (default: ReleaseSafe)
    \\  --target <t>     Zig target (default: x86_64-linux-musl)
    \\  -c               emit an object instead of linking
    \\  --zig <path>     zig binary    (env ZILC_ZIG)
    \\  --filc <path>    Fil-C's clang (env ZILC_FILC)
    \\  --keep-temps     keep the intermediate .ll/.o files
    \\  -v, --verbose    print every command
    \\  -h, --help       this text
    \\      --version    version
    \\
    \\Today's limits, each with a reason in cmem/known-issues.md:
    \\  * -O Debug works, but compiles at clang -O0 with -fno-stack-check and
    \\    produces very large objects (KI-4).
    \\  * Fil-C's libc is musl; a gnu target fails to link (KI-6).
    \\  * Zig's start code trips Fil-C, so C must own main (KI-5):
    \\    export C-ABI functions from Zig and link a C main.
    \\
    \\example:
    \\  zilc build examples/interop/c_caller.c examples/interop/bounds.zig -o prog
    \\
;

const exit_usage = 2;

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const args = try std.process.argsAlloc(arena);
    const code: u8 = run(arena, args) catch |e| blk: {
        // driver.run already reported what failed; don't bury it under a trace.
        if (e == driver.Error.ToolFailed) break :blk 1;
        std.debug.print("zilc: {s}\n", .{@errorName(e)});
        break :blk 1;
    };
    if (code != 0) std.process.exit(code);
}

fn isFlag(arg: []const u8, short: []const u8, long: []const u8) bool {
    return std.mem.eql(u8, arg, short) or std.mem.eql(u8, arg, long);
}

fn run(arena: std.mem.Allocator, args: []const []const u8) !u8 {
    if (args.len < 2 or isFlag(args[1], "-h", "--help")) {
        std.debug.print(usage, .{zilc.version_string});
        return if (args.len < 2) exit_usage else 0;
    }
    if (std.mem.eql(u8, args[1], "--version")) {
        std.debug.print("zilc {s}\n", .{zilc.version_string});
        return 0;
    }
    if (!std.mem.eql(u8, args[1], "build")) {
        std.debug.print("zilc: unknown command '{s}'. Try 'zilc --help'.\n", .{args[1]});
        return exit_usage;
    }

    var inputs: std.ArrayListUnmanaged([]const u8) = .{};
    var output: []const u8 = "a.out";
    var optimize: []const u8 = "ReleaseSafe";
    var target: []const u8 = "x86_64-linux-musl";
    var emit: @FieldType(driver.Options, "emit") = .exe;
    var keep_temps = false;
    var verbose = false;
    var zig_path = std.process.getEnvVarOwned(arena, "ZILC_ZIG") catch @as([]u8, @constCast("zig"));
    var filc_path = std.process.getEnvVarOwned(arena, "ZILC_FILC") catch @as([]u8, @constCast("clang"));

    var i: usize = 2;
    while (i < args.len) : (i += 1) {
        const a = args[i];
        const takes_value = std.mem.eql(u8, a, "-o") or std.mem.eql(u8, a, "-O") or
            std.mem.eql(u8, a, "--target") or std.mem.eql(u8, a, "--zig") or
            std.mem.eql(u8, a, "--filc");
        if (takes_value and i + 1 >= args.len) {
            std.debug.print("zilc: '{s}' needs a value\n", .{a});
            return exit_usage;
        }
        if (std.mem.eql(u8, a, "-o")) {
            i += 1;
            output = args[i];
        } else if (std.mem.eql(u8, a, "-O")) {
            i += 1;
            optimize = args[i];
        } else if (std.mem.eql(u8, a, "--target")) {
            i += 1;
            target = args[i];
        } else if (std.mem.eql(u8, a, "--zig")) {
            i += 1;
            zig_path = @constCast(args[i]);
        } else if (std.mem.eql(u8, a, "--filc")) {
            i += 1;
            filc_path = @constCast(args[i]);
        } else if (std.mem.eql(u8, a, "-c")) {
            emit = .obj;
        } else if (std.mem.eql(u8, a, "--keep-temps")) {
            keep_temps = true;
        } else if (isFlag(a, "-v", "--verbose")) {
            verbose = true;
        } else if (std.mem.startsWith(u8, a, "-")) {
            std.debug.print("zilc: unknown option '{s}'\n", .{a});
            return exit_usage;
        } else {
            try inputs.append(arena, a);
        }
    }

    if (inputs.items.len == 0) {
        std.debug.print("zilc: no input files\n", .{});
        return exit_usage;
    }

    // Debug works, but only with two concessions the driver applies for you.
    // Say so rather than letting the size and the missing probes surprise people.
    if (driver.isDebug(optimize)) {
        std.debug.print(
            \\zilc: note: Debug builds compile the instrumented IR at clang -O0 and pass
            \\  -fno-stack-check, because Debug IR crashes Fil-C's pass at -O1 and Zig's
            \\  stack probe never goes through it. Expect large objects.
            \\  Detail: cmem/known-issues.md KI-4.
            \\
        , .{});
    }
    if (std.mem.indexOf(u8, target, "-musl") == null) {
        std.debug.print(
            \\zilc: warning: target '{s}' is not musl. Fil-C's libc is musl, and a
            \\  gnu target fails to link on mmap64/getrlimit64 (cmem/known-issues.md KI-6).
            \\
        , .{target});
    }

    try driver.build(arena, .{
        .inputs = inputs.items,
        .output = output,
        .optimize = optimize,
        .target = target,
        .emit = emit,
        .zig = zig_path,
        .filc = filc_path,
        .keep_temps = keep_temps,
        .verbose = verbose,
    });
    return 0;
}

test {
    _ = driver;
}
