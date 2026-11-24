// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
// C owns main and calls mul.zig's f128 export (see mul.zig).
#include <stdio.h>

double mulq(double a, double b);

int main(void) {
    printf("mulq: %g\n", mulq(2.0, 3.0));
    return 0;
}
