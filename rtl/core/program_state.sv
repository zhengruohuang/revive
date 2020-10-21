`include "include/config.svh"
`include "include/ps.svh"

module program_state (
    input   [1:0]               i_priv,
    input                       i_isa_c,
    input   reg_data_t          i_satp,
    
    output  program_state_t     o_ps,
    
    // Log
    input   [31:0] i_log_fd,
    
    input   i_clk,
    input   i_rst_n
);

    assign  o_ps = { i_priv, i_isa_c, i_satp[31], i_satp[30:22], i_satp[21:0] };

endmodule

