`include "include/config.svh"
`include "include/instr.svh"

module ldst_unit (
    input                       i_flush,
    input   program_state_t     i_ps,
    
    // From and to previous stage - Ex
    input   issued_instr_t      i_instr,
    input   reg_data_t          i_data,
    input   reg_data_t          i_data_rs2,
    output                      o_stall,
    
    // To next stage - Writeback
    output  issued_instr_t      o_instr,
    output  reg_data_t          o_data,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

            logic               in_except/*verilator public*/;

    wire    [7:0]               priv/*verilator public*/            = {  6'b0, i_ps.priv };
    wire    [7:0]               trans_enabled/*verilator public*/   = {  7'b0, i_ps.trans };
    wire    [31:0]              trans_base_ppn/*verilator public*/  = { 10'b0, i_ps.base };

    wire                        is_mem_op/*verilator public*/   = ~in_except & i_instr.valid & ~i_instr.except.valid & i_instr.decode.unit == UNIT_MEM;
    wire                        is_amo_op/*verilator public*/   = ~in_except & i_instr.valid & ~i_instr.except.valid & i_instr.decode.unit == UNIT_AMO;
    wire    reg_data_t          addr/*verilator public*/        = i_data;
    wire    reg_data_t          st_data/*verilator public*/     = i_data_rs2;
    wire    decode_op_t         op/*verilator public*/          = i_instr.decode.op;
    wire    decode_op_size_t    op_size/*verilator public*/     = i_instr.decode.op_size;
    wire                        op_w32/*verilator public*/      = i_instr.decode.op_size.w32[0];
    wire                        op_ignore/*verilator public*/   = i_instr.except.valid;

            reg_data_t          ld_data/*verilator public*/;
            logic               page_fault_ld/*verilator public*/;
            logic               page_fault_st/*verilator public*/;

    /*
     * Output
     */
    assign  o_stall = 1'b0;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_flush) begin
            o_instr <= '0;
            o_data <= '0;
            in_except <= '0;
        end
        
        else begin
            o_instr <= i_instr;
            o_data <= i_data;
            in_except <= 1'b0;
        end
    end
    
//    always_ff @ (posedge i_clk) begin
//        if (~i_rst_n | i_flush) begin
//            o_instr <= '0;
//            o_data <= '0;
//            in_except <= '0;
//        end
//        
//        else begin
//            o_instr <= page_fault_ld ? compose_issued_instr(i_instr.pc, i_instr.decode, `EXCEPT_LOAD_PAGE_FAULT(addr), 1'b1) :
//                       page_fault_st ? compose_issued_instr(i_instr.pc, i_instr.decode, `EXCEPT_STORE_PAGE_FAULT(addr), 1'b1) :
//                       i_instr;
//            o_data <= (is_mem_op | is_amo_op) ? ld_data : i_data;
//            if (i_instr.valid & (i_instr.except.valid | page_fault_ld | page_fault_st)) begin
//                in_except <= 1'b1;
//            end
//            
//            if (i_log_fd != '0) begin
//                $fdisplay(i_log_fd, "[LSU] Valid: %d, PC @ %h, Decode: %h, Data: %h, LD Data: %h, RS2: %h",
//                          i_instr.valid, i_instr.pc, i_instr.decode, (is_mem_op | is_amo_op) ? ld_data : i_data, ld_data, i_data_rs2);
//            end
//        end
//    end

endmodule

