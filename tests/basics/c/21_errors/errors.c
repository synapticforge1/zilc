#include <stdio.h>
#include <string.h>

/* C uses integer return codes and output parameters for error handling.
   By convention, 0 means success and a negative value signals an error. */

/* f1: returns the result via output parameter; returns 0 on success, -1 on error. */
static int f1(int arg, int *result, char *errmsg) {
    if (arg == 42) {
        *result = -1;
        strcpy(errmsg, "can't work with 42");
        return -1;
    }
    *result = arg + 3;
    errmsg[0] = '\0';
    return 0;
}

/* Custom "error type" for f2, carrying extra context. */
typedef struct {
    int  arg;
    char prob[64];
} ArgError;

static int f2(int arg, int *result, ArgError *err) {
    if (arg == 42) {
        *result = -1;
        err->arg = arg;
        strcpy(err->prob, "can't work with it");
        return -1;
    }
    *result = arg + 3;
    return 0;
}

int main(void) {
    int inputs[] = {7, 42};

    for (int i = 0; i < 2; i++) {
        int r;
        char errmsg[64];
        if (f1(inputs[i], &r, errmsg) != 0) {
            printf("f1 failed: %s\n", errmsg);
        } else {
            printf("f1 worked: %d\n", r);
        }
    }

    for (int i = 0; i < 2; i++) {
        int r;
        ArgError err = {0};
        if (f2(inputs[i], &r, &err) != 0) {
            printf("f2 failed: %d - %s\n", err.arg, err.prob);
        } else {
            printf("f2 worked: %d\n", r);
        }
    }

    /* Access the custom error's fields directly. */
    int r;
    ArgError ae = {0};
    f2(42, &r, &ae);
    printf("%d\n", ae.arg);
    printf("%s\n", ae.prob);

    return 0;
}
