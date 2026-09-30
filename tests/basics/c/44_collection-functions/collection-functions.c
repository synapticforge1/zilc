#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>

/* Collection functions for arrays of strings, implemented as standalone
   functions that accept a function pointer for predicate/transform logic. */

typedef bool (*StrPred)(const char *);
typedef void (*StrTransform)(const char *in, char *out, int outsz);

static int index_of(const char **vs, int n, const char *t) {
    for (int i = 0; i < n; i++) {
        if (strcmp(vs[i], t) == 0) return i;
    }
    return -1;
}

static bool include(const char **vs, int n, const char *t) {
    return index_of(vs, n, t) >= 0;
}

static bool any(const char **vs, int n, StrPred f) {
    for (int i = 0; i < n; i++) if (f(vs[i])) return true;
    return false;
}

static bool all(const char **vs, int n, StrPred f) {
    for (int i = 0; i < n; i++) if (!f(vs[i])) return false;
    return true;
}

static int filter(const char **vs, int n, StrPred f, const char **out) {
    int cnt = 0;
    for (int i = 0; i < n; i++) if (f(vs[i])) out[cnt++] = vs[i];
    return cnt;
}

static void map_strs(const char **vs, int n, StrTransform f,
                     char out[][32], int outsz) {
    for (int i = 0; i < n; i++) f(vs[i], out[i], outsz);
}

/* Predicates and transforms. */
static bool has_prefix_p(const char *s) { return s[0] == 'p'; }
static bool contains_e(const char *s)   { return strchr(s, 'e') != NULL; }
static void to_upper(const char *in, char *out, int outsz) {
    int i;
    for (i = 0; in[i] && i < outsz - 1; i++) out[i] = (char)toupper((unsigned char)in[i]);
    out[i] = '\0';
}

static void print_strarray(const char **arr, int n) {
    printf("[");
    for (int i = 0; i < n; i++) printf("%s%s", arr[i], i < n - 1 ? " " : "");
    printf("]\n");
}

int main(void) {
    const char *strs[] = {"peach", "apple", "pear", "plum"};
    int n = 4;

    printf("%d\n", index_of(strs, n, "pear"));
    printf("%s\n", include(strs, n, "grape") ? "true" : "false");
    printf("%s\n", any(strs, n, has_prefix_p) ? "true" : "false");
    printf("%s\n", all(strs, n, has_prefix_p) ? "true" : "false");

    const char *filtered[4];
    int flen = filter(strs, n, contains_e, filtered);
    print_strarray(filtered, flen);

    char mapped[4][32];
    map_strs(strs, n, to_upper, mapped, 32);
    printf("[");
    for (int i = 0; i < n; i++) printf("%s%s", mapped[i], i < n - 1 ? " " : "");
    printf("]\n");

    return 0;
}
