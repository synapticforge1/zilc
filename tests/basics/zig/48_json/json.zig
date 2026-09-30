const std = @import("std");

const Response1 = struct {
    Page: i32,
    Fruits: []const []const u8,
};

const Response2 = struct {
    page: i32,
    fruits: []const []const u8,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    // Encode basic types
    {
        const s = try std.json.Stringify.valueAlloc(allocator, true, .{});
        defer allocator.free(s);
        try stdout.print("{s}\n", .{s});
    }
    {
        const s = try std.json.Stringify.valueAlloc(allocator, @as(i32, 1), .{});
        defer allocator.free(s);
        try stdout.print("{s}\n", .{s});
    }
    {
        const s = try std.json.Stringify.valueAlloc(allocator, @as(f64, 2.34), .{});
        defer allocator.free(s);
        try stdout.print("{s}\n", .{s});
    }
    {
        const s = try std.json.Stringify.valueAlloc(allocator, "vector", .{});
        defer allocator.free(s);
        try stdout.print("{s}\n", .{s});
    }

    // Slice
    {
        const slc = [_][]const u8{ "apple", "peach", "pear" };
        const s = try std.json.Stringify.valueAlloc(allocator, slc, .{});
        defer allocator.free(s);
        try stdout.print("{s}\n", .{s});
    }

    // Map (use string map; order matches insertion in Zig's StringArrayHashMap)
    {
        var map: std.json.ArrayHashMap(i32) = .{}; // zilc: 0.15 json serialises maps through this wrapper
        defer map.deinit(allocator);
        try map.map.put(allocator, "apple", 5);
        try map.map.put(allocator, "lettuce", 7);
        const s = try std.json.Stringify.valueAlloc(allocator, map, .{});
        defer allocator.free(s);
        try stdout.print("{s}\n", .{s});
    }

    // Struct with default field names
    {
        const res1 = Response1{
            .Page = 1,
            .Fruits = &[_][]const u8{ "apple", "peach", "pear" },
        };
        const s = try std.json.Stringify.valueAlloc(allocator, res1, .{});
        defer allocator.free(s);
        try stdout.print("{s}\n", .{s});
    }

    // Struct with json field names (lowercase)
    {
        const res2 = Response2{
            .page = 1,
            .fruits = &[_][]const u8{ "apple", "peach", "pear" },
        };
        const s = try std.json.Stringify.valueAlloc(allocator, res2, .{});
        defer allocator.free(s);
        try stdout.print("{s}\n", .{s});
    }

    // Decode generic JSON
    {
        const input = "{\"num\":6.13,\"strs\":[\"a\",\"b\"]}";
        const parsed = try std.json.parseFromSlice(std.json.Value, allocator, input, .{});
        defer parsed.deinit();
        const obj = parsed.value.object;
        const num = obj.get("num").?.float;
        const strs = obj.get("strs").?.array;
        try stdout.print("map[num:{d} strs:[{s} {s}]]\n", .{ num, strs.items[0].string, strs.items[1].string });
        try stdout.print("{d}\n", .{num});
        try stdout.print("{s}\n", .{strs.items[0].string});
    }

    // Decode into typed struct
    {
        const input = "{\"page\": 1, \"fruits\": [\"apple\", \"peach\"]}";
        const parsed = try std.json.parseFromSlice(Response2, allocator, input, .{});
        defer parsed.deinit();
        const res = parsed.value;
        try stdout.print("{{{d} [{s} {s}]}}\n", .{ res.page, res.fruits[0], res.fruits[1] });
        try stdout.print("{s}\n", .{res.fruits[0]});
    }

    // Stream encode to stdout
    {
        var map: std.json.ArrayHashMap(i32) = .{}; // zilc: 0.15 json serialises maps through this wrapper
        defer map.deinit(allocator);
        try map.map.put(allocator, "apple", 5);
        try map.map.put(allocator, "lettuce", 7);
        const s = try std.json.Stringify.valueAlloc(allocator, map, .{});
        defer allocator.free(s);
        try stdout.print("{s}\n", .{s});
    }
}
