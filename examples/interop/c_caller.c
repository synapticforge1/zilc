/* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT */
/*
 * C side of the interop example. C allocates; Zig writes.
 *
 * Built with plain `zig cc` / `clang`, the last call is undefined behavior and
 * usually appears to work. Built with `zilc build`, it panics inside the ZIG
 * function, naming bounds.zig's line and column under this call site.
 *
 *   zilc build examples/interop/c_caller.c examples/interop/bounds.zig -o interop
 */
#include <stdio.h>
#include <stdlib.h>

extern void zig_add(int *p, unsigned long i, int v);
extern int zig_sum(const int *p, unsigned long n);

int main(void) {
    int *a = malloc(4 * sizeof(int));
    if (!a) return 1;

    for (unsigned long i = 0; i < 4; i++)
        zig_add(a, i, (int)i);
    printf("in bounds ok, sum=%d\n", zig_sum(a, 4));
    fflush(stdout);

    zig_add(a, 4, 99); /* one past the end, inside Zig: must trap */

    printf("NOT REACHED: the overflow went undetected\n");
    free(a);
    return 0;
}
