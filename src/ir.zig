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
// Raw system calls (KI-7).
//
// Zig's std issues some system calls through inline `syscall` asm even when libc
// is linked (gettid, futex, clock_nanosleep, statx, …). Fil-C refuses any inline
// `syscall`: it would bypass the checked OS boundary, and a blocking one would
// never tell the GC it is leaving managed code. So each such asm call becomes a
// call to `zilc_syscall`, a small C helper compiled by Fil-C (see driver.zig)
// that reaches the kernel through Fil-C's libc.
//
// Every argument is passed as `ptr`, so that one that WAS a pointer keeps its
// capability. A `ptrtoint` constant expression is unwrapped to the pointer it
// came from. Any other operand gets an `inttoptr` in the calling function, where
// Fil-C's pass recovers the capability if the integer came from a pointer there
// (gimso_semantics.md; cmem/filc-abi.md "inttoptr"). True integers simply carry
// a null capability and convert back to the same value.

/// The helper every raw `syscall` asm call is redirected to.
pub const syscall_helper = "zilc_syscall";
const syscall_decl = "declare i64 @" ++ syscall_helper ++ "(i64, ptr, ptr, ptr, ptr, ptr, ptr)";
const syscall_marker = "asm sideeffect \"syscall\", \"";

pub const SyscallRewrite = struct {
    ir: []u8,
    /// How many asm calls were redirected. Zero means `ir` is unchanged.
    count: usize,
};

/// Redirects every `asm sideeffect "syscall"` call in `ir` to `zilc_syscall`.
/// Other inline asm is left untouched. Idempotent: a rewritten module has no
/// `syscall` asm left, and the declaration is added only once.
pub fn rewriteSyscalls(gpa: std.mem.Allocator, ir: []const u8) !SyscallRewrite {
    var out: std.ArrayListUnmanaged(u8) = .{};
    errdefer out.deinit(gpa);

    var count: usize = 0;
    var pos: usize = 0;
    while (true) {
        const nl = std.mem.indexOfScalarPos(u8, ir, pos, '\n');
        const line = if (nl) |n| ir[pos..n] else ir[pos..];

        if (std.mem.indexOf(u8, line, syscall_marker) != null) {
            if (try rewriteSyscallLine(gpa, &out, line, count)) {
                count += 1;
            } else {
                try out.appendSlice(gpa, line); // a shape we don't understand: leave it to Fil-C
            }
        } else {
            try out.appendSlice(gpa, line);
        }
        if (nl) |n| {
            try out.append(gpa, '\n');
            pos = n + 1;
        } else break;
    }

    if (count > 0 and std.mem.indexOf(u8, ir, syscall_decl) == null) {
        if (out.items.len > 0 and out.items[out.items.len - 1] != '\n') try out.append(gpa, '\n');
        try out.print(gpa, "\n{s}\n", .{syscall_decl});
    }
    return .{ .ir = try out.toOwnedSlice(gpa), .count = count };
}

