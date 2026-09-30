#include <stdio.h>

/* C has no built-in XML library. We generate and parse XML manually
   using printf, reproducing Go's xml.MarshalIndent output exactly.
   prefix=" ", indent="  " (two spaces per level). */

typedef struct {
    int id;
    const char *name;
    const char *origin[4];
    int num_origins;
} Plant;

static void print_plant_xml(const Plant *p, int level) {
    int n = 1 + level * 2;  /* prefix(1) + level*indent(2) */
    int i;
    printf("%*s<plant id=\"%d\">\n", n, "", p->id);
    printf("%*s  <name>%s</name>\n", n, "", p->name);
    for (i = 0; i < p->num_origins; i++)
        printf("%*s  <origin>%s</origin>\n", n, "", p->origin[i]);
    printf("%*s</plant>\n", n, "");
}

static void plant_string(const Plant *p) {
    int i;
    printf("Plant id=%d, name=%s, origin=[", p->id, p->name);
    for (i = 0; i < p->num_origins; i++) {
        if (i) printf(" ");
        printf("%s", p->origin[i]);
    }
    printf("]\n");
}

int main(void) {
    Plant coffee = {27, "Coffee", {"Ethiopia", "Brazil"}, 2};
    Plant tomato = {81, "Tomato", {"Mexico", "California"}, 2};

    /* MarshalIndent(coffee, " ", "  ") */
    print_plant_xml(&coffee, 0);

    /* xml.Header + MarshalIndent(coffee, " ", "  ") */
    printf("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    print_plant_xml(&coffee, 0);

    /* Unmarshal then print via Plant.String() */
    plant_string(&coffee);

    /* Nesting: MarshalIndent(nesting, " ", "  ") */
    printf(" <nesting>\n");
    printf("   <parent>\n");
    printf("     <child>\n");
    print_plant_xml(&coffee, 3);
    print_plant_xml(&tomato, 3);
    printf("     </child>\n");
    printf("   </parent>\n");
    printf(" </nesting>\n");

    return 0;
}
