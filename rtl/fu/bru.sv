`include "config.sv"
`include "types.sv"

module branch_unit (
    input                               i_enabled,
    decoded_br_op_t                     i_op,
    input                               i_compressed,
    input                               i_invert,
    
    input   [`PC_WIDTH - 1:0]           i_pc,
    input   [`PC_WIDTH - 1:0]           i_offset,
    input   [`DATA_WIDTH - 1:0]         i_src1,
    input   [`DATA_WIDTH - 1:0]         i_src2,
    
    output  [`DATA_WIDTH - 1:0]         o_dest,
    output  [`PC_WIDTH - 1:0]           o_pc,
    
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
            OP_BR_JALR: dest <= i_compressed ? i_pc + 32'h2 : i_pc + 32'h4;
            default:    dest <= '0;
            end
        end
    end

    wire    [`PC_WIDTH - 1:0]   taken_pc = i_pc + i_offset;
    wire    [`PC_WIDTH - 1:0]   ntaken_pc = i_compressed ? i_pc + 32'h2 : i_pc + 32'h4;
    reg     [`PC_WIDTH - 1:0]   pc;
    assign  o_pc = pc;
    
    always @ (posedge i_clk) begin
        if (~i_rst_n) begin
            pc <= '0;
        end
        
        else if (i_enabled) begin
            case (i_op) begin
            OP_BR_BEQ:  pc <= (i_src1 == i_src2 && ~i_invert) ? taken_pc : ntaken_pc;
            OP_BR_BLT:  pc <= (i_src1 <  i_src2 && ~i_invert) ? taken_pc : ntaken_pc;
            OP_BR_BLTU: pc <= (i_src1 <  i_src2 && ~i_invert) ? taken_pc : ntaken_pc;   // FIXME
            OP_BR_JALR: pc <= i_src1 + i_offset;
            default:    pc <= '0;
            end
        end
    end

endmodule