/// Rewrites one asm-call line into zero or more `inttoptr` lines plus the
/// helper call. Returns false, writing nothing, if the line has an unexpected shape.
fn rewriteSyscallLine(gpa: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), line: []const u8, id: usize) !bool {
    const marker_at = std.mem.indexOf(u8, line, syscall_marker) orelse return false;

    // Everything before "call": indentation and an optional "%result = ".
    const call_at = std.mem.lastIndexOf(u8, line[0..marker_at], "call ") orelse return false;
    var head = line[0..call_at];
    for ([_][]const u8{ "musttail ", "notail ", "tail " }) |t| {
        if (std.mem.endsWith(u8, head, t)) head = head[0 .. head.len - t.len];
    }
    if (!std.mem.startsWith(u8, std.mem.trimLeft(u8, line[call_at..marker_at], " "), "call i64 ")) return false;

    // The constraint string, then the parenthesised operand list.
    const cons_start = marker_at + syscall_marker.len;
    const cons_end = std.mem.indexOfScalarPos(u8, line, cons_start, '"') orelse return false;
    if (cons_end + 1 >= line.len or line[cons_end + 1] != '(') return false;
    const args_start = cons_end + 2;
    const args_end = matchingParen(line, cons_end + 1) orelse return false;
    const args = line[args_start..args_end];
    const rest = line[args_end + 1 ..];

    var operands: [7][]const u8 = undefined;
    var n_ops: usize = 0;
    var it = TopLevelSplit{ .s = args };
    while (it.next()) |raw| {
        if (n_ops == operands.len) return false; // more than syscall6: not a shape we know
        operands[n_ops] = operandValue(std.mem.trim(u8, raw, " ")) orelse return false;
        n_ops += 1;
    }
    if (n_ops == 0) return false;

    const indent = head[0 .. head.len - std.mem.trimLeft(u8, head, " ").len];

    // Pointer forms of each argument (1..6); missing ones are null.
    var ptr_args: [6][]const u8 = .{ "null", "null", "null", "null", "null", "null" };
    var owned: [6]?[]u8 = .{ null, null, null, null, null, null };
    defer for (owned) |o| if (o) |s| gpa.free(s);
    for (operands[1..n_ops], 0..) |v, k| {
        if (unwrapPtrToInt(v)) |p| {
            ptr_args[k] = p; // `ptrtoint (ptr X to i64)`: pass X itself
        } else if (isIntLiteral(v)) {
            owned[k] = try std.fmt.allocPrint(gpa, "inttoptr (i64 {s} to ptr)", .{v});
            ptr_args[k] = owned[k].?;
        } else {
            const name = try std.fmt.allocPrint(gpa, "%zilc.sys.{d}.{d}", .{ id, k + 1 });
            try out.print(gpa, "{s}{s} = inttoptr i64 {s} to ptr\n", .{ indent, name, v });
            owned[k] = name;
            ptr_args[k] = name;
        }
    }

    // Keep the debug location, so a trap inside the helper still names the Zig line.
    // The asm's attribute group (#N) is dropped; it described the asm, not a call.
    const dbg = if (std.mem.indexOf(u8, rest, "!dbg ")) |d| rest[d..] else "";

    try out.print(gpa, "{s}call i64 @{s}(i64 {s}, ptr {s}, ptr {s}, ptr {s}, ptr {s}, ptr {s}, ptr {s})", .{
        head, syscall_helper, operands[0],
        ptr_args[0], ptr_args[1], ptr_args[2], ptr_args[3], ptr_args[4], ptr_args[5],
    });
    if (dbg.len > 0) try out.print(gpa, ", {s}", .{std.mem.trimRight(u8, dbg, " ")});
    return true;
}

/// Index of the ')' matching the '(' at `open`, or null.
fn matchingParen(s: []const u8, open: usize) ?usize {
    var depth: usize = 0;
    var i = open;
    while (i < s.len) : (i += 1) switch (s[i]) {
        '(' => depth += 1,
        ')' => {
            depth -= 1;
            if (depth == 0) return i;
        },
        else => {},
    };
    return null;
}

/// Splits on commas that are not inside parentheses.
const TopLevelSplit = struct {
    s: []const u8,
    pos: usize = 0,
    fn next(self: *TopLevelSplit) ?[]const u8 {
        if (self.pos > self.s.len) return null;
        var depth: usize = 0;
        var i = self.pos;
        while (i < self.s.len) : (i += 1) switch (self.s[i]) {
            '(' => depth += 1,
            ')' => depth -|= 1,
            ',' => if (depth == 0) break,
            else => {},
        };
        const part = self.s[self.pos..i];
        self.pos = i + 1;
        return part;
    }
};

/// `i64 [attrs] VALUE` → `VALUE`. Only i64 operands are expected.
fn operandValue(arg: []const u8) ?[]const u8 {
    if (!std.mem.startsWith(u8, arg, "i64 ")) return null;
    var v = std.mem.trimLeft(u8, arg["i64 ".len..], " ");
    while (true) {
        if (std.mem.startsWith(u8, v, "range(")) {
            const close = matchingParen(v, "range".len) orelse return null;
            v = std.mem.trimLeft(u8, v[close + 1 ..], " ");
            continue;
        }
        var stripped = false;
        for ([_][]const u8{ "noundef ", "signext ", "zeroext ", "inreg ", "immarg " }) |a| {
            if (std.mem.startsWith(u8, v, a)) {
                v = std.mem.trimLeft(u8, v[a.len..], " ");
                stripped = true;
            }
        }
        if (!stripped) break;
    }
    return if (v.len == 0) null else v;
}

