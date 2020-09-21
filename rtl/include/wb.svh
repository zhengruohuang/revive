`ifndef __WB_SVH__
`define __WB_SVH__


`include "include/config.svh"


typedef struct packed {
    int_arch_reg_write_t    int_wb;
    sys_arch_reg_write_t    sys_wb; // PC is one of sys regs
    rob_idx_t               rob_idx;
    logic                   valid;
} wb2_req_t;


typedef struct packed {
    int_arch_reg_write_t    int_wb;
    rob_idx_t               rob_idx;
    logic                   valid;
} wb_req_t;


`endif

