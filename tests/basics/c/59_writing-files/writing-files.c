#include <stdio.h>
#include <string.h>

int main(void) {
    FILE *f;
    size_t n;

    /* Write entire byte slice to file (ioutil.WriteFile equivalent). */
    f = fopen("./tmp/dat1.txt", "wb");
    if (!f) { perror("fopen dat1"); return 1; }
    fwrite("hello\ngo\n", 1, 9, f);
    fclose(f);

    /* Open for granular writing (os.Create equivalent). */
    f = fopen("./tmp/dat2.txt", "wb");
    if (!f) { perror("fopen dat2"); return 1; }

    /* Write byte slice. */
    n = fwrite("\x73\x6f\x6d\x65\x0a", 1, 5, f);
    printf("wrote %zu bytes\n", n);

    /* Write string (WriteString equivalent). */
    n = fwrite("writes\n", 1, 7, f);
    printf("wrote %zu bytes\n", n);

    /* Flush to stable storage (Sync equivalent). */
    fflush(f);

    /* Buffered write (bufio.Writer equivalent). */
    n = fwrite("buffered\n", 1, 9, f);
    printf("wrote %zu bytes\n", n);

    /* Flush buffered writes. */
    fflush(f);
    fclose(f);

    return 0;
}
