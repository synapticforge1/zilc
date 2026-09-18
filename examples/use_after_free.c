/* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT */
/*
 * Use-after-free. Under Fil-C semantics free() marks the object freed and any
 * later access traps; the GC reclaims it only once unreachable.
 */
#include <stdlib.h>
#include <stdio.h>

int main(void) {
    int *p = malloc(sizeof(int));
    *p = 42;
    free(p);
    printf("%d\n", *p); /* must trap under zilc */
    return 0;
}
