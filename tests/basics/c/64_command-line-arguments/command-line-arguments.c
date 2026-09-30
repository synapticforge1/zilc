#include <stdio.h>

/* argc/argv are the C equivalents of os.Args.
   argv[0] is the program name; argv[1..] are the arguments. */

int main(int argc, char *argv[]) {
    int i;

    /* All arguments including the program name (os.Args). */
    printf("[");
    for (i = 0; i < argc; i++) {
        if (i > 0) printf(" ");
        printf("%s", argv[i]);
    }
    printf("]\n");

    /* Arguments without the program name (os.Args[1:]). */
    printf("[");
    for (i = 1; i < argc; i++) {
        if (i > 1) printf(" ");
        printf("%s", argv[i]);
    }
    printf("]\n");

    /* Third argument (os.Args[3] = argv[3]). */
    if (argc > 3)
        printf("%s\n", argv[3]);

    return 0;
}
