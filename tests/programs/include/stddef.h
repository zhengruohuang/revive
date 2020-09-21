#ifndef __STDDEF_H__
#define __STDDEF_H__

#include "inttypes.h"

typedef unsigned long       size_t;

#define NULL                ((void *)0)
#define offsetof(st, m)     __builtin_offsetof(st, m)

#endif

