#include <stdio.h>

/* C does not support multiple return values directly. The idiomatic
   approach is to use output parameters (pointers) or return a struct. */

typedef struct { int a; int b; } IntPair;

/* Return two ints packed in a struct. */
IntPair vals(void) {
    IntPair p = {3, 7};
    return p;
}

int main(void) {
    /* Unpack both return values. */
    IntPair p = vals();
    printf("%d\n", p.a);
    printf("%d\n", p.b);

    /* Use only the second value (ignore the first). */
    int c = vals().b;
    printf("%d\n", c);

    return 0;
}
