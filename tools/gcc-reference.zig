// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! `zig build gcc-reference` (build/gcc_reference.zig): one pinned GCC, built by Zig. MAINTAINER-ONLY.
//!
//!   gcc-reference <version> <gcc src> <gmp src> <mpfr src> <mpc src> <work dir> <prefix> <jobs>
//!                 <zig-cc> <zig-c++> <zig-ar> <zig-ranlib> <backport patch>
//!
//! The one change to GCC's sources is GCC's OWN backport of PR middle-end/111632
//! (third_party/gcc-patches/gcc-<version>-PR111632-safe-ctype.patch: the upstream release
//! branches' commits, which first shipped in 11.5.0 / 12.4.0), needed because `zig c++` uses
//! libc++ (cmem/toolchain-quirks.md Z-cc-14).
//!
//! 1. Stage <work>/src-<version>: a COPY of GCC's tree (configure and make write nothing into it,
//!    but the timestamps below must not touch the fetched package), with gmp/, mpfr/, mpc/ inside
//!    it, which GCC builds in-tree. Every file gets the same timestamp: Zig's fetcher writes files
//!    in archive order, so a generated file (configure, Makefile.in, *.info) could look older than
//!    its source and make would try to run autoconf, automake or makeinfo.
//! 2. Configure in <work>/build-<version>, with Zig as the host compiler: non-bootstrap (the new
//!    compiler is not rebuilt by itself: what it EMITS is the same either way), C and C++ only, no
//!    multilib, multiarch (Debian/Ubuntu keep crt files in /usr/lib/x86_64-linux-gnu), and the
//!    defaults Ubuntu's GCC has that change generated code where vanilla GCC can express them:
//!    default PIE and stack protector, CET. Ubuntu's default _FORTIFY_SOURCE is a distribution
//!    patch, so not reproduced. The configure command is stamped; a change reconfigures.
//! 3. make -j<jobs>; make install-strip into <prefix>.

const std = @import("std");

fn fail(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print("gcc-reference: " ++ fmt ++ "\n", args);
    std.process.exit(1);
}

