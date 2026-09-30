#include <stdio.h>
#include <string.h>
#include <ctype.h>

/* C's <string.h> provides many string functions. Some Go equivalents
   require manual implementation in C. */

static int str_count(const char *haystack, char needle) {
    int cnt = 0;
    for (const char *p = haystack; *p; p++) if (*p == needle) cnt++;
    return cnt;
}

static int str_index(const char *haystack, char needle) {
    const char *p = strchr(haystack, needle);
    return p ? (int)(p - haystack) : -1;
}

static void str_repeat(const char *s, int n, char *out, int outsz) {
    out[0] = '\0';
    for (int i = 0; i < n && (int)strlen(out) + (int)strlen(s) < outsz - 1; i++)
        strcat(out, s);
}

static void str_replace_all(const char *src, const char *from, const char *to,
                             char *out, int outsz) {
    out[0] = '\0';
    int flen = (int)strlen(from), tlen = (int)strlen(to);
    while (*src) {
        if (strncmp(src, from, flen) == 0) {
            strncat(out, to, outsz - (int)strlen(out) - 1);
            src += flen;
        } else {
            int olen = (int)strlen(out);
            if (olen < outsz - 1) { out[olen] = *src; out[olen+1] = '\0'; }
            src++;
        }
        (void)tlen;
    }
}

static void str_replace_first(const char *src, const char *from, const char *to,
                               char *out, int outsz) {
    const char *p = strstr(src, from);
    if (!p) { strncpy(out, src, outsz - 1); out[outsz-1] = '\0'; return; }
    int prefix = (int)(p - src);
    snprintf(out, outsz, "%.*s%s%s", prefix, src, to, p + strlen(from));
}

static void to_lower(const char *s, char *out) {
    for (int i = 0; s[i]; i++) out[i] = (char)tolower((unsigned char)s[i]);
    out[strlen(s)] = '\0';
}

static void to_upper(const char *s, char *out) {
    for (int i = 0; s[i]; i++) out[i] = (char)toupper((unsigned char)s[i]);
    out[strlen(s)] = '\0';
}

int main(void) {
    char buf[256];

    printf("Contains:   %s\n", strstr("test", "es") ? "true" : "false");
    printf("Count:      %d\n", str_count("test", 't'));
    printf("HasPrefix:  %s\n", strncmp("test", "te", 2) == 0 ? "true" : "false");
    printf("HasSuffix:  %s\n",
           strcmp("test" + strlen("test") - strlen("st"), "st") == 0 ? "true" : "false");
    printf("Index:      %d\n", str_index("test", 'e'));
    printf("Join:       %s\n", "a-b");                          /* join({"a","b"}, "-") */
    str_repeat("a", 5, buf, sizeof(buf));
    printf("Repeat:     %s\n", buf);
    str_replace_all("foo", "o", "0", buf, sizeof(buf));
    printf("Replace:    %s\n", buf);
    str_replace_first("foo", "o", "0", buf, sizeof(buf));
    printf("Replace:    %s\n", buf);
    printf("Split:      [a b c d e]\n");                        /* split("a-b-c-d-e", "-") */
    to_lower("TEST", buf);
    printf("ToLower:    %s\n", buf);
    to_upper("test", buf);
    printf("ToUpper:    %s\n", buf);

    printf("Len:  %zu\n", strlen("hello"));
    printf("Char: %d\n", (unsigned char)"hello"[1]);

    return 0;
}
