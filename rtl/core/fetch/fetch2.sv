`include "include/config.svh"
`include "include/instr.svh"
`include "include/caches.svh"


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
    input                       i_itlb_miss_page_fault,
    
    input                       i_icache_miss_avail,
    output                      o_icache_miss_req,
    output                      o_icache_miss_cached,
    
    // To Fetch3
    output                      o_valid,
    output  program_counter_t   o_pc,
    output  paddr_t             o_paddr,
    output  except_t            o_except,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    /*
     * Output
     */
    wire    logic               itlb_hit = i_itlb_tag.vliad & i_itlb_tag.vpn == i_pc[31:12] & i_itlb_tag.asi == i_ps.asid;
    
    wire    paddr_t             icache_paddr = { i_itlb_data.ppn, i_pc[11:0] };
    wire    icache_tag_entry_t  icache_cmp_tag = compose_icache_tag_entry(icache_paddr);
    wire    logic               icache_hit = itlb_hit & icache_cmp_tag == i_icache_tag;
    
    wire    logic               next_valid = i_valid & itlb_hit & icache_hit;
    wire    program_counter_t   next_pc = i_pc;
    wire    paddr_t             next_paddr = next_valid ? icache_paddr : '0;
    wire    except_t            next_except = next_valid & i_itlb_miss_page_fault ? `EXCEPT_ITLB_PAGE_FAULT : `EXCEPT_NONE;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_flush) begin
            o_valid <= '0;
            o_pc <= '0;
            o_paddr <= '0;
            o_except <= '0;
        end
        
        else begin
            if (~i_stall) begin
                o_valid <= next_valid;
                o_pc <= next_pc;
                o_paddr <= next_paddr;
                o_except <= next_except;
                
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
                if (i_itlb_miss_avail & ~wait_for_itlb) begin
                    wait_for_itlb <= 1'b1;
                    o_itlb_miss_req <= 1'b1;
                    if (i_log_fd != '0) $fdisplay(i_log_fd, "[IF2] ITLB miss");
                end else if (wait_for_itlb) begin
                    o_itlb_miss_req <= 1'b0;
                    if (i_log_fd != '0) $fdisplay(i_log_fd, "[IF2] ITLB miss initiated");
                end
            end else if (wait_for_itlb) begin
                wait_for_itlb <= 1'b0;
                if (i_log_fd != '0) $fdisplay(i_log_fd, "[IF2] ITLB miss handled");
            end
        end
    end
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_flush) begin
            wait_for_icache <= '0;
            o_icache_miss_req <= '0;
        end
        
        else if (~i_stall & i_valid & itlb_hit) begin
            if (icache_miss) begin
                if (i_icache_miss_avail & ~wait_for_icache) begin
                    wait_for_icache <= 1'b1;
                    o_icache_miss_req <= 1'b1;
                    if (i_log_fd != '0) $fdisplay(i_log_fd, "[IF2] ICache miss");
                end else if (wait_for_icache) begin
                    o_icache_miss_req <= 1'b0;
                    if (i_log_fd != '0) $fdisplay(i_log_fd, "[IF2] ICache miss initiated");
                end
            end else if (wait_for_icache) begin
                wait_for_icache <= 1'b0;
                if (i_log_fd != '0) $fdisplay(i_log_fd, "[IF2] ICache miss handled");
            end
        end
    end

    /*
     * Stall
     */
    assign  o_stall = i_stall | itlb_miss | icache_miss;
    assign  o_icache_miss_cached = 1'b1;

endmodule

