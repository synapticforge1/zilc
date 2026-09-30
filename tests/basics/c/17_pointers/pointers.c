#include <stdio.h>

/* Pointers are a native feature of C, used to pass references to values. */

/* zeroval receives a copy of ival; changes do not affect the caller. */
void zeroval(int ival) {
    ival = 0;
}

/* zeroptr receives a pointer; dereferencing and assigning changes the caller's value. */
void zeroptr(int *iptr) {
    *iptr = 0;
}

int main(void) {
    int i = 1;
    printf("initial: %d\n", i);

    zeroval(i);
    printf("zeroval: %d\n", i);

    /* The `&i` syntax gives the memory address of `i`. */
    zeroptr(&i);
    printf("zeroptr: %d\n", i);

    /* Print the pointer address itself. */
    printf("pointer: %p\n", (void *)&i);

    return 0;
}
