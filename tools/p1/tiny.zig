// Minimal Zig: no std, no libc, no start code. Just pointer arithmetic and a
// store, so the pass sees Zig-shaped IR with nothing else in the module.
export fn zig_add(p: [*]i32, i: usize, v: i32) void {
    p[i] = v;
}

export fn zig_sum(p: [*]const i32, n: usize) i32 {
    var total: i32 = 0;
    var i: usize = 0;
    while (i < n) : (i += 1) total +%= p[i];
    return total;
}
