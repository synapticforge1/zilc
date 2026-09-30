const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    const data = "abc123!?$*&()'-=@~";

    // Standard base64 encode
    const enc_len = std.base64.standard.Encoder.calcSize(data.len);
    const encoded = try allocator.alloc(u8, enc_len);
    defer allocator.free(encoded);
    _ = std.base64.standard.Encoder.encode(encoded, data);
    try stdout.print("{s}\n", .{encoded});

    // Standard base64 decode
    const dec_len = try std.base64.standard.Decoder.calcSizeForSlice(encoded);
    const decoded = try allocator.alloc(u8, dec_len);
    defer allocator.free(decoded);
    try std.base64.standard.Decoder.decode(decoded, encoded);
    try stdout.print("{s}\n", .{decoded});
    try stdout.print("\n", .{});

    // URL-safe base64 encode
    const url_enc_len = std.base64.url_safe.Encoder.calcSize(data.len);
    const url_encoded = try allocator.alloc(u8, url_enc_len);
    defer allocator.free(url_encoded);
    _ = std.base64.url_safe.Encoder.encode(url_encoded, data);
    try stdout.print("{s}\n", .{url_encoded});

    // URL-safe base64 decode
    const url_dec_len = try std.base64.url_safe.Decoder.calcSizeForSlice(url_encoded);
    const url_decoded = try allocator.alloc(u8, url_dec_len);
    defer allocator.free(url_decoded);
    try std.base64.url_safe.Decoder.decode(url_decoded, url_encoded);
    try stdout.print("{s}\n", .{url_decoded});
}
