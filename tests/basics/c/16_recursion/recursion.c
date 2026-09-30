#include <stdio.h>

/* C supports recursive functions natively. */

int fact(int n) {
    if (n == 0) return 1;
    return n * fact(n - 1);
}

int main(void) {
    printf("%d\n", fact(7));
    return 0;
}
