`include "include/config.svh"
`include "include/pc.svh"
`include "include/ps.svh"


module instr_fetch1 (
    input                       i_stall,
    input                       i_flush,
    
    input   program_counter_t   i_pc,
    input   program_state_t     i_ps,
    
    // To next stage
    output                      o_valid,
    output  program_counter_t   o_pc,
    
    // To RAMs
    output                      o_itlb_read,
    output                      o_icache_read,
    output  program_counter_t   o_ram_pc,
    
    input   i_clk,
    input   i_rst_n
);

    logic               valid;
    program_counter_t   pc;
    assign  o_valid     = valid;
    assign  o_pc        = pc;

    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush) begin
            valid <= 1'b0;
            pc <= '0;
        end
        
        else begin
            valid <= 1'b1;
            if (~i_stall) begin
                pc <= i_pc;
            end
        end
    end

    wire    pc_unaligned    = i_pc[0];
    assign  o_itlb_read     = ~i_stall & ~i_flush & ~pc_unaligned & ~i_ps.mmu_enabled;
    assign  o_icache_read   = ~i_stall & ~i_flush & ~pc_unaligned;
    assign  o_ram_pc        = i_stall ? pc : i_pc;

endmodule

