`include "include/config.svh"
`include "include/instr.svh"

module interrupt_unit (
    input   [31:0] i_log_fd,
    
    input                           i_e,
    input   [11:0]                  i_intp,
    input   [11:0]                  i_inte,
    input   [11:0]                  i_mideleg,
    input   program_state_t         i_ps,
    
    output                          o_int,
    output  reg_data_t              o_data
);

    assign  o_int = '0;
    assign  o_data = '0;

endmodule

