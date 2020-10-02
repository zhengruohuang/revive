#ifndef __STDLIB_H__
#define __STDLIB_H__

#include "inttypes.h"
#include "stddef.h"

extern int isdigit(int ch);
extern int isxdigit(int ch);

extern u64 stou64(const char *str, int base);
extern u32 stou32(const char *str, int base);
extern ulong stoul(const char *str, int base);
extern int stoi(const char *str, int base);

extern int atoi(const char *str);
extern ulong atol(const char *str);
extern u64 atoll(const char *str);

extern void abort();
extern void exit(int status);

extern int rand();
extern int rand_r(u32 *seedp);
extern void srand(u32 seed);

#endif

