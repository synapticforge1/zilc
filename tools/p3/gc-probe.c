// For the GC-protocol probe (gc-probe.ts): a loop, so the pass emits pollchecks, and a
// blocking system call, so the runtime must exit and re-enter around it.
#include <stdio.h>
#include <unistd.h>

long spin(long n) {
    long s = 0;
    for (long i = 0; i < n; i++) s += i ^ (s >> 3);
    return s;
}

int main(void) {
    char buf[16];
    long got = read(0, buf, sizeof buf); // blocks until input or EOF
    printf("%ld %ld\n", got, spin(1000000));
    return 0;
}
