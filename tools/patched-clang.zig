// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! `zig build patched-clang`: Fil-C's clang built from the fetched sources WITH zilc's pass fixes
//! (third_party/filc-patches/zilc-filc-pass.patch; cmem/workarounds.md KI-4, KI-22), for local use
//! only (ledger `filc-pass-fixes`). Replaces, for a user, what tools/filc/build-patched-clang.ts
//! does from a git checkout: no git, no Bun (owner, 2026-10-27: clone, install the build tools,
//! `zig build`; cmem/open-work.md).
//!
//!   patched-clang <filc src> <patch> <work dir> <jobs> <vc repository> <vc revision> <out dir>
//!                 [--cc <cc> --cxx <c++> --ar <ar> --ranlib <ranlib>]
//!
//! 1. Stage: <work>/src mirrors what LLVM's CMake reads (the top-level files, llvm/, clang/,
//!    cmake/, third-party/ — the sparse set of the git build) as HARD LINKS into the fetched
//!    package, so ~2 GB is not copied; the two patched files are real copies. Re-staged only when
//!    the source or the patch changes (<work>/src/.zilc-stage), so ninja's state stays valid.
//! 2. Patch, without git: each file's bytes must be the patch's pre-image (its git blob id, from the
//!    `index` line) and the result must be the post-image, so the patched files are exactly the
//!    ones the git build compiles. Hunks must match at their line numbers, with no fuzz.
//! 3. Configure (again whenever the configure command changes) as build-patched-clang.ts does, which mirrors Fil-C's own
//!    configure_llvm.sh except LLVM_ENABLE_LLD; plus LLVM_FORCE_VC_REPOSITORY/REVISION, since a
//!    fetched tree has no .git and `clang --version` must still name the prebuilt's origin.
//! 4. ninja -j <jobs> clang llvm-split (not one job per core: 32 RelWithDebInfo compiles exhausted
//!    a 31 GB WSL VM twice, 2026-10-01; jobs change speed only).
//! 5. <out>/bin: clang-20, and llvm-split stripped of debug info (by the llvm-objcopy built with it).
//!
//! With --cc/--cxx/--ar/--ranlib (Zig's own, through tools/zig-shim.zig; build.zig's default), Zig
//! is the only compiler (owner, 2026-10-27: "the user not needing an additional C compiler, just
//! zig to start"); its own build dir, since CMake caches the compiler. Without them, the system's
//! cc/c++, as the git build. Both proven by Fil-C's suite, 0 differences (cmem/testing.md).

const std = @import("std");

fn fail(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print("patched-clang: " ++ fmt ++ "\n", args);
    std.process.exit(1);
}

/// What CMake reads of the fork for LLVM_ENABLE_PROJECTS=clang (with the top-level files).
const stage_dirs = [_][]const u8{ "llvm", "clang", "cmake", "third-party" };

// ---- The patch ------------------------------------------------------------------------------

const Hunk = struct { old_start: usize, lines: []const []const u8 };
const FilePatch = struct { path: []const u8, old_id: []const u8, new_id: []const u8, hunks: []const Hunk };

