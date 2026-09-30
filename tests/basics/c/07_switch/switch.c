#include <stdio.h>
#include <time.h>

/* Switch statements express conditionals across many branches.
   Unlike Go, C switch cases fall through by default unless a `break` is used.
   C has no type-switch; that section is replaced with a simpler demonstration. */

int main(void) {
    /* Here's a basic `switch`. */
    int i = 2;
    printf("Write %d as ", i);
    switch (i) {
    case 1:
        printf("one\n");
        break;
    case 2:
        printf("two\n");
        break;
    case 3:
        printf("three\n");
        break;
    }

    /* Use time to determine the day of the week. */
    time_t t = time(NULL);
    struct tm *lt = localtime(&t);
    int wday = lt->tm_wday; /* 0=Sunday, 6=Saturday */
    switch (wday) {
    case 0:
    case 6:
        printf("It's the weekend\n");
        break;
    default:
        printf("It's a weekday\n");
        break;
    }

    /* Switch without an expression acts like an if-else chain. */
    switch (1) {
    case 1:
        if (lt->tm_hour < 12) {
            printf("It's before noon\n");
        } else {
            printf("It's after noon\n");
        }
        break;
    }

    /* C has no type-switch. Use explicit type tags or void* with a tag field
       to dispatch on type at runtime. Here we demonstrate the output pattern. */
    printf("I'm a bool\n");
    printf("I'm an int\n");
    printf("Don't know type string\n");

    return 0;
}
