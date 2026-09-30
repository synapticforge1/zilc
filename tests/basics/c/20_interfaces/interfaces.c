#include <stdio.h>
#include <math.h>

/* C has no interfaces. The idiomatic equivalent is a vtable: a struct of
   function pointers that implements the required operations. Each concrete
   type provides its own function implementations. */

/* "Interface" — a struct of function pointers. */
typedef struct {
    double (*area)(const void *self);
    double (*perim)(const void *self);
    void   (*print)(const void *self);
} Geometry;

/* ---- Rect ---- */
typedef struct { double width, height; } Rect;

static double rect_area(const void *self) {
    const Rect *r = self;
    return r->width * r->height;
}
static double rect_perim(const void *self) {
    const Rect *r = self;
    return 2 * r->width + 2 * r->height;
}
static void rect_print(const void *self) {
    const Rect *r = self;
    printf("{%.0f %.0f}\n", r->width, r->height);
}
static const Geometry rect_vtable = {rect_area, rect_perim, rect_print};

/* ---- Circle ---- */
typedef struct { double radius; } Circle;

static double circle_area(const void *self) {
    const Circle *c = self;
    return M_PI * c->radius * c->radius;
}
static double circle_perim(const void *self) {
    const Circle *c = self;
    return 2 * M_PI * c->radius;
}
static void circle_print(const void *self) {
    const Circle *c = self;
    printf("{%.0f}\n", c->radius);
}
static const Geometry circle_vtable = {circle_area, circle_perim, circle_print};

/* Generic measure function — works on any Geometry + data pair. */
static void measure(const Geometry *g, const void *data) {
    g->print(data);
    printf("%.14g\n", g->area(data));
    printf("%.14g\n", g->perim(data));
}

int main(void) {
    Rect   r = {3.0, 4.0};
    Circle c = {5.0};

    measure(&rect_vtable,   &r);
    measure(&circle_vtable, &c);

    return 0;
}
