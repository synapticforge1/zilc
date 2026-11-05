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
//!    default PIE and stack protector, CET-built libraries. The configure command is stamped; a
//!    change reconfigures.
//! 3. make -j<jobs>; make install-strip into <prefix>.
//! 4. The rest of Ubuntu's defaults, which are distribution patches to GCC's built-in specs
//!    (-fcf-protection, -fstack-clash-protection, -D_FORTIFY_SOURCE=2 when optimizing): a `specs`
//!    file GCC reads by itself, then a probe whose assembly must show each one.

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

    // 4. Ubuntu's other compile defaults, which no configure option gives (Ubuntu patches GCC's
    //    built-in specs): a `specs` file in GCC's own library directory, which the driver reads by
    //    itself at startup (gcc.c: find_a_file(startfile_prefixes, "specs")). ⚠️ That file
    //    REPLACES the built-in specs, and the driver then skips init_spec(), which is what puts
    //    `--as-needed -lgcc_s` into the libgcc spec: a file holding only our additions made g++
    //    link the static libgcc alone, and `_Unwind_Resume` went undefined (projeny, 2026-11-05;
    //    cmem/toolchain-quirks.md B-7..B-9). Nor can the file simply be -dumpspecs: GCC's reader cannot read
    //    that back (empty values such as `*self_spec:` make it take the next name as the value).
    //    And -dumpspecs cannot show the difference: it runs init_spec() itself before printing.
    //    So the file carries init_spec()'s two results, taken from -dumpspecs (gcc.c, GCC 11 and
    //    12: *libgcc made shared-libgcc aware; *link with LINK_EH_SPEC and the build-id spec
    //    prepended), then our `+` additions, each yielding to the user's own spelling of the flag,
    //    as Ubuntu's does. The proof is the driver's real commands (-###) with and without the
    //    file: identical, but for our flags on the cc1 line (checkCommands).
    const specs_path = try std.fs.path.join(gpa, &.{ prefix, "lib", "gcc", "x86_64-linux-gnu", version, "specs" });
    std.fs.cwd().deleteFile(specs_path) catch |e| if (e != error.FileNotFound) return e;
    const gxx = try std.fs.path.join(gpa, &.{ prefix, "bin", "g++" });
    const probes = try writeProbes(gpa, work, version);
    const variants = try commandVariants(gpa, gcc, gxx, probes, work);
    var before: [variants.len][]const []const u8 = undefined;
    for (variants, 0..) |vr, i| before[i] = try driverCommands(gpa, vr);
    const base = try dumpSpecs(gpa, gcc);
    var file: std.ArrayList(u8) = .empty;
    for (init_spec_results) |name| {
        const value = for (base) |e| {
            if (std.mem.eql(u8, e.name, name)) break e.value;
        } else fail("GCC {s}: no *{s} in -dumpspecs", .{ version, name });
        if (value.len == 0 or std.mem.indexOfScalar(u8, value, '\n') != null) fail("GCC {s}: *{s} cannot be held in a specs file", .{ version, name });
        try file.print(gpa, "*{s}:\n{s}\n\n", .{ name, value });
    }
    try file.appendSlice(gpa, ubuntu_specs);
    try std.fs.cwd().writeFile(.{ .sub_path = specs_path, .data = file.items });
    try checkDefaults(gpa, gcc, probes.c, version);
    for (variants, 0..) |vr, i| try checkCommands(gpa, version, vr, before[i], try driverCommands(gpa, vr));
    std.debug.print("gcc-reference: {s} specs file: the driver's commands are unchanged but for our flags on cc1 ({d} variants)\n", .{ version, variants.len });
    const exe = try std.fs.path.join(gpa, &.{ work, try std.fmt.allocPrint(gpa, "cxx-probe-{s}", .{version}) });
    try runIn(gpa, work, &.{ gxx, "-O2", "-pthread", "-o", exe, probes.cxx }, null);
    try runIn(gpa, work, &.{exe}, null);
    std.debug.print("gcc-reference: {s} a C++ throw links (shared libgcc) and runs\n", .{version});
}

/// What init_spec() computes and a specs file must therefore carry (gcc.c, GCC 11 and 12).
const init_spec_results = [_][]const u8{ "libgcc", "link" };
/// What our specs add to the cc1 command, and nothing else may differ.
const our_cc1_args = [_][]const u8{ "-fcf-protection", "-fstack-clash-protection", "-D_FORTIFY_SOURCE=2" };

const Probes = struct { c: []const u8, cxx: []const u8 };

