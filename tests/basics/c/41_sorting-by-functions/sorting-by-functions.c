#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Custom sorting in C uses qsort() with a comparison function that
   encodes the custom ordering logic. Here we sort strings by length. */

static int cmp_by_length(const void *a, const void *b) {
    size_t la = strlen(*(const char **)a);
    size_t lb = strlen(*(const char **)b);
    return (la > lb) - (la < lb);
}

int main(void) {
    const char *fruits[] = {"peach", "banana", "kiwi"};
    int n = 3;

    qsort(fruits, n, sizeof(char *), cmp_by_length);

    printf("[");
    for (int i = 0; i < n; i++) {
        printf("%s%s", fruits[i], i < n - 1 ? " " : "");
    }
    printf("]\n");

    return 0;
}
