// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! The Zig side of tools/sarcasm/check-stages.ts: one stage of the sarcasm port over a list of
//! inputs, dumped in the same canonical text the Luau harness prints for upstream's modules.
//!
//!   stage-check detect <files.txt>     each line a path: "arch syntax|nil"
//!   stage-check sig <annotations.hex>  each line a hex string: "ok …" or "err <message>"

const std = @import("std");
const s = @import("sarcasm");

fn writeList(out: *std.ArrayList(u8), gpa: std.mem.Allocator, xs: []const u8) !void {
    try out.append(gpa, '{');
    for (xs, 0..) |x, i| {
        if (i > 0) try out.append(gpa, ',');
        try out.print(gpa, "{d}", .{x});
    }
    try out.append(gpa, '}');
}

pub fn main() !void {
    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const gpa = arena_state.allocator();
    const args = try std.process.argsAlloc(gpa);
    const stage = args[1];
    const list = try std.fs.cwd().readFileAlloc(gpa, args[2], 1 << 30);
    var out: std.ArrayList(u8) = .empty;
    var lines = std.mem.tokenizeScalar(u8, list, '\n');
    var nb: [64]u8 = undefined;
    while (lines.next()) |line| {
        if (std.mem.eql(u8, stage, "detect")) {
            const text = try std.fs.cwd().readFileAlloc(gpa, line, 1 << 30);
            const r = try s.detect.detect(gpa, text);
            try out.print(gpa, "{s} {s}\n", .{ @tagName(r.arch), if (r.syntax) |x| @tagName(x) else "nil" });
        } else if (std.mem.eql(u8, stage, "sig")) {
            const ann = try gpa.alloc(u8, line.len / 2);
            _ = try std.fmt.hexToBytes(ann, line);
            const loc: s.err.Loc = .{ .file = "<in>", .line = 7 };
            if (s.sig.parseSignature(gpa, ann, loc)) |d| {
                if (s.sig.checkSupportedClasses(gpa, d, "call to 'f'", false, loc)) |_| {
                    try out.print(gpa, "ok {s} ", .{s.luau_number.tostring(&nb, d.signature)});
                    try writeList(&out, gpa, d.retTypes);
                    try writeList(&out, gpa, d.argTypes);
                    try out.print(gpa, " {d} {d} {} {}\n", .{ d.argWords, d.retWords, d.isVoid, d.retIsPtr });
                } else |e| switch (e) {
                    error.Sarcasm => try out.print(gpa, "err {s}\n", .{s.err.message}),
                    else => return e,
                }
            } else |e| switch (e) {
                error.Sarcasm => try out.print(gpa, "err {s}\n", .{s.err.message}),
                else => return e,
            }
        } else return error.UnknownStage;
    }
    try std.fs.File.stdout().writeAll(out.items);
}
