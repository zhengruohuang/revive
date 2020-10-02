#ifndef __CSR_H__
#define __CSR_H__

#define csr_swap(reg, val) \
    __asm__ __volatile__ ( \
        "csrrw %[dst], " #reg ", %[src]" \
        : [dst] "=r" (val) \
        : [src] "rK" (val) \
        : "memory" \
    )

#define csr_read(reg, val) \
    __asm__ __volatile__ ( \
        "csrr %[dst], " #reg ";" \
        : [dst] "=r"(val) \
        : \
        : "memory" \
    )

#define csr_write(reg, val) \
    __asm__ __volatile__ ( \
        "csrw " #reg ", %[src];" \
        : \
        : [src] "r"(val) \
        : "memory" \
    )

#define csr_set(reg, mask) \
    __asm__ __volatile__ ( \
        "csrrs x0, " #reg ", %[src];" \
        : \
        : [src] "r"(mask) \
        : "memory" \
    )

#define csr_clear(reg, mask) \
    __asm__ __volatile__ ( \
        "csrrc x0, " #reg ", %[src];" \
        : \
        : [src] "r"(mask) \
        : "memory" \
    )

#endif

