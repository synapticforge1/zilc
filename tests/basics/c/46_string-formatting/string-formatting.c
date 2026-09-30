#include <stdio.h>

int main(void) {
    int px = 1;
    int py = 2;
    char buf[64];
    const char *hs;
    char b[33];
    unsigned int n;
    int pos;
    int k;

    /* Print struct-style values (x=1, y=2). */
    printf("{%d %d}\n", px, py);
    printf("{x:%d y:%d}\n", px, py);
    printf("main.point{x:%d, y:%d}\n", px, py);
    printf("main.point\n");

    /* Boolean. */
    printf("%s\n", 1 ? "true" : "false");

    /* Integer. */
    printf("%d\n", 123);

    /* Binary: 14 = 1110. Build the string manually. */
    n = 14u;
    b[32] = '\0';
    pos = 32;
    while (n) { b[--pos] = (char)('0' + (n & 1u)); n >>= 1; }
    printf("%s\n", b + pos);

    /* Character from integer (33 = '!'). */
    printf("%c\n", (char)33);

    /* Hex. */
    printf("%x\n", 456);

    /* Float. */
    double f = 78.9; printf("%f\n", f);

    /* Scientific notation. */
    double e = 123400000.0; printf("%e\n", e);
    printf("%E\n", e);

    /* String with embedded double-quotes. */
    printf("%s\n", "\"string\"");

    /* Quoted string — output: "\"string\"" */
    printf("\"\\\"string\\\"\"\n");

    /* Hex-encode each byte of "hex this". */
    hs = "hex this";
    for (k = 0; hs[k] != '\0'; k++) {
        printf("%02x", (unsigned char)hs[k]);
    }
    printf("\n");

    /* Pointer. */
    printf("%p\n", (void *)&px);

    /* Width-padded integers. */
    printf("|%6d|%6d|\n", 12, 345);

    /* Width + precision for floats. */
    printf("|%6.2f|%6.2f|\n", 1.2, 3.45);

    /* Left-justified floats. */
    printf("|%-6.2f|%-6.2f|\n", 1.2, 3.45);

    /* Width-padded strings. */
    printf("|%6s|%6s|\n", "foo", "b");

    /* Left-justified strings. */
    printf("|%-6s|%-6s|\n", "foo", "b");

    /* snprintf to buffer (Sprintf equivalent). */
    snprintf(buf, sizeof(buf), "a %s", "string");
    printf("%s\n", buf);

    /* fprintf to stderr (Fprintf equivalent). */
    fprintf(stderr, "an %s\n", "error");

    return 0;
}
