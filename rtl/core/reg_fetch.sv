`include "include/config.svh"
`include "include/instr.svh"

`include "lib/sram_1w2r.sv"

module reg_fetch (
    input                       i_flush,
    input                       i_stall,
    
    // From previous stage - Sched
    input   issued_instr_t      i_instr,
    
    // To next stage - Ex
    output  issued_instr_t      o_instr,
    output  reg_data_t          o_data_rs1,
    output  reg_data_t          o_data_rs2,
    
    // From WB
    input   int_arch_reg_wb_t   i_int_reg_wb,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    sram_1w2r #(
        .WIDTH      (32),
        .DEPTH      (32)
    ) reg_file (
        .i_w_e      (i_int_reg_wb.valid),
        .i_w_addr   (i_int_reg_wb.idx),
        .i_w_data   (i_int_reg_wb.data),
        .i_r0_e     (~i_stall & i_instr.decode.rs1.valid),
        .i_r0_addr  (i_instr.decode.rs1.idx),
        .o_r0_data  (o_data_rs1),
        .i_r1_e     (~i_stall & i_instr.decode.rs2.valid),
        .i_r1_addr  (i_instr.decode.rs2.idx),
        .o_r1_data  (o_data_rs2),
        .i_clk      (i_clk)
    );
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush) begin
            o_instr <= '0;
        end
        
        else if (~i_stall) begin
            o_instr <= i_instr;
            
            if (i_log_fd != '0) begin
                $fdisplay(i_log_fd, "[RF ] Valid: %d, PC @ %h, Decode: %h, WB Valid: %d @ %d = %h",
                          i_instr.valid, i_instr.pc, i_instr.decode, i_int_reg_wb.valid, i_int_reg_wb.idx, i_int_reg_wb.data);
            end
        end
    end

endmodule