/// A `git diff` with `index <old>..<new> <mode>` lines; nothing else (no renames, no binary).
fn parsePatch(gpa: std.mem.Allocator, text: []const u8) ![]FilePatch {
    var files: std.ArrayListUnmanaged(FilePatch) = .{};
    var hunks: std.ArrayListUnmanaged(Hunk) = .{};
    var body: std.ArrayListUnmanaged([]const u8) = .{};
    var cur: ?FilePatch = null;
    var old_start: ?usize = null;

    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |line| {
        if (std.mem.startsWith(u8, line, "diff --git ")) {
            if (old_start) |s| try hunks.append(gpa, .{ .old_start = s, .lines = try body.toOwnedSlice(gpa) });
            old_start = null;
            if (cur) |*c| {
                c.hunks = try hunks.toOwnedSlice(gpa);
                try files.append(gpa, c.*);
            }
            cur = .{ .path = "", .old_id = "", .new_id = "", .hunks = &.{} };
        } else if (std.mem.startsWith(u8, line, "index ")) {
            const ids = std.mem.sliceTo(line["index ".len..], ' ');
            const dots = std.mem.indexOf(u8, ids, "..") orelse fail("bad index line: {s}", .{line});
            cur.?.old_id = ids[0..dots];
            cur.?.new_id = ids[dots + 2 ..];
        } else if (std.mem.startsWith(u8, line, "--- ")) {
            if (!std.mem.startsWith(u8, line, "--- a/")) fail("only modifications are supported: {s}", .{line});
        } else if (std.mem.startsWith(u8, line, "+++ ")) {
            if (!std.mem.startsWith(u8, line, "+++ b/")) fail("only modifications are supported: {s}", .{line});
            cur.?.path = line["+++ b/".len..];
        } else if (std.mem.startsWith(u8, line, "@@ -")) {
            if (old_start) |s| try hunks.append(gpa, .{ .old_start = s, .lines = try body.toOwnedSlice(gpa) });
            const rest = line["@@ -".len..];
            const end = std.mem.indexOfAny(u8, rest, ", ") orelse fail("bad hunk header: {s}", .{line});
            old_start = try std.fmt.parseInt(usize, rest[0..end], 10);
        } else if (old_start != null and line.len > 0 and (line[0] == ' ' or line[0] == '-' or line[0] == '+')) {
            try body.append(gpa, line);
        } else if (std.mem.startsWith(u8, line, "\\")) {
            fail("\"no newline at end of file\" is not supported", .{});
        } else if (line.len != 0 and old_start != null) {
            fail("unexpected patch line: {s}", .{line});
        }
    }
    if (old_start) |s| try hunks.append(gpa, .{ .old_start = s, .lines = try body.toOwnedSlice(gpa) });
    if (cur) |*c| {
        c.hunks = try hunks.toOwnedSlice(gpa);
        try files.append(gpa, c.*);
    }
    for (files.items) |f| if (f.path.len == 0 or f.old_id.len < 7 or f.new_id.len < 7) fail("incomplete file header in the patch", .{});
    return files.items;
}

/// git's blob id: SHA-1 of "blob <len>\0" ++ bytes, in hex.
fn blobId(bytes: []const u8) [40]u8 {
    var h = std.crypto.hash.Sha1.init(.{});
    var hdr: [32]u8 = undefined;
    h.update(std.fmt.bufPrint(&hdr, "blob {d}\x00", .{bytes.len}) catch unreachable);
    h.update(bytes);
    return std.fmt.bytesToHex(h.finalResult(), .lower);
}

fn applyFile(gpa: std.mem.Allocator, src: []const u8, f: FilePatch) ![]const u8 {
    const pre = blobId(src);
    if (!std.mem.startsWith(u8, &pre, f.old_id))
        fail("{s} is not the patch's base (blob {s}, the patch expects {s}): the source is not at zilc's Fil-C commit", .{ f.path, pre[0..12], f.old_id });
    if (src.len == 0 or src[src.len - 1] != '\n') fail("{s}: no final newline", .{f.path});

    var lines: std.ArrayListUnmanaged([]const u8) = .{};
    var it = std.mem.splitScalar(u8, src[0 .. src.len - 1], '\n');
    while (it.next()) |l| try lines.append(gpa, l);

    var out: std.ArrayListUnmanaged(u8) = .{};
    var next: usize = 0; // index into lines of the next unconsumed line
    for (f.hunks) |h| {
        const at = h.old_start - 1;
        if (at < next) fail("{s}: hunks overlap or are out of order", .{f.path});
        for (lines.items[next..at]) |l| try out.print(gpa, "{s}\n", .{l});
        var i = at;
        for (h.lines) |hl| switch (hl[0]) {
            ' ', '-' => {
                if (i >= lines.items.len or !std.mem.eql(u8, lines.items[i], hl[1..]))
                    fail("{s}: hunk @@ -{d} does not match at line {d}", .{ f.path, h.old_start, i + 1 });
                if (hl[0] == ' ') try out.print(gpa, "{s}\n", .{hl[1..]});
                i += 1;
            },
            '+' => try out.print(gpa, "{s}\n", .{hl[1..]}),
            else => unreachable,
        };
        next = i;
    }
    for (lines.items[next..]) |l| try out.print(gpa, "{s}\n", .{l});

    const post = blobId(out.items);
    if (!std.mem.startsWith(u8, &post, f.new_id))
        fail("{s}: the patched result is blob {s}, the patch says {s}", .{ f.path, post[0..12], f.new_id });
    return out.items;
}

