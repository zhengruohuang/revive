`include "include/config.svh"
`include "include/caches.svh"
`include "include/pc.svh"

module instr_cache_tag (
    input                       i_stall,
    input                       i_flush,
    
    // Read
    input   program_counter_t   i_pc,
    input                       i_read,
    output                      o_avail, // accepting read req?
    
    // Miss
    input                       i_miss_req,
    output                      o_miss_avail, // accepting miss req?
    
    // Tag
    output  icache_tag_entry_t  o_tag,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_flush) begin
            o_valid <= '0;
            o_pc <= '0;
            o_paddr <= '0;
            o_except <= '0;
        end
        
        else begin
        
        else if (i_read) begin
            itlb_tag[0] <= compose_itlb_tag_entry(0, i_pc);
            itlb_data[0] <= compose_ppn(i_pc);
        end
    end

endmodule

