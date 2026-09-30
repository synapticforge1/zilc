#include <stdio.h>
#include <setjmp.h>

static jmp_buf panic_env;
static const char *panic_msg;

static void may_panic(void) {
    panic_msg = "a problem";
    longjmp(panic_env, 1);
}

int main(void) {
    if (setjmp(panic_env) != 0) {
        printf("Recovered. Error:\n %s\n", panic_msg);
        return 0;
    }

    may_panic();

    printf("After mayPanic()\n");
    return 0;
}