// ---- Staging --------------------------------------------------------------------------------

fn isPatched(files: []const FilePatch, rel: []const u8) bool {
    for (files) |f| if (std.mem.eql(u8, f.path, rel)) return true;
    return false;
}

/// Mirror `from/sub` into `to/sub`: directories made, links re-made, files hard-linked (or copied
/// when a link is impossible, e.g. another filesystem), except the patched ones.
fn mirror(gpa: std.mem.Allocator, from: std.fs.Dir, to: std.fs.Dir, sub: []const u8, files: []const FilePatch, counts: *[2]usize) !void {
    var src = try from.openDir(sub, .{ .iterate = true });
    defer src.close();
    try to.makePath(sub);
    var walker = try src.walk(gpa);
    defer walker.deinit();
    while (try walker.next()) |e| {
        const rel = try std.fs.path.join(gpa, &.{ sub, e.path });
        switch (e.kind) {
            .directory => try to.makePath(rel),
            .sym_link => {
                var buf: [std.fs.max_path_bytes]u8 = undefined;
                try to.symLink(try from.readLink(rel, &buf), rel, .{});
            },
            .file => try placeFile(from, to, rel, files, counts),
            else => fail("unexpected file type at {s}", .{rel}),
        }
    }
}

fn placeFile(from: std.fs.Dir, to: std.fs.Dir, rel: []const u8, files: []const FilePatch, counts: *[2]usize) !void {
    if (!isPatched(files, rel)) {
        if (std.posix.linkat(from.fd, rel, to.fd, rel, 0)) |_| {
            counts[0] += 1;
            return;
        } else |_| {}
    }
    try from.copyFile(rel, to, rel, .{});
    counts[1] += 1;
}

fn stage(gpa: std.mem.Allocator, filc_src: []const u8, work: []const u8, files: []const FilePatch, stamp: []const u8) ![]const u8 {
    const dst = try std.fs.path.join(gpa, &.{ work, "src" });
    const stamp_path = try std.fs.path.join(gpa, &.{ dst, ".zilc-stage" });
    if (std.fs.cwd().readFileAlloc(gpa, stamp_path, 1 << 16)) |old| {
        if (std.mem.eql(u8, old, stamp)) {
            std.debug.print("patched-clang: staged source is current ({s})\n", .{dst});
            return dst;
        }
    } else |_| {}

    std.debug.print("patched-clang: staging {s} -> {s}\n", .{ filc_src, dst });
    std.fs.cwd().deleteTree(dst) catch {};
    try std.fs.cwd().makePath(dst);
    var from = try std.fs.cwd().openDir(filc_src, .{ .iterate = true });
    defer from.close();
    var to = try std.fs.cwd().openDir(dst, .{});
    defer to.close();

    var counts = [2]usize{ 0, 0 }; // linked, copied
    var top = from.iterate();
    while (try top.next()) |e| switch (e.kind) {
        .file => try placeFile(from, to, e.name, files, &counts),
        .sym_link => {
            var buf: [std.fs.max_path_bytes]u8 = undefined;
            try to.symLink(try from.readLink(e.name, &buf), e.name, .{});
        },
        else => {},
    };
    for (stage_dirs) |d| try mirror(gpa, from, to, d, files, &counts);

    // The patched files: replace the copies (never the package's files, which are linked).
    for (files) |f| {
        const before = try to.readFileAlloc(gpa, f.path, 64 << 20);
        const after = try applyFile(gpa, before, f);
        try to.deleteFile(f.path);
        try to.writeFile(.{ .sub_path = f.path, .data = after });
        std.debug.print("patched-clang: patched {s} (blob {s} -> {s})\n", .{ f.path, f.old_id, f.new_id });
    }
    std.debug.print("patched-clang: staged {d} files as links, {d} as copies\n", .{ counts[0], counts[1] });
    try to.writeFile(.{ .sub_path = ".zilc-stage", .data = stamp });
    return dst;
}

