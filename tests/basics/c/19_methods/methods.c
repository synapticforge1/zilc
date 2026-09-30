#include <stdio.h>

/* C has no method syntax. Methods are implemented as regular functions
   that take a pointer to the struct as their first parameter. */

typedef struct {
    int width;
    int height;
} Rect;

/* "Method" with a pointer receiver — can mutate the struct. */
int rect_area(const Rect *r) {
    return r->width * r->height;
}

/* "Method" with a value receiver — receives a copy. */
int rect_perim(Rect r) {
    return 2 * r.width + 2 * r.height;
}

int main(void) {
    Rect r = {.width = 10, .height = 5};

    printf("area:  %d\n", rect_area(&r));
    printf("perim: %d\n", rect_perim(r));

    /* Using a pointer to the struct — same results. */
    Rect *rp = &r;
    printf("area:  %d\n", rect_area(rp));
    printf("perim: %d\n", rect_perim(*rp));

    return 0;
}
