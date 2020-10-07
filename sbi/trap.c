#include "inttypes.h"
#include "csr.h"
#include "sbi.h"
#include "assert.h"

extern void _mtrap_entry();

static struct mtrap_context mtrap_context;

static mtrap_handler_t mint_handlers[64];
static mtrap_handler_t mexcept_handlers[64];

void init_mtrap()
{
    // disable all ints
    csr_write(mie, 0);
    csr_clear(mstatus, 0xf);
    
    // set trap entry
    csr_write(mtvec, _mtrap_entry);
    
    // don't delegate anything
    csr_write(medeleg, 0);
    csr_write(mideleg, 0);
    
    // set mscratch
    csr_write(mscratch, &mtrap_context);
}

void reg_mint_handler(int code, mtrap_handler_t handler)
{
    panic_if(code >= 64, "code %d must be < 64!\n", code);
    mint_handlers[code] = handler;
}

void reg_mexcept_handler(int code, mtrap_handler_t handler)
{
    panic_if(code >= 64, "code %d must be < 64!\n", code);
    mexcept_handlers[code] = handler;
}

void dispatch_mtrap(struct mtrap_context *ctxt)
{
    mtrap_handler_t handler = NULL;
    unsigned long mcause = ctxt->cause;
    
    unsigned long code = (mcause << 1) >> 1;
    int is_int = mcause >> (sizeof(unsigned long) * 8 - 1);
    if (is_int) {
        if (code < 64 && mint_handlers[code]) {
            handler = mint_handlers[code];
        }
    } else {
        if (code < 64 && mexcept_handlers[code]) {
            handler = mexcept_handlers[code];
        }
    }
    
    panic_if(!handler, "[SBI] Unable to handle trap, cause: %x\n", mcause);
    handler(ctxt);
}

void enable_mint()
{
    csr_set(mstatus, 0x8);
}

void disable_mint()
{
    csr_clear(mstatus, 0x8);
}