fn runIn(gpa: std.mem.Allocator, cwd: []const u8, argv: []const []const u8, env: ?*const std.process.EnvMap) !void {
    var child = std.process.Child.init(argv, gpa);
    child.cwd = cwd;
    child.env_map = env;
    const term = try child.spawnAndWait();
    if (term != .Exited or term.Exited != 0) fail("failed ({any}): {s}", .{ term, try std.mem.join(gpa, " ", argv) });
}

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const gpa = arena_state.allocator();
    const args = try std.process.argsAlloc(gpa);
    if (args.len != 14) fail("usage: gcc-reference <version> <gcc src> <gmp src> <mpfr src> <mpc src> <work dir> <prefix> <jobs> <zig-cc> <zig-c++> <zig-ar> <zig-ranlib> <backport patch>", .{});
    const backport = args[13];
    const version = args[1];
    const gcc_src = args[2];
    const work = args[6];
    const prefix = args[7];
    const jobs = args[8];

    // 1. Stage.
    const src = try std.fs.path.join(gpa, &.{ work, try std.fmt.allocPrint(gpa, "src-{s}", .{version}) });
    const stamp_path = try std.fs.path.join(gpa, &.{ src, ".zilc-stage" });
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(try std.fs.cwd().readFileAlloc(gpa, backport, 1 << 20), &digest, .{});
    const stamp = try std.fmt.allocPrint(gpa, "{s}\n{s}\n{s}\n{s}\nbackport sha256 {s}\n", .{ gcc_src, args[3], args[4], args[5], std.fmt.bytesToHex(digest, .lower) });
    const staged = if (std.fs.cwd().readFileAlloc(gpa, stamp_path, 1 << 16)) |old| std.mem.eql(u8, old, stamp) else |_| false;
    if (!staged) {
        std.debug.print("gcc-reference: staging GCC {s} -> {s}\n", .{ version, src });
        std.fs.cwd().deleteTree(src) catch {};
        try std.fs.cwd().makePath(work);
        try runIn(gpa, work, &.{ "cp", "-a", gcc_src, src }, null);
        for ([_][2][]const u8{ .{ args[3], "gmp" }, .{ args[4], "mpfr" }, .{ args[5], "mpc" } }) |d|
            try runIn(gpa, work, &.{ "cp", "-a", d[0], try std.fs.path.join(gpa, &.{ src, d[1] }) }, null);
        try runIn(gpa, src, &.{ "find", ".", "-exec", "touch", "-h", "-d", "2000-01-01T00:00:00Z", "{}", "+" }, null);
        // GCC's own backport of PR middle-end/111632 (third_party/gcc-patches/, header says why):
        // after the timestamps, as system.h is a source nothing is generated from. `patch` fails
        // on any hunk that does not apply, which stops the staging.
        try runIn(gpa, src, &.{ "patch", "-p1", "--batch", "--forward", "-i", backport }, null);
        try std.fs.cwd().writeFile(.{ .sub_path = stamp_path, .data = stamp });
    }

    // 2. Configure.
    const build_dir = try std.fs.path.join(gpa, &.{ work, try std.fmt.allocPrint(gpa, "build-{s}", .{version}) });
    try std.fs.cwd().makePath(build_dir);
    const configure: []const []const u8 = &.{
        try std.fs.path.join(gpa, &.{ src, "configure" }),
        try std.fmt.allocPrint(gpa, "--prefix={s}", .{prefix}),
        "--build=x86_64-linux-gnu",
        "--host=x86_64-linux-gnu",
        "--target=x86_64-linux-gnu",
        "--disable-bootstrap",
        "--enable-languages=c,c++",
        "--disable-multilib",
        "--enable-multiarch",
        "--disable-nls",
        "--without-isl",
        "--disable-werror",
        "--enable-checking=release",
        "--enable-shared",
        "--enable-threads=posix",
        "--enable-linker-build-id",
        "--enable-clocale=gnu",
        "--with-default-libstdcxx-abi=new",
        "--enable-gnu-unique-object",
        "--with-tune=generic",
        "--enable-default-pie",
        "--enable-default-ssp",
        "--enable-cet",
        // Reaches the in-tree MPFR (GCC's configure passes its options down). Under Zig's clang
        // MPFR 4.1.0 finds `_Float128` missing but `__float128` usable and #defines one as the
        // other; glibc's bits/floatn.h then reads `typedef __float128 _Float128;` as a typedef of
        // `__float128` to itself, and every later probe fails ("GMP_NUMB_BITS and
        // sizeof(mp_limb_t) are not consistent", 2026-11-04). MPFR's float128 functions are its
        // own conversion API; GCC does not use them, so its output is unchanged.
        "--disable-float128",
        // libcc1 is GDB's plugin for compiling code from the debugger; nothing here uses it, and
        // its libtool link passes `-retain-symbols-file`, which `zig cc` refuses (2026-11-04).
        "--disable-libcc1",
        // The sanitizer runtimes are compiled by the NEW GCC against the system's glibc headers;
        // GCC 11's libsanitizer uses `struct termio`, which glibc 2.42 removed ("invalid
        // application of 'sizeof' to incomplete type '__sanitizer::termio'", 2026-11-04). Not a
        // Zig matter, and nothing in Fil-C's build uses -fsanitize.
        "--disable-libsanitizer",
        try std.fmt.allocPrint(gpa, "--with-pkgversion=zilc reference {s}", .{version}),
    };
    var env = try std.process.getEnvMap(gpa);
    try env.put("CC", args[9]);
    try env.put("CXX", args[10]);
    try env.put("AR", args[11]);
    try env.put("RANLIB", args[12]);
    const configured = try std.fs.path.join(gpa, &.{ build_dir, ".zilc-configure" });
    // The compilers come through the environment: they are part of the configuration too.
    const want = try std.fmt.allocPrint(gpa, "{s}\nCC={s}\nCXX={s}\nAR={s}\nRANLIB={s}", .{ try std.mem.join(gpa, "\n", configure), args[9], args[10], args[11], args[12] });
    const have = std.fs.cwd().readFileAlloc(gpa, configured, 1 << 20) catch "";
    if (!std.mem.eql(u8, have, want)) {
        std.fs.cwd().deleteTree(build_dir) catch {};
        try std.fs.cwd().makePath(build_dir);
        try runIn(gpa, build_dir, configure, &env);
        try std.fs.cwd().writeFile(.{ .sub_path = configured, .data = want });
    }

    // 3. Build and install.
    try runIn(gpa, build_dir, &.{ "make", try std.fmt.allocPrint(gpa, "-j{s}", .{jobs}) }, &env);
    try runIn(gpa, build_dir, &.{ "make", "install-strip" }, &env);
    const gcc = try std.fs.path.join(gpa, &.{ prefix, "bin", "gcc" });
    const v = try std.process.Child.run(.{ .allocator = gpa, .argv = &.{ gcc, "--version" } });
    std.debug.print("gcc-reference: {s}\n", .{std.mem.sliceTo(v.stdout, '\n')});
}
