`include "include/config.svh"
`include "include/instr.svh"

module writeback (
    input   program_state_t     i_ps,
    
    // From previous stage - Mem
    input   issued_instr_t      i_instr,
    input   reg_data_t          i_data,
    
    // To RegFile
    output  int_arch_reg_wb_t   o_int_reg_wb,
    
    // To all
    output  logic               o_flush,
    
    // To PS
    output  logic               o_ps_alter,
    output  program_state_t     o_ps,
    
    // To PC
    output  logic               o_pc_alter,
    output  program_counter_t   o_pc,
    
    // Log
    input   [31:0] i_log_fd,
    input   [31:0] i_commit_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    /*
     * Flushing
     */
    logic                       flushing;

    /*
     * Next
     */
    wire                        next_flush_ic   = ~flushing & i_instr.valid & i_instr.except.valid & i_instr.except.code == EXCEPT_FLUSH;
    wire                        next_pc_alter   = ~flushing & i_instr.valid & i_instr.except.valid & i_instr.except.code == EXCEPT_MISPRED;
    wire    program_counter_t   next_pc         = next_flush_ic ? i_instr.pc + 32'h4 :
                                                  next_pc_alter ? i_data : '0;
    
    wire                        next_ps_alter   = '0;
    wire    program_state_t     next_ps         = '0;
    
    wire                        next_flush              = ~flushing & (next_flush_ic | next_pc_alter | next_ps_alter |
                                                            (i_instr.valid & i_instr.decode.rd_sel == RD_FLUSH));
    wire                        next_int_reg_wb_valid   = ~flushing & i_instr.valid & (i_instr.decode.rd.idx != '0) &
                                                        (i_instr.decode.rd_sel == RD_REG | i_instr.decode.rd_sel == RD_REG_AND_PC);
    wire    int_arch_reg_wb_t   next_int_reg_wb =
                                    compose_int_arch_reg_wb(i_instr.decode.rd_sel == RD_REG_AND_PC ? i_instr.pc + (i_instr.decode.half ? 32'h2 : 32'h4) : i_data,
                                                            i_instr.decode.rd.idx, next_int_reg_wb_valid);

    /*
     * Output
     */
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | flushing) begin
            o_int_reg_wb <= '0;
            o_flush <= '0;
            o_ps_alter <= '0;
            o_ps <= '0;
            o_pc_alter <= '0;
            o_pc <= '0;
            flushing <= 1'b0;
        end
        
        else begin
            o_int_reg_wb <= next_int_reg_wb;
            o_flush <= next_flush;
            o_ps_alter <= next_ps_alter;
            o_ps <= next_ps;
            o_pc_alter <= next_flush_ic | next_pc_alter;
            o_pc <= next_pc;
            flushing <= next_flush;
            
            if (i_log_fd != '0) begin
                $fdisplay(i_log_fd, "[WB ] Valid: %d, PC @ %h, Decode: %h, PC Alter: %d @ %h, WB Valid: %d @ %d = %h",
                          i_instr.valid, i_instr.pc, i_instr.decode,
                          next_flush_ic | next_pc_alter, next_pc,
                          next_int_reg_wb.valid, next_int_reg_wb.idx, next_int_reg_wb.data);
            end
        end
    end

    /*
     * Commit trace
     */
    //int commit_fd;
    //initial begin
    //    commit_fd = $fopen ("target/commit.txt", "w");
    //end
    
    logic [31:0] cycle_count;
    logic [31:0] instr_count;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n) begin
            cycle_count <= '0;
        end else begin
            cycle_count <= cycle_count + 32'b1;
        end
    end
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n) begin
            instr_count <= '0;
        end
    end
    
    always_ff @ (posedge i_clk) begin
        if (i_commit_fd != '0 & ~(~i_rst_n | flushing) & i_instr.valid) begin
            instr_count <= instr_count + 32'b1;
            $fdisplay(i_commit_fd, "[Cycle %5d] Instr #%5d | PC @ %h | Decode: %h | PC Alter: %d @ %h | WB Valid: %d @ %d = %h",
                      cycle_count, instr_count, i_instr.pc, i_instr.decode,
                      next_pc_alter, next_pc,
                      next_int_reg_wb.valid, next_int_reg_wb.idx, next_int_reg_wb.data);
        end
    end

endmodule

