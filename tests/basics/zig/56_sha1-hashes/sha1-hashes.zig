const std = @import("std");

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;

    const s = "sha1 this string";

    var h = std.crypto.hash.Sha1.init(.{});
    h.update(s);
    var digest: [std.crypto.hash.Sha1.digest_length]u8 = undefined;
    h.final(&digest);

    try stdout.print("{s}\n", .{s});
    try stdout.print("{s}\n", .{&std.fmt.bytesToHex(digest, .lower)});
}
