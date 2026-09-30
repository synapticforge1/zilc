#include <stdio.h>
#include <time.h>

int main(void) {
    struct timespec ts;
    struct tm *tm;
    long long secs, millis, nanos;
    time_t t;
    long ns_rem;

    clock_gettime(CLOCK_REALTIME, &ts);

    /* Current time. */
    tm = gmtime(&ts.tv_sec);
    printf("%04d-%02d-%02d %02d:%02d:%02d.%09ld +0000 UTC\n",
           tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday,
           tm->tm_hour, tm->tm_min, tm->tm_sec, (long)ts.tv_nsec);

    secs   = (long long)ts.tv_sec;
    nanos  = secs * 1000000000LL + (long long)ts.tv_nsec;
    millis = nanos / 1000000LL;

    printf("%lld\n", secs);
    printf("%lld\n", millis);
    printf("%lld\n", nanos);

    /* time.Unix(secs, 0) — from seconds, no sub-second part. */
    t = (time_t)secs;
    tm = gmtime(&t);
    printf("%04d-%02d-%02d %02d:%02d:%02d +0000 UTC\n",
           tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday,
           tm->tm_hour, tm->tm_min, tm->tm_sec);

    /* time.Unix(0, nanos) — reconstructed from nanoseconds. */
    t      = (time_t)(nanos / 1000000000LL);
    ns_rem = (long)(nanos % 1000000000LL);
    tm = gmtime(&t);
    printf("%04d-%02d-%02d %02d:%02d:%02d.%09ld +0000 UTC\n",
           tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday,
           tm->tm_hour, tm->tm_min, tm->tm_sec, ns_rem);

    return 0;
}
