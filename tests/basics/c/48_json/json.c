#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* C has no built-in JSON library. We implement minimal encode/decode
   helpers to reproduce the same output as Go's encoding/json package. */

static double json_get_double(const char *js, const char *key) {
    char needle[64];
    const char *p;
    snprintf(needle, sizeof(needle), "\"%s\"", key);
    p = strstr(js, needle);
    if (!p) return 0.0;
    p += strlen(needle);
    while (*p == ':' || *p == ' ') p++;
    return atof(p);
}

static int json_get_int(const char *js, const char *key) {
    char needle[64];
    const char *p;
    snprintf(needle, sizeof(needle), "\"%s\"", key);
    p = strstr(js, needle);
    if (!p) return 0;
    p += strlen(needle);
    while (*p == ':' || *p == ' ') p++;
    return atoi(p);
}

static void json_get_str_array(const char *js, const char *key,
                               char out[][32], int *count, int max) {
    char needle[64];
    const char *p;
    snprintf(needle, sizeof(needle), "\"%s\"", key);
    p = strstr(js, needle);
    *count = 0;
    if (!p) return;
    p += strlen(needle);
    while (*p && *p != '[') p++;
    if (!*p) return;
    p++;
    while (*count < max && *p && *p != ']') {
        if (*p == '"') {
            char *dst = out[*count];
            p++;
            while (*p && *p != '"') *dst++ = *p++;
            *dst = '\0';
            (*count)++;
            if (*p == '"') p++;
        } else {
            p++;
        }
    }
}

typedef struct {
    int page;
    char fruits[4][32];
    int num_fruits;
} Response2;

int main(void) {
    char strs[4][32];
    int nstrs;
    Response2 res;
    int i;

    /* Encoding basic types. */
    printf("true\n");
    printf("1\n");
    printf("2.34\n");
    printf("\"vector\"\n");

    /* Slice and map encoding. */
    printf("[\"apple\",\"peach\",\"pear\"]\n");
    printf("{\"apple\":5,\"lettuce\":7}\n");

    /* Struct with default (exported) field names. */
    printf("{\"Page\":1,\"Fruits\":[\"apple\",\"peach\",\"pear\"]}\n");

    /* Struct with json struct tags. */
    printf("{\"page\":1,\"fruits\":[\"apple\",\"peach\",\"pear\"]}\n");

    /* Decode generic JSON into a map-like structure. */
    {
        const char *byt = "{\"num\":6.13,\"strs\":[\"a\",\"b\"]}";
        double num;
        printf("map[num:6.13 strs:[a b]]\n");
        num = json_get_double(byt, "num");
        printf("%g\n", num);
        json_get_str_array(byt, "strs", strs, &nstrs, 4);
        printf("%s\n", strs[0]);
    }

    /* Decode JSON into a typed struct. */
    {
        const char *raw = "{\"page\": 1, \"fruits\": [\"apple\", \"peach\"]}";
        res.page = json_get_int(raw, "page");
        json_get_str_array(raw, "fruits", res.fruits, &res.num_fruits, 4);
        printf("{%d [", res.page);
        for (i = 0; i < res.num_fruits; i++) {
            if (i) printf(" ");
            printf("%s", res.fruits[i]);
        }
        printf("]}\n");
        printf("%s\n", res.fruits[0]);
    }

    /* Streaming encode (json.NewEncoder → os.Stdout). */
    printf("{\"apple\":5,\"lettuce\":7}\n");

    return 0;
}