// ---- Build ----------------------------------------------------------------------------------

fn runIn(gpa: std.mem.Allocator, cwd: []const u8, argv: []const []const u8) !void {
    var child = std.process.Child.init(argv, gpa);
    child.cwd = cwd;
    const term = try child.spawnAndWait();
    if (term != .Exited or term.Exited != 0) fail("failed ({any}): {s}", .{ term, try std.mem.join(gpa, " ", argv) });
}

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena_state.deinit();
    const gpa = arena_state.allocator();

    const args = try std.process.argsAlloc(gpa);
    if (args.len != 8 and args.len != 16)
        fail("usage: patched-clang <filc src> <patch> <work dir> <jobs> <vc repository> <vc revision> <out dir> [--cc <cc> --cxx <c++> --ar <ar> --ranlib <ranlib>]", .{});
    const filc_src = args[1];
    const patch_path = args[2];
    const work = args[3];
    const jobs = args[4];
    const vc_repo = args[5];
    const vc_rev = args[6];
    const out = args[7];
    var zig_tools: ?[4][]const u8 = null; // cc, c++, ar, ranlib
    if (args.len == 16) {
        var t: [4][]const u8 = undefined;
        for ([_][]const u8{ "--cc", "--cxx", "--ar", "--ranlib" }, 0..) |flag, i| {
            if (!std.mem.eql(u8, args[8 + 2 * i], flag)) fail("expected {s}, got {s}", .{ flag, args[8 + 2 * i] });
            t[i] = args[9 + 2 * i];
        }
        zig_tools = t;
    }

    const patch_text = try std.fs.cwd().readFileAlloc(gpa, patch_path, 16 << 20);
    const files = try parsePatch(gpa, patch_text);
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(patch_text, &digest, .{});
    const stamp = try std.fmt.allocPrint(gpa, "source {s}\npatch sha256 {s}\n", .{ filc_src, std.fmt.bytesToHex(digest, .lower) });

    try std.fs.cwd().makePath(work);
    const src = try stage(gpa, filc_src, work, files, stamp);

    const build_dir = try std.fs.path.join(gpa, &.{ work, if (zig_tools != null) "build-zig" else "build-system" });
    try std.fs.cwd().makePath(build_dir);
    {
        var argv: std.ArrayListUnmanaged([]const u8) = .{};
        try argv.appendSlice(gpa, &.{
            "cmake",                                                       "-S",                              try std.fs.path.join(gpa, &.{ src, "llvm" }),
            "-B",                                                          build_dir,                         "-G",
            "Ninja",                                                       "-DLLVM_ENABLE_PROJECTS=clang",    "-DCMAKE_BUILD_TYPE=RelWithDebInfo",
            "-DLLVM_ENABLE_ASSERTIONS=ON",                                 "-DLLVM_TARGETS_TO_BUILD=X86",     "-DLLVM_ENABLE_LIBXML2=OFF",
            "-DLLVM_ENABLE_LIBEDIT=OFF",                                   "-DLLVM_ENABLE_LIBPFM=OFF",        "-DLLVM_ENABLE_ZLIB=OFF",
            "-DLLVM_ENABLE_ZSTD=OFF",                                      "-DLLVM_ENABLE_CURL=OFF",          "-DLLVM_ENABLE_HTTPLIB=OFF",
            try std.fmt.allocPrint(gpa, "-DLLVM_FORCE_VC_REPOSITORY={s}", .{vc_repo}),
            try std.fmt.allocPrint(gpa, "-DLLVM_FORCE_VC_REVISION={s}", .{vc_rev}),
        });
        if (zig_tools) |t| {
            // Zig links libc++ statically itself; -static-libstdc++ / -static-libgcc are GCC's.
            // CMake 4 asks the linker for a dependency file (-Wl,--dependency-file), which `zig cc`
            // refuses ("unsupported linker arg", 2026-10-30); ninja then tracks link inputs by its
            // own rules instead, which changes no output.
            try argv.appendSlice(gpa, &.{
                "-DCMAKE_LINK_DEPENDS_USE_LINKER=OFF",
                try std.fmt.allocPrint(gpa, "-DCMAKE_C_COMPILER={s}", .{t[0]}),
                try std.fmt.allocPrint(gpa, "-DCMAKE_CXX_COMPILER={s}", .{t[1]}),
                try std.fmt.allocPrint(gpa, "-DCMAKE_AR={s}", .{t[2]}),
                try std.fmt.allocPrint(gpa, "-DCMAKE_RANLIB={s}", .{t[3]}),
            });
        } else {
            try argv.appendSlice(gpa, &.{ "-DLLVM_STATIC_LINK_CXX_STDLIB=ON", "-DCMAKE_EXE_LINKER_FLAGS=-static-libgcc" });
        }
        // Configure when the build dir is new or the configuration changed (a stamp of the exact
        // command); otherwise leave CMake's state alone so ninja rebuilds only what changed.
        const configured = try std.fs.path.join(gpa, &.{ build_dir, ".zilc-configure" });
        const want = try std.mem.join(gpa, "\n", argv.items);
        const have = std.fs.cwd().readFileAlloc(gpa, configured, 1 << 20) catch "";
        const ninja_file = try std.fs.path.join(gpa, &.{ build_dir, "build.ninja" });
        const has_ninja = if (std.fs.cwd().access(ninja_file, .{})) |_| true else |_| false;
        if (!has_ninja or !std.mem.eql(u8, have, want)) {
            try runIn(gpa, build_dir, argv.items);
            try std.fs.cwd().writeFile(.{ .sub_path = configured, .data = want });
        }
    }
    // llvm-objcopy strips llvm-split below: `zig objcopy --strip-debug` is "unimplemented" for it
    // (Zig 0.15.2, 2026-10-30), and binutils' strip would be one more tool to install.
    try runIn(gpa, build_dir, &.{ "ninja", "-j", jobs, "clang", "llvm-split", "llvm-objcopy" });

    const bin = try std.fs.path.join(gpa, &.{ out, "bin" });
    try std.fs.cwd().makePath(bin);
    try std.fs.cwd().copyFile(try std.fs.path.join(gpa, &.{ build_dir, "bin", "clang-20" }), std.fs.cwd(), try std.fs.path.join(gpa, &.{ bin, "clang-20" }), .{});
    // Stripped: ~1 GB of debug info otherwise, which does not change what llvm-split writes.
    try runIn(gpa, build_dir, &.{ try std.fs.path.join(gpa, &.{ build_dir, "bin", "llvm-objcopy" }), "--strip-debug", try std.fs.path.join(gpa, &.{ build_dir, "bin", "llvm-split" }), try std.fs.path.join(gpa, &.{ bin, "llvm-split" }) });

    const version = try std.process.Child.run(.{ .allocator = gpa, .argv = &.{ try std.fs.path.join(gpa, &.{ bin, "clang-20" }), "--version" } });
    std.debug.print("patched-clang: {s}", .{std.mem.sliceTo(version.stdout, '\n')});
    std.debug.print("\npatched-clang: built with {s}; installed {s}/clang-20 and llvm-split\n", .{ if (zig_tools != null) "Zig's clang" else "the system's cc/c++", bin });
}
