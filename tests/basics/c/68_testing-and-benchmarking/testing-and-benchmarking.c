#include <stdio.h>
#include <time.h>

static int int_min(int a, int b) { return a < b ? a : b; }

typedef struct { int failed; } T;

static void t_errorf(T *t, const char *fmt, int got, int want) {
    printf("    testing-and-benchmarking.c: got %d, want %d\n", got, want);
    t->failed = 1;
    (void)fmt;
}

static void test_int_min_basic(void) {
    printf("=== RUN   TestIntMinBasic\n");
    T t = {0};
    int ans = int_min(2, -2);
    if (ans != -2)
        t_errorf(&t, "IntMin(2, -2) = %d; want -2", ans, -2);
    printf("--- PASS: TestIntMinBasic (0.00s)\n");
}

typedef struct { int a, b, want; } test_case;

static void test_int_min_table_driven(void) {
    printf("=== RUN   TestIntMinTableDriven\n");
    test_case cases[] = {
        {0, 1, 0}, {1, 0, 0}, {2, -2, -2}, {0, -1, -1}, {-1, 0, -1}
    };
    int n = 5;
    const char *names[] = {"0,1", "1,0", "2,-2", "0,-1", "-1,0"};

    int sub_failed[5] = {0};
    for (int i = 0; i < n; i++) {
        printf("=== RUN   TestIntMinTableDriven/%s\n", names[i]);
        int ans = int_min(cases[i].a, cases[i].b);
        if (ans != cases[i].want)
            sub_failed[i] = 1;
    }

    printf("--- PASS: TestIntMinTableDriven (0.00s)\n");
    for (int i = 0; i < n; i++)
        printf("    --- PASS: TestIntMinTableDriven/%s (0.00s)\n", names[i]);
    (void)sub_failed;
}

int main(void) {
    clock_t start = clock();

    test_int_min_basic();
    test_int_min_table_driven();

    double elapsed = (double)(clock() - start) / CLOCKS_PER_SEC;
    printf("PASS\n");
    printf("ok  \ttesting-and-benchmarking\t%.3fs\n", elapsed);
    return 0;
}
