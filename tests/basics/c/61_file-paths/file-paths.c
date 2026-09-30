#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* Minimal POSIX-style path helpers (separator = '/'). */

static void path_join(char *out, size_t sz, const char *a, const char *b) {
    /* Normalize double slashes and resolve leading ../ segments. */
    char tmp[512];
    size_t i, j = 0;

    /* Concatenate with '/' separator. */
    snprintf(tmp, sizeof(tmp), "%s/%s", a, b);

    /* Collapse double slashes. */
    for (i = 0; tmp[i]; i++) {
        if (tmp[i] == '/' && j > 0 && out[j-1] == '/') continue;
        if (j < sz - 1) out[j++] = tmp[i];
    }
    out[j] = '\0';

    /* Resolve leading a/../ patterns (simple single-level only). */
    {
        char *dotdot;
        while ((dotdot = strstr(out, "/../")) != NULL) {
            char *slash = dotdot - 1;
            while (slash > out && *slash != '/') slash--;
            memmove(slash, dotdot + 3, strlen(dotdot + 3) + 1);
        }
        /* Handle trailing /.. */
        size_t len = strlen(out);
        if (len >= 3 && strcmp(out + len - 3, "/..") == 0) {
            out[len-3] = '\0';
            char *slash2 = strrchr(out, '/');
            if (slash2) *slash2 = '\0';
        }
    }
}

static void path_join3(char *out, size_t sz,
                       const char *a, const char *b, const char *c) {
    char tmp[512];
    path_join(tmp, sizeof(tmp), a, b);
    path_join(out, sz, tmp, c);
}

static const char *path_dir(char *out, size_t sz, const char *p) {
    const char *slash = strrchr(p, '/');
    if (!slash) { strncpy(out, ".", sz); return out; }
    size_t n = (size_t)(slash - p);
    if (n == 0) { strncpy(out, "/", sz); return out; }
    strncpy(out, p, n < sz ? n : sz - 1);
    out[n < sz ? n : sz - 1] = '\0';
    return out;
}

static const char *path_base(const char *p) {
    const char *slash = strrchr(p, '/');
    return slash ? slash + 1 : p;
}

static const char *path_ext(const char *name) {
    const char *dot = strrchr(name, '.');
    return dot ? dot : "";
}

static void path_rel(char *out, size_t sz, const char *base, const char *target) {
    /* Count common path components. */
    size_t bi = 0, ti = 0;
    while (base[bi] && target[ti] && base[bi] == target[ti]) { bi++; ti++; }
    /* Back up to last '/'. */
    while (bi > 0 && base[bi-1] != '/') { bi--; ti--; }
    /* Count remaining segments in base. */
    int ups = 0;
    size_t k;
    for (k = bi; base[k]; k++) if (base[k] == '/') ups++;
    if (base[bi]) ups++;  /* at least one segment after common prefix */

    out[0] = '\0';
    for (k = 0; (int)k < ups; k++) {
        if (k > 0) strncat(out, "/", sz - strlen(out) - 1);
        strncat(out, "..", sz - strlen(out) - 1);
    }
    if (target[ti]) {
        if (strlen(out) > 0) strncat(out, "/", sz - strlen(out) - 1);
        strncat(out, target + ti, sz - strlen(out) - 1);
    }
    if (strlen(out) == 0) strncpy(out, ".", sz);
}

int main(void) {
    char buf[256], dir[256], rel[256];
    const char *p;

    /* filepath.Join("dir1", "dir2", "filename") */
    path_join3(buf, sizeof(buf), "dir1", "dir2", "filename");
    printf("p: %s\n", buf);

    /* filepath.Join("dir1//", "filename") — collapse double slash */
    path_join(buf, sizeof(buf), "dir1//", "filename");
    printf("%s\n", buf);

    /* filepath.Join("dir1/../dir1", "filename") — resolve ..\/ */
    path_join(buf, sizeof(buf), "dir1/../dir1", "filename");
    printf("%s\n", buf);

    p = "dir1/dir2/filename";
    path_dir(dir, sizeof(dir), p);
    printf("Dir(p): %s\n", dir);
    printf("Base(p): %s\n", path_base(p));

    printf("%s\n", strncmp("dir/file", "/", 1) == 0 ? "true" : "false");
    printf("%s\n", strncmp("/dir/file", "/", 1) == 0 ? "true" : "false");

    printf("%s\n", path_ext("config.json"));

    {
        const char *ext = path_ext("config.json");
        size_t n = strlen("config.json") - strlen(ext);
        printf("%.*s\n", (int)n, "config.json");
    }

    path_rel(rel, sizeof(rel), "a/b", "a/b/t/file");
    printf("%s\n", rel);

    path_rel(rel, sizeof(rel), "a/b", "a/c/t/file");
    printf("%s\n", rel);

    return 0;
}
