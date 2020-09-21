#include "bare.h"

extern int main(int argc, char *argv[]);

void crt()
{
    char *argv[] = { "" };
    int status = main(1, argv);
    
    // Done
    sim_term(status);
    
    // Should never reach here
    while (1);
}

