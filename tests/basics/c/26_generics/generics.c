#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static int slices_index(const char **s, int n, const char *v) {
    for (int i = 0; i < n; i++) {
        if (strcmp(s[i], v) == 0) return i;
    }
    return -1;
}

typedef struct int_node {
    struct int_node *next;
    int val;
} int_node;

typedef struct {
    int_node *head;
    int_node *tail;
} int_list;

static void list_push(int_list *lst, int v) {
    int_node *e = malloc(sizeof(*e));
    e->next = NULL;
    e->val = v;
    if (!lst->tail) { lst->head = lst->tail = e; }
    else { lst->tail->next = e; lst->tail = e; }
}

int main(void) {
    const char *s[] = {"foo", "bar", "zoo"};
    printf("index of zoo: %d\n", slices_index(s, 3, "zoo"));

    int_list lst = {NULL, NULL};
    list_push(&lst, 10);
    list_push(&lst, 13);
    list_push(&lst, 23);

    printf("list: [");
    int first = 1;
    for (int_node *e = lst.head; e; e = e->next) {
        if (!first) printf(" ");
        printf("%d", e->val);
        first = 0;
    }
    printf("]\n");

    for (int_node *e = lst.head; e; ) {
        int_node *nx = e->next;
        free(e);
        e = nx;
    }
    return 0;
}
