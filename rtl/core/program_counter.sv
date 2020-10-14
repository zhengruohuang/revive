`include "include/config.svh"
`include "include/pc.svh"

module program_counter (
    input                       i_stall,
    input   program_counter_t   i_init_pc,
    
    // From writeback
    input                       i_alter,
    input   program_counter_t   i_pc,
    
    // To fetch
    output  program_counter_t   o_pc,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    program_counter_t   pc;
    assign  o_pc        = pc;

    always_ff @ (posedge i_clk) begin
        if (~i_rst_n) begin
            pc <= i_init_pc;
        end
        
        else if (i_alter) begin
            pc <= i_pc;
            
            if (i_log_fd != '0) begin
                $fdisplay(i_log_fd, "[PC] Alter: %h", i_pc);
            end
        end else if (~i_stall) begin
            pc <= get_next_fetch_block_pc(pc);
        end
    end

endmodule

