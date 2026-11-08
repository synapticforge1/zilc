// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! A reader for the identity-aware serialization check-stages.ts's capture harnesses write
//! (`iser` there): upstream's Luau values as they cross a module boundary, so a stage can run the
//! port on EXACTLY the inputs upstream's module received.
//!
//!   value := nil | true | false | <number, as tostring prints it> | "<string, fixed-width \ddd escapes>"
//!          | &<id>{<key>=<value>,...}     a table, first occurrence (id: its identity)
//!          | *<id>                       the same table again
//!   key   := <identifier> | #<number> | "<string>"

const std = @import("std");
const ln = @import("sarcasm").luau_number;

pub const Key = union(enum) { name: []const u8, num: f64 };
pub const Entry = struct { key: Key, val: Value };
pub const Table = struct { id: u32, entries: std.ArrayList(Entry) = .empty };
pub const Value = union(enum) {
    nil,
    boolean: bool,
    num: f64,
    str: []const u8,
    table: *Table,

    pub fn get(v: Value, name: []const u8) ?Value {
        if (v != .table) return null;
        for (v.table.entries.items) |e| if (e.key == .name and std.mem.eql(u8, e.key.name, name)) return e.val;
        return null;
    }
    /// The array part `#1..#n` in order.
    pub fn list(v: Value, a: std.mem.Allocator) ![]Value {
        var o: std.ArrayList(Value) = .empty;
        if (v != .table) return o.items;
        var i: f64 = 1;
        outer: while (true) : (i += 1) {
            for (v.table.entries.items) |e| if (e.key == .num and e.key.num == i) {
                try o.append(a, e.val);
                continue :outer;
            };
            break;
        }
        return o.items;
    }
};

pub const Parser = struct {
    a: std.mem.Allocator,
    s: []const u8,
    i: usize = 0,
    tables: std.AutoHashMapUnmanaged(u32, *Table) = .empty,

    fn peek(p: *Parser) u8 {
        return if (p.i < p.s.len) p.s[p.i] else 0;
    }
    fn expect(p: *Parser, c: u8) !void {
        if (p.peek() != c) return error.BadCapture;
        p.i += 1;
    }
    fn num(p: *Parser) !f64 {
        const st = p.i;
        while (p.i < p.s.len and std.mem.indexOfScalar(u8, "0123456789+-.eEinfa", p.s[p.i]) != null) p.i += 1;
        return ln.tonumber(p.s[st..p.i]) orelse error.BadCapture;
    }
    fn uint(p: *Parser) !u32 {
        const st = p.i;
        while (p.i < p.s.len and std.ascii.isDigit(p.s[p.i])) p.i += 1;
        return std.fmt.parseInt(u32, p.s[st..p.i], 10);
    }
    fn str(p: *Parser) ![]const u8 {
        try p.expect('"');
        var o: std.ArrayList(u8) = .empty;
        while (p.peek() != '"') {
            if (p.i >= p.s.len) return error.BadCapture;
            if (p.s[p.i] == '\\') {
                // a fixed-width \ddd escape
                if (p.i + 4 > p.s.len) return error.BadCapture;
                try o.append(p.a, try std.fmt.parseInt(u8, p.s[p.i + 1 .. p.i + 4], 10));
                p.i += 4;
            } else {
                try o.append(p.a, p.s[p.i]);
                p.i += 1;
            }
        }
        p.i += 1;
        return o.items;
    }
    pub fn value(p: *Parser) anyerror!Value {
        const c = p.peek();
        if (std.mem.startsWith(u8, p.s[p.i..], "nil")) {
            p.i += 3;
            return .nil;
        }
        if (std.mem.startsWith(u8, p.s[p.i..], "true")) {
            p.i += 4;
            return .{ .boolean = true };
        }
        if (std.mem.startsWith(u8, p.s[p.i..], "false")) {
            p.i += 5;
            return .{ .boolean = false };
        }
        if (c == '"') return .{ .str = try p.str() };
        if (c == '*') {
            p.i += 1;
            return .{ .table = p.tables.get(try p.uint()) orelse return error.BadCapture };
        }
        if (c == '&') {
            p.i += 1;
            const t = try p.a.create(Table);
            t.* = .{ .id = try p.uint() };
            try p.tables.put(p.a, t.id, t);
            try p.expect('{');
            while (p.peek() != '}') {
                const k: Key = switch (p.peek()) {
                    '#' => blk: {
                        p.i += 1;
                        break :blk .{ .num = try p.num() };
                    },
                    '"' => .{ .name = try p.str() },
                    else => blk: {
                        const st = p.i;
                        while (p.i < p.s.len and (std.ascii.isAlphanumeric(p.s[p.i]) or p.s[p.i] == '_')) p.i += 1;
                        break :blk .{ .name = p.s[st..p.i] };
                    },
                };
                try p.expect('=');
                try t.entries.append(p.a, .{ .key = k, .val = try p.value() });
                if (p.peek() == ',') p.i += 1;
            }
            p.i += 1;
            return .{ .table = t };
        }
        return .{ .num = try p.num() };
    }
};
