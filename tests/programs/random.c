#include "bare.h"
#include <stdio.h>
#include <stdlib.h>

#define POOL_SIZE 0x40000  // 256KB

static char pool[POOL_SIZE] __attribute__ ((aligned(8)));

static void stream_init()
{
    printf("Stream init\n");
    
    volatile unsigned int *pool32 = (void *)pool;
    for (unsigned int i = 0; i < POOL_SIZE / 4; i++) {
        pool32[i] = (unsigned int)i;
    }
}

static void rand_replace()
{
    printf("Random replace\n");
    
    volatile unsigned int *pool32 = (void *)pool;
    for (unsigned int i = 0; i < POOL_SIZE / 4; i++) {
        int replace = rand() & 1;
        if (replace) {
            int j = rand() % (POOL_SIZE / 4);
            pool32[i] = pool32[j];
        }
    }
}

static void stream_sum()
{
    printf("Stream sum: ");
    
    volatile unsigned int *pool32 = (void *)pool;
    unsigned long long sum = 0;
    for (unsigned int i = 0; i < POOL_SIZE / 4; i++) {
        sum += (unsigned long long)pool32[i];
    }
    
    printf("%llu\n", sum);
}

int main(int argc, char *argv[])
{
    stream_init();
    rand_replace();
    stream_sum();
    return 0;
}

