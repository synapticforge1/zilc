#include <stdio.h>

#ifdef _WIN32
#  include <windows.h>
#  define THREAD_T        HANDLE
#  define THREAD_RET      DWORD WINAPI
#  define THREAD_RET_VAL  0
#  define thread_create(t, fn, arg) (*(t) = CreateThread(NULL, 0, fn, arg, 0, NULL))
#  define thread_join(t)            (WaitForSingleObject(t, INFINITE), CloseHandle(t))
typedef CRITICAL_SECTION mutex_t;
#  define mutex_init(m)    InitializeCriticalSection(m)
#  define mutex_lock(m)    EnterCriticalSection(m)
#  define mutex_unlock(m)  LeaveCriticalSection(m)
#  define mutex_destroy(m) DeleteCriticalSection(m)
#else
#  include <pthread.h>
#  define THREAD_T        pthread_t
#  define THREAD_RET      void*
#  define THREAD_RET_VAL  NULL
#  define thread_create(t, fn, arg) pthread_create(t, NULL, fn, arg)
#  define thread_join(t)            pthread_join(t, NULL)
typedef pthread_mutex_t mutex_t;
#  define mutex_init(m)    pthread_mutex_init(m, NULL)
#  define mutex_lock(m)    pthread_mutex_lock(m)
#  define mutex_unlock(m)  pthread_mutex_unlock(m)
#  define mutex_destroy(m) pthread_mutex_destroy(m)
#endif

typedef struct {
    mutex_t mu;
    int a;
    int b;
} container;

static container c;

typedef struct { const char *name; int n; } inc_args;

static THREAD_RET do_increment(void *arg) {
    inc_args *a = (inc_args *)arg;
    for (int i = 0; i < a->n; i++) {
        mutex_lock(&c.mu);
        if (a->name[0] == 'a') c.a++;
        else c.b++;
        mutex_unlock(&c.mu);
    }
    return THREAD_RET_VAL;
}

int main(void) {
    mutex_init(&c.mu);
    c.a = 0;
    c.b = 0;

    inc_args aa1 = {"a", 10000};
    inc_args aa2 = {"a", 10000};
    inc_args ab  = {"b", 10000};

    THREAD_T t1, t2, t3;
    thread_create(&t1, do_increment, &aa1);
    thread_create(&t2, do_increment, &aa2);
    thread_create(&t3, do_increment, &ab);

    thread_join(t1);
    thread_join(t2);
    thread_join(t3);

    printf("map[a:%d b:%d]\n", c.a, c.b);

    mutex_destroy(&c.mu);
    return 0;
}
