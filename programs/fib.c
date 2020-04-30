#include "bare.h"

int main(int argc, char *argv[])
{
    int dest = (int)read_input(0);
    int f1 = 1, f2 = 1;
    
    if (dest == 1 || dest == 2) {
        write_output(0, 1);
        return 0;
    }
    
    for (int i = 2; i < dest; i++) {
        int save_f2 = f2;
        f2 += f1;
        f1 = save_f2;
    }
    
    write_output(0, (unsigned long)f2);
    return 0;
}

