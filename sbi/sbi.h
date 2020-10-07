#ifndef __SBI_H__
#define __SBI_H__

#include "inttypes.h"

enum sbi_error_type {
    SBI_SUCCESS = 0,
    SBI_ERR_FAILED = -1,
    SBI_ERR_NOT_SUPPORTED = -2,
    SBI_ERR_INVALID_PARAM = -3,
    SBI_ERR_DENIED = -4,
    SBI_ERR_INVALID_ACCESS = -5,
    SBI_ERR_ALREADY_AVAILABLE = -6,
};

enum sbi_ext_num {
    SBI_EXT_BASE = 0x10,
    SBI_EXT_TIMER = 0x54494D45,
    SBI_EXT_IPI = 0x735049,
    SBI_EXT_RFENCE = 0x52464E43,
    SBI_EXT_HSM = 0x48534D,
    
    SBI_EXT_LEGACY_SET_TIMER = 0x0,
    SBI_EXT_LEGACY_PUTCHAR = 0x1,
    SBI_EXT_LEGACY_GETCHAR = 0x2,
    SBI_EXT_LEGACY_IPI_CLEAR = 0x3,
    SBI_EXT_LEGACY_IPI_SEND = 0x4,
    SBI_EXT_LEGACY_REMOTE_FENCE_I = 0x5,
    SBI_EXT_LEGACY_REMOTE_SFENCE_VMA = 0x6,
    SBI_EXT_LEGACY_REMOTE_SFENCE_VMA_ASID = 0x7,
    SBI_EXT_LEGACY_SHUTDOWN = 0x8,
};

enum sbi_func_num {
    SBI_FUNC_SPEC_VER = 0,
    SBI_FUNC_IMPL_ID = 1,
    SBI_FUNC_IMPL_VER = 2,
    SBI_FUNC_PROBE_EXT = 3,
    SBI_FUNC_GET_MVENDORID = 4,
    SBI_FUNC_GET_MARCHID = 5,
    SBI_FUNC_GET_MIMPID = 6,
    
    SBI_FUNC_REMOTE_FENCE_I = 0,
    SBI_FUNC_REMOTE_SFENCE_VMA = 1,
    SBI_FUNC_REMOTE_SFENCE_VMA_ASID = 2,
    SBI_FUNC_REMOTE_HFENCE_GVMA_VMID = 3,
    SBI_FUNC_REMOTE_HFENCE_GVMA = 4,
    SBI_FUNC_REMOTE_HFENCE_VVMA_ASID = 5,
    SBI_FUNC_REMOTE_HFENCE_VVMA = 6,
    
    SBI_FUNC_START = 0,
    SBI_FUNC_STOP = 1,
    SBI_FUNC_GET_STATUS = 2,
};

struct mtrap_context {
    union {
        unsigned long gpr[32];
        struct {
            unsigned long zero, ra, sp, gp, tp, t0, t1, t2, s0, s1;
            unsigned long a0, a1, a2, a3, a4, a5, a6, a7;
            unsigned long s2, s3, s4, s5, s6, s7, s8, s9, s10, s11;
            unsigned long t3, t4, t5, t6;
        };
    };
    unsigned long status;
    unsigned long pc;
    unsigned long cause;
    unsigned long tval;
};

typedef void (*mtrap_handler_t)(struct mtrap_context *ctxt);

extern void init_mtrap();
extern void reg_mint_handler(int code, mtrap_handler_t handler);
extern void reg_mexcept_handler(int code, mtrap_handler_t handler);

extern void init_ecall();

extern void set_timer_delta(uint64_t delta);
extern void init_timer();

extern void boot_supervisor();

extern void sim_putchar(int ch);
extern void sim_term(int code);

#endif

