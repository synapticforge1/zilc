// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
// The C half of interop.zig: a kernel Zig calls once per row.
#include <stddef.h>

double bench_dot(const double *a, const double *b, size_t n) {
    double s = 0;
    for (size_t i = 0; i < n; i++) s += a[i] * b[i];
    return s;
}
