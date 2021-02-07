`include "include/config.svh"
`include "include/caches.svh"
`include "include/pc.svh"

`include "caches/icache/icache_tag.sv"
`include "caches/icache/icache_data.sv"

typedef enum logic [1:0] {
    ICACHE_FREE,
    ICACHE_L2_REQ,
    ICACHE_L2_WAIT,
    ICACHE_L2_RETURNED
} icache_state_t;

module instr_cache #(
    parameter CACHELINE_SIZE = 16,
    parameter CACHELINE_SIZE_BITS = 4,
    parameter NUM_ENTRIES = 32,
    parameter NUM_ENTRIES_BITS = 5
) (
    input                       i_clear,    // flush cache
    
    // Cache avail
    output                      o_read_avail,
    output                      o_miss_avail,
    
    // From Fetch1
    input                       i_tag_read,
    input   program_counter_t   i_tag_read_pc,
    
    // From and to Fetch2
    input                       i_data_read,
    input   paddr_t             i_data_read_paddr,
    input                       i_miss,
    input                       i_miss_cached,
    output  icache_tag_entry_t  o_tag,
    
    // To output of Fetch3
    output  logic               o_miss_returned,
    output  logic   [31:0]      o_data,
    
    // From and to L2
    input                       i_l2_grant,
    output                      o_l2_req,
    output  logic               o_l2_req_valid,
    output  paddr_t             o_l2_req_paddr,
    output                      o_l2_req_cached,
    input                       i_l2_returned,
    input   icache_data_entry_t i_l2_returned_data,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    /*
     * ITag
     */
    instr_cache_tag #(
        .CACHELINE_SIZE         (CACHELINE_SIZE),
        .CACHELINE_SIZE_BITS    (CACHELINE_SIZE_BITS),
        .NUM_ENTRIES            (NUM_ENTRIES),
        .NUM_ENTRIES_BITS       (NUM_ENTRIES_BITS)
    ) itag (
        .i_clear                (i_clear),
        .i_read                 (i_tag_read)
        .i_pc                   (i_tag_read_pc),
        .o_tag                  (o_tag),
        .i_fill                 (l2_returned),
        .i_fill_paddr           (i_data_read_paddr),
        .i_log_fd               (i_log_fd),
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n)
    );

    /*
     * IData
     */
    wire    reg_data_t  idata_data;
    
    instr_cache_tag #(
        .CACHELINE_SIZE         (CACHELINE_SIZE),
        .CACHELINE_SIZE_BITS    (CACHELINE_SIZE_BITS),
        .NUM_ENTRIES            (NUM_ENTRIES),
        .NUM_ENTRIES_BITS       (NUM_ENTRIES_BITS)
    ) idata (
        .i_read                 (i_data_read)
        .i_read_paddr           (i_data_read_paddr),
        .o_data                 (idata_data),
        .i_fill                 (l2_returned),
        .i_fill_paddr           (i_data_read_paddr),
        .i_fill_data            (l2_returned_data),
        .i_log_fd               (i_log_fd),
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n)
    );

    /*
     * Miss handling state machine
     */
    icache_state_t      state;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n) begin
            state <= ICACHE_FREE;
        end
        
        else if (state == ICACHE_FREE) begin
            if (i_miss & i_l2_grant) begin
                state <= ICACHE_L2_REQ;
            end
        end
        
        else if (state == ICACHE_L2_REQ) begin
            state <= ICACHE_L2_WAIT;
        end
        
        else if (state == ICACHE_L2_WAIT) begin
            if (i_l2_returned) begin
                state <= i_miss ? ICACHE_L2_RETURNED : ICACHE_FREE;
            end
        end
        
        else if (state == ICACHE_L2_RETURNED) begin
            state <= ICACHE_FREE;
        end
    end
    
    /*
     * Output
     */
    logic       l2_returned;
    reg_data_t  l2_returned_data;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_clear) begin
            o_l2_req_valid <= '0;
            o_l2_req_paddr <= '0;
            o_l2_req_cached <= '0;
            l2_returned <= '0;
            l2_returned_data <= '0;
        end
        
        else if (state == ICACHE_L2_REQ) begin
            o_l2_req_valid <= 1'b1;
            o_l2_req_paddr <= i_data_read_paddr;
            o_l2_req_cached <= i_miss_cached;
        end
        
        else if (state == ICACHE_L2_WAIT) begin
            if (i_l2_returned & i_miss) begin
                l2_returned <= 1'b1;
                l2_returned_data <= i_l2_returned_data;
            end
        end
        
        else if (state == ICACHE_L2_RETURNED) begin
            l2_returned <= 1'b0;
            l2_returned_data <= '0;
        end
    end
    
    assign  o_read_avail = state == ICACHE_FREE;
    assign  o_miss_avail = state == ICACHE_FREE;
    
    assign  o_l2_req = state == ICACHE_FREE & i_miss_req;
    
    assign  o_miss_returned = l2_returned;
    assign  o_data = state == ICACHE_L2_RETURNED ? l2_returned_data : idata_data;

endmodule

