#include <stdio.h>
#include <string.h>

int main(void) {
    FILE *f;
    char buf[64];
    size_t n;
    long off;

    /* Read entire file into memory (ioutil.ReadFile equivalent). */
    f = fopen("./tmp/dat.txt", "r");
    if (!f) { perror("fopen"); return 1; }
    while (fgets(buf, sizeof(buf), f))
        printf("%s", buf);
    fclose(f);

    /* Open for granular reading. */
    f = fopen("./tmp/dat.txt", "rb");
    if (!f) { perror("fopen"); return 1; }

    /* Read first 5 bytes. */
    n = fread(buf, 1, 5, f);
    printf("%zu bytes: %.*s\n", n, (int)n, buf);

    /* Seek to offset 6 and read 2 bytes. */
    fseek(f, 6, SEEK_SET);
    off = ftell(f);
    n = fread(buf, 1, 2, f);
    printf("%zu bytes @ %ld: %.*s\n", n, off, (int)n, buf);

    /* Seek to offset 6 again and read at least 2 bytes (ReadAtLeast). */
    fseek(f, 6, SEEK_SET);
    off = ftell(f);
    n = fread(buf, 1, 2, f);
    printf("%zu bytes @ %ld: %.*s\n", n, off, (int)n, buf);

    /* Rewind and buffered peek of first 5 bytes. */
    fseek(f, 0, SEEK_SET);
    n = fread(buf, 1, 5, f);
    printf("5 bytes: %.*s\n", (int)n, buf);

    fclose(f);
    return 0;
}
