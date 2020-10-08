#include "inttypes.h"
#include "csr.h"
#include "io.h"
#include "sbi.h"
#include "print.h"

static inline int get_spec_ver(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_SUCCESS;
}

static inline int get_impl_id(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_SUCCESS;
}

static inline int get_impl_ver(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_SUCCESS;
}

static inline int get_probe_ext(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_SUCCESS;
}

static inline int get_mvendorid(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_SUCCESS;
}

static inline int get_marchid(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_SUCCESS;
}

static inline int get_mimpid(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_SUCCESS;
}

static inline int set_timer(struct mtrap_context *ctxt, unsigned long *value)
{
#if __riscv_xlen == 32
    uint64_t mtcmp = ((uint64_t)ctxt->gpr[11] << 32) | (uint64_t)ctxt->gpr[10];
#else
    uint64_t mtcmp = ctxt->gpr[10];
#endif
    set_timer_event(mtcmp);
    *value = 0;
    return SBI_SUCCESS;
}

static inline int send_ipi(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_ERR_NOT_SUPPORTED;
}

static inline int clear_ipi(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_ERR_NOT_SUPPORTED;
}

static inline int console_putchar(struct mtrap_context *ctxt, unsigned long *value)
{
    int ch = ctxt->gpr[10];
    if (ch) {
        uart_putchar(ch);
    }
    *value = 0;
    return SBI_SUCCESS;
}

static inline int console_getchar(struct mtrap_context *ctxt, unsigned long *value)
{
    int ch = uart_getchar();
    return ch ? ch & 0xff : -1;
}

static inline int remote_fence_i(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_ERR_NOT_SUPPORTED;
}

static inline int remote_sfence_vma(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_ERR_NOT_SUPPORTED;
}

static inline int remote_sfence_vma_asid(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_ERR_NOT_SUPPORTED;
}

static inline int remote_hfence_gvma_vmid(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_ERR_NOT_SUPPORTED;
}

static inline int remote_hfence_gvma(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_ERR_NOT_SUPPORTED;
}

static inline int remote_hfence_vvma_asid(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_ERR_NOT_SUPPORTED;
}

static inline int remote_hfence_vvma(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_ERR_NOT_SUPPORTED;
}

static inline int hart_start(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_ERR_NOT_SUPPORTED;
}

static inline int hart_shutdown(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_ERR_NOT_SUPPORTED;
}

static inline int hart_status(struct mtrap_context *ctxt, unsigned long *value)
{
    *value = 0;
    return SBI_ERR_NOT_SUPPORTED;
}

static void ecall_handler(struct mtrap_context *ctxt)
{
    uint32_t ext_id = ctxt->gpr[17]; // a7
    uint32_t func_id = ctxt->gpr[16]; // a6
    
    int err = SBI_ERR_NOT_SUPPORTED;
    unsigned long value = 0;
    switch (ext_id) {
    // Base
    case SBI_EXT_BASE:
        switch (func_id) {
        case SBI_FUNC_SPEC_VER:
            err = get_spec_ver(ctxt, &value);
            break;
        case SBI_FUNC_IMPL_ID:
            err = get_impl_id(ctxt, &value);
            break;
        case SBI_FUNC_IMPL_VER:
            err = get_impl_ver(ctxt, &value);
            break;
        case SBI_FUNC_PROBE_EXT:
            err = get_probe_ext(ctxt, &value);
            break;
        case SBI_FUNC_GET_MVENDORID:
            err = get_mvendorid(ctxt, &value);
            break;
        case SBI_FUNC_GET_MARCHID:
            err = get_marchid(ctxt, &value);
            break;
        case SBI_FUNC_GET_MIMPID:
            err = get_mimpid(ctxt, &value);
            break;
        default:
            break;
        }
        break;
    
    // Timer
    case SBI_EXT_TIMER:
        err = set_timer(ctxt, &value);
        break;
    
    // IPI
    case SBI_EXT_IPI:
        err = send_ipi(ctxt, &value);
        break;
    
    // Remote fence
    case SBI_EXT_RFENCE:
        switch (func_id) {
        case SBI_FUNC_REMOTE_FENCE_I:
            err = remote_fence_i(ctxt, &value);
            break;
        case SBI_FUNC_REMOTE_SFENCE_VMA:
            err = remote_sfence_vma(ctxt, &value);
            break;
        case SBI_FUNC_REMOTE_SFENCE_VMA_ASID:
            err = remote_sfence_vma_asid(ctxt, &value);
            break;
        case SBI_FUNC_REMOTE_HFENCE_GVMA_VMID:
            err = remote_hfence_gvma_vmid(ctxt, &value);
            break;
        case SBI_FUNC_REMOTE_HFENCE_GVMA:
            err = remote_hfence_gvma(ctxt, &value);
            break;
        case SBI_FUNC_REMOTE_HFENCE_VVMA_ASID:
            err = remote_hfence_vvma_asid(ctxt, &value);
            break;
        case SBI_FUNC_REMOTE_HFENCE_VVMA:
            err = remote_hfence_vvma(ctxt, &value);
            break;
        default:
            break;
        }
        break;
    
    // HSM
    case SBI_EXT_HSM:
        switch (func_id) {
            case SBI_FUNC_START:
                err = hart_start(ctxt, &value);
                break;
            case SBI_FUNC_STOP:
                err = hart_shutdown(ctxt, &value);
                break;
            case SBI_FUNC_GET_STATUS:
                err = hart_status(ctxt, &value);
                break;
            default:
                break;
        }
        break;
    
    // Legacy
    case SBI_EXT_LEGACY_SET_TIMER:
        err = set_timer(ctxt, &value);
        break;
    case SBI_EXT_LEGACY_PUTCHAR:
        err = console_putchar(ctxt, &value);
        break;
    case SBI_EXT_LEGACY_GETCHAR:
        err = console_getchar(ctxt, &value);
        break;
    case SBI_EXT_LEGACY_IPI_CLEAR:
        err = clear_ipi(ctxt, &value);
        break;
    case SBI_EXT_LEGACY_IPI_SEND:
        err = send_ipi(ctxt, &value);
        break;
    case SBI_EXT_LEGACY_REMOTE_FENCE_I:
        err = remote_fence_i(ctxt, &value);
        break;
    case SBI_EXT_LEGACY_REMOTE_SFENCE_VMA:
        err = remote_sfence_vma(ctxt, &value);
        break;
    case SBI_EXT_LEGACY_REMOTE_SFENCE_VMA_ASID:
        err = remote_sfence_vma_asid(ctxt, &value);
        break;
    case SBI_EXT_LEGACY_SHUTDOWN:
        err = hart_shutdown(ctxt, &value);
        break;
    
    // Unknown
    default:
        break;
    }
    
    if (err == SBI_ERR_NOT_SUPPORTED) {
        printf("[SBI] Unimpl ext: %x, func: %x\n", ext_id, func_id);
    }
    
    ctxt->gpr[10] = (long)err; // a0
    ctxt->gpr[11] = value; // a1
    ctxt->pc += 4;
}

void init_ecall()
{
    reg_mexcept_handler(9, ecall_handler); // from S
    reg_mexcept_handler(11, ecall_handler); // from M
}

