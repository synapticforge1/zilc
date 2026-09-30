#include <stdio.h>

/* `for` is C's most versatile looping construct. */

int main(void) {
    /* The most basic type, with a single condition (while-style). */
    int i = 1;
    for (; i <= 3; ) {
        printf("%d\n", i);
        i = i + 1;
    }

    /* A classic initial/condition/after `for` loop. */
    for (int j = 7; j <= 9; j++) {
        printf("%d\n", j);
    }

    /* A `for` without a condition loops until a `break`. */
    for (;;) {
        printf("loop\n");
        break;
    }

    /* Use `continue` to skip to the next iteration. */
    for (int n = 0; n <= 5; n++) {
        if (n % 2 == 0) {
            continue;
        }
        printf("%d\n", n);
    }

    return 0;
}
