#include "inttypes.h"
#include "sim_ctrl.h"
#include "csr.h"
#include "io.h"
#include "sbi.h"
#include "print.h"

#define CLINT_MSIP_ADDR     (SIM_CLINT_START + 0x0ul)
#define CLINT_MTIMECMP_ADDR (SIM_CLINT_START + 0x4000ul)
#define CLINT_MTIME_ADDR    (SIM_CLINT_START + 0xbff8ul)

static void timer_handler(struct mtrap_context *ctxt)
{
    csr_clear(mie, 0x1 << 7);
    csr_set(mip, 0x1 << 5);
}

void set_timer_event(uint64_t mtimecmp)
{
    //uint64_t mtime = io_read64(CLINT_MTIME_ADDR);
    //uint64_t mtimecmp = mtime + delta;
    io_write64(CLINT_MTIMECMP_ADDR, mtimecmp);
    
    csr_clear(mip, 0x1 << 7);
    csr_clear(mip, 0x1 << 5);
    //csr_set(mie, 0x1 << 5);
    csr_set(mie, 0x1 << 7);
    
    //printf("[SBI] Timer: %llu, next: %llu\n", mtime, mtimecmp);
}

void init_timer()
{
    csr_clear(mie, 0x1 << 7);
    io_write64(CLINT_MTIME_ADDR, 0);
    reg_mint_handler(7, timer_handler);
}

