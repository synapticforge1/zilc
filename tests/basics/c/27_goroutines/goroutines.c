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

static void f(const char *from) {
    for (int i = 0; i < 3; i++)
        printf("%s : %d\n", from, i);
}

static THREAD_RET goroutine_f(void *arg) {
    (void)arg;
    f("goroutine");
    return THREAD_RET_VAL;
}

static THREAD_RET going_f(void *arg) {
    (void)arg;
    printf("going\n");
    return THREAD_RET_VAL;
}

int main(void) {
    f("direct");

    THREAD_T t1, t2;
    thread_create(&t1, goroutine_f, NULL);
    thread_create(&t2, going_f, NULL);

    sleep_ms(1000);
    printf("done\n");

    thread_join(t1);
    thread_join(t2);
    return 0;
}
