#include <unistd.h>
int main(void) { return write(1, "hi\n", 3) == 3 ? 0 : 1; }
