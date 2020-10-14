`include "include/config.svh"
`include "include/instr.svh"

module addr_gen_unit (
    input   [31:0] i_log_fd,
    
    input                           i_e,
    
    input   reg_data_t              i_src1,
    input   reg_data_t              i_offset,
    
    output  reg_data_t              o_dest
);

    assign o_dest = i_e ? (i_src1 + i_offset) : '0;

endmodule

