/* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT */
/*
 * The canonical bug zilc exists to stop: an out-of-bounds heap write.
 *
 * Built with plain `zig cc`, this is undefined behavior (it may "work").
 * Built with Fil-C's `filcc` today — and with zilc once the pass exists — it
 * must panic at the faulting store, never corrupt memory.
 */
#include <stdlib.h>
#include <stdio.h>

int main(void) {
    int *a = malloc(4 * sizeof(int));
    for (int i = 0; i <= 4; i++) /* <= : one past the end */
        a[i] = i;
    printf("a[3] = %d\n", a[3]);
    free(a);
    return 0;
}
