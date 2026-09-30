#include <stdio.h>
#include <time.h>

#ifdef _WIN32
#  include <windows.h>
#  define sleep_ms(ms) Sleep(ms)
static void print_now(void) {
    SYSTEMTIME st;
    TIME_ZONE_INFORMATION tz;
    GetLocalTime(&st);
    GetTimeZoneInformation(&tz);
    long off_min = -(long)tz.Bias;
    int off_h = (int)(off_min / 60), off_m = (int)(off_min % 60);
    if (off_m < 0) off_m = -off_m;
    printf("%04d-%02d-%02d %02d:%02d:%02d.%06d +%02d%02d",
           st.wYear, st.wMonth, st.wDay,
           st.wHour, st.wMinute, st.wSecond, st.wMilliseconds * 1000,
           off_h, off_m);
}
#else
#  include <unistd.h>
#  define sleep_ms(ms) usleep((unsigned)((ms) * 1000))
static void print_now(void) {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    struct tm *tm = localtime(&ts.tv_sec);
    char date[32], zoff[8], zname[16];
    strftime(date, sizeof(date), "%Y-%m-%d %H:%M:%S", tm);
    strftime(zoff, sizeof(zoff), "%z", tm);
    strftime(zname, sizeof(zname), "%Z", tm);
    printf("%s.%06ld %s %s", date, (long)(ts.tv_nsec / 1000), zoff, zname);
}
#endif

int main(void) {
    for (int i = 1; i <= 5; i++) {
        sleep_ms(200);
        printf("request %d ", i);
        print_now();
        printf("\n");
    }

    for (int i = 1; i <= 5; i++) {
        if (i > 3) sleep_ms(200);
        printf("request %d ", i);
        print_now();
        printf("\n");
    }

    return 0;
}
