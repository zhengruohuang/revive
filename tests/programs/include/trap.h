#ifndef __TARP_H__
#define __TARP_H__

struct mtrap_context {
    unsigned long gpr[32];
    unsigned long status;
    unsigned long pc;
    unsigned long cause;
    unsigned long tval;
};

typedef void (*mtrap_handler_t)(struct mtrap_context *ctxt);

extern void init_mtrap();
extern void reg_mint_handler(int code, mtrap_handler_t handler);
extern void reg_mexcept_handler(int code, mtrap_handler_t handler);

extern void enable_mint();
extern void disable_mint();

#endif

