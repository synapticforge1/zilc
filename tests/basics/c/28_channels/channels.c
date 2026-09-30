#include <stdio.h>
#include <string.h>

#ifdef _WIN32
#  include <windows.h>
#  define THREAD_T        HANDLE
#  define THREAD_RET      DWORD WINAPI
#  define THREAD_RET_VAL  0
#  define thread_create(t, fn, arg) (*(t) = CreateThread(NULL, 0, fn, arg, 0, NULL))
#  define thread_join(t)            (WaitForSingleObject(t, INFINITE), CloseHandle(t))
typedef HANDLE sem_t;
#  define sem_init(s)     (*(s) = CreateSemaphore(NULL, 0, 1, NULL))
#  define sem_post(s)     ReleaseSemaphore(*(s), 1, NULL)
#  define sem_wait(s)     WaitForSingleObject(*(s), INFINITE)
#  define sem_destroy(s)  CloseHandle(*(s))
#else
#  include <pthread.h>
#  include <semaphore.h>
/* zilc: the Win32 branch takes sem_init(s) with one argument; match it here
   (not shared between processes, initial count 0, as CreateSemaphore above). */
static int sem_init_1(sem_t *s) { return sem_init(s, 0, 0); }
#  define sem_init(s) sem_init_1(s)
#  define THREAD_T        pthread_t
#  define THREAD_RET      void*
#  define THREAD_RET_VAL  NULL
#  define thread_create(t, fn, arg) pthread_create(t, NULL, fn, arg)
#  define thread_join(t)            pthread_join(t, NULL)
#endif

static sem_t ready;
static char message[64];

static THREAD_RET sender(void *arg) {
    (void)arg;
    strcpy(message, "ping");
    sem_post(&ready);
    return THREAD_RET_VAL;
}

int main(void) {
    sem_init(&ready);

    THREAD_T t;
    thread_create(&t, sender, NULL);

    sem_wait(&ready);
    printf("%s\n", message);

    thread_join(t);
    sem_destroy(&ready);
    return 0;
}
