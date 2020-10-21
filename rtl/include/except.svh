`ifndef __EXCEPT_SVH__
`define __EXCEPT_SVH__


/*
 * Exception
 */
typedef enum logic [4:0] {
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
    EXCEPT_STORE_PAGE_FAULT,
    
    NUM_STD_EXCEPTS = 5'b10000,
    
    EXCEPT_NONE,
    EXCEPT_MISPRED,
    EXCEPT_FLUSH,
    EXCEPT_INTERRUPT,
    EXCEPT_TRAP,
    EXCEPT_SYS,
    
    NUM_EXCEPTS
} except_code_t;

typedef struct packed {
    except_code_t   code;
    logic [31:0]    tval;
    logic           valid;
} except_t;

`define IS_STD_EXCEPT_CODE(code)    (~code[4])

`define EXCEPT_PC_MISALIGN(tval)        { EXCEPT_PC_MISALIGN, tval, 1'b1 }
`define EXCEPT_INVALID_INSTR(tval)      { EXCEPT_UNKNOW_INSTR, tval, 1'b1 }
`define EXCEPT_LOAD_MISALIGN(tval)      { EXCEPT_LOAD_MISALIGN, tval, 1'b1 }
`define EXCEPT_STORE_MISALIGN(tval)     { EXCEPT_STORE_MISALIGN, tval, 1'b1 }
`define EXCEPT_ITLB_PAGE_FAULT(tval)    { EXCEPT_ITLB_PAGE_FAULT, tval, 1'b1 }
`define EXCEPT_LOAD_PAGE_FAULT(tval)    { EXCEPT_LOAD_PAGE_FAULT, tval, 1'b1 }
`define EXCEPT_STORE_PAGE_FAULT(tval)   { EXCEPT_STORE_PAGE_FAULT, tval, 1'b1 }

`define EXCEPT_NONE             { EXCEPT_NONE, 32'b0, 1'b0 }
`define EXCEPT_MISPRED          { EXCEPT_MISPRED, 32'b0, 1'b1 }
`define EXCEPT_FLUSH            { EXCEPT_FLUSH, 32'b0, 1'b1 }
`define EXCEPT_INTERRUPT        { EXCEPT_INTERRUPT, 32'b0, 1'b1 }
`define EXCEPT_TRAP             { EXCEPT_TRAP, 32'b0, 1'b1 }
`define EXCEPT_SYS              { EXCEPT_SYS, 32'b0, 1'b1 }

`endif

