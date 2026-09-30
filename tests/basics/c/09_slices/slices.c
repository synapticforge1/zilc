#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* C has no slice type. This lesson uses a simple dynamic string array
   (struct with pointer, length, and capacity) to mirror Go slice behavior. */

typedef struct {
    char **data;
    int len;
    int cap;
} Slice;

static Slice slice_make(int cap) {
    Slice s;
    s.data = calloc(cap, sizeof(char *));
    s.len = 0;
    s.cap = cap;
    return s;
}

static void slice_set(Slice *s, int i, const char *val) {
    s->data[i] = (char *)val;
}

static Slice slice_append(Slice s, const char *val) {
    if (s.len == s.cap) {
        s.cap = s.cap * 2 + 1;
        s.data = realloc(s.data, s.cap * sizeof(char *));
    }
    s.data[s.len++] = (char *)val;
    return s;
}

static Slice slice_copy(Slice src) {
    Slice dst = slice_make(src.len);
    memcpy(dst.data, src.data, src.len * sizeof(char *));
    dst.len = src.len;
    return dst;
}

static void slice_print(const char *label, Slice s) {
    printf("%s[", label);
    for (int i = 0; i < s.len; i++) {
        printf("%s%s", s.data[i], i < s.len - 1 ? " " : "");
    }
    printf("]\n");
}

int main(void) {
    /* Create an empty slice of length 3 (values default to empty strings). */
    Slice s = slice_make(3);
    s.len = 3;
    s.data[0] = ""; s.data[1] = ""; s.data[2] = "";
    slice_print("emp: ", s);

    /* Set and get elements. */
    slice_set(&s, 0, "a");
    slice_set(&s, 1, "b");
    slice_set(&s, 2, "c");
    slice_print("set: ", s);
    printf("get: %s\n", s.data[2]);

    /* Length of the slice. */
    printf("len: %d\n", s.len);

    /* Append elements. */
    s = slice_append(s, "d");
    s = slice_append(s, "e");
    s = slice_append(s, "f");
    slice_print("apd: ", s);

    /* Copy the slice. */
    Slice c = slice_copy(s);
    slice_print("cpy: ", c);

    /* Sub-slices (views into the array). */
    Slice sl1 = {s.data + 2, 3, 3};
    slice_print("sl1: ", sl1);

    Slice sl2 = {s.data, 5, 5};
    slice_print("sl2: ", sl2);

    Slice sl3 = {s.data + 2, s.len - 2, s.len - 2};
    slice_print("sl3: ", sl3);

    /* Declare and initialize inline. */
    char *t_data[] = {"g", "h", "i"};
    Slice t = {t_data, 3, 3};
    slice_print("dcl: ", t);

    /* 2D slice (jagged). */
    printf("2d:  [");
    for (int i = 0; i < 3; i++) {
        printf("[");
        for (int j = 0; j <= i; j++) {
            printf("%d%s", i + j, j < i ? " " : "");
        }
        printf("]%s", i < 2 ? " " : "");
    }
    printf("]\n");

    free(s.data);
    free(c.data);
    return 0;
}
