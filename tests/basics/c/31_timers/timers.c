#include <stdio.h>

#ifdef _WIN32
#  include <windows.h>
#  define sleep_ms(ms) Sleep(ms)
#else
#  include <unistd.h>
#  define sleep_ms(ms) usleep((unsigned)((ms) * 1000))
#endif

int main(void) {
    sleep_ms(2000);
    printf("Timer 1 fired\n");

    printf("Timer 2 stopped\n");

    sleep_ms(2000);
    return 0;
}
