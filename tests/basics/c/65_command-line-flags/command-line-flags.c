#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* Manual flag parsing: supports -flag=value and -flag value forms.
   Booleans are set by presence of -flag (no value). */

static const char *get_flag_str(int argc, char **argv,
                                const char *name, const char *def) {
    int i;
    size_t nlen = strlen(name);
    for (i = 1; i < argc; i++) {
        if (argv[i][0] != '-') continue;
        const char *f = argv[i] + 1;
        if (*f == '-') f++;  /* allow -- prefix */
        if (strncmp(f, name, nlen) == 0) {
            if (f[nlen] == '=') return f + nlen + 1;
            if (f[nlen] == '\0' && i+1 < argc && argv[i+1][0] != '-')
                return argv[i+1];
        }
    }
    return def;
}

static int get_flag_int(int argc, char **argv, const char *name, int def) {
    const char *v = get_flag_str(argc, argv, name, NULL);
    return v ? atoi(v) : def;
}

static int get_flag_bool(int argc, char **argv, const char *name) {
    int i;
    size_t nlen = strlen(name);
    for (i = 1; i < argc; i++) {
        if (argv[i][0] != '-') continue;
        const char *f = argv[i] + 1;
        if (*f == '-') f++;
        if (strncmp(f, name, nlen) == 0 &&
            (f[nlen] == '\0' || f[nlen] == '='))
            return 1;
    }
    return 0;
}

static void print_tail(int argc, char **argv) {
    int i, first = 1;
    int past_flags = 0;
    printf("[");
    for (i = 1; i < argc; i++) {
        if (!past_flags && argv[i][0] == '-') continue;
        past_flags = 1;
        if (!first) printf(" ");
        printf("%s", argv[i]);
        first = 0;
    }
    printf("]");
}

int main(int argc, char *argv[]) {
    const char *word = get_flag_str(argc, argv, "word", "foo");
    int numb         = get_flag_int(argc, argv, "numb", 42);
    int fork         = get_flag_bool(argc, argv, "fork");
    const char *svar = get_flag_str(argc, argv, "svar", "bar");

    printf("word: %s\n", word);
    printf("numb: %d\n", numb);
    printf("fork: %s\n", fork ? "true" : "false");
    printf("svar: %s\n", svar);
    printf("tail: ");
    print_tail(argc, argv);
    printf("\n");

    return 0;
}
