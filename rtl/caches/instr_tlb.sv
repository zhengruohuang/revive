`include "include/config.svh"
`include "include/caches.svh"
`include "include/pc.svh"

module instr_tlb (
    input   program_counter_t   i_pc/*verilator public*/,
    input                       i_read/*verilator public*/,
    
    output  itlb_tag_entry_t    o_itlb_tag    [0:`ITLB_ASSOC - 1],
    output  itlb_data_entry_t   o_itlb_data   [0:`ITLB_ASSOC - 1],
    
    input   i_clk,
    input   i_rst_n
);

    // Dummy ICache data
    itlb_tag_entry_t    itlb_tag    [0:`ITLB_ASSOC - 1]/*verilator public*/;
    itlb_data_entry_t   itlb_data   [0:`ITLB_ASSOC - 1]/*verilator public*/;

    assign o_itlb_tag   = itlb_tag;
    assign o_itlb_data  = itlb_data;

    always @ (posedge i_clk) begin
        if (~i_rst_n) begin
            for (int i = 0; i < `ITLB_ASSOC; i++) begin
                itlb_tag[i] <= '0;
                itlb_data[i] <= '0;
            end
        end
        
        else if (i_read) begin
            itlb_tag[0] <= compose_itlb_tag_entry(0, i_pc);
            itlb_data[0] <= compose_ppn(i_pc);
        end
    end

endmodule

