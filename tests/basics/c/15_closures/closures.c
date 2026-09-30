#include <stdio.h>
#include <stdlib.h>

/* C has no closure syntax. The idiomatic equivalent uses a heap-allocated
   state struct paired with a function pointer. Each "closure" is an
   independent struct instance, giving independent state. */

typedef struct {
    int i;
} IntSeqState;

static int int_seq_next(IntSeqState *state) {
    state->i++;
    return state->i;
}

int main(void) {
    /* Allocate state for the first sequence (analogous to calling intSeq()). */
    IntSeqState *next_int = malloc(sizeof(IntSeqState));
    next_int->i = 0;

    /* Each call advances this sequence's counter. */
    printf("%d\n", int_seq_next(next_int));
    printf("%d\n", int_seq_next(next_int));
    printf("%d\n", int_seq_next(next_int));

    /* A second, independent state confirms the state is not shared. */
    IntSeqState *new_ints = malloc(sizeof(IntSeqState));
    new_ints->i = 0;
    printf("%d\n", int_seq_next(new_ints));

    free(next_int);
    free(new_ints);
    return 0;
}
