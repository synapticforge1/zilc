#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(void) {
    /* rand() returns values in [0, RAND_MAX]. Scale to [0,100). */
    printf("%d,%d\n", rand() % 100, rand() % 100);

    /* Float in [0.0, 1.0). */
    printf("%f\n", (double)rand() / ((double)RAND_MAX + 1.0));

    /* Float in [5.0, 10.0). */
    printf("%f,%f\n",
           5.0 + (double)rand() / ((double)RAND_MAX + 1.0) * 5.0,
           5.0 + (double)rand() / ((double)RAND_MAX + 1.0) * 5.0);

    /* Seed with current time for a different sequence each run. */
    srand((unsigned int)time(NULL));
    printf("%d,%d\n", rand() % 100, rand() % 100);

    /* Same seed produces the same sequence. */
    srand(42);
    printf("%d,%d\n", rand() % 100, rand() % 100);
    srand(42);
    printf("%d,%d\n", rand() % 100, rand() % 100);

    return 0;
}
