#include <stdio.h>
#include <stdatomic.h>

#ifdef _WIN32
#  include <windows.h>
#  define THREAD_T        HANDLE
#  define THREAD_RET      DWORD WINAPI
#  define THREAD_RET_VAL  0
#  define thread_create(t, fn, arg) (*(t) = CreateThread(NULL, 0, fn, arg, 0, NULL))
#  define thread_join(t)            (WaitForSingleObject(t, INFINITE), CloseHandle(t))
#else
#  include <pthread.h>
#  define THREAD_T        pthread_t
#  define THREAD_RET      void*
#  define THREAD_RET_VAL  NULL
#  define thread_create(t, fn, arg) pthread_create(t, NULL, fn, arg)
#  define thread_join(t)            pthread_join(t, NULL)
#endif

static atomic_ullong ops;

static THREAD_RET worker(void *arg) {
    (void)arg;
    for (int i = 0; i < 1000; i++)
        atomic_fetch_add(&ops, 1);
    return THREAD_RET_VAL;
}

int main(void) {
    atomic_init(&ops, 0);

    THREAD_T threads[50];
    for (int i = 0; i < 50; i++)
        thread_create(&threads[i], worker, NULL);
    for (int i = 0; i < 50; i++)
        thread_join(threads[i]);

    printf("ops: %llu\n", (unsigned long long)atomic_load(&ops));
    return 0;
}
