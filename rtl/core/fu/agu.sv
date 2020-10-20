`include "include/config.svh"
`include "include/instr.svh"

module addr_gen_unit (
    input   [31:0] i_log_fd,
    
    input                           i_e,
    input   decode_mem_op_t         i_op,
    
    input   reg_data_t              i_src1,
    input   reg_data_t              i_offset,
    input   logic   [1:0]           i_size,
    
    output  reg_data_t              o_dest,
    output                          o_ld,
    output                          o_misalign
);

    wire    reg_data_t  dest = i_e ? (i_src1 + i_offset) : '0;
    wire    logic       misalign = i_e ? (i_size == 2'b00 ? 1'b0 :
                                          i_size == 2'b01 ? dest[0] :
                                          i_size == 2'b10 ? dest[1] | dest[0] :
                                                            dest[2] | dest[1] | dest[0]
                                         ) : 1'b0;
    
    assign  o_dest = dest;
    assign  o_ld = i_op == OP_MEM_LD | i_op == OP_MEM_LDU;
    assign  o_misalign = misalign;

endmodule

