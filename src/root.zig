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

/// Semantic version of zilc. Keep in sync with `build.zig.zon` (see `cmem/releasing.md`).
pub const version = std.SemanticVersion{ .major = 0, .minor = 3, .patch = 0 };

/// Version string, e.g. "0.3.0".
pub const version_string = std.fmt.comptimePrint("{d}.{d}.{d}", .{ version.major, version.minor, version.patch });

test "version string matches version" {
    try std.testing.expectEqualStrings("0.3.0", version_string);
}

test {
    _ = ir;
}
