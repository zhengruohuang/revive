#include "bare.h"
#include <stdio.h>

int main(int argc, char *argv[])
{
    int dest = 50;
    unsigned long long f1 = 1, f2 = 1;
    
    if (dest == 1 || dest == 2) {
        printf("Fib #%d = 1\n", dest);
        write_output(0, 1);
        return 0;
    }
    
    for (int i = 3; i <= dest; i++) {
        unsigned long long save_f2 = f2;
        f2 += f1;
        f1 = save_f2;
        
        if (!(i % 10)) {
            printf("Fib #%d = %llu\n", i, f2);
        }
    }
    
    printf("Fib #%d = %llu\n", dest, f2);
    write_output(0, (unsigned long)f2);
    return 0;
}

