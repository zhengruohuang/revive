#ifndef __BARE_H__
#define __BARE_H__

#define PSEUDO_INPUT_BASE   0x80000000ul
#define PSEUDO_OUTPUT_BASE  0xc0000000ul

extern unsigned long read_input(int idx);
extern void write_output(int idx, unsigned long val);

#endif

