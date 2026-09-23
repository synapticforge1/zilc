// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! Rewriting stock LLVM IR into Fil-C's dialect.
//!
//! Fil-C's `FilPizlonatorPass` asserts that its input module declares address
//! space 0 **non-integral**, and it reads a second layout through Fil-C's own
//! `Module::getDataLayoutAfterFilC()`. So a module entering the pass carries:
//!
//!     target datalayout = "e-m:e-ni:0-…"           ; "before": AS0 non-integral
//!     target datalayout_after_filc = "e-m:e-…"     ; "after":  plain
//!
//! Stock LLVM rejects `ni:0` outright (`address space 0 cannot be
//! non-integral`), which is the point: it forbids the optimizer from
//! round-tripping pointers through integers behind the pass's back. Zig cannot
//! emit this, so the driver rewrites it in the text IR. Detail: cmem/known-issues.md KI-4.

const std = @import("std");

pub const Error = error{
    /// The module has no `target datalayout` line to rewrite.
    NoDataLayout,
    /// The `target datalayout` line is not `target datalayout = "…"`.
    MalformedDataLayout,
};

const layout_prefix = "target datalayout = \"";
const after_prefix = "target datalayout_after_filc = ";

/// Returns `layout` with an `ni:0` component inserted directly after the
/// mangling (`m:…`) component, which is where Fil-C's own clang puts it.
///
/// ⚠️ Position is load-bearing: LLVM compares data-layout strings textually, so
/// appending `-ni:0` yields a layout that does not match the target's and the
/// backend rejects it. Learned the hard way — cmem/known-issues.md KI-4.
pub fn nonIntegralLayout(gpa: std.mem.Allocator, layout: []const u8) ![]u8 {
    var out: std.ArrayListUnmanaged(u8) = .{};
    errdefer out.deinit(gpa);

    // Scan FIRST: an ni: spec can sit after the m: component, and noticing it
    // only when we reach it would mean we had already inserted a second one.
    // (Caught by the idempotence test, which is exactly what it is for.)
    var scan = std.mem.splitScalar(u8, layout, '-');
    var inserted = while (scan.next()) |part| {
        if (std.mem.startsWith(u8, part, "ni:")) break true;
    } else false;

    var it = std.mem.splitScalar(u8, layout, '-');
    var first = true;
    while (it.next()) |part| {
        if (!first) try out.append(gpa, '-');
        try out.appendSlice(gpa, part);
        first = false;

        if (!inserted and std.mem.startsWith(u8, part, "m:")) {
            try out.appendSlice(gpa, "-ni:0");
            inserted = true;
        }
    }
    // No mangling component (unusual, but not our business to judge): put the
    // spec at the end rather than silently producing a layout without it.
    if (!inserted) try out.appendSlice(gpa, "-ni:0");

    return out.toOwnedSlice(gpa);
}

/// Returns `layout` with every `ni:` component removed — the "after" layout,
/// which is what the module must look like once the pass has run.
pub fn integralLayout(gpa: std.mem.Allocator, layout: []const u8) ![]u8 {
    var out: std.ArrayListUnmanaged(u8) = .{};
    errdefer out.deinit(gpa);

    var it = std.mem.splitScalar(u8, layout, '-');
    var first = true;
    while (it.next()) |part| {
        if (std.mem.startsWith(u8, part, "ni:")) continue;
        if (!first) try out.append(gpa, '-');
        try out.appendSlice(gpa, part);
        first = false;
    }
    return out.toOwnedSlice(gpa);
}

