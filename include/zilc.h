/* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT */
/*
 * zilc.h — C ABI of the zilc runtime.
 *
 * Every declaration here must be defined in src/capi.zig; tests/capi_smoke.c
 * is the link-time gate that proves it.
 */
#ifndef ZILC_H
#define ZILC_H

#ifdef __cplusplus
extern "C" {
#endif

/* Returns the zilc version as a static NUL-terminated string, e.g. "0.1.0". */
const char *zilc_version(void);

#ifdef __cplusplus
}
#endif

#endif /* ZILC_H */
