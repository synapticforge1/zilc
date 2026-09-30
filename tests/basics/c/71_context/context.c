#include <stdio.h>
#include <string.h>
#include <stdlib.h>

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
#  define thread_join(t)            (WaitForSingleObject(t, INFINITE), CloseHandle(t))
#  define sleep_ms(ms)              Sleep(ms)
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
#  define thread_join(t)            pthread_join(t, NULL)
#  define sleep_ms(ms)              usleep((unsigned)((ms) * 1000))
static void sock_init(void) {}
#endif

static void send_str(sock_t c, const char *s) {
    send(c, s, (int)strlen(s), 0);
}

static THREAD_RET handle_conn(void *arg) {
    sock_t c = *(sock_t *)arg;
    free(arg);

    printf("server: hello handler started\n");
    fflush(stdout);

    char buf[1024] = {0};
    recv(c, buf, sizeof(buf) - 1, 0);

    sleep_ms(10000);

    send_str(c, "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\nhello\n");
    sock_close(c);
    printf("server: hello handler ended\n");
    fflush(stdout);
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
