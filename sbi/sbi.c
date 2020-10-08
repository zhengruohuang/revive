#include "inttypes.h"
#include "sbi.h"
#include "csr.h"
#include "print.h"
#include "sim_ctrl.h"

/*
 * Sim ctrl
 */
void sim_term(int code)
{
    volatile int *buf = (void *)SIM_CTRL_TERM;
    *buf = code;
}

/*
 * BSS
 */
extern int __bss_start;
extern int __bss_end;

static void init_bss()
{
    int *cur;
    for (cur = &__bss_start; cur < &__bss_end; cur++) {
        *cur = 0;
    }
}

/*
 * Trap delegate
 */
static void init_mdeleg()
{
    // delegate exceptions
    csr_write(medeleg,
        (0x1 << 0)  |   // Instr addr misalign
        (0x1 << 3)  |   // Breakpoint
        (0x1 << 8)  |   // ECALL from U
        (0x1 << 12) |   // Instr page fault
        (0x1 << 13) |   // Load page fault
        (0x1 << 15)     // Store/AMO page fault
    );
    
    // delegate interrupts
    csr_write(mideleg,
        (0x1 << 9)  |   // SEIP
        (0x1 << 5)  |   // STIP
        (0x1 << 1)      // SSIP
    );
}

/*
 * Counters
 */
static void init_counters()
{
    csr_write(mcounteren, 0xffffffff); // Make all counters readable in S
}

/*
 * SBI entry
 */
void sbi_entry()
{
    // Init
    init_bss();
    init_mtrap();
    init_mdeleg();
    init_counters();
    init_ecall();
    init_timer();
    
    printf("[SBI] Initialized\n");
    
    // Boot
    boot_supervisor();
    
    // Should never reach here
    sim_term(-1);
    while (1);
}

