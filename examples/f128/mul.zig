// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! A Zig export that computes in 128-bit floats, so zilc must also build compiler-rt's f128
//! helpers (KI-9). The gate builds it alone with `zilc build -c` and links it with main.c: the
//! object must hold `mulq` itself, with the helpers handed over beside it (review 1, re-review 2).

export fn mulq(a: f64, b: f64) f64 {
    const x: f128 = a;
    const y: f128 = b;
    return @floatCast(x * y);
}
