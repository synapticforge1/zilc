const std = @import("std");

const Person = struct {
    name: []const u8,
    age: i64,
};

fn newPerson(name: []const u8) Person {
    return Person{ .name = name, .age = 42 };
}

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;

    const p1 = Person{ .name = "Bob", .age = 20 };
    try stdout.print("{{{s} {d}}}\n", .{ p1.name, p1.age });

    const p2 = Person{ .name = "Alice", .age = 30 };
    try stdout.print("{{{s} {d}}}\n", .{ p2.name, p2.age });

    const p3 = Person{ .name = "Fred", .age = 0 };
    try stdout.print("{{{s} {d}}}\n", .{ p3.name, p3.age });

    const p4 = Person{ .name = "Ann", .age = 40 };
    try stdout.print("&{{{s} {d}}}\n", .{ p4.name, p4.age });

    const p5 = newPerson("Jon");
    try stdout.print("&{{{s} {d}}}\n", .{ p5.name, p5.age });

    const s = Person{ .name = "Sean", .age = 50 };
    try stdout.print("{s}\n", .{s.name});

    const sp = &s;
    try stdout.print("{d}\n", .{sp.age});

    var s2 = Person{ .name = "Sean", .age = 50 };
    const sp2 = &s2;
    sp2.age = 51;
    try stdout.print("{d}\n", .{sp2.age});
}
