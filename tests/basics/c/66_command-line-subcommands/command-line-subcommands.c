#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* Manual subcommand dispatch with per-subcommand flag parsing. */

static int get_bool_flag(int argc, char **argv, const char *name) {
    int i;
    size_t nlen = strlen(name);
    for (i = 0; i < argc; i++) {
        if (argv[i][0] != '-') break;  /* stop at first non-flag */
        const char *f = argv[i] + 1;
        if (*f == '-') f++;
        if (strncmp(f, name, nlen) == 0 &&
            (f[nlen] == '\0' || f[nlen] == '='))
            return 1;
    }
    return 0;
}

static const char *get_str_flag(int argc, char **argv,
                                const char *name, const char *def) {
    int i;
    size_t nlen = strlen(name);
    for (i = 0; i < argc; i++) {
        if (argv[i][0] != '-') break;
        const char *f = argv[i] + 1;
        if (*f == '-') f++;
        if (strncmp(f, name, nlen) == 0) {
            if (f[nlen] == '=') return f + nlen + 1;
            if (f[nlen] == '\0' && i+1 < argc) return argv[i+1];
        }
    }
    return def;
}

static int get_int_flag(int argc, char **argv, const char *name, int def) {
    const char *v = get_str_flag(argc, argv, name, NULL);
    return v ? atoi(v) : def;
}

static void print_tail(int argc, char **argv) {
    int i, first = 1;
    printf("[");
    for (i = 0; i < argc; i++) {
        if (argv[i][0] == '-') continue;
        if (!first) printf(" ");
        printf("%s", argv[i]);
        first = 0;
    }
    printf("]");
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "expected 'foo' or 'bar' subcommands\n");
        return 1;
    }

    /* argv[2..] are the flags and args for the subcommand. */
    int sub_argc = argc - 2;
    char **sub_argv = argv + 2;

    if (strcmp(argv[1], "foo") == 0) {
        int enable      = get_bool_flag(sub_argc, sub_argv, "enable");
        const char *name = get_str_flag(sub_argc, sub_argv, "name", "");
        printf("subcommand 'foo'\n");
        printf("  enable: %s\n", enable ? "true" : "false");
        printf("  name: %s\n", name);
        printf("  tail: ");
        print_tail(sub_argc, sub_argv);
        printf("\n");
    } else if (strcmp(argv[1], "bar") == 0) {
        int level = get_int_flag(sub_argc, sub_argv, "level", 0);
        printf("subcommand 'bar'\n");
        printf("  level: %d\n", level);
        printf("  tail: ");
        print_tail(sub_argc, sub_argv);
        printf("\n");
    } else {
        fprintf(stderr, "expected 'foo' or 'bar' subcommands\n");
        return 1;
    }

    return 0;
}
