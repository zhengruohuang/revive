`include "include/config.svh"
`include "include/instr.svh"

module branch_unit (
    input   [31:0] i_log_fd,
    
    input                           i_e,
    input   decode_bru_op_t         i_op,
    input                           i_invert,
    input                           i_isa_c,
    
    input   program_counter_t       i_pc,
    input                           i_compressed,
    input   reg_data_t              i_src1,
    input   reg_data_t              i_src2,
    input   reg_data_t              i_offset,
    
    output  program_counter_t       o_dest_pc,
    output                          o_taken,
    output                          o_misalign
);

    // Cond met
    logic               cond_met;
    
    always_comb begin
        if (~i_e) begin
            cond_met = '0;
        end
        
        else begin
            case (i_op)
                OP_BRU_BEQ: cond_met = i_src1 == i_src2;
                OP_BRU_BLT: cond_met = $signed(i_src1) < $signed(i_src2);
                OP_BRU_BLTU:cond_met = i_src1 < i_src2;
                OP_BRU_JAL: cond_met = 1'b1;
                OP_BRU_JALR:cond_met = 1'b1;
                default:    cond_met = 1'b0;
            endcase
            
            if (i_log_fd != '0) begin
                $fdisplay(i_log_fd, "[BRU] src1: %h, src2: %h, invert: %d, met: %d",
                          i_src1, i_src2, i_invert, cond_met);
            end
        end
    end
    
    // Taken and Dest PC
    wire                        taken = i_invert ? ~cond_met : cond_met;
    
    wire    program_counter_t   taken_pc = i_op == OP_BRU_JALR ?
                                           i_src1 + i_offset :
                                           i_pc + { i_offset[30:0], 1'b0 };
    wire    program_counter_t   ntaken_pc = i_compressed ? i_pc + 32'h2 : i_pc + 32'h4;
    wire    program_counter_t   dest_pc = taken ? taken_pc : ntaken_pc;
    
    wire                        misalign = ~i_isa_c & dest_pc[1];
    
    // Output
    assign o_dest_pc    = { dest_pc[31:1], 1'b0 };
    assign o_taken      = taken;
    assign o_misalign   = misalign;

endmodule

