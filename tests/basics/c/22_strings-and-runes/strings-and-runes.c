#include <stdio.h>
#include <string.h>
#include <stdint.h>

static uint32_t utf8_decode(const unsigned char *s, int i, int *width) {
    unsigned char c = s[i];
    if (c < 0x80) { *width = 1; return c; }
    if (c < 0xE0) { *width = 2; return ((uint32_t)(c & 0x1F) << 6) | (s[i+1] & 0x3F); }
    if (c < 0xF0) { *width = 3; return ((uint32_t)(c & 0x0F) << 12) | ((uint32_t)(s[i+1] & 0x3F) << 6) | (s[i+2] & 0x3F); }
    *width = 4;
    return ((uint32_t)(c & 0x07) << 18) | ((uint32_t)(s[i+1] & 0x3F) << 12) | ((uint32_t)(s[i+2] & 0x3F) << 6) | (s[i+3] & 0x3F);
}

static void print_utf8(uint32_t cp) {
    if (cp < 0x80) { putchar((int)cp); }
    else if (cp < 0x800) { putchar(0xC0 | (cp >> 6)); putchar(0x80 | (cp & 0x3F)); }
    else if (cp < 0x10000) {
        putchar(0xE0 | (cp >> 12));
        putchar(0x80 | ((cp >> 6) & 0x3F));
        putchar(0x80 | (cp & 0x3F));
    } else {
        putchar(0xF0 | (cp >> 18));
        putchar(0x80 | ((cp >> 12) & 0x3F));
        putchar(0x80 | ((cp >> 6) & 0x3F));
        putchar(0x80 | (cp & 0x3F));
    }
}

static void examine_rune(uint32_t r) {
    if (r == 't') printf("found tee\n");
    else if (r == 0x0E2A) printf("found so sua\n");
}

int main(void) {
    const char *s = "สวัสดี";
    int len = (int)strlen(s);

    printf("Len: %d\n", len);

    for (int i = 0; i < len; i++)
        printf("%x ", (unsigned char)s[i]);
    printf("\n");

    int rune_count = 0;
    for (int i = 0; i < len; ) {
        int w;
        utf8_decode((const unsigned char *)s, i, &w);
        rune_count++;
        i += w;
    }
    printf("Rune count: %d\n", rune_count);

    for (int i = 0; i < len; ) {
        int w;
        uint32_t r = utf8_decode((const unsigned char *)s, i, &w);
        printf("U+%04X '", r);
        print_utf8(r);
        printf("' starts at %d\n", i);
        i += w;
    }

    printf("\nUsing DecodeRuneInString\n");
    for (int i = 0; i < len; ) {
        int w;
        uint32_t r = utf8_decode((const unsigned char *)s, i, &w);
        printf("U+%04X '", r);
        print_utf8(r);
        printf("' starts at %d\n", i);
        examine_rune(r);
        i += w;
    }

    return 0;
}
