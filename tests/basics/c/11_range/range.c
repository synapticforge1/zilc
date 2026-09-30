#include <stdio.h>
#include <string.h>

/* C has no `range` keyword. Iteration over arrays, arrays of key-value pairs,
   and strings is done with `for` loops and index arithmetic. */

int main(void) {
    /* Sum a fixed-size integer array (equivalent to ranging over a slice). */
    int nums[] = {2, 3, 4};
    int len_nums = 3;
    int sum = 0;
    for (int i = 0; i < len_nums; i++) {
        sum += nums[i];
    }
    printf("sum: %d\n", sum);

    /* Access both index and value in a loop. */
    for (int i = 0; i < len_nums; i++) {
        if (nums[i] == 3) {
            printf("index: %d\n", i);
        }
    }

    /* Iterate over an array of key-value string pairs (map equivalent). */
    const char *keys[] = {"a", "b"};
    const char *vals[] = {"apple", "banana"};
    int map_len = 2;
    for (int i = 0; i < map_len; i++) {
        printf("%s -> %s\n", keys[i], vals[i]);
    }

    /* Iterate over just keys. */
    for (int i = 0; i < map_len; i++) {
        printf("key: %s\n", keys[i]);
    }

    /* Iterate over a string character-by-character (byte index + value).
       Go's range over "go" yields rune values: g=103, o=111. */
    const char *str = "go";
    for (int i = 0; str[i] != '\0'; i++) {
        printf("%d %d\n", i, (unsigned char)str[i]);
    }

    return 0;
}
