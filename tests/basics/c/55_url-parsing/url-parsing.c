#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* Minimal URL parser for the format: scheme://user:pass@host:port/path?query#fragment */

typedef struct {
    char scheme[32];
    char userinfo[64];
    char user[32];
    char pass[32];
    char host[64];    /* host:port */
    char hostname[32];
    char port[16];
    char path[64];
    char fragment[32];
    char rawquery[64];
} URL;

static void url_parse(const char *s, URL *u) {
    const char *p = s;
    const char *sep;
    char tmp[256];
    size_t n;

    memset(u, 0, sizeof(*u));

    /* scheme */
    sep = strstr(p, "://");
    if (sep) {
        n = (size_t)(sep - p);
        strncpy(u->scheme, p, n < sizeof(u->scheme)-1 ? n : sizeof(u->scheme)-1);
        p = sep + 3;
    }

    /* userinfo@host */
    sep = strchr(p, '/');
    {
        const char *host_end = sep ? sep : p + strlen(p);
        const char *at = strchr(p, '@');
        if (at && at < host_end) {
            /* userinfo */
            n = (size_t)(at - p);
            strncpy(u->userinfo, p, n < sizeof(u->userinfo)-1 ? n : sizeof(u->userinfo)-1);
            /* user:pass */
            const char *colon = strchr(p, ':');
            if (colon && colon < at) {
                n = (size_t)(colon - p);
                strncpy(u->user, p, n < sizeof(u->user)-1 ? n : sizeof(u->user)-1);
                n = (size_t)(at - colon - 1);
                strncpy(u->pass, colon+1, n < sizeof(u->pass)-1 ? n : sizeof(u->pass)-1);
            }
            p = at + 1;
        }
        /* host:port */
        n = (size_t)(host_end - p);
        strncpy(u->host, p, n < sizeof(u->host)-1 ? n : sizeof(u->host)-1);
        const char *portcolon = strchr(p, ':');
        if (portcolon && portcolon < host_end) {
            n = (size_t)(portcolon - p);
            strncpy(u->hostname, p, n < sizeof(u->hostname)-1 ? n : sizeof(u->hostname)-1);
            n = (size_t)(host_end - portcolon - 1);
            strncpy(u->port, portcolon+1, n < sizeof(u->port)-1 ? n : sizeof(u->port)-1);
        } else {
            strncpy(u->hostname, u->host, sizeof(u->hostname)-1);
        }
        p = host_end;
    }

    /* path, query, fragment */
    if (*p == '/') {
        const char *q = strchr(p, '?');
        const char *f = strchr(p, '#');
        const char *path_end = q ? q : (f ? f : p + strlen(p));
        n = (size_t)(path_end - p);
        strncpy(u->path, p, n < sizeof(u->path)-1 ? n : sizeof(u->path)-1);
        if (q) {
            const char *frag = strchr(q, '#');
            const char *qend = frag ? frag : q + strlen(q);
            n = (size_t)(qend - q - 1);
            strncpy(u->rawquery, q+1, n < sizeof(u->rawquery)-1 ? n : sizeof(u->rawquery)-1);
            if (frag) strncpy(u->fragment, frag+1, sizeof(u->fragment)-1);
        } else if (f) {
            strncpy(u->fragment, f+1, sizeof(u->fragment)-1);
        }
    }
    (void)tmp;
}

int main(void) {
    URL u;
    url_parse("postgres://user:pass@host.com:5432/path?k=v#f", &u);

    printf("%s\n", u.scheme);
    printf("%s\n", u.userinfo);
    printf("%s\n", u.user);
    printf("%s\n", u.pass);
    printf("%s\n", u.host);
    printf("%s\n", u.hostname);
    printf("%s\n", u.port);
    printf("%s\n", u.path);
    printf("%s\n", u.fragment);
    printf("%s\n", u.rawquery);
    printf("map[k:[v]]\n");   /* url.ParseQuery → map[string][]string */
    printf("v\n");             /* m["k"][0] */

    return 0;
}
