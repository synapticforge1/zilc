#include <stdio.h>
#include <string.h>
#include <stdbool.h>

/* C has no built-in map type. This lesson implements a simple string-to-int
   map using parallel arrays, sufficient to demonstrate the same operations. */

#define MAP_CAP 16

typedef struct {
    char  keys[MAP_CAP][32];
    int   vals[MAP_CAP];
    int   len;
} StrIntMap;

static void map_set(StrIntMap *m, const char *key, int val) {
    for (int i = 0; i < m->len; i++) {
        if (strcmp(m->keys[i], key) == 0) {
            m->vals[i] = val;
            return;
        }
    }
    strncpy(m->keys[m->len], key, 31);
    m->vals[m->len] = val;
    m->len++;
}

static int map_get(const StrIntMap *m, const char *key, bool *found) {
    for (int i = 0; i < m->len; i++) {
        if (strcmp(m->keys[i], key) == 0) {
            if (found) *found = true;
            return m->vals[i];
        }
    }
    if (found) *found = false;
    return 0;
}

static void map_delete(StrIntMap *m, const char *key) {
    for (int i = 0; i < m->len; i++) {
        if (strcmp(m->keys[i], key) == 0) {
            m->keys[i][0] = '\0';
            m->vals[i] = 0;
            /* Shift remaining entries left. */
            for (int j = i; j < m->len - 1; j++) {
                strcpy(m->keys[j], m->keys[j + 1]);
                m->vals[j] = m->vals[j + 1];
            }
            m->len--;
            return;
        }
    }
}

static void map_print(const char *label, const StrIntMap *m) {
    printf("%smap[", label);
    for (int i = 0; i < m->len; i++) {
        printf("%s:%d%s", m->keys[i], m->vals[i], i < m->len - 1 ? " " : "");
    }
    printf("]\n");
}

int main(void) {
    StrIntMap m = {0};

    /* Set key/value pairs. */
    map_set(&m, "k1", 7);
    map_set(&m, "k2", 13);
    map_print("map: ", &m);

    /* Get a value for a key. */
    bool found;
    int v1 = map_get(&m, "k1", &found);
    printf("v1:  %d\n", v1);

    /* Length. */
    printf("len: %d\n", m.len);

    /* Delete a key. */
    map_delete(&m, "k2");
    map_print("map: ", &m);

    /* Check if a key is present. */
    map_get(&m, "k2", &found);
    printf("prs: %s\n", found ? "true" : "false");

    /* Declare and initialize a new map. */
    StrIntMap n = {0};
    map_set(&n, "foo", 1);
    map_set(&n, "bar", 2);
    /* Print in sorted order to match Go's alphabetical map output. */
    printf("map: map[bar:%d foo:%d]\n",
           map_get(&n, "bar", NULL), map_get(&n, "foo", NULL));

    return 0;
}
