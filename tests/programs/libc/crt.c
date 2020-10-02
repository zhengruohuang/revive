#include "bare.h"

extern int main(int argc, char *argv[]);

extern int __bss_start;
extern int __bss_end;

static void init_bss()
{
    int *cur;
    for (cur = &__bss_start; cur < &__bss_end; cur++) {
        *cur = 0;
    }
}

void crt()
{
    // Init BSS
    init_bss();
    
    // Prepare argv
    char *argv[] = { "" };
    int status = main(1, argv);
    
    // Done
    sim_term(status);
    
    // Should never reach here
    while (1);
}

