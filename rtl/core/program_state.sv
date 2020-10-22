`include "include/config.svh"
`include "include/ps.svh"

module program_state (
    input   [1:0]               i_priv,
    input                       i_isa_c,
    input   reg_data_t          i_satp,
    input   reg_data_t          i_status,
    
    output  program_state_t     o_ps,
    
    // Log
    input   [31:0] i_log_fd,
    
    input   i_clk,
    input   i_rst_n
);

    assign  o_ps = {
                i_priv,         // priv
                i_isa_c,        // compressed instr enabled
                i_status[3],    // mie
                i_status[1],    // sie
                i_satp[31],     // trans
                i_satp[30:22],  // asid
                i_satp[21:0]    // base
            };

endmodule