fn writeProbes(gpa: std.mem.Allocator, work: []const u8, version: []const u8) !Probes {
    const p: Probes = .{
        .c = try std.fs.path.join(gpa, &.{ work, try std.fmt.allocPrint(gpa, "defaults-probe-{s}.c", .{version}) }),
        .cxx = try std.fs.path.join(gpa, &.{ work, try std.fmt.allocPrint(gpa, "cxx-probe-{s}.cc", .{version}) }),
    };
    try std.fs.cwd().writeFile(.{ .sub_path = p.c, .data = 
        \\#include <stdio.h>
        \\#include <string.h>
        \\void use(char *); /* external: the buffer must survive the optimiser (only -S and -### read this) */
        \\int f(const char *s, int n) {
        \\    char buf[16384];
        \\    strcpy(buf, s);
        \\    use(buf);
        \\    fprintf(stderr, "%d %s\n", n, s);
        \\    return buf[0];
        \\}
        \\
    });
    try std.fs.cwd().writeFile(.{ .sub_path = p.cxx, .data = 
        \\#include <stdexcept>
        \\#include <string>
        \\int main(int argc, char **) {
        \\    try { if (argc > 0) throw std::runtime_error("ok"); } catch (const std::exception &e) { return std::string(e.what()) == "ok" ? 0 : 2; }
        \\    return 3;
        \\}
        \\
    });
    return p;
}

fn commandVariants(gpa: std.mem.Allocator, gcc: []const u8, gxx: []const u8, p: Probes, work: []const u8) ![5][]const []const u8 {
    const o = try std.fs.path.join(gpa, &.{ work, "variant-out" });
    return .{
        try gpa.dupe([]const u8, &.{ gcc, "-O2", "-o", o, p.c }),
        try gpa.dupe([]const u8, &.{ gcc, "-O0", "-fPIC", "-shared", "-o", o, p.c }),
        try gpa.dupe([]const u8, &.{ gcc, "-O2", "-static", "-o", o, p.c }),
        try gpa.dupe([]const u8, &.{ gxx, "-O2", "-pthread", "-o", o, p.cxx }),
        try gpa.dupe([]const u8, &.{ gxx, "-O1", "-fPIC", "-shared", "-o", o, p.cxx }),
    };
}

/// The commands the driver would run (`-###`), one string per command, temp files normalized.
fn driverCommands(gpa: std.mem.Allocator, argv: []const []const u8) ![]const []const u8 {
    const full = try std.mem.concat(gpa, []const u8, &.{ argv[0..1], &.{"-###"}, argv[1..] });
    const r = try std.process.Child.run(.{ .allocator = gpa, .argv = full, .max_output_bytes = 1 << 20 });
    if (r.term != .Exited or r.term.Exited != 0) fail("{s} -### failed:\n{s}", .{ argv[0], r.stderr });
    var out: std.ArrayList([]const u8) = .empty;
    var lines = std.mem.splitScalar(u8, r.stderr, '\n');
    while (lines.next()) |l| {
        // A command line starts with one space; its tokens may or may not be quoted.
        if (l.len < 2 or l[0] != ' ' or l[1] == ' ') continue;
        var norm: std.ArrayList(u8) = .empty;
        var toks = std.mem.tokenizeScalar(u8, l, ' ');
        while (toks.next()) |q| {
            const t = std.mem.trim(u8, q, "\"");
            if (norm.items.len != 0) try norm.append(gpa, ' ');
            // The driver's temp files (/tmp/ccXXXXXX.*), also inside a token (-fresolution=...).
            if (std.mem.indexOf(u8, t, "/tmp/")) |i| {
                try norm.appendSlice(gpa, t[0..i]);
                try norm.appendSlice(gpa, "<tmp>");
            } else try norm.appendSlice(gpa, t);
        }
        try out.append(gpa, norm.items);
    }
    return out.items;
}

fn checkCommands(gpa: std.mem.Allocator, version: []const u8, argv: []const []const u8, was: []const []const u8, now: []const []const u8) !void {
    const what = try std.mem.join(gpa, " ", argv);
    if (was.len != now.len or was.len < 2) fail("GCC {s}: `{s}`: {d} commands with the specs file, {d} without", .{ version, what, now.len, was.len });
    for (was, now) |w, n| {
        const first = w[0 .. std.mem.indexOfScalar(u8, w, ' ') orelse w.len];
        const cc1 = std.mem.endsWith(u8, first, "/cc1") or std.mem.endsWith(u8, first, "/cc1plus");
        var kept: std.ArrayList(u8) = .empty;
        var toks = std.mem.tokenizeScalar(u8, n, ' ');
        while (toks.next()) |t| {
            const ours = cc1 and for (our_cc1_args) |a| {
                if (std.mem.eql(u8, a, t)) break true;
            } else false;
            if (ours) continue;
            if (kept.items.len != 0) try kept.append(gpa, ' ');
            try kept.appendSlice(gpa, t);
        }
        if (!std.mem.eql(u8, w, kept.items)) fail("GCC {s}: `{s}`: the specs file changed a command\n  was: {s}\n  now: {s}", .{ version, what, w, n });
    }
}

