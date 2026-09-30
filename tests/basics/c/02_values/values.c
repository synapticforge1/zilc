#include <stdio.h>
#include <stdbool.h>

int main(void) {
    /* C has various value types. String literals placed side-by-side
       are concatenated at compile time. */
    printf("%s\n", "go" "lang");

    /* Integers and floats. */
    printf("1+1 = %d\n", 1 + 1);
    printf("7.0/3.0 = %.17g\n", 7.0 / 3.0);

    /* Booleans, with boolean operators. */
    printf("%s\n", (true && false) ? "true" : "false");
    printf("%s\n", (true || false) ? "true" : "false");
    printf("%s\n", (!true) ? "true" : "false");

    return 0;
}
