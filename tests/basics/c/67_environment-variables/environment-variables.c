#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#  include <stdlib.h>
   /* _putenv_s is Windows-specific */
   static int setenv_compat(const char *name, const char *value) {
       char buf[512];
       snprintf(buf, sizeof(buf), "%s=%s", name, value);
       return _putenv(buf);
   }
   extern char **_environ;
#  define ENVIRON _environ
#else
#  include <unistd.h>
   static int setenv_compat(const char *name, const char *value) {
       return setenv(name, value, 1);
   }
   extern char **environ;
#  define ENVIRON environ
#endif

int main(void) {
    char **ep;
    char key[256];
    int i;

    /* Set FOO=1 and get it back. */
    setenv_compat("FOO", "1");
    printf("FOO: %s\n", getenv("FOO") ? getenv("FOO") : "");
    printf("BAR: %s\n", getenv("BAR") ? getenv("BAR") : "");
    printf("\n");

    /* List all environment variable keys. */
    for (ep = ENVIRON; ep && *ep; ep++) {
        const char *eq = strchr(*ep, '=');
        if (!eq) { printf("%s\n", *ep); continue; }
        i = (int)(eq - *ep);
        strncpy(key, *ep, i < (int)sizeof(key)-1 ? i : (int)sizeof(key)-1);
        key[i < (int)sizeof(key)-1 ? i : (int)sizeof(key)-1] = '\0';
        printf("%s\n", key);
    }

    return 0;
}
