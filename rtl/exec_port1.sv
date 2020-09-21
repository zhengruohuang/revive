`include "include/config.svh"
`include "include/ps.svh"
`include "include/reg.svh"
`include "include/wb.svh"

module exec_port1 (
    input                           i_flush,
    input   program_state_t         i_ps,
    
    input   issued_instr_t          i_instr,
    input   reg_data_t              i_src1_data,
    input   reg_data_t              i_src2_data,
    input   reg_data_t              i_sys_data,
    
    input                           i_mul_grant,
    output                          o_mul_ready,
    output  wb2_req_t               o_alu_wb_req,
    output  wb_req_t                o_mul_wb_req,
    
    input   i_clk,
    input   i_rst_n
);


endmodule

