#include <stdio.h>
#include <math.h>

/* C supports constants of character, string, boolean, and numeric values.
   The `const` keyword or preprocessor `#define` declares a constant. */

const char *s = "constant";

int main(void) {
    printf("%s\n", s);

    /* A numeric constant. */
    const long n = 500000000L;

    /* Constant expression with high-precision arithmetic. */
    const double d = 3e20 / n;
    printf("%g\n", d);

    /* Explicit conversion to integer type. */
    printf("%lld\n", (long long)d);

    /* Pass the constant to a function expecting double. */
    printf("%.17g\n", sin((double)n));

    return 0;
}
