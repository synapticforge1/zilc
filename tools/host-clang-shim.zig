// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! `clang` for upstream's own Makefiles in the maintainer's reference chain
//! (`tools/filc/build-filc-from-source.ts MODE=upstream`): libpas's stock half (`HOST_CLANG`, also
//! its link of libpizlo.so) and yolounwind, which call `clang` by name. Owner, 2026-11-05: *"The
//! available clang should be the one that is being uses to compile that corpus, not what is in
//! ubuntu"* — Zig's clang, so the reference chain no longer drifts with the host's clang (Fil-C's
//! own clang cannot do it: it instruments everything it compiles). It is `zig cc` plus what
//! upstream's flags need (cmem/toolchain-quirks.md):
//!   - `-march=<cpu>` is respelled `-mcpu=<cpu, - as _>`: Zig reads `-march` with its `-mcpu`
//!     syntax, so libpas's `-march=x86-64-v2` failed "unknown CPU: 'x86'" (Z-cc-4);
//!   - a generic CPU and `x86_64-linux-none` unless the caller names a CPU or target (Z-cc-2: else
//!     the host's CPU). `none`, as build/pure_zig.zig's runtimeModule: these pieces bring their
//!     own libc headers (pizfix/yolo-include, musl). ⚠️ NOT `-gnu`: for a glibc target Zig
//!     predefines `__GLIBC_MINOR__`, which put musl's headers in strict-POSIX mode (`strlcpy`
//!     undeclared in libpas's filc_setproctitle.c), and turns the stack protector on by default
//!     (`__SSP_STRONG__`), which a plain clang does not (2026-11-05, Z-cc-16);
//!   - `-fno-sanitize=all` first, so a caller's own `-fsanitize` still wins: `zig cc` turns UBSan
//!     on when no `-O` is given (the link steps), which a host clang never does.
//! Kept apart from tools/zig-shim.zig on purpose: changing that file would move the shim
//! patched-clang's build is configured with and force a full clang rebuild.
//!
//! Built by build-filc-from-source.ts with `zig build-exe`; `shim_options.zig_exe` names the Zig.

const std = @import("std");
const options = @import("shim_options");

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const gpa = arena_state.allocator();
    const args = try std.process.argsAlloc(gpa);

    var has_cpu = false;
    var has_target = false;
    for (args[1..]) |a| {
        if (std.mem.startsWith(u8, a, "-march=") or std.mem.startsWith(u8, a, "-mcpu=")) has_cpu = true;
        if (std.mem.eql(u8, a, "-target") or std.mem.startsWith(u8, a, "--target=")) has_target = true;
    }

    var argv: std.ArrayListUnmanaged([]const u8) = .{};
    try argv.appendSlice(gpa, &.{ options.zig_exe, "cc", "-fno-sanitize=all" });
    if (!has_target) try argv.appendSlice(gpa, &.{ "-target", "x86_64-linux-none" });
    if (!has_cpu) try argv.append(gpa, "-mcpu=baseline");
    for (args[1..]) |a| {
        if (std.mem.startsWith(u8, a, "-march=")) {
            const cpu = try gpa.dupe(u8, a["-march=".len..]);
            std.mem.replaceScalar(u8, cpu, '-', '_');
            try argv.append(gpa, try std.fmt.allocPrint(gpa, "-mcpu={s}", .{cpu}));
        } else try argv.append(gpa, a);
    }
    return std.process.execv(gpa, argv.items);
}
