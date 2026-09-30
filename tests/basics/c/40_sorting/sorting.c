#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

/* C provides qsort() from <stdlib.h> for in-place sorting. */

static int cmp_str(const void *a, const void *b) {
    return strcmp(*(const char **)a, *(const char **)b);
}

static int cmp_int(const void *a, const void *b) {
    int ia = *(const int *)a;
    int ib = *(const int *)b;
    return (ia > ib) - (ia < ib);
}

static bool ints_are_sorted(const int *arr, int n) {
    for (int i = 1; i < n; i++) {
        if (arr[i] < arr[i - 1]) return false;
    }
    return true;
}

int main(void) {
    /* Sort strings in-place. */
    const char *strs[] = {"c", "a", "b"};
    int strs_len = 3;
    qsort(strs, strs_len, sizeof(char *), cmp_str);
    printf("Strings: [");
    for (int i = 0; i < strs_len; i++) printf("%s%s", strs[i], i < strs_len - 1 ? " " : "");
    printf("]\n");

    /* Sort ints in-place. */
    int ints[] = {7, 2, 4};
    int ints_len = 3;
    qsort(ints, ints_len, sizeof(int), cmp_int);
    printf("Ints:    [");
    for (int i = 0; i < ints_len; i++) printf("%d%s", ints[i], i < ints_len - 1 ? " " : "");
    printf("]\n");

    /* Check if already sorted. */
    printf("Sorted:  %s\n", ints_are_sorted(ints, ints_len) ? "true" : "false");

    return 0;
}
