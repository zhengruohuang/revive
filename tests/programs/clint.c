#include "bare.h"
#include "csr.h"
#include "trap.h"
#include <stdio.h>
#include <assert.h>

#define CLINT_MSIP_ADDR     (SIM_CLINT_START + 0x0ul)
#define CLINT_MTIMECMP_ADDR (SIM_CLINT_START + 0x4000ul)
#define CLINT_MTIME_ADDR    (SIM_CLINT_START + 0xbff8ul)

#define TIME_OUT_CYCLES     0x40000000

static void update_timecmp()
{
    unsigned long long mtime = io_read64(CLINT_MTIME_ADDR);
    unsigned long long mtimecmp = mtime + 10000;
    io_write64(CLINT_MTIMECMP_ADDR, mtimecmp);
}

static void init_clint()
{
    // unmask timer interrupt
    csr_set(mie, 0x80);
    io_write64(CLINT_MTIME_ADDR, 0);
    
    update_timecmp();
}

static void clint_handler(struct mtrap_context *ctxt)
{
    static volatile int counter = 0;
    printf("%d\n", counter);
    
    if (counter == 10) {
        exit(0);
    }
    
    counter++;
    update_timecmp();
}

int main(int argc, char *argv[])
{
    init_mtrap();
    init_clint();
    reg_mint_handler(7, clint_handler);
    printf("Clint initialized!\n");
    
    enable_mint();
    
    for (volatile unsigned int i = 0; i < TIME_OUT_CYCLES; i++);
    
    panic("Clint timed out after %x cycles!\n", TIME_OUT_CYCLES);
    while (1);
}

