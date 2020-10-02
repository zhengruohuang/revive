#ifndef __BARE_H__
#define __BARE_H__

#include "sim_ctrl.h"

extern unsigned long read_input(int idx);
extern void write_output(int idx, unsigned long val);

extern void sim_putchar(int ch);
extern void sim_term(int code);

static inline unsigned int io_read32(unsigned long addr)
{
    volatile unsigned int *ptr = (volatile unsigned int *)addr;
    return *ptr;
}

static inline unsigned long long io_read64(unsigned long addr)
{
    volatile unsigned long long *ptr = (volatile unsigned long long *)addr;
    return *ptr;
}

static inline void io_write32(unsigned long addr, unsigned int val)
{
    volatile unsigned int *ptr = (volatile unsigned int *)addr;
    *ptr = val;
}

static inline void io_write64(unsigned long addr, unsigned long long val)
{
    volatile unsigned long long *ptr = (volatile unsigned long long *)addr;
    *ptr = val;
}

#endif

