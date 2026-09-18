/* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT */
/* Smoke test for include/zilc.h: links against the static runtime and calls it. */
#include <stdio.h>
#include <string.h>
#include "zilc.h"

int main(void) {
    const char *v = zilc_version();
    if (v == NULL || strlen(v) == 0) {
        fprintf(stderr, "capi_smoke: zilc_version() returned nothing\n");
        return 1;
    }
    printf("capi_smoke: zilc %s OK\n", v);
    return 0;
}
