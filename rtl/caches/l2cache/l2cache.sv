`include "include/config.svh"
`include "include/caches.svh"

typedef enum logic [1:0] {
    L2CACHE_FREE,
    L2CACHE_BUSY,
    L2CACHE_RESP,
    L2CACHE_RETURN
} l2cache_state_t;

module l2_cache #(
    parameter CACHELINE_SIZE = 16,
    parameter CACHELINE_SIZE_BITS = 4,
    parameter NUM_ENTRIES = 256,
    parameter NUM_ENTRIES_BITS = 8
) (

    // From and to L1I
    input                       i_l1i_req,
    output                      o_l1i_grant,
    input                       i_l1i_req_valid,
    input   paddr_t             i_l1i_req_paddr,
    input                       i_l1i_req_cached,
    output                      o_l1i_returned,
    output  icache_data_entry_t o_l1i_returned_data,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    /*
     * Req handling state machine
     */
    l2cache_state_t     state;
    
    logic               req_valid/*verilator public*/;
    paddr_t             req_paddr/*verilator public*/;
    icache_data_entry_t returned_data/*verilator public*/;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n) begin
            state <= L2CACHE_FREE;
        end
        
        else if (state == L2CACHE_FREE) begin
            if (i_l1i_req_valid) begin
                state <= L2CACHE_BUSY;
                
                req_valid <= 1'b1;
                req_paddr <= i_l1i_req_paddr;
            end
        end
        
        else if (state == L2CACHE_BUSY) begin
            state <= L2CACHE_RESP;
            
            req_valid <= 1'b0;
            req_paddr <= '0;
        end
        
        else if (state == L2CACHE_RESP) begin
            state <= L2CACHE_RETURN;
            
            o_l1i_returned <= 1'b1;
            o_l1i_returned_data <= returned_data;
        end
        
        else if (state == L2CACHE_RETURN) begin
            o_l1i_returned <= 1'b0;
            o_l1i_returned_data <= '0;
        end
    end

    /*
     * Arbiter
     */
    wire    l2_avail = state == L2CACHE_FREE;
    assign  o_l1i_grant = l2_avail & i_l1i_req;

endmodule

