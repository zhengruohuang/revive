`include "include/config.svh"
`include "include/reg.svh"
`include "include/wb.svh"

module writeback_arbiter (
    input   wb2_req_t               i_alu1_req,
    input   wb_req_t                i_mul_req,
    
    input   wb_req_t                i_alu2_req,
    input   wb_req_t                i_mem_req,
    
    output                          o_mul_grant,
    output                          o_mem_grant,
    
    output  int_arch_reg_write_t    o_int_reg   [0:`INT_ARCH_REG_WRITE_PORTS - 1],
    output  sys_arch_reg_write_t    o_sys_reg   [0:`SYS_ARCH_REG_WRITE_PORTS - 1],
    output  rob_sel_t               o_rob_idx   [0:`INT_ARCH_REG_WRITE_PORTS - 1],
    
    input   i_rst_n
);

//    // WBs from the two ALUs are always granted
//    assign o_alu1_grant = i_alu1_wb.valid | i_sys_wb.valid;
//    assign o_alu2_grant = i_alu2_wb.valid;
//    assign o_mul_grant = i_mem_wb.valid & (~o_alu1_grant | ~o_alu2_grant);
//    assign o_mem_grant = i_mem_wb.valid & (
//                { o_alu1_grant, o_alu2_grant, o_mul_grant } == 3'b000 |
//                { o_alu1_grant, o_alu2_grant, o_mul_grant } == 3'b001 |
//                { o_alu1_grant, o_alu2_grant, o_mul_grant } == 3'b010 |
//                { o_alu1_grant, o_alu2_grant, o_mul_grant } == 3'b100);
//    
//    assign o_int_reg_wb[0] = i_alu1_wb.valid ? i_alu1_wb : i_mul_wb;
//    assign o_int_reg_wb[1] = i_alu2_wb.valid ? i_alu2_wb : i_mem_wb;
//    assign o_sys_reg_wb[0] = i_sys_wb;
//    
//    assign o_rob_write[0] = i_alu1_wb.valid | i_mul_wb.valid | i_sys_wb.valid;
//    assign o_rob_write[1] = i_alu2_wb.valid | i_mem_wb.valid;
//    
//    assign o_rob_idx[0] = (i_alu1_wb.valid | i_sys_wb.valid) ? i_alu1_rob_idx : i_mul_rob_idx;
//    assign o_rob_idx[1] = i_alu2_wb.valid ? i_alu2_rob_idx : i_mem_rob_idx;

endmodule

