// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! The zilc compile pipeline.
//!
//!   .zig  --zig build-obj--> LLVM IR --rewrite--> Fil-C dialect IR --+
//!                                                                    |--filc clang--> safe binary
//!   .c/.cpp/.o/.a -----------------------------------------------------+
//!
//! Nothing here patches Zig or LLVM: stock Zig emits the IR, `ir.zig` rewrites
//! two lines of it, and Fil-C's clang runs the GIMSO pass and links.
//! Background and limits: cmem/roadmap.md P2, cmem/known-issues.md KI-4…KI-6.

const std = @import("std");
// Through the module, not the file: importing "ir.zig" directly would put the
// same file in two modules, which Zig rejects.
const ir = @import("zilc").ir;

pub const Options = struct {
    inputs: []const []const u8,
    output: []const u8,
    /// Zig optimize mode. ⚠️ Debug IR crashes the pass today (KI-4).
    optimize: []const u8 = "ReleaseSafe",
    /// ⚠️ Fil-C's libc is musl; a gnu target fails to link on `*64` symbols (KI-6).
    target: []const u8 = "x86_64-linux-musl",
    /// Emit a linked executable, or stop at objects.
    emit: enum { exe, obj } = .exe,
    zig: []const u8,
    filc: []const u8,
    keep_temps: bool = false,
    verbose: bool = false,
};

pub const Error = error{ ToolFailed, NoInputs, UnsupportedInput };

/// What a given input file needs: Zig compiles it to IR first, or Fil-C takes it directly.
fn classify(path: []const u8) !enum { zig, native } {
    const ext = std.fs.path.extension(path);
    if (std.mem.eql(u8, ext, ".zig")) return .zig;
    inline for (.{ ".c", ".cc", ".cpp", ".cxx", ".o", ".a", ".s", ".ll" }) |known| {
        if (std.mem.eql(u8, ext, known)) return .native;
    }
    return Error.UnsupportedInput;
}

fn run(gpa: std.mem.Allocator, argv: []const []const u8, verbose: bool) !void {
    if (verbose) {
        for (argv, 0..) |a, i| std.debug.print("{s}{s}", .{ if (i == 0) "+ " else " ", a });
        std.debug.print("\n", .{});
    }
    var child = std.process.Child.init(argv, gpa);
    child.stdin_behavior = .Inherit;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;
    const term = child.spawnAndWait() catch |e| {
        std.debug.print("zilc: cannot run '{s}': {s}\n", .{ argv[0], @errorName(e) });
        return Error.ToolFailed;
    };
    switch (term) {
        .Exited => |code| if (code != 0) {
            std.debug.print("zilc: '{s}' exited with {d}\n", .{ argv[0], code });
            return Error.ToolFailed;
        },
        else => {
            std.debug.print("zilc: '{s}' terminated abnormally\n", .{argv[0]});
            return Error.ToolFailed;
        },
    }
}

/// Zig source → LLVM IR → Fil-C-dialect IR → object file. Returns the object path.
fn compileZig(
    gpa: std.mem.Allocator,
    opts: Options,
    tmp_path: []const u8,
    src: []const u8,
) ![]u8 {
    const stem = std.fs.path.stem(src);
    const ll_path = try std.fmt.allocPrint(gpa, "{s}/{s}.ll", .{ tmp_path, stem });
    defer gpa.free(ll_path);
    const filc_ll_path = try std.fmt.allocPrint(gpa, "{s}/{s}.filc.ll", .{ tmp_path, stem });
    defer gpa.free(filc_ll_path);
    const obj_path = try std.fmt.allocPrint(gpa, "{s}/{s}.o", .{ tmp_path, stem });
    errdefer gpa.free(obj_path);

    // 1. Stock Zig emits plain LLVM IR. `-fno-emit-bin`: we only want the IR.
    const emit_arg = try std.fmt.allocPrint(gpa, "-femit-llvm-ir={s}", .{ll_path});
    defer gpa.free(emit_arg);
    try run(gpa, &.{
        opts.zig,    "build-obj", src,       "-target", opts.target,
        "-O",        opts.optimize,          "-fno-emit-bin",
        emit_arg,
    }, opts.verbose);

    // 2. The rewrite: two lines, and the whole reason this driver exists.
    const plain = try std.fs.cwd().readFileAlloc(gpa, ll_path, 512 * 1024 * 1024);
    defer gpa.free(plain);
    const dialect = ir.toFilCDialect(gpa, plain) catch |e| {
        std.debug.print("zilc: cannot rewrite IR for '{s}': {s}\n", .{ src, @errorName(e) });
        return Error.ToolFailed;
    };
    defer gpa.free(dialect);
    try std.fs.cwd().writeFile(.{ .sub_path = filc_ll_path, .data = dialect });

    // 3. Fil-C's clang runs the pass and emits the object.
    //
    // `-Wno-override-module`: Zig names the triple `…-linux-musl` while Fil-C's
    // driver is `…-linux-gnu`, so clang warns that it is overriding ours. It is
    // expected, not a mismatch to fix — Fil-C's libc *is* musl whatever its
    // triple says, which is why the musl target is the one that links (KI-6).
    try run(gpa, &.{
        opts.filc, "-O1", "-g", "-Wno-override-module", "-c", "-o", obj_path, filc_ll_path,
    }, opts.verbose);
    return obj_path;
}

pub fn build(gpa: std.mem.Allocator, opts: Options) !void {
    if (opts.inputs.len == 0) return Error.NoInputs;

    // Temps live beside the output so a failed build leaves them inspectable
    // with --keep-temps, which is how KI-4/KI-5 were diagnosed in the first place.
    const tmp_path = try std.fmt.allocPrint(gpa, "{s}.zilc-tmp", .{opts.output});
    defer gpa.free(tmp_path);
    try std.fs.cwd().makePath(tmp_path);
    defer if (!opts.keep_temps) {
        std.fs.cwd().deleteTree(tmp_path) catch {};
    } else std.debug.print("zilc: kept intermediates in {s}/\n", .{tmp_path});

    var link_args: std.ArrayListUnmanaged([]const u8) = .{};
    defer link_args.deinit(gpa);
    var owned: std.ArrayListUnmanaged([]u8) = .{};
    defer {
        for (owned.items) |p| gpa.free(p);
        owned.deinit(gpa);
    }

    try link_args.appendSlice(gpa, &.{ opts.filc, "-O1", "-g" });

    for (opts.inputs) |input| {
        switch (try classify(input)) {
            .zig => {
                const obj = try compileZig(gpa, opts, tmp_path, input);
                try owned.append(gpa, obj);
                try link_args.append(gpa, obj);
            },
            // C/C++/objects go to Fil-C untouched: it is already their compiler.
            .native => try link_args.append(gpa, input),
        }
    }

    if (opts.emit == .obj) {
        // Object-only: the .o files are the product, so copy them out.
        for (owned.items) |obj| {
            try std.fs.cwd().copyFile(obj, std.fs.cwd(), opts.output, .{});
        }
        return;
    }

    try link_args.appendSlice(gpa, &.{ "-o", opts.output });
    try run(gpa, link_args.items, opts.verbose);
}
