// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! A whole Zig program under zilc — no C file involved.
//!
//!   zilc build examples/whole_program/hello.zig -o hello
//!   ./hello        # prints two lines, then traps on the out-of-bounds write
//!
//! zilc wraps this `main` in a generated C-ABI entry, because Zig's own start
//! code forges a pointer from `getauxval(AT_PHDR)` and Fil-C traps on the first
//! read of it (cmem/known-issues.md KI-5).

extern fn printf(fmt: [*:0]const u8, ...) c_int;
extern fn malloc(n: usize) ?*anyopaque;
extern fn free(p: ?*anyopaque) void;

pub fn main() void {
    _ = printf("hello from a whole Zig program\n");

    const raw = malloc(4 * @sizeOf(i32)) orelse return;
    const a: [*]i32 = @ptrCast(@alignCast(raw));

    var i: usize = 0;
    while (i < 4) : (i += 1) a[i] = @intCast(i * i);
    _ = printf("a[3] = %d\n", a[3]);

    a[4] = 99; // one past the end: must trap, naming this line
    _ = printf("NOT REACHED: the overflow went undetected\n");
    free(raw);
}
