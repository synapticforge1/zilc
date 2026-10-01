// Zig's standard library does not include an XML encoder/decoder;
// a simplified struct-based output is shown instead.

const std = @import("std");

const Plant = struct {
    id: i32,
    name: []const u8,
    origin: []const []const u8,

    fn print(self: Plant, writer: anytype, indent: []const u8) !void {
        try writer.print("{s}<plant id=\"{d}\">\n", .{ indent, self.id });
        try writer.print("{s}  <name>{s}</name>\n", .{ indent, self.name });
        for (self.origin) |o| {
            try writer.print("{s}  <origin>{s}</origin>\n", .{ indent, o });
        }
        try writer.print("{s}</plant>", .{indent});
    }

    fn toString(self: Plant, allocator: std.mem.Allocator) ![]u8 {
        var origins = std.array_list.Managed(u8).init(allocator);
        defer origins.deinit();
        for (self.origin, 0..) |o, i| {
            if (i > 0) try origins.appendSlice(" ");
            try origins.appendSlice(o);
        }
        return std.fmt.allocPrint(allocator, "Plant id={d}, name={s}, origin=[{s}]", .{
            self.id, self.name, origins.items,
        });
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;

    const coffee_origins = [_][]const u8{ "Ethiopia", "Brazil" };
    const coffee = Plant{ .id = 27, .name = "Coffee", .origin = &coffee_origins };

    // MarshalIndent equivalent
    try coffee.print(stdout, " ");
    try stdout.print("\n", .{});

    // With XML header
    try stdout.print("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n", .{});
    try coffee.print(stdout, " ");
    try stdout.print("\n", .{});

    // Unmarshal then print (String() method)
    const s = try coffee.toString(allocator);
    defer allocator.free(s);
    try stdout.print("{s}\n", .{s});

    // Nesting
    const tomato_origins = [_][]const u8{ "Mexico", "California" };
    const tomato = Plant{ .id = 81, .name = "Tomato", .origin = &tomato_origins };

    try stdout.print(" <nesting>\n", .{});
    try stdout.print("   <parent>\n", .{});
    try stdout.print("     <child>\n", .{});
    try coffee.print(stdout, "       ");
    try stdout.print("\n", .{});
    try tomato.print(stdout, "       ");
    try stdout.print("\n", .{});
    try stdout.print("     </child>\n", .{});
    try stdout.print("   </parent>\n", .{});
    try stdout.print(" </nesting>", .{});
    try stdout.print("\n", .{});
}
