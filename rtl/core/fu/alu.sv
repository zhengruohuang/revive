`include "include/config.svh"
`include "include/instr.svh"

module arithmetic_unit (
    input   [31:0] i_log_fd,
    
    input                           i_e,
    input   decode_alu_op_t         i_op,
    input                           i_w32,
    
    input   reg_data_t              i_src1,
    input   reg_data_t              i_src2,
    
    output  reg_data_t              o_dest
);

    reg_data_t dest;
    assign o_dest = dest;
    
    always_comb begin
        if (~i_e) begin
            dest = '0;
        end
        
        else begin
            case (i_op)
                OP_ALU_LUI: dest = i_src1 + { i_src2[19:0], 12'b0 };
                OP_ALU_ADD: dest = i_src1 + i_src2;
                OP_ALU_SUB: dest = i_src1 - i_src2;
                OP_ALU_AND: dest = i_src1 & i_src2;
                OP_ALU_OR:  dest = i_src1 | i_src2;
                OP_ALU_XOR: dest = i_src1 ^ i_src2;
`ifdef RV32
                OP_ALU_SLL: dest = i_src1 << i_src2[4:0];
                OP_ALU_SRL: dest = i_src1 >> i_src2[4:0];
                OP_ALU_SRA: dest = $signed(i_src1) >>> i_src2[4:0];
`else
                OP_ALU_SLL: dest = i_src1 << i_src2[5:0];
                OP_ALU_SRL: dest = i_src1 >> i_src2[5:0];
                OP_ALU_SRA: dest = $signed(i_src1) >>> i_src2[5:0];
`endif
                OP_ALU_SLT: dest = $signed(i_src1) < $signed(i_src2) ? 32'b1 : '0;
                OP_ALU_SLTU:dest = i_src1 < i_src2 ? 32'b1 : '0;
                default:    dest = '0;
            endcase
            
            if (i_log_fd != '0) begin
                $fdisplay(i_log_fd, "[ALU] src1: %h, src2: %h, dest: %h",
                          i_src1, i_src2, dest);
            end
        end
    end

endmodule

