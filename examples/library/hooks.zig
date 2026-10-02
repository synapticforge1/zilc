// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! Library mode: C owns `main` (main.c) and calls these exports. Each one uses a std feature
//! that needs a hook std only reads from the ROOT module: zilc's generated library root
//! supplies them (src/driver.zig `library_shim`). Before it did, all three stopped the program
//! (2026-10-02): page_allocator on its mmap hint (KI-12), crypto.random on the madvise probe
//! (KI-20), and @panic with a stack overflow in std's trace code.

const std = @import("std");

/// Two page allocations: the second is the one std used to hint at the first one's end.
export fn zig_page_alloc() c_int {
    const mem = std.heap.page_allocator.alloc(u8, 3 * 4096) catch return -1;
    defer std.heap.page_allocator.free(mem);
    @memset(mem, 7);
    const more = std.heap.page_allocator.alloc(u8, 4096) catch return -2;
    defer std.heap.page_allocator.free(more);
    more[0] = 1;
    return mem[100] + more[0];
}

/// 1 if the 16 random bytes are not all zero.
export fn zig_random() c_int {
    var buf: [16]u8 = undefined;
    std.crypto.random.bytes(&buf);
    for (buf) |b| if (b != 0) return 1;
    return 0;
}

/// Panics for n > 0: Fil-C reports it ("zig panic: library panic") and stops the program.
export fn zig_panic(n: c_int) c_int {
    if (n > 0) @panic("library panic");
    return n;
}
