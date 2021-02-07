`include "include/config.svh"
`include "include/instr.svh"


module fetch (
    input                       i_flush,
    input                       i_stall,
    
    // From and to PC and PS
    input   program_counter_t   i_pc,
    input   program_state_t     i_ps,
    output                      o_stall,
    
//    // To and from L2 TLB
//    output                      o_l2tlb_req,
//    output                      o_l2tlb_vaddr,
//    input                       i_l2tlb_ack,
//    input                       i_l2tlb_resp,
//    input                       i_l2tlb_entry,
//    
//    // To and from L2 Cache
//    output                      o_l2cache_req,
//    output                      o_l2cache_paddr,
//    input                       i_l2cache_ack
//    input                       i_l2cache_resp,
//    input                       i_l2cache_entry,
    
    // To next stage - IA
    output  fetched_data_t      o_data,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    wire                        valid/*verilator public*/       = ~i_flush & ~i_stall;
    wire    reg_data_t          addr/*verilator public*/        = i_pc;
    wire    reg_data_t          fetch_addr/*verilator public*/  = { i_pc[31:2], 2'b0 };

            short_instr_t       fetch_data0/*verilator public*/;
            short_instr_t       fetch_data1/*verilator public*/;
            logic               fetch_ready/*verilator public*/;
            logic               page_fault/*verilator public*/;

    /*
     * Output
     */
    assign  o_stall = i_stall | ~fetch_ready;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush) begin
            o_data <= '0;
        end
        
        else if (~i_stall) begin
            o_data <= compose_fetched_data(i_pc, fetch_data0, fetch_data1, page_fault ? `EXCEPT_ITLB_PAGE_FAULT(i_pc) : `EXCEPT_NONE, valid & fetch_ready);
            
            if (i_log_fd != '0) begin
                $fdisplay(i_log_fd, "[IF ] Valid: %d, PC @ %h, Data: %h-%h",
                          valid, i_pc, fetch_data0, fetch_data1);
            end
        end
    end

endmodule

