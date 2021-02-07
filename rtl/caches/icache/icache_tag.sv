`include "include/config.svh"
`include "include/caches.svh"
`include "include/pc.svh"

module instr_cache_tag #(
    parameter CACHELINE_SIZE = 16,
    parameter CACHELINE_SIZE_BITS = 4,
    parameter NUM_ENTRIES = 32,
    parameter NUM_ENTRIES_BITS = 5
) (
    input                       i_clear,    // flush cache
    
    // From and to IFetch1
    input                       i_read,
    input   program_counter_t   i_pc,
    output  icache_tag_entry_t  o_tag,
    
    // From and to L1ICtrl
    input                       i_fill,
    input   paddr_t             i_fill_paddr,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    /*
     * RAM
     */
    logic   [NUM_ENTRIES - 1:0]         valid;
    icache_tag_t                        tags    [0:NUM_ENTRIES - 1];
    
    wire    [NUM_ENTRIES_BITS - 1:0]    rd_idx = i_read ? i_pc[CACHELINE_SIZE_BITS + NUM_ENTRIES_BITS - 1:CACHELINE_SIZE_BITS] : '0;
    wire    [NUM_ENTRIES_BITS - 1:0]    wr_idx = i_fill ? i_fill_paddr[CACHELINE_SIZE_BITS + NUM_ENTRIES_BITS - 1:CACHELINE_SIZE_BITS] : '0;
    
    wire    icache_tag_entry_t          fill_tag = i_fill ? compose_icache_tag_entry(i_fill_paddr) : '0;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_clear) begin
            o_tag <= '0;
        end
        
        else if (i_read) begin
            if (i_fill & wr_idx == rd_idx) begin
                o_tag <= { fill_tag, 1'b1 };
            end else begin
                o_tag <= { tags[rd_idx], valid[idx] };
            end
        end
    end
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_clear) begin
            valid <= '0;
        end
        
        else if (i_fill) begin
            valid[wr_idx] <= 1'b1;
            tags[wr_idx] <= fill_tag;
        end
    end

endmodule

