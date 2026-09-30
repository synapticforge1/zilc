#include <stdio.h>
#include <stdatomic.h>

#ifdef _WIN32
#  include <windows.h>
#  define THREAD_T        HANDLE
#  define THREAD_RET      DWORD WINAPI
#  define THREAD_RET_VAL  0
#  define thread_create(t, fn, arg) (*(t) = CreateThread(NULL, 0, fn, arg, 0, NULL))
#  define thread_join(t)            (WaitForSingleObject(t, INFINITE), CloseHandle(t))
#  define sleep_ms(ms)              Sleep(ms)
typedef CRITICAL_SECTION mutex_t;
#  define mutex_init(m)    InitializeCriticalSection(m)
#  define mutex_lock(m)    EnterCriticalSection(m)
#  define mutex_unlock(m)  LeaveCriticalSection(m)
#  define mutex_destroy(m) DeleteCriticalSection(m)
#else
#  include <pthread.h>
#  include <unistd.h>
#  define THREAD_T        pthread_t
#  define THREAD_RET      void*
#  define THREAD_RET_VAL  NULL
#  define thread_create(t, fn, arg) pthread_create(t, NULL, fn, arg)
#  define thread_join(t)            pthread_join(t, NULL)
#  define sleep_ms(ms)              usleep((unsigned)((ms) * 1000))
typedef pthread_mutex_t mutex_t;
#  define mutex_init(m)    pthread_mutex_init(m, NULL)
#  define mutex_lock(m)    pthread_mutex_lock(m)
#  define mutex_unlock(m)  pthread_mutex_unlock(m)
#  define mutex_destroy(m) pthread_mutex_destroy(m)
#endif

#define NUM_JOBS 5
#define NUM_WORKERS 3

static mutex_t jobs_mu;
static int next_job = 1;

static THREAD_RET worker(void *arg) {
    int id = *(int *)arg;
    for (;;) {
        mutex_lock(&jobs_mu);
        int j = next_job;
        if (j > NUM_JOBS) { mutex_unlock(&jobs_mu); break; }
        next_job++;
        mutex_unlock(&jobs_mu);

        printf("worker %d started  job %d\n", id, j);
        sleep_ms(1000);
        printf("worker %d finished job %d\n", id, j);
    }
    return THREAD_RET_VAL;
}

int main(void) {
    mutex_init(&jobs_mu);

    THREAD_T threads[NUM_WORKERS];
    int ids[NUM_WORKERS];
    for (int i = 0; i < NUM_WORKERS; i++) {
        ids[i] = i + 1;
        thread_create(&threads[i], worker, &ids[i]);
    }
    for (int i = 0; i < NUM_WORKERS; i++)
        thread_join(threads[i]);

    mutex_destroy(&jobs_mu);
    return 0;
}
