#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void run_and_print(const char *cmd) {
    FILE *f = popen(cmd, "r");
    if (!f) { fprintf(stderr, "popen failed\n"); return; }
    char buf[256];
    while (fgets(buf, sizeof(buf), f))
        printf("%s", buf);
    int rc = pclose(f);
    (void)rc;
}

int main(void) {
    printf("> date\n");
#ifdef _WIN32
    run_and_print("date /t");
#else
    run_and_print("date");
#endif
    printf("\n");

#ifdef _WIN32
    FILE *f2 = popen("date -x 2>&1", "r");
#else
    FILE *f2 = popen("date -x 2>&1", "r");
#endif
    if (f2) {
        int rc = pclose(f2);
        int exit_code = rc;
#ifdef _WIN32
        exit_code = rc;
#else
        if (WIFEXITED(rc)) exit_code = WEXITSTATUS(rc);
#endif
        printf("command exit rc = %d\n\n", exit_code);
    }

    printf("> grep hello\n");
#ifdef _WIN32
    FILE *gf = popen("echo hello grep| findstr hello", "r");
#else
    FILE *gf = popen("echo 'hello grep\ngoodbye grep' | grep hello", "r");
#endif
    if (gf) {
        char buf[256];
        while (fgets(buf, sizeof(buf), gf)) printf("%s", buf);
        pclose(gf);
    }
    printf("\n");

    printf("> ls -a -l -h\n");
#ifdef _WIN32
    run_and_print("dir");
#else
    run_and_print("ls -a -l -h");
#endif

    return 0;
}
