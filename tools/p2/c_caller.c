/* C side of the P1/P2 milestone: allocate in C, overflow inside ZIG code. */
#include <stdio.h>
#include <stdlib.h>

extern void zig_add(int *p, unsigned long i, int v); /* from tiny.zig */
extern int zig_sum(const int *p, unsigned long n);

int main(void) {
    int *a = malloc(4 * sizeof(int));
    for (unsigned long i = 0; i < 4; i++)
        zig_add(a, i, (int)i);
    printf("in bounds ok, sum=%d\n", zig_sum(a, 4));
    fflush(stdout);

    zig_add(a, 4, 99); /* one past the end, inside Zig code: must trap */
    printf("NOT REACHED: overflow went undetected\n");
    free(a);
    return 0;
}
