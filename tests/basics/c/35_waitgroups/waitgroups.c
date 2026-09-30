#include <stdio.h>

#ifdef _WIN32
#  include <windows.h>
#  define THREAD_T        HANDLE
#  define THREAD_RET      DWORD WINAPI
#  define THREAD_RET_VAL  0
#  define thread_create(t, fn, arg) (*(t) = CreateThread(NULL, 0, fn, arg, 0, NULL))
#  define thread_join(t)            (WaitForSingleObject(t, INFINITE), CloseHandle(t))
#  define sleep_ms(ms)              Sleep(ms)
#else
#  include <pthread.h>
#  include <unistd.h>
#  define THREAD_T        pthread_t
#  define THREAD_RET      void*
#  define THREAD_RET_VAL  NULL
#  define thread_create(t, fn, arg) pthread_create(t, NULL, fn, arg)
#  define thread_join(t)            pthread_join(t, NULL)
#  define sleep_ms(ms)              usleep((unsigned)((ms) * 1000))
#endif

static THREAD_RET worker(void *arg) {
    int id = *(int *)arg;
    printf("Worker %d starting\n", id);
    sleep_ms(1000);
    printf("Worker %d done\n", id);
    return THREAD_RET_VAL;
}

int main(void) {
    THREAD_T threads[5];
    int ids[5];
    for (int i = 0; i < 5; i++) {
        ids[i] = i + 1;
        thread_create(&threads[i], worker, &ids[i]);
    }
    for (int i = 0; i < 5; i++)
        thread_join(threads[i]);
    return 0;
}
