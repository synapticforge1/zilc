#include <stdio.h>

/* Functions are central in C. Every function must declare its return type
   and parameter types. */

/* A function that takes two ints and returns their sum. */
int plus(int a, int b) {
    return a + b;
}

/* A function that sums three ints. */
int plus_plus(int a, int b, int c) {
    return a + b + c;
}

int main(void) {
    int res = plus(1, 2);
    printf("1+2 = %d\n", res);

    res = plus_plus(1, 2, 3);
    printf("1+2+3 = %d\n", res);

    return 0;
}
