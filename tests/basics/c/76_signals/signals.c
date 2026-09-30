#include <stdio.h>
#include <signal.h>
#include <string.h>
#ifdef _WIN32
#  include <windows.h> /* zilc: Sleep */
#else
#  include <time.h>    /* zilc: nanosleep */
#endif

static volatile int received_signal = 0;
static const char *signal_name = NULL;

static void handle_signal(int sig) {
    received_signal = sig;
    if (sig == SIGINT) signal_name = "interrupt signal received";
    else if (sig == SIGTERM) signal_name = "terminated signal received";
    else signal_name = "signal received";
}

int main(void) {
    signal(SIGINT, handle_signal);
#ifdef SIGTERM
    signal(SIGTERM, handle_signal);
#endif

    printf("awaiting signal\n");
    fflush(stdout);

    while (!received_signal) {
#ifdef _WIN32
        Sleep(100);
#else
        struct timespec ts = {0, 100000000L};
        nanosleep(&ts, NULL);
#endif
    }

    printf("\n%s\n", signal_name);
    printf("exiting\n");
    return 0;
}
