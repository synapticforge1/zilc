#include <stdio.h>

/* In C, an array is a fixed-size sequence of elements of the same type.
   Arrays are zero-indexed and their length is fixed at compile time. */

int main(void) {
    /* Declare an array of 5 ints; C zero-initializes when `= {0}` is used. */
    int a[5] = {0};
    printf("emp: [%d %d %d %d %d]\n", a[0], a[1], a[2], a[3], a[4]);

    /* Set and get a value by index. */
    a[4] = 100;
    printf("set: [%d %d %d %d %d]\n", a[0], a[1], a[2], a[3], a[4]);
    printf("get: %d\n", a[4]);

    /* The length of an array is computed with sizeof. */
    printf("len: %zu\n", sizeof(a) / sizeof(a[0]));

    /* Declare and initialize in one line. */
    int b[5] = {1, 2, 3, 4, 5};
    printf("dcl: [%d %d %d %d %d]\n", b[0], b[1], b[2], b[3], b[4]);

    /* A two-dimensional array. */
    int twoD[2][3] = {0};
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 3; j++) {
            twoD[i][j] = i + j;
        }
    }
    printf("2d:  [[%d %d %d] [%d %d %d]]\n",
           twoD[0][0], twoD[0][1], twoD[0][2],
           twoD[1][0], twoD[1][1], twoD[1][2]);

    return 0;
}
