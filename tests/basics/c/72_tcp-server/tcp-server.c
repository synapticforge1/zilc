#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#ifdef _WIN32
#  include <winsock2.h>
#  include <ws2tcpip.h>
#  pragma comment(lib, "ws2_32.lib")
#  include <windows.h>
typedef SOCKET sock_t;
#  define SOCK_INVALID INVALID_SOCKET
#  define sock_close(s) closesocket(s)
#  define THREAD_T        HANDLE
#  define THREAD_RET      DWORD WINAPI
#  define THREAD_RET_VAL  0
#  define thread_create(t, fn, arg) (*(t) = CreateThread(NULL, 0, fn, arg, 0, NULL))
static void sock_init(void) { WSADATA w; WSAStartup(MAKEWORD(2,2), &w); }
#else
#  include <sys/socket.h>
#  include <netinet/in.h>
#  include <unistd.h>
#  include <pthread.h>
typedef int sock_t;
#  define SOCK_INVALID (-1)
#  define sock_close(s) close(s)
#  define THREAD_T        pthread_t
#  define THREAD_RET      void*
#  define THREAD_RET_VAL  NULL
#  define thread_create(t, fn, arg) pthread_create(t, NULL, fn, arg)
static void sock_init(void) {}
#endif

static THREAD_RET handle_conn(void *arg) {
    sock_t c = *(sock_t *)arg;
    free(arg);

    char msg[512] = {0};
    int n = (int)recv(c, msg, sizeof(msg) - 1, 0);
    if (n <= 0) { sock_close(c); return THREAD_RET_VAL; }

    int len = n;
    while (len > 0 && (msg[len-1] == '\n' || msg[len-1] == '\r')) len--;
    msg[len] = '\0';

    for (int i = 0; i < len; i++) msg[i] = (char)toupper((unsigned char)msg[i]);

    char resp[560];
    snprintf(resp, sizeof(resp), "ACK: %s\n", msg);
    send(c, resp, (int)strlen(resp), 0);
    sock_close(c);
    return THREAD_RET_VAL;
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
        sock_t *cp = malloc(sizeof(sock_t));
        *cp = accept(srv, NULL, NULL);
        if (*cp == SOCK_INVALID) { free(cp); continue; }
        THREAD_T t;
        thread_create(&t, handle_conn, cp);
    }
}
