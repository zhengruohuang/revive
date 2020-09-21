#ifndef __ASSERT_H__
#define __ASSERT_H__

#include "stdio.h"
#include "stdlib.h"

#define assert(cond)                                            \
    do {                                                        \
        if (!(cond)) {                                          \
            printf("!!! ASSERTION !!!\n");                      \
            printf("Failed: %s\n", #cond);                      \
            printf("File: %s, line %d\n", __FILE__, __LINE__);  \
            exit(-1);                                           \
        }                                                       \
    } while (0)

#endif

