`include "config.sv"
`include "types.sv"

module arithmetic_unit (
    input                               i_enabled,
    decoded_alu_op_t                    i_op,
    
    input   [`DATA_WIDTH - 1:0]         i_src1,
    input   [`DATA_WIDTH - 1:0]         i_src2,
    
    output  [`DATA_WIDTH - 1:0]         o_dest,
    
    input   i_clk,
    input   i_rst_n
);

    reg [`DATA_WIDTH - 1:0] dest;
    assign o_dest = dest;
    
    always @ (posedge i_clk) begin
        if (~i_rst_n) begin
            dest <= '0;
        end
        
        else if (i_enabled) begin
            case (i_op) begin
            OP_ALU_ADD: dest <= i_src1 + i_src2;
            OP_ALU_SUB: dest <= i_src1 - i_src2;
            OP_ALU_AND: dest <= i_src1 & i_src2;
            OP_ALU_OR:  dest <= i_src1 | i_src2;
            OP_ALU_XOR: dest <= i_src1 ^ i_src2;
            OP_ALU_SLL: dest <= i_src1 << i_src2;  // FIXME
            OP_ALU_SRL: dest <= i_src1 >> i_src2;  // FIXME
            OP_ALU_SRA: dest <= i_src1 >> i_src2;  // FIXME
            OP_ALU_SLT: dest <= i_src1 < i_src2 ? '1 : '0;
            default:    dest <= '0;
            end
        end
    end

endmodule

