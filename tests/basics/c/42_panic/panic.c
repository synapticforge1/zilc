#include <stdio.h>
#include <stdlib.h>

/* C has no `panic` keyword. The idiomatic equivalent is to print an error
   message to stderr and call `abort()` (which raises SIGABRT and produces
   a core dump) or `exit(1)` for a clean non-zero exit. */

int main(void) {
    fprintf(stderr, "panic: a problem\n");
    abort();

    /* This line is unreachable, but illustrates the pattern for
       handling unexpected errors from library calls. */
    FILE *f = fopen("/tmp/file", "w");
    if (f == NULL) {
        perror("panic");
        abort();
    }

    return 0;
}
