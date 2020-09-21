#include "bare.h"

unsigned long read_input(int idx)
{
    volatile unsigned long *buf = (void *)SIM_CTRL_PSEUDO_IN;
    return buf[idx];
}

void write_output(int idx, unsigned long val)
{
    volatile unsigned long *buf = (void *)SIM_CTRL_PSEUDO_OUT;
    buf[idx] = val;
}

void sim_putchar(int ch)
{
    volatile char *buf = (void *)SIM_CTRL_PUTCHAR;
    *buf = (char)ch;
}

void sim_term(int code)
{
    volatile int *buf = (void *)SIM_CTRL_TERM;
    *buf = code;
}

