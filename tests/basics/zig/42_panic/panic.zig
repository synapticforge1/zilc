// Zig uses @panic(); output differs from Go's panic output.

const std = @import("std");

pub fn main() void {
    @panic("a problem");
}
