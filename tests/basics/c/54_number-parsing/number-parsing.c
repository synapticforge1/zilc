#include <stdio.h>
#include <stdlib.h>

int main(void) {
    const char *bad = "wat";
    char *end;
    double f;
    long i;
    unsigned long u;

    /* Parse float — equivalent to strconv.ParseFloat("1.234", 64). */
    f = strtod("1.234", NULL);
    printf("%g\n", f);

    /* Parse int, auto-detect base — equivalent to ParseInt("123", 0, 64). */
    i = strtol("123", NULL, 0);
    printf("%ld\n", i);

    /* Hex — strtol recognizes 0x prefix. */
    i = strtol("0x1c8", NULL, 0);
    printf("%ld\n", i);

    /* Unsigned — ParseUint("789", 0, 64). */
    u = strtoul("789", NULL, 0);
    printf("%lu\n", u);

    /* Atoi convenience — ParseInt("135", 10, 0). */
    printf("%d\n", atoi("135"));

    /* Parse error — strtol sets end == str when no digits consumed. */
    strtol(bad, &end, 10);
    if (end == bad)
        printf("strconv.Atoi: parsing \"wat\": invalid syntax\n");

    return 0;
}
