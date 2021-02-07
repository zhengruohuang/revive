`include "include/config.svh"
`include "include/instr.svh"
`include "include/caches.svh"


/*
 * Instr Fetch 1 - ITLB read and ITag read
 */
module instr_fetch1 (
    input                       i_stall,
    input                       i_flush,
    
    // From and to PC
    input   program_counter_t   i_pc,
    output                      o_stall,
    
    // To Fetch2
    output                      o_valid,
    output  program_counter_t   o_pc,
    
    // From and to ITLB and ICache
    input                       i_itlb_avail,
    output                      o_itlb_read,
    
    input                       i_icache_tag_avail,
    output                      o_icache_tag_read,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    /*
     * Output
     */
    wire    logic   next_valid = i_itlb_avail & i_icache_tag_avail;
    assign  o_stall = i_stall | ~next_valid;
    assign  o_itlb_read = next_valid;
    assign  o_icache_tag_read = next_valid;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_flush) begin
            o_valid <= '0;
            o_pc <= '0;
        end
        
        else begin
            if (~i_stall) begin
                o_valid <= next_valid;
                o_pc <= i_pc;
                
                if (i_log_fd != '0) begin
                    $fdisplay(i_log_fd, "[IF1] Valid: %d, PC @ %h",
                              next_valid, i_pc);
                end
            end
        end
    end

endmodule

