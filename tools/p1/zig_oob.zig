// P1 spike: the smallest Zig program that should trap under Fil-C.
// Deliberately avoids Zig's std allocators and I/O: it calls libc directly,
// so the first test isolates "does Zig-produced IR survive the pass" from
// "does Zig's std survive the pass".

extern fn printf(fmt: [*:0]const u8, ...) c_int;
extern fn malloc(n: usize) ?*anyopaque;
extern fn free(p: ?*anyopaque) void;

pub fn main() void {
    const raw = malloc(4 * @sizeOf(i32)) orelse return;
    const a: [*]i32 = @ptrCast(@alignCast(raw));

    var i: usize = 0;
    while (i <= 4) : (i += 1) { // <= : one past the end, must trap at i == 4
        a[i] = @intCast(i);
    }

    _ = printf("a[3] = %d\n", a[3]);
    free(raw);
}
