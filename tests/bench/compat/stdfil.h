/* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT */
/* zilc's own: what the PLAIN (non-Fil-C) build of upstream's filc/benchmarks/richards.c needs from
   Fil-C's <stdfil.h>, so the same source runs as the native baseline (tools/bench/bench.ts). The
   Fil-C build uses Fil-C's real header. zgc_alloc returns zeroed memory, so calloc. */
#ifndef ZILC_BENCH_COMPAT_STDFIL_H
#define ZILC_BENCH_COMPAT_STDFIL_H
#include <stdio.h>
#include <stdlib.h>
#define zprintf printf
#define zgc_alloc(size) calloc(1, (size))
#endif
