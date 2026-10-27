#include <unistd.h>
int main(void) { return write(1, "hi\n", 3) == 3 ? 0 : 1; }
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
