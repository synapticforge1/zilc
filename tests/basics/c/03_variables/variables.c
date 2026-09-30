#include <stdio.h>
#include <stdbool.h>

/* In C, variables must be explicitly declared with a type before use. */

int main(void) {
    /* Declare and initialize a string (character array). */
    char a[] = "initial";
    printf("%s\n", a);

    /* Declare multiple variables of the same type. */
    int b = 1, c = 2;
    printf("%d %d\n", b, c);

    /* C requires explicit types; there is no type inference. */
    bool d = true;
    printf("%s\n", d ? "true" : "false");

    /* Variables declared without initialization contain indeterminate
       values, but zero-initialization is common practice. */
    int e = 0;
    printf("%d\n", e);

    /* A straightforward variable declaration and initialization. */
    char f[] = "apple";
    printf("%s\n", f);

    return 0;
}
