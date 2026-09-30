#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

#ifdef _WIN32
#  include <direct.h>
#  define MKDIR(p) _mkdir(p)
#else
#  include <sys/stat.h>
#  include <unistd.h> /* zilc: rmdir */
#  define MKDIR(p) mkdir(p, 0700)
#endif

int main(void) {
    const char *tmp;
    char fname[512], dname[512], fname2[512];
    FILE *f;

    /* Find the system temp directory. */
    tmp = getenv("TMPDIR");
    if (!tmp) tmp = getenv("TMP");
    if (!tmp) tmp = getenv("TEMP");
    if (!tmp) tmp = "/tmp";

    /* Create a unique temp file name (ioutil.TempFile equivalent). */
    srand((unsigned int)time(NULL) ^ (unsigned int)(size_t)&tmp);
    snprintf(fname, sizeof(fname), "%s/sample%06d", tmp, rand() % 1000000);
    f = fopen(fname, "wb");
    printf("Temp file name: %s\n", fname);
    fwrite("\x01\x02\x03\x04", 1, 4, f);
    fclose(f);
    remove(fname);

    /* Create a unique temp directory (ioutil.TempDir equivalent). */
    snprintf(dname, sizeof(dname), "%s/sampledir%06d", tmp, rand() % 1000000);
    MKDIR(dname);
    printf("Temp dir name: %s\n", dname);

    /* Write a file inside the temp directory. */
    snprintf(fname2, sizeof(fname2), "%s/file1", dname);
    f = fopen(fname2, "wb");
    if (f) { fwrite("\x01\x02", 1, 2, f); fclose(f); remove(fname2); }
    rmdir(dname);

    return 0;
}
