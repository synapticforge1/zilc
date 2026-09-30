#include <stdio.h>

typedef struct {
    int arg;
    const char *message;
} arg_error;

static int f(int arg, int *result, arg_error *out_err) {
    if (arg == 42) {
        if (out_err) {
            out_err->arg = arg;
            out_err->message = "can't work with it";
        }
        *result = -1;
        return 1;
    }
    *result = arg + 3;
    return 0;
}

int main(void) {
    int result;
    arg_error ae;
    int err = f(42, &result, &ae);
    if (err) {
        printf("%d\n", ae.arg);
        printf("%s\n", ae.message);
    } else {
        printf("err doesn't match argError\n");
    }
    return 0;
}
