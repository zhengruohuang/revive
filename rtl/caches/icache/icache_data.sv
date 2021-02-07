`include "include/config.svh"
`include "include/caches.svh"
`include "include/pc.svh"

module instr_cache_data #(
    parameter CACHELINE_SIZE = 16,
    parameter CACHELINE_SIZE_BITS = 4,
    parameter NUM_ENTRIES = 32,
    parameter NUM_ENTRIES_BITS = 5
) (
    // From and to IFetch2
    input                       i_read,
    input   paddr_t             i_read_paddr,
    output  icache_data_entry_t o_data,
    
    // From and to L1ICtrl
    input                       i_fill,
    input   paddr_t             i_fill_paddr,
    input   icache_data_entry_t i_fill_data,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    /*
     * RAM
     */
    icache_data_entry_t                 data    [0:NUM_ENTRIES - 1];
    
    wire    [NUM_ENTRIES_BITS - 1:0]    rd_idx = i_read ? i_read_paddr[CACHELINE_SIZE_BITS + NUM_ENTRIES_BITS - 1:CACHELINE_SIZE_BITS] : '0;
    wire    [NUM_ENTRIES_BITS - 1:0]    wr_idx = i_fill ? i_fill_paddr[CACHELINE_SIZE_BITS + NUM_ENTRIES_BITS - 1:CACHELINE_SIZE_BITS] : '0;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_clear) begin
            o_data <= '0;
        end
        
        else if (i_read) begin
            if (i_fill & wr_idx == rd_idx) begin
                o_data <= i_fill_data;
            end else begin
                o_data <= data[rd_idx];
            end
        end
    end
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_clear) begin
        end
        
        else if (i_fill) begin
            data[wr_idx] <= i_fill_tag;
        end
    end

endmodule

