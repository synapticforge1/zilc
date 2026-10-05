// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! zilc runtime — public library surface.
//!
//! This is the home of `zilc_runtime`: the Zig implementation of the Fil-C
//! runtime model (InvisiCap capability bounds + a FUGC-style accurate,
//! non-moving collector) that code compiled by the zilc pass links against.
//! Nothing is implemented yet; see `cmem/architecture.md` and `cmem/roadmap.md`.

const std = @import("std");

/// Rewriting stock LLVM IR into Fil-C's dialect — the core of the zilc driver.
pub const ir = @import("ir.zig");

/// Backports to Zig's std, applied to a cached overlay of the user's Zig lib (KI-11).
pub const stdpatch = @import("stdpatch.zig");

/// The Zig release this line of zilc is built with. Every Zig release gets its
/// own line. The Zig that compiles *user code* is a separate number: it must
/// match Fil-C's LLVM, and can lag behind this one (cmem/upstream.md, stage B).
pub const zig_line = std.SemanticVersion{ .major = 0, .minor = 15, .patch = 2 };

/// zilc's own release number within `zig_line`. It restarts at 1 whenever
/// `zig_line` changes, patch releases included (cmem/releasing.md).
pub const release = 3;

/// zilc's version, `<zig_line>-<release>` (cmem/releasing.md). Keep in sync
/// with `build.zig.zon`.
pub const version = std.SemanticVersion{
    .major = zig_line.major,
    .minor = zig_line.minor,
    .patch = zig_line.patch,
    .pre = std.fmt.comptimePrint("{d}", .{release}),
};

/// Version string, e.g. "0.15.2-3".
pub const version_string = std.fmt.comptimePrint("{d}.{d}.{d}-{s}", .{ version.major, version.minor, version.patch, version.pre.? });

// What the version number does NOT say (cmem/releasing.md "Still to act on" 4): `zilc --version`
// and RELEASE-NOTES.md state these. Keep RELEASE-NOTES.md in step when one changes.

/// The Zig that compiles USER code: its LLVM must match Fil-C's. On the reference line it equals
/// `zig_line`; on a latest line (built with a newer Zig) it can lag behind it.
pub const user_zig = std.SemanticVersion{ .major = 0, .minor = 15, .patch = 2 };

/// The Fil-C release zilc is built against: its compiler pass, runtime ABI and checked libc.
pub const filc_release = "0.685";

/// The reference release a latest-line release was ported from (e.g. "0.15.2-100"), or null on
/// the reference line itself, which is checked directly against Fil-C (cmem/releasing.md).
pub const basis: ?[]const u8 = null;

/// Which kind of line this is, derived from `basis`.
pub const line_kind = if (basis == null) "reference" else "latest";

test "the reference line compiles user code with its own Zig" {
    // On the reference line the two Zigs are the same; a latest line has a basis instead.
    if (basis == null) try std.testing.expectEqual(std.math.Order.eq, user_zig.order(zig_line));
    try std.testing.expectEqualStrings("0.685", filc_release);
}

test "version string matches version" {
    try std.testing.expectEqualStrings("0.15.2-3", version_string);
}

test "version string parses back to the same version" {
    // `0.15.2_3` would also parse, as patch 23: parsing is not enough, the
    // fields must round-trip (cmem/releasing.md).
    const parsed = try std.SemanticVersion.parse(version_string);
    try std.testing.expectEqual(std.math.Order.eq, parsed.order(version));
    try std.testing.expectEqualStrings(version.pre.?, parsed.pre.?);
}

test {
    _ = ir;
    _ = stdpatch;
}
