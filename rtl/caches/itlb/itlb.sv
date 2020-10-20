`include "include/config.svh"
`include "include/caches.svh"
`include "include/pc.svh"

module instr_tlb (
    input                       i_stall,
    input                       i_flush,
    
    // Read
    input   program_counter_t   i_pc,
    input                       i_read,
    output                      o_avail,
    
    // Miss
    input                       i_miss_req,
    output                      o_miss_avail,
    
    // Tag and Data
    output  itlb_tag_entry_t    o_tag,
    output  itlb_data_entry_t   o_data,
    
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
            o_tag <= compose_itlb_tag_entry(0, i_pc);
            o_data <= compose_ppn(i_pc);
        end
    end

endmodule

