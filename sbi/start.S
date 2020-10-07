#define BOOT_STACK_SIZE 4096

.section ".text.boot"

.global _start
.extern sbi_entry

_start:
    /* Set up machine state */
    li      x1, 0
    li      x2, 0
    li      x3, 0
    li      x4, 0
    li      x5, 0
    li      x6, 0
    li      x7, 0
    li      x8, 0
    li      x9, 0
    li      x10, 0
    li      x11, 0
    li      x12, 0
    li      x13, 0
    li      x14, 0
    li      x15, 0
    li      x16, 0
    li      x17, 0
    li      x18, 0
    li      x19, 0
    li      x20, 0
    li      x21, 0
    li      x22, 0
    li      x23, 0
    li      x24, 0
    li      x25, 0
    li      x26, 0
    li      x27, 0
    li      x28, 0
    li      x29, 0
    li      x30, 0
    li      x31, 0

    /* Set up stack, create stack frame */
    la      sp, boot_stack + BOOT_STACK_SIZE
    addi    sp, sp, -16

    /* Go to C */
    jal     sbi_entry

    // Should never reach here
    j       .

.section ".data.stack"

.align 12
boot_stack:
    .space BOOT_STACK_SIZE

