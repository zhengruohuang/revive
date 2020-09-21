`include "include/config.svh"
`include "include/ps.svh"

module program_state (
    input                       i_alter,
    input   program_state_t     i_ps,
    
    output  program_state_t     o_ps,
    
    input   i_clk,
    input   i_rst_n
);

    program_state_t ps;
    assign          o_ps = ps;

    always_ff @ (posedge i_clk) begin
        if (~i_rst_n) begin
            ps <= '0;
        end
        
        else if (i_alter) begin
            ps <= i_ps;
        end
    end

endmodule

