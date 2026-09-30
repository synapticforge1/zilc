#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#ifdef _WIN32
#  include <winsock2.h>
#  include <ws2tcpip.h>
#  pragma comment(lib, "ws2_32.lib")
typedef SOCKET sock_t;
#  define SOCK_INVALID INVALID_SOCKET
#  define sock_close(s) closesocket(s)
static void sock_init(void) { WSADATA w; WSAStartup(MAKEWORD(2,2), &w); }
#else
#  include <sys/socket.h>
#  include <netinet/in.h>
#  include <unistd.h>
typedef int sock_t;
#  define SOCK_INVALID (-1)
#  define sock_close(s) close(s)
static void sock_init(void) {}
#endif

static void send_str(sock_t c, const char *s) {
    send(c, s, (int)strlen(s), 0);
}

static void handle_hello(sock_t c) {
    send_str(c, "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\nhello\n");
}

static void handle_headers(sock_t c, const char *req) {
    char resp[4096];
    int pos = snprintf(resp, sizeof(resp),
                       "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\n");
    const char *p = strstr(req, "\r\n");
    if (p) p += 2;
    while (p && *p && !(p[0] == '\r' && p[1] == '\n')) {
        const char *nl = strstr(p, "\r\n");
        if (!nl) break;
        int len = (int)(nl - p);
        if (pos + len + 2 < (int)sizeof(resp)) {
            memcpy(resp + pos, p, len);
            pos += len;
            resp[pos++] = '\n';
        }
        p = nl + 2;
    }
    send(c, resp, pos, 0);
}

static void handle_conn(sock_t c) {
    char buf[4096] = {0};
    recv(c, buf, sizeof(buf) - 1, 0);
    if (strncmp(buf, "GET /hello", 10) == 0) handle_hello(c);
    else if (strncmp(buf, "GET /headers", 12) == 0) handle_headers(c, buf);
    else send_str(c, "HTTP/1.1 404 Not Found\r\nConnection: close\r\n\r\n");
    sock_close(c);
}

int main(void) {
    sock_init();

    sock_t srv = socket(AF_INET, SOCK_STREAM, 0);
    int opt = 1;
    setsockopt(srv, SOL_SOCKET, SO_REUSEADDR, (const char *)&opt, sizeof(opt));

    struct sockaddr_in addr = {0};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(8090);
    addr.sin_addr.s_addr = INADDR_ANY;
    bind(srv, (struct sockaddr *)&addr, sizeof(addr));
    listen(srv, 10);

    printf("Listening on :8090\n");
    fflush(stdout);
    for (;;) {
        sock_t c = accept(srv, NULL, NULL);
        if (c == SOCK_INVALID) continue;
        handle_conn(c);
    }
}
