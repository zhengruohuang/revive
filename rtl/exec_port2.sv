`include "include/config.svh"
`include "include/instr.svh"
`include "include/reg.svh"
`include "include/ps.svh"
`include "include/wb.svh"

module exec_port2 (
    input                           i_flush,
    input   program_state_t         i_ps,
    
    input   issued_instr_t          i_instr,
    input   reg_data_t              i_src1_data,
    input   reg_data_t              i_src2_data,
    
    input                           i_mem_grant,
    output                          o_mem_ready,
    output  wb_req_t                o_alu_wb_req,
    output  wb_req_t                o_mem_wb_req,
    
    input   i_clk,
    input   i_rst_n
);


endmodule

