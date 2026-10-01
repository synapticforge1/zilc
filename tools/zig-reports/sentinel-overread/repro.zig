// Minimal reproduction: Zig 0.15.2's std.mem.indexOfSentinel reads past the end of a
// null-terminated string (16 bytes at a time with SIMD, up to the page boundary).
//
// Natively this "works": the extra bytes are in the same page, so nothing faults. Under a
// byte-precise memory checker it is an out-of-bounds read:
//   * under zilc / Fil-C:   filc safety error: cannot read 16 bytes when upper - ptr = 12
//   * under Valgrind memcheck (build WITHOUT -fvalgrind, e.g. ReleaseSafe): "Invalid read of size 16"
//
// Fixed upstream in Zig 0.16.0, where the function is `findSentinel` with a scalar loop.
// See cmem/zig-upstream-notes.md.
const std = @import("std");

pub fn main() void {
    // The shape getenv() produces: a "NAME=value" entry in a 16-byte object, and a pointer to
    // the value, 4 bytes in, so only 12 bytes remain before the object's end. malloc'd so a
    // byte-precise checker knows the object's true size. (A string at the START of a 16-byte
    // object does not show it: the first 16-byte load then fits exactly.)
    const raw: [*]u8 = @ptrCast(std.c.malloc(16) orelse return);
    defer std.c.free(raw);
    @memcpy(raw[0..16], "FOO=hello world\x00");
    const s: [*:0]const u8 = @ptrCast(raw + 4);

    // std.mem.span -> len -> lenSliceTo -> indexOfSentinel: the 16-byte vector load starts here.
    const span = std.mem.span(s);
    std.debug.print("len = {d}\n", .{span.len});
}
