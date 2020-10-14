`include "include/config.svh"
`include "include/instr.svh"

module schedule (
    input                       i_flush,
    input                       i_stall,
    
    // From and to previous stage - ID
    input   decoded_instr_t     i_instr,
    output                      o_stall,
    
    // To next stage - RF
    output  issued_instr_t      o_instr,
    
    // From WB
    input   int_arch_reg_wb_t   i_int_reg_wb,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    /*
     * Register state and
     * Schedule
     */
    logic   [31:0]  int_reg_inuse;
    
    wire    rs1_ready = (~i_instr.decode.rs1.valid |
                            (~int_reg_inuse[i_instr.decode.rs1.idx] | i_instr.decode.rs1.idx == '0 |
                                (i_int_reg_wb.valid & i_instr.decode.rs1.idx == i_int_reg_wb.idx)));
    wire    rs2_ready = (~i_instr.decode.rs2.valid |
                            (~int_reg_inuse[i_instr.decode.rs2.idx] | i_instr.decode.rs2.idx == '0 |
                                (i_int_reg_wb.valid & i_instr.decode.rs2.idx == i_int_reg_wb.idx)));
    wire    rd_ready = (~i_instr.decode.rd.valid |
                            (~int_reg_inuse[i_instr.decode.rd.idx] | i_instr.decode.rd.idx == '0 |
                                (i_int_reg_wb.valid & i_instr.decode.rd.idx == i_int_reg_wb.idx)));
    
    wire    can_issue = ~i_stall & i_instr.valid & (rs1_ready & rs2_ready & rd_ready);
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_flush) begin
            int_reg_inuse <= '0;
        end
        
        else if (can_issue) begin
            if (i_instr.decode.rd.valid & i_instr.decode.rd.idx != '0)
                int_reg_inuse[i_instr.decode.rd.idx] <= 1'b1;
            
            if (i_int_reg_wb.valid & (~i_instr.decode.rd.valid | i_int_reg_wb.idx != i_instr.decode.rd.idx))
                int_reg_inuse[i_int_reg_wb.idx] <= 1'b0;
        end
        
        else if (i_int_reg_wb.valid) begin
            int_reg_inuse[i_int_reg_wb.idx] <= 1'b0;
        end
    end
    
    /*
     * Next instr
     */
    wire    issued_instr_t  next_instr = compose_issued_instr(i_instr.pc, i_instr.decode, i_instr.except, can_issue);
    
    /*
     * Output
     */
    assign  o_stall = i_stall | (i_instr.valid & (~rs1_ready | ~rs2_ready | ~rd_ready));
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush) begin
            o_instr <= '0;
        end
        
        else if (~i_stall) begin
            o_instr <= next_instr;
            
            if (i_log_fd != '0) begin
                $fdisplay(i_log_fd, "[IS ] Valid: %d, PC @ %h, Decode: %h, CanIssue: %d, RS1: %d, RS2: %d, RD: %d, Next: %d, Inuse: %h",
                          i_instr.valid, i_instr.pc, i_instr.decode, can_issue, rs1_ready, rs2_ready, rd_ready, next_instr.valid, int_reg_inuse);
            end
        end
    end

endmodule

