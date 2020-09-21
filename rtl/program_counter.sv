`include "include/config.svh"
`include "include/pc.svh"

module program_counter (
    input                       i_stall,
    
    input                       i_alter,
    input   program_counter_t   i_pc,
    
    output  program_counter_t   o_pc,
    
    input   i_clk,
    input   i_rst_n
);

    program_counter_t   pc;
    assign  o_pc        = pc;

    always_ff @ (posedge i_clk) begin
        if (~i_rst_n) begin
            pc <= `INIT_PC;
        end
        
        else if (i_alter) begin
            pc <= i_pc;
        end else if (~i_stall) begin
            pc <= get_next_fetch_block_pc(pc);
        end
    end

endmodule

