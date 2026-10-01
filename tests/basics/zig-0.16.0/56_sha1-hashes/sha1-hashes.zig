const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    const s = "sha1 this string";

    var h = std.crypto.hash.Sha1.init(.{});
    h.update(s);
    var digest: [std.crypto.hash.Sha1.digest_length]u8 = undefined;
    h.final(&digest);

    try stdout.print("{s}\n", .{s});
    // zilc: 0.15 dropped std.fmt.fmtSliceHexLower; bytesToHex returns the lowercase hex as an array.
    try stdout.print("{s}\n", .{&std.fmt.bytesToHex(digest, .lower)});
}
