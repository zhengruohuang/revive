#include "asm.h"

.section ".text.boot"

.global _start

_start:
    xor     x1, x1, x1
    xor     x2, x2, x2
    xor     x3, x3, x3
    li      x5, -1
    li      x6, 0x7fffffff
    divu     x4, x5, x6

loop:
    addi    x1, x1, 1
    addi    x2, x2, 1
    addi    x3, x3, 1
    addi    x4, x4, -1
    bne     x4, x0, loop

stop:
    j       .

