#include <stdio.h>
#include <time.h>
#include <string.h>

int main(void) {
    struct timespec ts;
    struct tm *tm;
    char buf[128];
    int h12, year, mon, day, hour, min, sec;
    struct tm t1, t2;

    clock_gettime(CLOCK_REALTIME, &ts);
    tm = gmtime(&ts.tv_sec);

    /* RFC3339 format of current time. */
    strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%S+00:00", tm);
    printf("%s\n", buf);

    /* Parse an RFC3339 string. */
    memset(&t1, 0, sizeof(t1));
    sscanf("2012-11-01T22:08:41+00:00", "%d-%d-%dT%d:%d:%d",
           &year, &mon, &day, &hour, &min, &sec);
    printf("%04d-%02d-%02d %02d:%02d:%02d +0000 +0000\n",
           year, mon, day, hour, min, sec);

    /* Format "3:04PM" — 12-hour without leading zero. */
    h12 = tm->tm_hour % 12;
    if (h12 == 0) h12 = 12;
    printf("%d:%02d%s\n", h12, tm->tm_min,
           tm->tm_hour >= 12 ? "PM" : "AM");

    /* Format "Mon Jan _2 15:04:05 2006". */
    strftime(buf, sizeof(buf), "%a %b %e %T %Y", tm);
    printf("%s\n", buf);

    /* Format "2006-01-02T15:04:05.999999-07:00" — microseconds + offset. */
    printf("%04d-%02d-%02dT%02d:%02d:%02d.%06ld+00:00\n",
           tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday,
           tm->tm_hour, tm->tm_min, tm->tm_sec,
           (long)ts.tv_nsec / 1000);

    /* Parse "8 41 PM" with format "3 04 PM". */
    memset(&t2, 0, sizeof(t2));
    {
        char ampm[4] = {0};
        sscanf("8 41 PM", "%d %d %3s", &hour, &min, ampm);
        if (strcmp(ampm, "PM") == 0 && hour != 12) hour += 12;
        else if (strcmp(ampm, "AM") == 0 && hour == 12) hour = 0;
    }
    printf("0000-01-01 %02d:%02d:00 +0000 UTC\n", hour, min);

    /* Printf-style numeric formatting. */
    printf("%04d-%02d-%02dT%02d:%02d:%02d-00:00\n",
           tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday,
           tm->tm_hour, tm->tm_min, tm->tm_sec);

    /* Parse error — sscanf returns 0 fields matched. */
    {
        int n = sscanf("8:41PM", "%d-%d-%dT%d:%d:%d",
                       &year, &mon, &day, &hour, &min, &sec);
        if (n < 6)
            printf("parsing time \"8:41PM\" as \"%%Y-%%m-%%dT%%H:%%M:%%S\": cannot parse\n");
    }

    return 0;
}