/// `ptrtoint (ptr X to i64)` → `X`, for a constant-expression operand.
fn unwrapPtrToInt(v: []const u8) ?[]const u8 {
    const pre = "ptrtoint (ptr ";
    const post = " to i64)";
    if (!std.mem.startsWith(u8, v, pre) or !std.mem.endsWith(u8, v, post)) return null;
    if (matchingParen(v, "ptrtoint ".len) != v.len - 1) return null;
    return v[pre.len .. v.len - post.len];
}

fn isIntLiteral(v: []const u8) bool {
    const digits = if (v.len > 0 and v[0] == '-') v[1..] else v;
    if (digits.len == 0) return false;
    for (digits) |c| if (!std.ascii.isDigit(c)) return false;
    return true;
}

// ---------------------------------------------------------------------------
// Keeping only the exports we asked for (KI-9).
//
// Some compiler-rt files export more than zilc needs: round.zig defines roundq,
// which f128 code needs, but also round, roundf and roundl. Linked into a program,
// those would quietly replace Fil-C's own libm functions for any C code in it.
// So every function definition not in `keep` becomes `internal`.

/// Linkage and visibility words that may precede a definition's return type.
const linkage_words = [_][]const u8{
    "external", "weak",            "weak_odr",  "linkonce", "linkonce_odr", "available_externally",
    "hidden",   "protected",       "default",   "dso_local", "dso_preemptable",
};

/// Makes every `define` whose name is not in `keep` internal. Declarations,
/// aliases and globals are left alone.
pub fn internalizeExcept(gpa: std.mem.Allocator, ir: []const u8, keep: []const []const u8) ![]u8 {
    var out: std.ArrayListUnmanaged(u8) = .{};
    errdefer out.deinit(gpa);

    var pos: usize = 0;
    while (true) {
        const nl = std.mem.indexOfScalarPos(u8, ir, pos, '\n');
        const line = if (nl) |n| ir[pos..n] else ir[pos..];

        if (internalizedDefine(line, keep)) |tail| {
            try out.print(gpa, "define internal {s}", .{tail});
        } else {
            try out.appendSlice(gpa, line);
        }
        if (nl) |n| {
            try out.append(gpa, '\n');
            pos = n + 1;
        } else break;
    }
    return out.toOwnedSlice(gpa);
}

