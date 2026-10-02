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
    \\       zilc --clean-cache    delete every cached Fil-C object
    \\
    \\  Inputs: .zig go through Zig, then the Fil-C pass.
    \\          .c .cc .cpp .o .a .s .ll go straight to Fil-C.
    \\
    \\options:
    \\  -o <path>        output (default: a.out)
    \\  -O <mode>        Zig optimize mode (default: ReleaseSafe)
    \\  --target <t>     Zig target (default: x86_64-linux-musl)
    \\  -c               emit an object instead of linking
    \\  --entry <who>    who owns main: auto (default), zig, or c.
    \\                   `zig` wraps your `pub fn main` in a generated C-ABI entry,
    \\                   because Zig's own start code cannot run under Fil-C (KI-5).
    \\  --runtime <rt>   runtime to link: filc (default), or zig.
    \\                   `zig` is reserved for zilc's own runtime and is refused
    \\                   until that runtime is ready for testing (roadmap P3).
    \\  --zig <path>     zig binary    (env ZILC_ZIG)
    \\  --filc <path>    Fil-C's clang (env ZILC_FILC)
    \\  -j <n>           parallel code generation parts for big modules
    \\                   (default: cores, at most 16; 1 = off; env ZILC_JOBS)
    \\  --no-cache       always run Fil-C's clang, even for an unchanged module
    \\                   (env ZILC_CACHE=0; the cache is in $ZILC_CACHE_DIR,
    \\                   else $XDG_CACHE_HOME/zilc, else ~/.cache/zilc)
    \\  --clean-cache    delete every cached object first, then build
    \\  --keep-temps     keep the intermediate .ll/.o files
    \\  -v, --verbose    print every command
    \\  -h, --help       this text
    \\      --version    version
    \\
    \\Today's limits, each with a reason in cmem/known-issues.md:
    \\  * -O Debug needs zilc's patched Fil-C clang (KI-4; tools/filc/).
    \\  * Fil-C's libc is musl; a gnu target fails to link (KI-6).
    \\  * Zig's own start code trips Fil-C (KI-5), so zilc generates the
    \\    entry: a Zig `pub fn main` works, and so does a C main calling Zig
    \\    exports; std.os.environ is not set.
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
        // The driver already reported these; don't bury them under an error name.
        if (e == driver.Error.ToolFailed or e == driver.Error.RuntimeNotReady) break :blk 1;
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
    if (std.mem.eql(u8, args[1], "--clean-cache")) {
        try cleanCache(arena);
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
    var entry: driver.Entry = .auto;
    var runtime: driver.Runtime = .filc;
    var keep_temps = false;
    var verbose = false;
    var zig_path = std.process.getEnvVarOwned(arena, "ZILC_ZIG") catch @as([]u8, @constCast("zig"));
    var filc_path = std.process.getEnvVarOwned(arena, "ZILC_FILC") catch @as([]u8, @constCast("clang"));
    var jobs_text: ?[]const u8 = std.process.getEnvVarOwned(arena, "ZILC_JOBS") catch null;
    var cache = if (std.process.getEnvVarOwned(arena, "ZILC_CACHE")) |v| !std.mem.eql(u8, v, "0") else |_| true;
    var clean_cache = false;

    var i: usize = 2;
    while (i < args.len) : (i += 1) {
        const a = args[i];
        const takes_value = std.mem.eql(u8, a, "-o") or std.mem.eql(u8, a, "-O") or
            std.mem.eql(u8, a, "--target") or std.mem.eql(u8, a, "--zig") or
            std.mem.eql(u8, a, "--filc") or std.mem.eql(u8, a, "--entry") or
            std.mem.eql(u8, a, "--runtime") or std.mem.eql(u8, a, "-j");
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
        } else if (std.mem.eql(u8, a, "--entry")) {
            i += 1;
            entry = std.meta.stringToEnum(driver.Entry, args[i]) orelse {
                std.debug.print("zilc: --entry must be auto, zig or c (got '{s}')\n", .{args[i]});
                return exit_usage;
            };
        } else if (std.mem.eql(u8, a, "--runtime")) {
            i += 1;
            runtime = std.meta.stringToEnum(driver.Runtime, args[i]) orelse {
                std.debug.print("zilc: --runtime must be filc or zig (got '{s}')\n", .{args[i]});
                return exit_usage;
            };
        } else if (std.mem.eql(u8, a, "-j")) {
            i += 1;
            jobs_text = args[i];
        } else if (std.mem.eql(u8, a, "-c")) {
            emit = .obj;
        } else if (std.mem.eql(u8, a, "--no-cache")) {
            cache = false;
        } else if (std.mem.eql(u8, a, "--clean-cache")) {
            clean_cache = true;
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

    const jobs: u32 = if (jobs_text) |t| std.fmt.parseInt(u32, t, 10) catch {
        std.debug.print("zilc: -j / ZILC_JOBS must be a number (got '{s}')\n", .{t});
        return exit_usage;
    } else 0;

    if (std.mem.indexOf(u8, target, "-musl") == null) {
        std.debug.print(
            \\zilc: warning: target '{s}' is not musl. Fil-C's libc is musl, and a
            \\  gnu target fails to link on mmap64/getrlimit64 (cmem/known-issues.md KI-6).
            \\
        , .{target});
    }

    if (clean_cache) try cleanCache(arena);

    try driver.build(arena, .{
        .inputs = inputs.items,
        .output = output,
        .entry = entry,
        .optimize = optimize,
        .target = target,
        .emit = emit,
        .runtime = runtime,
        .zig = zig_path,
        .filc = filc_path,
        .keep_temps = keep_temps,
        .verbose = verbose,
        .jobs = jobs,
        .cache = cache,
    });
    return 0;
}

fn cleanCache(arena: std.mem.Allocator) !void {
    const r = try driver.cleanCache(arena);
    std.debug.print("zilc: cleaned the object cache in {s}/objects: {d} object(s), {d:.1} MB\n", .{
        r.root, r.files, @as(f64, @floatFromInt(r.bytes)) / (1024 * 1024),
    });
}

test {
    _ = driver;
}
