#include <stdio.h>
#include <stdlib.h>

/* C has no `defer` keyword. Cleanup is performed manually after the work
   is done, or via `goto` to a cleanup label. This example mirrors the
   Go defer example: create a file, write to it, then close it. */

static FILE *create_file(const char *path) {
    printf("creating\n");
    FILE *f = fopen(path, "w");
    if (f == NULL) {
        perror("create_file");
        exit(1);
    }
    return f;
}

static void write_file(FILE *f) {
    printf("writing\n");
    fprintf(f, "data\n");
}

static void close_file(FILE *f) {
    printf("closing\n");
    if (fclose(f) != 0) {
        perror("close_file");
        exit(1);
    }
}

int main(void) {
    /* In C, cleanup is called explicitly after all work is done,
       producing the same create → write → close ordering as Go's defer. */
    FILE *f = create_file("./tmp/defer.txt");
    write_file(f);
    close_file(f);

    return 0;
}