/// Rewrites textual LLVM IR so the module declares Fil-C's two layouts.
///
/// The caller owns the returned buffer. Any pre-existing
/// `target datalayout_after_filc` line is dropped and both layouts are derived
/// from the plain form, so the function is idempotent: rewriting an
/// already-rewritten module leaves it byte-identical.
pub fn toFilCDialect(gpa: std.mem.Allocator, ir: []const u8) ![]u8 {
    var out: std.ArrayListUnmanaged(u8) = .{};
    errdefer out.deinit(gpa);

    var found = false;
    var pos: usize = 0;
    while (true) {
        const nl = std.mem.indexOfScalarPos(u8, ir, pos, '\n');
        const line = if (nl) |n| ir[pos..n] else ir[pos..];
        const terminated = nl != null;

        blk: {
            // Drop any existing "after" line; we emit our own beside the layout.
            if (std.mem.startsWith(u8, line, after_prefix)) break :blk;

            if (!found and std.mem.startsWith(u8, line, layout_prefix)) {
                const rest = line[layout_prefix.len..];
                const end = std.mem.indexOfScalar(u8, rest, '"') orelse return Error.MalformedDataLayout;

                // Derive BOTH from the plain layout, so a module that already
                // carries ni:0 does not accumulate a second one.
                const plain = try integralLayout(gpa, rest[0..end]);
                defer gpa.free(plain);
                const ni = try nonIntegralLayout(gpa, plain);
                defer gpa.free(ni);

                try out.print(gpa, "target datalayout = \"{s}\"\n", .{ni});
                try out.print(gpa, "target datalayout_after_filc = \"{s}\"", .{plain});
                if (terminated) try out.append(gpa, '\n');
                found = true;
                break :blk;
            }

            try out.appendSlice(gpa, line);
            if (terminated) try out.append(gpa, '\n');
        }

        if (nl) |n| pos = n + 1 else break;
    }

    if (!found) return Error.NoDataLayout;
    return out.toOwnedSlice(gpa);
}

// ---------------------------------------------------------------------------

const testing = std.testing;

test "ni:0 goes right after the mangling component" {
    const zig_layout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128";
    const got = try nonIntegralLayout(testing.allocator, zig_layout);
    defer testing.allocator.free(got);

    // This is byte-for-byte what Fil-C's own clang uses; see KI-4.
    try testing.expectEqualStrings(
        "e-m:e-ni:0-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128",
        got,
    );
}

test "an existing ni spec is left alone" {
    const already = "e-m:e-ni:0-p270:32:32-S128";
    const got = try nonIntegralLayout(testing.allocator, already);
    defer testing.allocator.free(got);
    try testing.expectEqualStrings(already, got);
}

test "a layout without a mangling component still gets ni:0" {
    const got = try nonIntegralLayout(testing.allocator, "e-i64:64-S128");
    defer testing.allocator.free(got);
    try testing.expectEqualStrings("e-i64:64-S128-ni:0", got);
}

test "rewrite emits both layout lines and keeps the rest" {
    const ir =
        \\; ModuleID = 'x'
        \\target datalayout = "e-m:e-i64:64-S128"
        \\target triple = "x86_64-unknown-linux-musl"
        \\define void @f() { ret void }
        \\
    ;
    const got = try toFilCDialect(testing.allocator, ir);
    defer testing.allocator.free(got);

    try testing.expect(std.mem.indexOf(u8, got, "target datalayout = \"e-m:e-ni:0-i64:64-S128\"") != null);
    try testing.expect(std.mem.indexOf(u8, got, "target datalayout_after_filc = \"e-m:e-i64:64-S128\"") != null);
    try testing.expect(std.mem.indexOf(u8, got, "target triple = \"x86_64-unknown-linux-musl\"") != null);
    try testing.expect(std.mem.indexOf(u8, got, "define void @f()") != null);
}

test "rewriting twice changes nothing" {
    const ir =
        \\target datalayout = "e-m:e-i64:64-S128"
        \\define void @f() { ret void }
        \\
    ;
    const once = try toFilCDialect(testing.allocator, ir);
    defer testing.allocator.free(once);
    const twice = try toFilCDialect(testing.allocator, once);
    defer testing.allocator.free(twice);
    try testing.expectEqualStrings(once, twice);
}

test "a module with no datalayout is an error, not a silent pass-through" {
    try testing.expectError(Error.NoDataLayout, toFilCDialect(testing.allocator, "define void @f() { ret void }\n"));
}
