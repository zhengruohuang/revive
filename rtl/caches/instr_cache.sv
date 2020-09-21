`include "include/config.svh"
`include "include/caches.svh"
`include "include/pc.svh"

module instr_cache (
    input   program_counter_t   i_pc/*verilator public*/,
    input                       i_read/*verilator public*/,
    
    output  icache_tag_entry_t  o_icache_tag    [0:`ICACHE_ASSOC - 1],
    output  icache_data_entry_t o_icache_data   [0:`ICACHE_ASSOC - 1],
    
    input   i_clk,
    input   i_rst_n
);

    icache_tag_entry_t  icache_tag  [0:`ICACHE_ASSOC - 1]/*verilator public*/;
    icache_data_entry_t icache_data [0:`ICACHE_ASSOC - 1]/*verilator public*/;

    // Dummy ICache data
    assign o_icache_tag = icache_tag;
    assign o_icache_data = icache_data;

    always @ (posedge i_clk) begin
        if (~i_rst_n) begin
            for (int i = 0; i < `ICACHE_ASSOC; i++) begin
                icache_tag[i] <= '0;
                icache_data[i] <= '0;
            end
        end
    end

endmodule

