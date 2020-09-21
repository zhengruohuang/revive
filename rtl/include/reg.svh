`ifndef __REG_SVH__
`define __REG_SVH__


`include "include/config.svh"


/*
 * Reg state
 */
typedef enum logic [1:0] {
    REG_READY,
    REG_BUSY,
    REG_BYPASS
} reg_state_t;


/*
 * Reg read and write
 */
typedef logic [`DATA_WIDTH - 1:0]           reg_data_t;
typedef logic [`INT_ARCH_REGS_BITS - 1:0]   int_arch_reg_idx_t;
typedef logic [`SYS_ARCH_REGS_BITS - 1:0]   sys_arch_reg_idx_t;


typedef struct packed {
    int_arch_reg_idx_t  idx;
    logic               valid;
} int_arch_reg_sel_t;

function int_arch_reg_sel_t compose_int_reg_sel;
    input int_arch_reg_idx_t    idx;
    input logic                 valid;
    begin
        compose_int_reg_sel = { idx, valid };
    end
endfunction

`define INVALID_REG { 5'b0, 1'b0 }


typedef struct packed {
    sys_arch_reg_idx_t  idx;
    logic               valid;
} sys_arch_reg_sel_t;

function sys_arch_reg_sel_t compose_sys_reg_sel;
    input sys_arch_reg_idx_t    idx;
    input logic                 valid;
    begin
        compose_sys_reg_sel = { idx, valid };
    end
endfunction


typedef struct packed {
    reg_data_t          data;
    int_arch_reg_idx_t  idx;
    logic               valid;
} int_arch_reg_wb_t;

typedef struct packed {
    reg_data_t          data;
    sys_arch_reg_idx_t  idx;
    logic               valid;
} sys_arch_reg_wb_t;

function int_arch_reg_wb_t compose_int_arch_reg_wb;
    input reg_data_t            data;
    input int_arch_reg_idx_t    idx;
    input logic                 valid;
    begin
        compose_int_arch_reg_wb = { valid ? data : '0, valid ? idx : '0, valid };
    end
endfunction


`endif

