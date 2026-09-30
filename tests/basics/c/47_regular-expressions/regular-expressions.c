#include <stdio.h>
#include <string.h>
#include <regex.h>

/* C uses POSIX regex.h for regular expressions (available on Linux/Mac
   and via Zig's libc on Windows). The API uses regcomp/regexec. */

static void print_bool(int v) { printf("%s\n", v ? "true" : "false"); }

int main(void) {
    regex_t r;
    regmatch_t m[4];
    const char *input;
    int rc;

    /* Test whether a pattern matches a string. */
    regcomp(&r, "p([a-z]+)ch", REG_EXTENDED);
    rc = regexec(&r, "peach", 0, NULL, 0);
    print_bool(rc == 0);
    regfree(&r);

    /* Compile once, use many times. */
    regcomp(&r, "p([a-z]+)ch", REG_EXTENDED);
    rc = regexec(&r, "peach", 0, NULL, 0);
    print_bool(rc == 0);

    /* Find the first match. */
    input = "peach punch";
    if (regexec(&r, input, 1, m, 0) == 0) {
        printf("%.*s\n", (int)(m[0].rm_eo - m[0].rm_so), input + m[0].rm_so);
    }

    /* Start and end indexes of the first match. */
    if (regexec(&r, input, 1, m, 0) == 0) {
        printf("[%d %d]\n", (int)m[0].rm_so, (int)m[0].rm_eo);
    }

    /* Whole match and first submatch. */
    if (regexec(&r, input, 2, m, 0) == 0) {
        printf("[%.*s %.*s]\n",
               (int)(m[0].rm_eo - m[0].rm_so), input + m[0].rm_so,
               (int)(m[1].rm_eo - m[1].rm_so), input + m[1].rm_so);
    }

    /* Submatch indexes. */
    if (regexec(&r, input, 2, m, 0) == 0) {
        printf("[%d %d %d %d]\n",
               (int)m[0].rm_so, (int)m[0].rm_eo,
               (int)m[1].rm_so, (int)m[1].rm_eo);
    }

    /* Find all matches. */
    {
        const char *all = "peach punch pinch";
        const char *p = all;
        int first = 1;
        printf("[");
        while (regexec(&r, p, 1, m, 0) == 0) {
            if (!first) printf(" ");
            printf("%.*s", (int)(m[0].rm_eo - m[0].rm_so), p + m[0].rm_so);
            p += m[0].rm_eo;
            first = 0;
        }
        printf("]\n");
    }

    /* All match + submatch indexes. */
    {
        const char *all = "peach punch pinch";
        const char *p = all;
        printf("[");
        int first = 1;
        while (regexec(&r, p, 2, m, 0) == 0) {
            if (!first) printf(" ");
            printf("[%d %d %d %d]",
                   (int)(p - all) + m[0].rm_so, (int)(p - all) + m[0].rm_eo,
                   (int)(p - all) + m[1].rm_so, (int)(p - all) + m[1].rm_eo);
            p += m[0].rm_eo;
            first = 0;
        }
        printf("]\n");
    }

    /* Limit to first two matches. */
    {
        const char *all = "peach punch pinch";
        const char *p = all;
        int cnt = 0;
        printf("[");
        while (cnt < 2 && regexec(&r, p, 1, m, 0) == 0) {
            if (cnt > 0) printf(" ");
            printf("%.*s", (int)(m[0].rm_eo - m[0].rm_so), p + m[0].rm_so);
            p += m[0].rm_eo;
            cnt++;
        }
        printf("]\n");
    }

    /* Match against a byte buffer. */
    rc = regexec(&r, "peach", 0, NULL, 0);
    print_bool(rc == 0);

    /* Print the pattern string. */
    printf("p([a-z]+)ch\n");

    /* Replace first match with a literal. */
    {
        const char *src = "a peach";
        char out[64];
        if (regexec(&r, src, 1, m, 0) == 0) {
            int before = (int)m[0].rm_so;
            snprintf(out, sizeof(out), "%.*s<fruit>%s",
                     before, src, src + m[0].rm_eo);
            printf("%s\n", out);
        }
    }

    /* Transform matched text to upper-case equivalent. */
    {
        const char *src = "a peach";
        char out[64];
        if (regexec(&r, src, 1, m, 0) == 0) {
            int i;
            int before = (int)m[0].rm_so;
            int mlen   = (int)(m[0].rm_eo - m[0].rm_so);
            snprintf(out, sizeof(out), "%.*s", before, src);
            for (i = 0; i < mlen; i++) {
                char c = src[m[0].rm_so + i];
                out[before + i] = (char)(c >= 'a' && c <= 'z' ? c - 32 : c);
            }
            out[before + mlen] = '\0';
            strncat(out, src + m[0].rm_eo, sizeof(out) - strlen(out) - 1);
            printf("%s\n", out);
        }
    }

    regfree(&r);
    return 0;
}
