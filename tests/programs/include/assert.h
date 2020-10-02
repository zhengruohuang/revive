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

#define panic(...)                                              \
    do {                                                        \
        printf("!!! PANIC !!!\n");                              \
        printf("File: %s, line %d\n", __FILE__, __LINE__);      \
        printf(__VA_ARGS__);                                    \
        printf("\n");                                           \
        exit(-1);                                               \
    } while (0)

#define panic_if(cond, ...)                                     \
    do {                                                        \
        if (cond) {                                             \
            printf("!!! PANIC !!!\n");                          \
            printf("Condition: %s\n", #cond);                   \
            printf("File: %s, line %d\n", __FILE__, __LINE__);  \
            printf(__VA_ARGS__);                                \
            printf("\n");                                       \
            exit(-1);                                           \
        }                                                       \
    } while (0)

#endif

