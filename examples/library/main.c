// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
// Library mode: this C file owns main and calls the Zig exports in hooks.zig.
//   prog page | random | panic
#include <stdio.h>
#include <string.h>

int zig_page_alloc(void);
int zig_random(void);
int zig_panic(int n);

int main(int argc, char **argv) {
    const char *what = argc > 1 ? argv[1] : "";
    if (!strcmp(what, "page")) printf("page_allocator: %d\n", zig_page_alloc());
    else if (!strcmp(what, "random")) printf("random: %d\n", zig_random());
    else if (!strcmp(what, "panic")) printf("panic: %d\n", zig_panic(1));
    else {
        fprintf(stderr, "usage: prog page|random|panic\n");
        return 2;
    }
    return 0;
}
