// What does Fil-C's libc syscall() accept? Probe for KI-7 (Zig std's raw `syscall` asm).
// Built with Fil-C's clang; run under Fil-C. Each case prints its result, or the program
// traps and the trap message says which case broke.
#define _GNU_SOURCE
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/syscall.h>
#include <time.h>
#include <unistd.h>
// Fil-C ships no <linux/futex.h>; these are the stable kernel ABI values.
#define FUTEX_WAIT_PRIVATE 128
#define FUTEX_WAKE_PRIVATE 129

static int word = 0;

int main(int argc, char **argv) {
    const char *only = argc > 1 ? argv[1] : "all";
    if (!strcmp(only, "all") || !strcmp(only, "gettid")) {
        long r = syscall(SYS_gettid);
        printf("gettid (186): %ld (getpid %d)\n", r, getpid());
    }
    if (!strcmp(only, "all") || !strcmp(only, "futex-ptr")) {
        long r = syscall(SYS_futex, &word, FUTEX_WAKE_PRIVATE, 1, NULL, NULL, 0);
        printf("futex (202) wake, real pointer: %ld\n", r);
    }
    if (!strcmp(only, "all") || !strcmp(only, "futex-err")) {
        // Wait with a wrong expected value: the kernel returns EAGAIN at once.
        long r = syscall(SYS_futex, &word, FUTEX_WAIT_PRIVATE, 1, NULL, NULL, 0);
        printf("futex (202) wait mismatch: %ld errno=%d (EAGAIN=%d)\n", r, errno, EAGAIN);
    }
    if (!strcmp(only, "all") || !strcmp(only, "nanosleep")) {
        struct timespec ts = {0, 1000000};
        long r = syscall(SYS_clock_nanosleep, CLOCK_MONOTONIC, 0, &ts, NULL);
        printf("clock_nanosleep (230): %ld\n", r);
    }
    if (!strcmp(only, "futex-int")) {
        // The raw-asm shape: the address travels as a plain integer, as Zig's asm passes it.
        uintptr_t addr = (uintptr_t)&word;
        long r = syscall(SYS_futex, addr, FUTEX_WAKE_PRIVATE, 1, 0L, 0L, 0L);
        printf("futex (202) wake, address as integer: %ld\n", r);
    }
    return 0;
}
