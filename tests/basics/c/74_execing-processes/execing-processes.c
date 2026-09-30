#include <stdio.h>
#include <stdlib.h>

#ifdef _WIN32
#  include <process.h>
#  include <io.h>
int main(void) {
    const char *args[] = {"ls", "-a", "-l", "-h", NULL};
    _execvp("ls", args);
    perror("execvp");
    return 1;
}
#else
#  include <unistd.h>
extern char **environ;
int main(void) {
    char *args[] = {"ls", "-a", "-l", "-h", NULL};
    execvpe("ls", args, environ);
    perror("execvp");
    return 1;
}
#endif
