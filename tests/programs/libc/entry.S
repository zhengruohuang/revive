.global _mtrap_entry
.extern dispatch_mtrap

.align 4
_mtrap_entry:
    // swap mscratch and sp
    csrrw   sp, mscratch, sp
    //addi    sp, sp, -(36 * 4)
    
    // save GPRs
    sw      x31, (4 * 31)(sp)
    sw      x30, (4 * 30)(sp)
    sw      x29, (4 * 29)(sp)
    sw      x28, (4 * 28)(sp)
    sw      x27, (4 * 27)(sp)
    sw      x26, (4 * 26)(sp)
    sw      x25, (4 * 25)(sp)
    sw      x24, (4 * 24)(sp)
    sw      x23, (4 * 23)(sp)
    sw      x22, (4 * 22)(sp)
    sw      x21, (4 * 21)(sp)
    sw      x20, (4 * 20)(sp)
    sw      x19, (4 * 19)(sp)
    sw      x18, (4 * 18)(sp)
    sw      x17, (4 * 17)(sp)
    sw      x16, (4 * 16)(sp)
    sw      x15, (4 * 15)(sp)
    sw      x14, (4 * 14)(sp)
    sw      x13, (4 * 13)(sp)
    sw      x12, (4 * 12)(sp)
    sw      x11, (4 * 11)(sp)
    sw      x10, (4 * 10)(sp)
    sw      x9,  (4 *  9)(sp)
    sw      x8,  (4 *  8)(sp)
    sw      x7,  (4 *  7)(sp)
    sw      x6,  (4 *  6)(sp)
    sw      x5,  (4 *  5)(sp)
    sw      x4,  (4 *  4)(sp)
    sw      x3,  (4 *  3)(sp)
    //sw    x2,  (4 *  2)(sp) // sp
    sw      x1,  (4 *  1)(sp)
    //sw    x0,  (4 *  0)(sp) // zero
    
    // save SP
    csrr    s0, mscratch
    sw      s0,  (4 *  2)(sp)
    
    // save CSRs
    csrr    s0, mstatus
    sw      s0,  (4 * 32)(sp)
    
    csrr    s0, mtval
    sw      s0,  (4 * 35)(sp)
    
    csrr    s0, mcause
    sw      s0,  (4 * 34)(sp)
    
    csrr    s0, mepc
    sw      s0,  (4 * 33)(sp)
    
    // dispatch
    mv      a0, sp
    jal     dispatch_mtrap
    //mv    sp, a0
    
    // restore CSRs
    lw      s0,  (4 * 33)(sp)
    csrw    mepc, s0
    
    lw      s0,  (4 * 32)(sp)
    csrw    mstatus, s0
    
    // restore GPRs
    //lw    x0,  (4 *  0)(sp) // zero
    lw      x1,  (4 *  1)(sp)
    //lw    x2,  (4 *  2)(sp) // sp
    lw      x3,  (4 *  3)(sp)
    lw      x4,  (4 *  4)(sp)
    lw      x5,  (4 *  5)(sp)
    lw      x6,  (4 *  6)(sp)
    lw      x7,  (4 *  7)(sp)
    lw      x8,  (4 *  8)(sp)
    lw      x9,  (4 *  9)(sp)
    lw      x10, (4 * 10)(sp)
    lw      x11, (4 * 11)(sp)
    lw      x12, (4 * 12)(sp)
    lw      x13, (4 * 13)(sp)
    lw      x14, (4 * 14)(sp)
    lw      x15, (4 * 15)(sp)
    lw      x16, (4 * 16)(sp)
    lw      x17, (4 * 17)(sp)
    lw      x18, (4 * 18)(sp)
    lw      x19, (4 * 19)(sp)
    lw      x20, (4 * 20)(sp)
    lw      x21, (4 * 21)(sp)
    lw      x22, (4 * 22)(sp)
    lw      x23, (4 * 23)(sp)
    lw      x24, (4 * 24)(sp)
    lw      x25, (4 * 25)(sp)
    lw      x26, (4 * 26)(sp)
    lw      x27, (4 * 27)(sp)
    lw      x28, (4 * 28)(sp)
    lw      x29, (4 * 29)(sp)
    lw      x30, (4 * 30)(sp)
    lw      x31, (4 * 31)(sp)
    
    // restore SP
    //addi    sp, sp, (36 * 4)
    csrrw   sp, mscratch, sp
    mret
    
    // should never reach here
    j       .

