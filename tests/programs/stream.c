#include "bare.h"
#include <stdio.h>

#define POOL_SIZE 0x40000  // 256KB

static char pool[POOL_SIZE] __attribute__ ((aligned(8)));

static inline void stream64()
{
    volatile unsigned long long *pool64 = (void *)pool;
    
    printf("Stream write 64\n");
    for (unsigned int i = 0; i < POOL_SIZE / 8; i++) {
        pool64[i] = (unsigned long long)i;
    }
    
    unsigned long long sum = 0;
    printf("Stream read 64\n");
    for (unsigned int i = 0; i < POOL_SIZE / 8; i++) {
        sum += (unsigned long long)pool64[i];
    }
    
    printf("Stream sum 64: %llu\n", sum);
}

static inline void stream32()
{
    volatile unsigned int *pool32 = (void *)pool;
    
    printf("Stream write 32\n");
    for (unsigned int i = 0; i < POOL_SIZE / 4; i++) {
        pool32[i] = (unsigned int)i;
    }
    
    unsigned long long sum = 0;
    printf("Stream read 32\n");
    for (unsigned int i = 0; i < POOL_SIZE / 4; i++) {
        sum += (unsigned long long)pool32[i];
    }
    
    printf("Stream sum 32: %llu\n", sum);
}

static inline void stream16()
{
    volatile unsigned short *pool16 = (void *)pool;
    
    printf("Stream write 16\n");
    for (unsigned int i = 0; i < POOL_SIZE / 2; i++) {
        pool16[i] = (unsigned short)i;
    }
    
    unsigned long long sum = 0;
    printf("Stream read 16\n");
    for (unsigned int i = 0; i < POOL_SIZE / 2; i++) {
        sum += (unsigned long long)pool16[i];
    }
    
    printf("Stream sum 16: %llu\n", sum);
}

static inline void stream8()
{
    volatile unsigned char *pool8 = (void *)pool;
    
    printf("Stream write 8\n");
    for (unsigned int i = 0; i < POOL_SIZE / 1; i++) {
        pool8[i] = (unsigned char)i;
    }
    
    unsigned long long sum = 0;
    printf("Stream read 8\n");
    for (unsigned int i = 0; i < POOL_SIZE / 1; i++) {
        sum += (unsigned long long)pool8[i];
    }
    
    printf("Stream sum 8: %llu\n", sum);
}

int main(int argc, char *argv[])
{
    //stream64();
    stream32();
    //stream16();
    //stream8();
    
    return 0;
}

