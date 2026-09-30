#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* C structs are typed collections of fields, identical in purpose to Go structs. */

typedef struct {
    char name[64];
    int  age;
} Person;

/* Constructor function returning a heap-allocated Person. */
Person *new_person(const char *name) {
    Person *p = malloc(sizeof(Person));
    strncpy(p->name, name, 63);
    p->age = 42;
    return p;
}

int main(void) {
    /* Create a struct by value. */
    Person bob = {"Bob", 20};
    printf("{%s %d}\n", bob.name, bob.age);

    /* Initialize with named fields (designated initializers, C99). */
    Person alice = {.name = "Alice", .age = 30};
    printf("{%s %d}\n", alice.name, alice.age);

    /* Omitted fields default to zero. */
    Person fred = {.name = "Fred"};
    printf("{%s %d}\n", fred.name, fred.age);

    /* Pointer to a struct (prefix notation matches Go's `&{...}`). */
    Person ann = {.name = "Ann", .age = 40};
    printf("&{%s %d}\n", ann.name, ann.age);

    /* Constructor returning a pointer. */
    Person *jon = new_person("Jon");
    printf("&{%s %d}\n", jon->name, jon->age);

    /* Access struct fields with `.`. */
    Person sean = {.name = "Sean", .age = 50};
    printf("%s\n", sean.name);

    /* Pointer auto-dereferences with `->`. */
    Person *sp = &sean;
    printf("%d\n", sp->age);

    /* Structs are mutable. */
    sp->age = 51;
    printf("%d\n", sp->age);

    free(jon);
    return 0;
}
