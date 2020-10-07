#include "csr.h"

extern unsigned long vmlinux_bytes;
extern char vmlinux[];

extern unsigned long dtb_bytes;
extern char dtb[];

void boot_supervisor()
{
    // prepare trap return, MPP = S, MPIE = 1
    csr_write(mepc, vmlinux);
    csr_write(mstatus, (0x1 << 11) | (1 << 7));
    
    // switch to S
    register unsigned long a0 __asm__ ("a0") = 0;
    register unsigned long a1 __asm__ ("a1") = (unsigned long)dtb;
    register unsigned long a2 __asm__ ("a2") = 0;
    register unsigned long a3 __asm__ ("a3") = 0;
    __asm__ __volatile__ (
        "mret;"
        :
        : "r" (a0), "r" (a1), "r" (a2), "r" (a3)
        : "memory"
    );
}