/// For a `define` line that must become internal, the text after its linkage
/// and visibility words; otherwise null.
fn internalizedDefine(line: []const u8, keep: []const []const u8) ?[]const u8 {
    if (!std.mem.startsWith(u8, line, "define ")) return null;
    const at = std.mem.indexOfScalar(u8, line, '@') orelse return null;
    const name_end = std.mem.indexOfScalarPos(u8, line, at, '(') orelse return null;
    const name = line[at + 1 .. name_end];
    for (keep) |k| if (std.mem.eql(u8, name, k)) return null;

    var rest = line["define ".len..];
    if (std.mem.startsWith(u8, rest, "internal ") or std.mem.startsWith(u8, rest, "private ")) return null;
    outer: while (true) {
        for (linkage_words) |w| {
            if (std.mem.startsWith(u8, rest, w) and rest.len > w.len and rest[w.len] == ' ') {
                rest = rest[w.len + 1 ..];
                continue :outer;
            }
        }
        break;
    }
    return rest;
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

test "raw syscall asm becomes a zilc_syscall call (shapes taken from real Zig IR)" {
    const ir =
        \\define void @f(ptr %p) {
        \\  %10 = ptrtoint ptr %p to i64
        \\  %0 = tail call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},{rdx},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 202, i64 ptrtoint (ptr getelementptr inbounds nuw (i8, ptr @Progress.stderr_mutex, i64 8) to i64), i64 129, i64 1) #23, !dbg !44286
        \\  %12 = call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},{rdx},{r10},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 202, i64 %10, i64 128, i64 range(i64 0, 4) 0, i64 0) #25, !dbg !32170
        \\  %29 = call i64 asm sideeffect "syscall", "={rax},{rax},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 186) #22, !dbg !3899
        \\  ret void
        \\}
        \\
    ;
    const got = try rewriteSyscalls(testing.allocator, ir);
    defer testing.allocator.free(got.ir);

    try testing.expectEqual(@as(usize, 3), got.count);
    try testing.expect(std.mem.indexOf(u8, got.ir, "asm sideeffect \"syscall\"") == null);
    // A ptrtoint constant expression is unwrapped to the pointer itself.
    try testing.expect(std.mem.indexOf(u8, got.ir,
        \\  %0 = call i64 @zilc_syscall(i64 202, ptr getelementptr inbounds nuw (i8, ptr @Progress.stderr_mutex, i64 8), ptr inttoptr (i64 129 to ptr), ptr inttoptr (i64 1 to ptr), ptr null, ptr null, ptr null), !dbg !44286
    ) != null);
    // An SSA operand gets an inttoptr in the same function; the range attribute is dropped.
    try testing.expect(std.mem.indexOf(u8, got.ir,
        \\  %zilc.sys.1.1 = inttoptr i64 %10 to ptr
        \\  %12 = call i64 @zilc_syscall(i64 202, ptr %zilc.sys.1.1, ptr inttoptr (i64 128 to ptr), ptr inttoptr (i64 0 to ptr), ptr inttoptr (i64 0 to ptr), ptr null, ptr null), !dbg !32170
    ) != null);
    try testing.expect(std.mem.indexOf(u8, got.ir,
        \\  %29 = call i64 @zilc_syscall(i64 186, ptr null, ptr null, ptr null, ptr null, ptr null, ptr null), !dbg !3899
    ) != null);
    try testing.expect(std.mem.indexOf(u8, got.ir, syscall_decl) != null);
}

test "syscall rewrite: other asm untouched, no-op without syscalls, idempotent" {
    const other =
        \\define void @g() {
        \\  call void asm sideeffect "pause", ""()
        \\  ret void
        \\}
        \\
    ;
    const none = try rewriteSyscalls(testing.allocator, other);
    defer testing.allocator.free(none.ir);
    try testing.expectEqual(@as(usize, 0), none.count);
    try testing.expectEqualStrings(other, none.ir);

    const ir =
        \\define void @f() {
        \\  %1 = call i64 asm sideeffect "syscall", "={rax},{rax},~{memory}"(i64 39) #1, !dbg !7
        \\  ret void
        \\}
        \\
    ;
    const once = try rewriteSyscalls(testing.allocator, ir);
    defer testing.allocator.free(once.ir);
    const twice = try rewriteSyscalls(testing.allocator, once.ir);
    defer testing.allocator.free(twice.ir);
    try testing.expectEqual(@as(usize, 1), once.count);
    try testing.expectEqual(@as(usize, 0), twice.count);
    try testing.expectEqualStrings(once.ir, twice.ir);
}

test "internalizeExcept keeps only the asked-for exports" {
    const ir =
        \\define weak hidden float @roundf(float %0) #0 {
        \\define weak hidden fp128 @roundq(fp128 %0) #0 {
        \\define internal fp128 @helper(fp128 %0) {
        \\define weak hidden double @round(double %0) #0 {
        \\declare double @floor(double)
        \\
    ;
    const got = try internalizeExcept(testing.allocator, ir, &.{"roundq"});
    defer testing.allocator.free(got);
    try testing.expectEqualStrings(
        \\define internal float @roundf(float %0) #0 {
        \\define weak hidden fp128 @roundq(fp128 %0) #0 {
        \\define internal fp128 @helper(fp128 %0) {
        \\define internal double @round(double %0) #0 {
        \\declare double @floor(double)
        \\
    , got);
}

test "a module with no datalayout is an error, not a silent pass-through" {
    try testing.expectError(Error.NoDataLayout, toFilCDialect(testing.allocator, "define void @f() { ret void }\n"));
}
