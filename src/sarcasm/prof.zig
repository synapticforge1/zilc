// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//! Optional pass-level profiling (a port of projects/sarcasm/sarcasm/prof.luau, Fil-C 0.687),
//! enabled by SARCASM_PROFILE (set, non-empty, not "0"). Each mark prints CPU time (os.clock) and
//! the current RSS (/proc/self/status VmRSS) with the deltas since the last mark, to stdout and,
//! when SARCASM_PROFILE_LOG names a writable path, to that file. Inert when disabled: callers
//! pass a format and arguments, which are only formatted when enabled.

const std = @import("std");

var state: enum { unknown, off, on } = .unknown;
var t0: f64 = 0;
var lastT: f64 = 0;
var lastR: f64 = 0;
var log_file: ?std.fs.File = null;

fn cpuSeconds() f64 {
    const ts = std.posix.clock_gettime(.PROCESS_CPUTIME_ID) catch return 0;
    return @as(f64, @floatFromInt(ts.sec)) + @as(f64, @floatFromInt(ts.nsec)) / 1e9;
}

fn rssKb() f64 {
    var buf: [8192]u8 = undefined;
    const f = std.fs.openFileAbsolute("/proc/self/status", .{}) catch return 0;
    defer f.close();
    const n = f.readAll(&buf) catch return 0;
    const s = buf[0..n];
    const i = std.mem.indexOf(u8, s, "VmRSS:") orelse return 0;
    var j = i + 6;
    while (j < s.len and (s[j] == ' ' or s[j] == '\t')) j += 1;
    var k = j;
    while (k < s.len and std.ascii.isDigit(s[k])) k += 1;
    return std.fmt.parseFloat(f64, s[j..k]) catch 0;
}

pub fn enabled() bool {
    if (state == .unknown) {
        const v = std.posix.getenv("SARCASM_PROFILE");
        state = if (v != null and v.?.len > 0 and !std.mem.eql(u8, v.?, "0")) .on else .off;
        t0 = cpuSeconds();
        if (state == .on) if (std.posix.getenv("SARCASM_PROFILE_LOG")) |p| {
            log_file = std.fs.cwd().createFile(p, .{ .truncate = true }) catch null;
        };
    }
    return state == .on;
}

/// "%+N.Mf": the sign always shown.
fn signed(buf: []u8, x: f64, comptime prec: u8) []const u8 {
    return std.fmt.bufPrint(buf, "{s}{d:." ++ std.fmt.comptimePrint("{d}", .{prec}) ++ "}", .{ if (x < 0) "-" else "+", @abs(x) }) catch "";
}

pub fn mark(comptime fmt: []const u8, args: anytype) void {
    if (!enabled()) return;
    var lb: [512]u8 = undefined;
    const label = std.fmt.bufPrint(&lb, fmt, args) catch fmt;
    const t = cpuSeconds() - t0;
    const r = rssKb();
    var a: [32]u8 = undefined;
    var b: [32]u8 = undefined;
    var line: [768]u8 = undefined;
    const s = std.fmt.bufPrint(&line, "[prof] {d:>10.2}s rss={d:>10.1}MB (dt={s:>8}s drss={s:>10}MB) {s}\n", .{ t, r / 1024, signed(&a, t - lastT, 2), signed(&b, (r - lastR) / 1024, 1), label }) catch return;
    std.fs.File.stdout().writeAll(s) catch {};
    if (log_file) |f| f.writeAll(s) catch {};
    lastT = t;
    lastR = r;
}
