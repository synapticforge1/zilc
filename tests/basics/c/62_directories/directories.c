#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <dirent.h>
#include <sys/stat.h>

#ifdef _WIN32
#  include <direct.h>
#  define MKDIR(p)  _mkdir(p)
#  define CHDIR(p)  _chdir(p)
#else
#  include <unistd.h>
#  define MKDIR(p)  mkdir(p, 0755)
#  define CHDIR(p)  chdir(p)
#endif

static void create_file(const char *name) {
    FILE *f = fopen(name, "wb");
    if (f) fclose(f);
}

/* Collect and sort directory entries, then print them. */
static void list_dir(const char *path) {
    DIR *d = opendir(path);
    struct dirent *e;
    char names[64][256];
    int count = 0, i, j;

    if (!d) { perror("opendir"); return; }
    while ((e = readdir(d)) != NULL) {
        if (strcmp(e->d_name, ".") == 0 || strcmp(e->d_name, "..") == 0) continue;
        strncpy(names[count++], e->d_name, 255);
    }
    closedir(d);

    /* Sort alphabetically. */
    for (i = 0; i < count - 1; i++)
        for (j = i + 1; j < count; j++)
            if (strcmp(names[i], names[j]) > 0) {
                char tmp[256];
                strcpy(tmp, names[i]); strcpy(names[i], names[j]); strcpy(names[j], tmp);
            }

    for (i = 0; i < count; i++) {
        char full[512];
        struct stat st;
        snprintf(full, sizeof(full), "%s/%s", path, names[i]);
        stat(full, &st);
        printf("  %s %s\n", names[i], S_ISDIR(st.st_mode) ? "true" : "false");
    }
}

/* Recursive walk (sorted, pre-order). */
static void walk(const char *path) {
    struct stat st;
    DIR *d;
    struct dirent *e;
    char names[64][256];
    int count = 0, i, j;

    stat(path, &st);
    printf("  %s %s\n", path, S_ISDIR(st.st_mode) ? "true" : "false");

    if (!S_ISDIR(st.st_mode)) return;

    d = opendir(path);
    if (!d) return;
    while ((e = readdir(d)) != NULL) {
        if (strcmp(e->d_name, ".") == 0 || strcmp(e->d_name, "..") == 0) continue;
        strncpy(names[count++], e->d_name, 255);
    }
    closedir(d);

    for (i = 0; i < count - 1; i++)
        for (j = i + 1; j < count; j++)
            if (strcmp(names[i], names[j]) > 0) {
                char tmp[256];
                strcpy(tmp, names[i]); strcpy(names[i], names[j]); strcpy(names[j], tmp);
            }

    for (i = 0; i < count; i++) {
        char child[512];
        snprintf(child, sizeof(child), "%s/%s", path, names[i]);
        walk(child);
    }
}

int main(void) {
    MKDIR("subdir");

    create_file("subdir/file1");
    MKDIR("subdir/parent");
    MKDIR("subdir/parent/child");
    create_file("subdir/parent/file2");
    create_file("subdir/parent/file3");
    create_file("subdir/parent/child/file4");

    printf("Listing subdir/parent\n");
    list_dir("subdir/parent");

    CHDIR("subdir/parent/child");

    printf("Listing subdir/parent/child\n");
    list_dir(".");

    CHDIR("../../..");

    printf("Visiting subdir\n");
    walk("subdir");

    /* Cleanup. */
    remove("subdir/parent/child/file4");
    remove("subdir/parent/file2");
    remove("subdir/parent/file3");
    remove("subdir/file1");
    rmdir("subdir/parent/child");
    rmdir("subdir/parent");
    rmdir("subdir");

    return 0;
}
