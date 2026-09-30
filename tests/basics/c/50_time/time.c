#include <stdio.h>
#include <time.h>

static const char *months[] = {
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
};
static const char *weekdays[] = {
    "Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"
};

int main(void) {
    struct timespec now_ts;
    struct tm *now_tm;
    /* 2009-11-17 20:34:58.651387237 UTC = Unix 1258576498 */
    time_t   then_t  = (time_t)1258576498;
    long     then_ns = 651387237L;
    struct tm *then_tm;
    long long diff_ns, total_h, rem_m, rem_s, rem_ns;
    time_t sub_t;
    long sub_ns;

    clock_gettime(CLOCK_REALTIME, &now_ts);

    /* now */
    now_tm = gmtime(&now_ts.tv_sec);
    printf("%04d-%02d-%02d %02d:%02d:%02d.%09ld +0000 UTC\n",
           now_tm->tm_year + 1900, now_tm->tm_mon + 1, now_tm->tm_mday,
           now_tm->tm_hour, now_tm->tm_min, now_tm->tm_sec,
           (long)now_ts.tv_nsec);

    /* then */
    printf("2009-11-17 20:34:58.651387237 +0000 UTC\n");

    /* Components of then. */
    then_tm = gmtime(&then_t);
    printf("%d\n", then_tm->tm_year + 1900);
    printf("%s\n", months[then_tm->tm_mon]);
    printf("%d\n", then_tm->tm_mday);
    printf("%d\n", then_tm->tm_hour);
    printf("%d\n", then_tm->tm_min);
    printf("%d\n", then_tm->tm_sec);
    printf("%ld\n", then_ns);
    printf("UTC\n");
    printf("%s\n", weekdays[then_tm->tm_wday]);

    /* Before / After / Equal. */
    printf("%s\n", (then_t < now_ts.tv_sec ||
                    (then_t == now_ts.tv_sec && then_ns < (long)now_ts.tv_nsec))
                   ? "true" : "false");
    printf("%s\n", (then_t > now_ts.tv_sec ||
                    (then_t == now_ts.tv_sec && then_ns > (long)now_ts.tv_nsec))
                   ? "true" : "false");
    printf("false\n");

    /* diff = now - then (in nanoseconds). */
    diff_ns = (long long)(now_ts.tv_sec - then_t) * 1000000000LL
              + ((long long)now_ts.tv_nsec - then_ns);

    total_h = diff_ns / 3600000000000LL;
    rem_ns  = diff_ns % 3600000000000LL;
    rem_m   = rem_ns  / 60000000000LL;
    rem_ns %= 60000000000LL;
    rem_s   = rem_ns  / 1000000000LL;
    rem_ns %= 1000000000LL;

    printf("%lldh%lldm%lld.%09llds\n", total_h, rem_m, rem_s, rem_ns);
    printf("%.15g\n", (double)diff_ns / 3600e9);
    printf("%.15g\n", (double)diff_ns / 60e9);
    printf("%.15g\n", (double)diff_ns / 1e9);
    printf("%lld\n", diff_ns);

    /* then.Add(diff) = then + diff ≈ now. */
    now_tm = gmtime(&now_ts.tv_sec);
    printf("%04d-%02d-%02d %02d:%02d:%02d.%09ld +0000 UTC\n",
           now_tm->tm_year + 1900, now_tm->tm_mon + 1, now_tm->tm_mday,
           now_tm->tm_hour, now_tm->tm_min, now_tm->tm_sec,
           (long)now_ts.tv_nsec);

    /* then.Add(-diff) = 2*then - now. */
    {
        long long sub_total = (long long)then_t * 1000000000LL + then_ns - diff_ns;
        sub_t  = (time_t)(sub_total / 1000000000LL);
        sub_ns = (long)(sub_total % 1000000000LL);
        if (sub_ns < 0) { sub_t--; sub_ns += 1000000000L; }
        then_tm = gmtime(&sub_t);
        printf("%04d-%02d-%02d %02d:%02d:%02d.%09ld +0000 UTC\n",
               then_tm->tm_year + 1900, then_tm->tm_mon + 1, then_tm->tm_mday,
               then_tm->tm_hour, then_tm->tm_min, then_tm->tm_sec, sub_ns);
    }

    return 0;
}
