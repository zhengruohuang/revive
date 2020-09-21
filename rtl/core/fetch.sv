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
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    wire                        valid/*verilator public*/       = ~i_flush & ~i_stall;
    wire    reg_data_t          addr/*verilator public*/        = i_pc;

            short_instr_t       ld_data0/*verilator public*/;
            short_instr_t       ld_data1/*verilator public*/;

    /*
     * Output
     */
    assign  o_stall = i_stall;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush) begin
            o_data <= '0;
        end
        
        else if (~i_stall) begin
            o_data <= compose_fetched_data(i_pc, ld_data0, ld_data1, `EXCEPT_NONE, valid);
            $display("[IF ] Valid: %d, PC @ %h, Data: %h-%h", valid, i_pc, ld_data0, ld_data1);
        end
    end

endmodule

