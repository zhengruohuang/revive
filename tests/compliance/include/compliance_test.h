#ifndef __COMPLIANCE_TEST_H__
#define __COMPLIANCE_TEST_H__

#include "sim_ctrl.h"

//-----------------------------------------------------------------------
// Pass/Fail
//-----------------------------------------------------------------------
//#define RVTEST_SYNC fence
#define RVTEST_SYNC nop

/*
#define RVTEST_PASS                                                     \
        RVTEST_SYNC;                                                    \
        li TESTNUM, 1;                                                  \
        SWSIG (0, TESTNUM);                                             \
        ecall
*/

#define TESTNUM gp
#define RVTEST_FAIL                                                     \
        RVTEST_SYNC;                                                    \
        /* terminate simulation */                                      \
        li t0, -1;                                                       \
        li t1, SIM_CTRL_TERM;                                           \
        sw t0, 0(t1);                                                   \
        j .                                                             \
        
        /*
1:      beqz TESTNUM, 1b;                                               \
        sll TESTNUM, TESTNUM, 1;                                        \
        or TESTNUM, TESTNUM, 1;                                         \
        SWSIG (0, TESTNUM);                                             \
        la x1, end_testcode;                                            \
        jr x1;
        */

//-----------------------------------------------------------------------
// Test control
//-----------------------------------------------------------------------
#define RV_COMPLIANCE_HALT                                                    \
        /* tell simulation about location of begin_signature */               \
        la t0, begin_signature;                                               \
        li t1, SIM_CTRL_DUMP_BEGIN;                                           \
        sw t0, 0(t1);                                                         \
        /* tell simulation about location of end_signature */                 \
        la t0, end_signature;                                                 \
        li t1, SIM_CTRL_DUMP_END;                                             \
        sw t0, 0(t1);                                                         \
        /* dump signature */                                                  \
        li t0, 1;                                                             \
        li t1, SIM_CTRL_DUMP_SAVE;                                            \
        sw t0, 0(t1);                                                         \
        /* terminate simulation */                                            \
        li t0, 0;                                                             \
        li t1, SIM_CTRL_TERM;                                                 \
        sw t0, 0(t1);                                                         \
        j .;                                                                  \

#define RV_COMPLIANCE_RV32M

#define RV_COMPLIANCE_CODE_BEGIN                                              \
        .global _start_test;                                                  \
        _start_test:                                                          \

#define RV_COMPLIANCE_CODE_END                                                \
        .global _end_test;                                                    \
        _end_test:                                                            \
        j .;

#define RV_COMPLIANCE_DATA_BEGIN                                              \
        .align 8; .global begin_signature; begin_signature:

#define RV_COMPLIANCE_DATA_END                                                \
        .align 4; .global end_signature; end_signature:                       \
        .align 8; .global begin_regstate; begin_regstate:                     \
        .word 128;                                                            \
        .align 8; .global end_regstate; end_regstate:                         \
        .word 4;

#endif

