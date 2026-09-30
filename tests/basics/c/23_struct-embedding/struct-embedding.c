#include <stdio.h>

typedef struct {
    int num;
} base;

typedef struct {
    base base;
    const char *str;
} container;

static void base_describe(const base *b, char *out, int size) {
    snprintf(out, size, "base with num=%d", b->num);
}

int main(void) {
    container co;
    co.base.num = 1;
    co.str = "some name";

    printf("co={num: %d, str: %s}\n", co.base.num, co.str);
    printf("also num: %d\n", co.base.num);

    char desc[64];
    base_describe(&co.base, desc, sizeof(desc));
    printf("describe: %s\n", desc);
    printf("describer: %s\n", desc);

    return 0;
}
