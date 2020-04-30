#include "bare.h"

unsigned long read_input(int idx)
{
    volatile unsigned long *buf = (void *)PSEUDO_INPUT_BASE;
    return buf[idx];
}

void write_output(int idx, unsigned long val)
{
    volatile unsigned long *buf = (void *)PSEUDO_OUTPUT_BASE;
    buf[idx] = val;
}

