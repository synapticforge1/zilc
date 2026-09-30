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
static void sock_init(void) {
    WSADATA w; WSAStartup(MAKEWORD(2,2), &w);
}
static void sock_cleanup(void) { WSACleanup(); }
#else
#  include <sys/socket.h>
#  include <netdb.h>
#  include <unistd.h>
typedef int sock_t;
#  define SOCK_INVALID (-1)
#  define sock_close(s) close(s)
static void sock_init(void) {}
static void sock_cleanup(void) {}
#endif

static sock_t tcp_connect(const char *host, const char *port) {
    struct addrinfo hints = {0}, *res;
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    if (getaddrinfo(host, port, &hints, &res) != 0) return SOCK_INVALID;
    sock_t s = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (s == SOCK_INVALID) { freeaddrinfo(res); return SOCK_INVALID; }
    if (connect(s, res->ai_addr, (int)res->ai_addrlen) != 0) {
        sock_close(s); freeaddrinfo(res); return SOCK_INVALID;
    }
    freeaddrinfo(res);
    return s;
}

int main(void) {
    sock_init();

    sock_t s = tcp_connect("gobyexample.com", "80");
    if (s == SOCK_INVALID) {
        fprintf(stderr, "connection failed\n");
        sock_cleanup();
        return 1;
    }

    const char *req =
        "GET / HTTP/1.0\r\n"
        "Host: gobyexample.com\r\n"
        "Connection: close\r\n"
        "\r\n";
    send(s, req, (int)strlen(req), 0);

    char buf[8192];
    int n = recv(s, buf, sizeof(buf) - 1, 0);
    if (n > 0) {
        buf[n] = '\0';
        char *body = strstr(buf, "\r\n\r\n");
        if (!body) body = strstr(buf, "\n\n");
        char status[64] = "";
        sscanf(buf, "HTTP/%*s %63[^\r\n]", status);
        printf("Response status: %s\n", status);
        if (body) {
            body += (body[1] == '\n' ? 2 : 4);
            int lines = 0;
            char *p = body;
            while (*p && lines < 5) {
                char *nl = strchr(p, '\n');
                if (!nl) { printf("%s\n", p); lines++; break; }
                *nl = '\0';
                if (p[0] != '\0' && p[strlen(p)-1] == '\r')
                    p[strlen(p)-1] = '\0';
                printf("%s\n", p);
                p = nl + 1;
                lines++;
            }
        }
    }

    sock_close(s);
    sock_cleanup();
    return 0;
}
