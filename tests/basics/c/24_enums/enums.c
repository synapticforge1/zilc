#include <stdio.h>
#include <stdlib.h>

typedef int ServerState;

#define StateIdle      0
#define StateConnected 1
#define StateError     2
#define StateRetrying  3

static const char *state_name(ServerState ss) {
    switch (ss) {
    case StateIdle:      return "idle";
    case StateConnected: return "connected";
    case StateError:     return "error";
    case StateRetrying:  return "retrying";
    default:             return "unknown";
    }
}

static ServerState transition(ServerState s) {
    switch (s) {
    case StateIdle:
        return StateConnected;
    case StateConnected:
    case StateRetrying:
        return StateIdle;
    case StateError:
        return StateError;
    default:
        fprintf(stderr, "unknown state: %s\n", state_name(s));
        exit(1);
    }
}

int main(void) {
    ServerState ns = transition(StateIdle);
    printf("%s\n", state_name(ns));

    ServerState ns2 = transition(ns);
    printf("%s\n", state_name(ns2));

    return 0;
}
