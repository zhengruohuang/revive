`ifndef __EXCEPT_SVH__
`define __EXCEPT_SVH__


/*
 * Exception
 */
typedef enum logic [3:0] {
    EXCEPT_PC_MISALIGN,
    EXCEPT_PC_ACCESS_FAULT,
    EXCEPT_UNKNOW_INSTR,
    EXCEPT_BREAKPOINT,
    EXCEPT_LOAD_MISALIGN,
    EXCEPT_LOAD_ACCESS_FAULT,
    EXCEPT_STORE_MISALIGN,
    EXCEPT_STORE_ACCESS_FAULT,
    EXCEPT_ECALL_FROM_U,
    EXCEPT_ECALL_FROM_S,
    EXCEPT_RESERVED1,
    EXCEPT_ECALL_FROM_M,
    EXCEPT_ITLB_PAGE_FAULT,
    EXCEPT_LOAD_PAGE_FAULT,
    EXCEPT_RESERVED2,
    EXCEPT_STORE_PAGE_FAULT
} except_code_t;


typedef struct packed {
    except_code_t   code;
    logic           valid;
} except_t;


`endif

