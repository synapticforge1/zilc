#include <stdio.h>
#include <time.h>
#include <string.h>

#ifdef _WIN32
#  include <windows.h>
static void get_time(int *yr, int *mo, int *dy,
                     int *hr, int *mn, int *sc, long *us, int *off_h, int *off_m) {
    SYSTEMTIME st;
    TIME_ZONE_INFORMATION tz;
    GetLocalTime(&st);
    GetTimeZoneInformation(&tz);
    *yr = st.wYear; *mo = st.wMonth; *dy = st.wDay;
    *hr = st.wHour; *mn = st.wMinute; *sc = st.wSecond;
    *us = st.wMilliseconds * 1000L;
    long off = -(long)tz.Bias;
    *off_h = (int)(off / 60); *off_m = (int)(off % 60);
    if (*off_m < 0) *off_m = -*off_m;
}
#else
#  include <unistd.h>
static void get_time(int *yr, int *mo, int *dy,
                     int *hr, int *mn, int *sc, long *us, int *off_h, int *off_m) {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    struct tm *tm = localtime(&ts.tv_sec);
    *yr = 1900 + tm->tm_year; *mo = 1 + tm->tm_mon; *dy = tm->tm_mday;
    *hr = tm->tm_hour; *mn = tm->tm_min; *sc = tm->tm_sec;
    *us = ts.tv_nsec / 1000L;
    long goff = tm->tm_gmtoff;
    *off_h = (int)(goff / 3600); *off_m = (int)((goff % 3600) / 60);
    if (*off_m < 0) *off_m = -*off_m;
}
#endif

static void log_std(FILE *f, const char *prefix, const char *msg) {
    int yr, mo, dy, hr, mn, sc, oh, om;
    long us;
    get_time(&yr, &mo, &dy, &hr, &mn, &sc, &us, &oh, &om);
    fprintf(f, "%s%04d/%02d/%02d %02d:%02d:%02d %s\n",
            prefix, yr, mo, dy, hr, mn, sc, msg);
}

static void log_micro(FILE *f, const char *prefix, const char *msg) {
    int yr, mo, dy, hr, mn, sc, oh, om;
    long us;
    get_time(&yr, &mo, &dy, &hr, &mn, &sc, &us, &oh, &om);
    fprintf(f, "%s%04d/%02d/%02d %02d:%02d:%02d.%06ld %s\n",
            prefix, yr, mo, dy, hr, mn, sc, us, msg);
}

static void log_fileline(FILE *f, const char *prefix,
                         const char *file, int line, const char *msg) {
    int yr, mo, dy, hr, mn, sc, oh, om;
    long us;
    get_time(&yr, &mo, &dy, &hr, &mn, &sc, &us, &oh, &om);
    const char *base = strrchr(file, '/');
    if (!base) base = strrchr(file, '\\');
    base = base ? base + 1 : file;
    fprintf(f, "%s%04d/%02d/%02d %02d:%02d:%02d %s:%d: %s\n",
            prefix, yr, mo, dy, hr, mn, sc, base, line, msg);
}

static void log_slog(FILE *f, const char *msg,
                     const char *key1, const char *val1, int age) {
    int yr, mo, dy, hr, mn, sc, oh, om;
    long us;
    get_time(&yr, &mo, &dy, &hr, &mn, &sc, &us, &oh, &om);
    if (key1) {
        fprintf(f, "{\"time\":\"%04d-%02d-%02dT%02d:%02d:%02d.%09ld%+03d:%02d\","
                "\"level\":\"INFO\",\"msg\":\"%s\",\"%s\":\"%s\",\"age\":%d}\n",
                yr, mo, dy, hr, mn, sc, us * 1000L, oh, om, msg, key1, val1, age);
    } else {
        fprintf(f, "{\"time\":\"%04d-%02d-%02dT%02d:%02d:%02d.%09ld%+03d:%02d\","
                "\"level\":\"INFO\",\"msg\":\"%s\"}\n",
                yr, mo, dy, hr, mn, sc, us * 1000L, oh, om, msg);
    }
}

int main(void) {
    log_std(stderr, "", "standard logger");

    log_micro(stderr, "", "with micro");

    log_fileline(stderr, "", __FILE__, __LINE__, "with file/line");

    log_std(stdout, "my:", "from mylog");

    log_std(stdout, "ohmy:", "from mylog");

    char buf[256];
    int yr, mo, dy, hr, mn, sc, oh, om;
    long us;
    get_time(&yr, &mo, &dy, &hr, &mn, &sc, &us, &oh, &om);
    snprintf(buf, sizeof(buf), "buf:%04d/%02d/%02d %02d:%02d:%02d hello\n",
             yr, mo, dy, hr, mn, sc);
    printf("from buflog:%s", buf);

    log_slog(stderr, "hi there", NULL, NULL, 0);
    log_slog(stderr, "hello again", "key", "val", 25);

    return 0;
}
