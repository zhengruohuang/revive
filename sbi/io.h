#ifndef __IO_H__
#define __IO_H__

#include "sim_ctrl.h"

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