const Spec = struct { name: []const u8, value: []const u8 };

/// `gcc -dumpspecs` as entries: `*name:`, the value's lines, a blank line (an empty value is
/// the blank line alone; blank lines between entries are skipped).
fn dumpSpecs(gpa: std.mem.Allocator, driver: []const u8) ![]Spec {
    const r = try std.process.Child.run(.{ .allocator = gpa, .argv = &.{ driver, "-dumpspecs" }, .max_output_bytes = 1 << 20 });
    if (r.term != .Exited or r.term.Exited != 0) fail("{s} -dumpspecs failed:\n{s}", .{ driver, r.stderr });
    var out: std.ArrayList(Spec) = .empty;
    var lines = std.mem.splitScalar(u8, r.stdout, '\n');
    while (lines.next()) |l| {
        if (l.len == 0) continue;
        if (l[0] != '*' or l[l.len - 1] != ':') fail("{s} -dumpspecs: unexpected line {s}", .{ driver, l });
        var value: std.ArrayList(u8) = .empty;
        while (lines.next()) |v| {
            if (v.len == 0) break;
            if (value.items.len != 0) try value.append(gpa, '\n');
            try value.appendSlice(gpa, v);
        }
        try out.append(gpa, .{ .name = l[1 .. l.len - 1], .value = value.items });
    }
    if (out.items.len < 20) fail("{s} -dumpspecs: only {d} specs", .{ driver, out.items.len });
    return out.items;
}

/// cmem/toolchain-quirks.md C-7b: what Ubuntu 22.04's GCC adds by default and vanilla GCC cannot
/// be configured to add. (PIE and -fstack-protector-strong come from configure, step 2.)
///   cpp_unique_options: -D_FORTIFY_SOURCE=2 when optimizing (not at -O0), unless set or unset.
///   cc1_options:        -fcf-protection and -fstack-clash-protection, unless the user chose.
const ubuntu_specs =
    \\*cpp_unique_options:
    \\+ %{O*:%{!O0:%{!D_FORTIFY_SOURCE*:%{!U_FORTIFY_SOURCE*:-D_FORTIFY_SOURCE=2}}}}
    \\
    \\*cc1_options:
    \\+ %{!fcf-protection*:-fcf-protection} %{!fstack-clash-protection:%{!fno-stack-clash-protection:-fstack-clash-protection}}
    \\
    \\
;

/// Compiles one probe and reads the assembly: each default must show, fortify only when
/// optimizing. A specs file GCC did not read, or a spec it parsed differently, fails here.
fn checkDefaults(gpa: std.mem.Allocator, gcc: []const u8, probe: []const u8, version: []const u8) !void {
    const Want = struct { needle: []const u8, what: []const u8 };
    const all = [_]Want{
        .{ .needle = "endbr64", .what = "CET (-fcf-protection)" },
        .{ .needle = "__stack_chk_fail", .what = "stack protector" },
        .{ .needle = "orq\t$0, (%rsp)", .what = "stack-clash probe" },
        .{ .needle = "__fprintf_chk", .what = "_FORTIFY_SOURCE=2" },
    };
    for ([_][]const u8{ "-O2", "-O0" }) |opt| {
        const r = try std.process.Child.run(.{ .allocator = gpa, .argv = &.{ gcc, opt, "-S", "-o", "-", probe }, .max_output_bytes = 1 << 22 });
        if (r.term != .Exited or r.term.Exited != 0) fail("defaults probe {s} did not compile:\n{s}", .{ opt, r.stderr });
        for (all) |w| {
            const want = !(std.mem.eql(u8, opt, "-O0") and std.mem.eql(u8, w.needle, "__fprintf_chk"));
            const has = std.mem.indexOf(u8, r.stdout, w.needle) != null;
            if (has != want) fail("GCC {s} {s}: {s} {s} (specs not applied as Ubuntu's?)", .{ version, opt, w.what, if (want) "missing" else "present" });
        }
    }
    std.debug.print("gcc-reference: {s} Ubuntu defaults ok (CET, SSP, stack-clash; fortify at -O2, not -O0)\n", .{version});
}
