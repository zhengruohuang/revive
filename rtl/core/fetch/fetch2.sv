`include "include/config.svh"
`include "include/instr.svh"
`include "include/caches.svh"

typedef enum logic [2:0] {
    IF2_FREE,
    IF2_ITLB_REQ,
    IF2_ITLB_WAIT,
    IF2_ICACHE_REQ,
    IF2_ICACHE_WAIT
} if2_state_t;

/*
 * Instr Fetch 2 - Tag compare
 */
module instr_fetch2 (
    input                       i_stall,
    input                       i_flush,
    
    // From PS
    input   program_state_t     i_ps,
    
    // From and to Fetch1
    input                       i_valid,
    input   program_counter_t   i_pc,
    output                      o_stall,
    
    // From ITLB and ITag
    input   itlb_tag_entry_t    i_itlb_tag,
    input   itlb_data_entry_t   i_itlb_data,
    
    input   icache_tag_entry_t  i_icache_tag,
    
    // From and to ITLB and ITag, miss handling
    input                       i_itlb_miss_avail,
    output                      o_itlb_miss_req,
    input                       i_itlb_miss_returned,
    input                       i_itlb_miss_page_fault,
    
    input                       i_icache_miss_avail,
    output  logic               o_icache_miss_req,
    output  paddr_t             o_icache_miss_paddr,
    output  logic               o_icache_miss_cached,   // is data cached?
    input                       i_icache_miss_returned,
    input   reg_data_t          i_icache_miss_data,
    
    // To Fetch3
    output  logic               o_valid,
    output  logic               o_icache_miss,
    output  reg_data_t          o_icache_miss_data,
    output  program_counter_t   o_pc,
    output  paddr_t             o_paddr,
    output  logic               o_page_fault,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    /*
     * Miss check
     */
    wire    logic               itlb_miss = i_valid & i_itlb_tag.valid & (i_itlb_tag.vpn != i_pc[31:12] | i_itlb_tag.asid != i_ps.asid);
    
    wire    paddr_t             icache_paddr = { i_itlb_data.ppn, i_pc[11:0] };
    wire    icache_tag_entry_t  icache_cmp_tag = compose_icache_tag_entry(icache_paddr);
    wire    logic               icache_miss = i_valid & icache_cmp_tag != i_icache_tag;
    
    /*
     * Internal state
     */
    if2_state_t     state;
    
    logic           miss_returned;
    reg_data_t      miss_data;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_flush) begin
            state <= IF2_FREE;
            miss_returned <= 1'b0;
            miss_data <= '0;
        end
        
        else begin
            case (state)
                IF2_FREE: begin
                    if (itlb_miss & i_itlb_miss_avail) begin
                        state <= IF2_ITLB_REQ;
                        o_itlb_miss_req <= 1'b1;
                    end
                    
                    else if (icache_miss & i_icache_miss_avail) begin
                        state <= IF2_ICACHE_REQ;
                        o_icache_miss_req <= 1'b1;
                        o_icache_miss_paddr <= icache_paddr;
                    end
                end
                
                IF2_ICACHE_REQ: begin
                    state <= IF2_ICACHE_WAIT;
                    o_icache_miss_req <= 1'b0;
                end
                
                IF2_ICACHE_WAIT: begin
                    if (i_icache_miss_returned) begin
                        state <= IF2_FREE;
                        miss_returned <= 1'b1;
                        miss_data <= i_icache_miss_data;
                    end
                end
            endcase
        end
    end

    /*
     * Output
     */
    wire    logic               next_valid = i_valid & ((~itlb_miss & (~icache_miss | ~i_itlb_data.cached)) | i_itlb_miss_page_fault);
    wire    program_counter_t   next_pc = i_pc;
    wire    paddr_t             next_paddr = next_valid ? icache_paddr : '0;
    wire    logic               next_page_fault = next_valid & i_itlb_miss_page_fault;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_flush) begin
            o_valid <= '0;
            o_pc <= '0;
            o_paddr <= '0;
            o_page_fault <= '0;
        end
        
        else begin
            if (~i_stall) begin
                o_valid <= next_valid;
                o_pc <= next_pc;
                o_paddr <= next_paddr;
                o_page_fault <= next_page_fault;
                
                if (i_log_fd != '0) begin
                    $fdisplay(i_log_fd, "[IF2] Valid: %d, PC @ %h, Data: %h-%h",
                              next_valid, i_pc, next_data0, next_data1);
                end
            end
        end
    end

    /*
     * Miss handling
     */
     wire   logic               itlb_miss = i_valid & ~itlb_hit;
     wire   logic               icache_miss = i_valid & ~icache_hit;
     
            logic               wait_for_itlb;
            logic               wait_for_icache;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_flush) begin
            wait_for_itlb <= '0;
            o_itlb_miss_req <= '0;
        end
        
        else if (~i_stall & i_valid) begin
            if (itlb_miss) begin
                if (wait_for_itlb) begin
                    if (o_itlb_miss_req) begin
                        o_itlb_miss_req <= 1'b0;
                        if (i_log_fd != '0) $fdisplay(i_log_fd, "[IF2] ITLB miss initiated");
                    end
                end
                
                else if (i_itlb_miss_avail) begin
                    wait_for_itlb <= 1'b1;
                    o_itlb_miss_req <= 1'b1;
                    if (i_log_fd != '0) $fdisplay(i_log_fd, "[IF2] ITLB miss");
                end
            end
            
            else if (wait_for_itlb) begin
                wait_for_itlb <= 1'b0;
                if (i_log_fd != '0) $fdisplay(i_log_fd, "[IF2] ITLB miss handled");
            end
        end
    end
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_flush) begin
            wait_for_icache <= '0;
            o_icache_miss_req <= '0;
            o_icache_miss_cached <= '0;
        end
        
        else if (~i_stall & i_valid & itlb_hit) begin
            if (icache_miss) begin
                if (wait_for_icache) begin
                    if (o_icache_miss_req) begin
                        o_icache_miss_req <= 1'b0;
                        if (i_log_fd != '0) $fdisplay(i_log_fd, "[IF2] ICache miss initiated");
                    end
                end
                
                else if (i_icache_miss_avail) begin
                    wait_for_icache <= 1'b1;
                    o_icache_miss_req <= 1'b1;
                    o_icache_miss_cached <= i_itlb_tag.cached;
                    if (i_log_fd != '0) $fdisplay(i_log_fd, "[IF2] ICache miss");
                end
            end
            
            else if (wait_for_icache) begin
                wait_for_icache <= 1'b0;
                if (i_log_fd != '0) $fdisplay(i_log_fd, "[IF2] ICache miss handled");
            end
        end
    end

    /*
     * Stall
     */
    assign  o_stall = i_stall | itlb_miss   | wait_for_itlb |
                                icache_miss | wait_for_icache;

endmodule

