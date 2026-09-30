#include <stdio.h>
#include <ctype.h>
#include <string.h>

/* Line filter: read stdin line by line and write each line uppercased. */

int main(void) {
    char line[4096];

    while (fgets(line, sizeof(line), stdin)) {
        size_t i;
        /* Strip trailing newline before uppercasing, then re-add. */
        for (i = 0; line[i] != '\0'; i++)
            line[i] = (char)toupper((unsigned char)line[i]);
        printf("%s", line);
    }

    if (ferror(stdin)) {
        fprintf(stderr, "error: reading stdin\n");
        return 1;
    }

    return 0;
}
