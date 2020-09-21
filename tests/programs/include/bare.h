#ifndef __BARE_H__
#define __BARE_H__

#include "sim_ctrl.h"

extern unsigned long read_input(int idx);
extern void write_output(int idx, unsigned long val);

extern void sim_putchar(int ch);
extern void sim_term(int code);

#endif

