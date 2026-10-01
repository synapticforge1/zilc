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
