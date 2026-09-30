#include <stdio.h>

#ifdef _WIN32
#  include <windows.h>
#  define THREAD_T        HANDLE
#  define THREAD_RET      DWORD WINAPI
#  define THREAD_RET_VAL  0
#  define thread_create(t, fn, arg) (*(t) = CreateThread(NULL, 0, fn, arg, 0, NULL))
#  define thread_join(t)            (WaitForSingleObject(t, INFINITE), CloseHandle(t))
#  define sleep_ms(ms)              Sleep(ms)
typedef HANDLE sem_t;
#  define sem_init(s)       (*(s) = CreateSemaphore(NULL, 0, 1, NULL))
#  define sem_post(s)       ReleaseSemaphore(*(s), 1, NULL)
#  define sem_destroy(s)    CloseHandle(*(s))
static int sem_timedwait_ms(sem_t *s, long ms) {
    return WaitForSingleObject(*s, (DWORD)ms) == WAIT_TIMEOUT ? -1 : 0;
}
#else
#  include <pthread.h>
#  include <semaphore.h>
/* zilc: the Win32 branch takes sem_init(s) with one argument; match it here
   (not shared between processes, initial count 0, as CreateSemaphore above). */
static int sem_init_1(sem_t *s) { return sem_init(s, 0, 0); }
#  define sem_init(s) sem_init_1(s)
#  include <time.h>
#  include <unistd.h>
#  include <errno.h>
#  define THREAD_T        pthread_t
#  define THREAD_RET      void*
#  define THREAD_RET_VAL  NULL
#  define thread_create(t, fn, arg) pthread_create(t, NULL, fn, arg)
#  define thread_join(t)            pthread_join(t, NULL)
#  define sleep_ms(ms)              usleep((unsigned)((ms) * 1000))
static int sem_timedwait_ms(sem_t *s, long ms) {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    ts.tv_sec  += ms / 1000;
    ts.tv_nsec += (ms % 1000) * 1000000L;
    if (ts.tv_nsec >= 1000000000L) { ts.tv_sec++; ts.tv_nsec -= 1000000000L; }
    return sem_timedwait(s, &ts) == -1 && errno == ETIMEDOUT ? -1 : 0;
}
#endif

static sem_t c1_ready, c2_ready;

static THREAD_RET sender1(void *arg) {
    (void)arg;
    sleep_ms(2000);
    sem_post(&c1_ready);
    return THREAD_RET_VAL;
}

static THREAD_RET sender2(void *arg) {
    (void)arg;
    sleep_ms(2000);
    sem_post(&c2_ready);
    return THREAD_RET_VAL;
}

int main(void) {
    sem_init(&c1_ready);
    sem_init(&c2_ready);

    THREAD_T t1;
    thread_create(&t1, sender1, NULL);
    if (sem_timedwait_ms(&c1_ready, 1000) == -1)
        printf("timeout 1\n");
    else
        printf("result 1\n");
    thread_join(t1);

    THREAD_T t2;
    thread_create(&t2, sender2, NULL);
    if (sem_timedwait_ms(&c2_ready, 3000) == -1)
        printf("timeout 2\n");
    else
        printf("result 2\n");
    thread_join(t2);

    sem_destroy(&c1_ready);
    sem_destroy(&c2_ready);
    return 0;
}
