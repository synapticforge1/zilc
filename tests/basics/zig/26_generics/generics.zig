const std = @import("std");

fn slicesIndex(comptime T: type, s: []const T, v: T) i64 {
    for (s, 0..) |item, i| {
        const equal = switch (@typeInfo(T)) {
            .pointer => std.mem.eql(u8, item, v),
            else => item == v,
        };
        if (equal) return @intCast(i);
    }
    return -1;
}

fn Element(comptime T: type) type {
    return struct {
        next: ?*@This() = null,
        val: T,
    };
}

fn List(comptime T: type) type {
    return struct {
        const Self = @This();
        const Elem = Element(T);

        head: ?*Elem = null,
        tail: ?*Elem = null,
        allocator: std.mem.Allocator,

        fn init(allocator: std.mem.Allocator) Self {
            return Self{ .allocator = allocator };
        }

        fn push(self: *Self, v: T) !void {
            const node = try self.allocator.create(Elem);
            node.* = Elem{ .val = v };
            if (self.tail) |t| {
                t.next = node;
                self.tail = node;
            } else {
                self.head = node;
                self.tail = node;
            }
        }

        fn allElements(self: *Self, out: *std.array_list.Managed(T)) !void {
            var e = self.head;
            while (e) |node| {
                try out.append(node.val);
                e = node.next;
            }
        }

        fn deinit(self: *Self) void {
            var e = self.head;
            while (e) |node| {
                const next = node.next;
                self.allocator.destroy(node);
                e = next;
            }
        }
    };
}

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const s = [_][]const u8{ "foo", "bar", "zoo" };
    try stdout.print("index of zoo: {d}\n", .{slicesIndex([]const u8, &s, "zoo")});

    var lst = List(i64).init(allocator);
    defer lst.deinit();
    try lst.push(10);
    try lst.push(13);
    try lst.push(23);

    var elems = std.array_list.Managed(i64).init(allocator);
    defer elems.deinit();
    try lst.allElements(&elems);

    try stdout.print("list: [", .{});
    for (elems.items, 0..) |v, i| {
        if (i > 0) try stdout.print(" ", .{});
        try stdout.print("{d}", .{v});
    }
    try stdout.print("]\n", .{});
}
