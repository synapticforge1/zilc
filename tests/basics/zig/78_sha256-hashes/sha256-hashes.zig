const std = @import("std");

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    const s = "sha256 this string";

    // Compute SHA256 hash using Zig's stdlib crypto
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    h.update(s);
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    h.final(&digest);

    try stdout.print("{s}\n", .{s});
    for (digest) |byte| {
        try stdout.print("{x:0>2}", .{byte});
    }
    try stdout.print("\n", .{});
}
