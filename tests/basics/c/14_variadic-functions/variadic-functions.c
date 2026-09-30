#include <stdio.h>
#include <stdarg.h>

/* C supports variadic functions through <stdarg.h>.
   The function must know the count of arguments (passed explicitly here). */

void sum(int count, ...) {
    va_list args;
    va_start(args, count);

    /* Print the argument list in [v1 v2 ...] format, then the total. */
    printf("[");
    int total = 0;
    int nums[16];
    for (int i = 0; i < count; i++) {
        nums[i] = va_arg(args, int);
        total += nums[i];
    }
    for (int i = 0; i < count; i++) {
        printf("%d%s", nums[i], i < count - 1 ? " " : "");
    }
    printf("] %d\n", total);

    va_end(args);
}

int main(void) {
    sum(2, 1, 2);
    sum(3, 1, 2, 3);

    /* In Go, a slice can be spread into a variadic call with `...`.
       In C, we pass the count and each element individually. */
    sum(4, 1, 2, 3, 4);

    return 0;
}
