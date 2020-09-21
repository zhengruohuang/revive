`include "include/config.svh"

// FIXME: The code assumes that compressed instrs are 16 bits and decompressed ones are 32 bits

module instr_decompressor (
    input   [15:0]  i_instr,
    output  [31:0]  o_instr,
    output          o_unknown
);

// Common
wire [1:0]  quadrant = i_instr[1:0];
wire [2:0]  opcode = i_instr[15:13];

// Quadrant 0
wire [4:0]  q0_rdp = { 2'b0, i_instr[4:2] };
wire [4:0]  q0_rs1p = { 2'b0, i_instr[9:7] };
wire [4:0]  q0_rs2p = { 2'b0, i_instr[4:2] };
wire [9:0]  q0_nzuimm = { i_instr[10:7], i_instr[12:11], i_instr[5], i_instr[6], 2'b00 };
wire [7:0]  q0_uimm_7 = { i_instr[6:5], i_instr[12:10], 3'b0 };
wire [8:0]  q0_uimm_8 = { i_instr[10], i_instr[6:5], i_instr[12:11], 4'b0 };
wire [6:0]  q0_uimm_6 = { i_instr[5], i_instr[12:10], i_instr[6], 2'b0 };

// Quadrant 1
wire [4:0]  q1_r = i_instr[11:7];
wire [4:0]  q1_rp = { 2'b0, i_instr[9:7] };
wire [4:0]  q1_rs2p = { 2'b0, i_instr[4:2] };
wire [1:0]  q1_opcode2 = i_instr[11:10];
wire [2:0]  q1_opcode3 = { i_instr[12], i_instr[6:5] };
wire [5:0]  q1_nzimm_5 = { i_instr[12], i_instr[6:2] };
wire [9:0]  q1_nzimm_9 = { i_instr[12], i_instr[4:3], i_instr[5], i_instr[2], i_instr[6], 4'b0 };
wire [17:0] q1_nzimm_17 = { i_instr[12], i_instr[6:2], 12'b0 };
wire [5:0]  q1_imm_5 = { i_instr[12], i_instr[6:2] };
wire [8:0]  q1_imm_8 = { i_instr[12], i_instr[6:5], i_instr[2], i_instr[11:10], i_instr[4:3], 1'b0 };
wire [11:0] q1_imm_11 = { i_instr[12], i_instr[8], i_instr[10:9], i_instr[6], i_instr[7], i_instr[2], i_instr[11], i_instr[5:3], 1'b0 };

// Quadrant 2
wire [4:0]  q2_r = i_instr[11:7];
wire [4:0]  q2_rs2 = i_instr[6:2];
wire        q2_opcode2 = i_instr[12];
wire [5:0]  q2_nzuimm = { i_instr[12], i_instr[6:2] };
wire [8:0]  q2_uimm_8 = { i_instr[4:2], i_instr[12], i_instr[6:5], 3'b0 };
wire [9:0]  q2_uimm_9 = { i_instr[5:2], i_instr[12], i_instr[6], 4'b0 };
wire [7:0]  q2_uimm_7 = { i_instr[3:2], i_instr[12], i_instr[6:4], 2'b0 };

// NOP
wire [31:0] EXPANDED_NOP = 32'b0;

// Decompressed instr
reg [31:0]  dc_instr;
reg         dc_unknown;

assign o_instr = dc_instr;
assign o_unknown = dc_unknown;

always_comb begin
    dc_instr = EXPANDED_NOP;
    dc_unknown = 1'b0;
    
    case (quadrant)
    // Quadrant 0
    2'b00: begin
        case (opcode)
        // C.ADDI4SPN
        3'b000: begin
            if (q0_nzuimm != 10'b0) begin
                // addi rd', x2, nzuimm[9:2]
                dc_instr = { 2'b0, q0_nzuimm, 5'd2, 3'b000, q0_rdp, 7'b0010011 };
            end else begin
                dc_unknown = 1'b1;
            end
        end
        
        // C.FLD(RV32/64)/C.LQ(RV128)
        3'b001: begin
            dc_unknown = 1'b1;
        end
        
        // C.LW
        3'b010: begin
            // lw rd', offset[6:2](rs1')
            dc_instr = { 5'b0, q0_uimm_6, q0_rs1p, 3'b010, q0_rdp, 7'b0000011 };
        end
        
        // C.FLW(RV32)/C.LD(RV64/128)
        3'b011: begin
        `ifdef RV32
            dc_unknown = 1'b1;
        `else
            // ld rd', offset[7:3](rs1')
            dc_instr = { 4'b0, q0_uimm_7, q0_rs1p, 3'b011, q0_rdp, 7'b0000011 };
        `endif
        end
        
        // Reserved
        3'b100: begin
            dc_unknown = 1'b1;
        end
        
        // C.FSD(RV32/64)/C.SQ(RV128)
        3'b101: begin
            dc_unknown = 1'b1;
        end
        
        // C.SW
        3'b110: begin
            // sw rs2',offset[6:2](rs1')
            dc_instr = { 5'b0, q0_uimm_6[6:5], q0_rs2p, q0_rs1p, 3'b010, q0_uimm_6[4:0], 7'b0100011 };
        end
        
        // C.FSW(RV32)/C.SD(RV64/128)
        3'b111: begin
        `ifdef RV32
            dc_unknown = 1'b1;
        `else
            // sd rs2', offset[7:3](rs1')
            dc_instr = { 4'b0, q0_uimm_7[7:5], q0_rs2p, q0_rs1p, 3'b011, q0_uimm_7[4:0], 7'b0100011 };
        `endif
        end
        
        // Unknown
        default: dc_unknown = 1'b1;
        endcase
    end
    
    // Quadrant 1
    2'b01: begin
        case (opcode)
        // C.ADDI
        3'b000: begin
            // addi rd, rd, nzimm[5:0]
            dc_instr = { 6'b0, q1_nzimm_5, q1_rp, 3'b000, q1_rp, 7'b0010011 };
        end
        
        // C.JAL(RV32)/C.ADDIW(RV64/128)
        3'b001: begin
        `ifdef RV32
            // jal x1, offset[11:1]
            dc_instr = { q1_imm_11[11], q1_imm_11[10:1], q1_imm_11[11], { 8{q1_imm_11[11]} }, 5'd1, 7'b1101111 };
        `else
            // addiw rd, rd, imm[5:0]
            dc_instr = { { 6{q1_imm_5[5]} }, q1_imm_5, q1_rp, 3'b000, q1_rp, 7'b0011011 };
        `endif
        end
        
        // C.LI
        3'b010: begin
            // addi rd, x0, imm[5:0]
            dc_instr = { { 6{q1_imm_5[5]} }, q1_imm_5, 5'd0, 3'b000, q1_rp, 7'b0010011 };
        end
        
        // C.ADDI16SP/C.LUI
        3'b011: begin
            if (q1_rp == 5'd2) begin
                // addi x2, x2, nzimm[9:4]
                dc_instr = { 2'b0, q1_nzimm_9, 5'd2, 3'b000, 5'd2, 7'b0010011 };
            end else begin
                // lui rd, nzimm[17:12]
                dc_instr = { 14'b0, q1_nzimm_17[17:12], q1_rp, 7'b0110111 };
            end
        end
        
        // ALU
        3'b100: begin
            case (q1_opcode2)
            // C.SRLI -> srli rd', rd', shamt[5:0]
            2'b00: dc_instr = { 6'b000000, q1_nzimm_5, q1_rp, 3'b101, q1_rp, 7'b0010011 };
            
            // C.SRAI -> srai rd', rd', shamt[5:0]
            2'b01: dc_instr = { 6'b010000, q1_nzimm_5, q1_rp, 3'b101, q1_rp, 7'b0010011 };
            
            // C.ANDI -> andi rd',rd', imm[5:0]
            2'b10: dc_instr = { { 6{q1_imm_5[5]} }, q1_imm_5, q1_rp, 3'b111, q1_rp, 7'b0010011 };
            
            2'b11: begin
                case (q1_opcode3)
                // C.SUB -> sub rd', rd', rs2'
                3'b000: dc_instr = { 7'b0100000, q1_rs2p, q1_rp, 3'b000, q1_rp, 7'b0110011 };
                
                // C.XOR -> xor rd', rd', rs2'
                3'b001: dc_instr = { 7'b0000000, q1_rs2p, q1_rp, 3'b100, q1_rp, 7'b0110011 };
                
                // C.OR -> or rd', rd', rs2'
                3'b010: dc_instr = { 7'b0000000, q1_rs2p, q1_rp, 3'b110, q1_rp, 7'b0110011 };
                
                // C.AND -> and rd', rd', rs2'
                3'b011: dc_instr = { 7'b0000000, q1_rs2p, q1_rp, 3'b111, q1_rp, 7'b0110011 };
                
                // C.SUBW -> subw rd', rd', rs2'
                3'b100: dc_instr = { 7'b0100000, q1_rs2p, q1_rp, 3'b000, q1_rp, 7'b0111011 };
                
                // C.ADDW -> addw rd', rd', rs2'
                3'b101: dc_instr = { 7'b0000000, q1_rs2p, q1_rp, 3'b000, q1_rp, 7'b0111011 };
                
                // Reserved
                default: dc_unknown = 1'b1;
                endcase
            end
            endcase
        end
        
        // C.J
        3'b101: begin
            // jal x0, offset[11:1]
            dc_instr = { q1_imm_11[11], q1_imm_11[10:1], q1_imm_11[11], { 8{q1_imm_11[11]} }, 5'd0, 7'b1101111 };
        end
        
        // C.BEQZ:
        3'b110: begin
            // beq rs1', x0, offset[8:1]
            dc_instr = { q1_imm_8[8], { 2{q1_imm_8[8]} }, q1_imm_8[8:5], 5'd0, q1_rp, 3'b000, q1_imm_8[4:1], q1_imm_8[8], 7'b1100011 };
        end
        
        // C.BNEZ:
        3'b111: begin
            // bne rs1', x0, offset[8:1]
            dc_instr = { q1_imm_8[8], { 2{q1_imm_8[8]} }, q1_imm_8[8:5], 5'd0, q1_rp, 3'b001, q1_imm_8[4:1], q1_imm_8[8], 7'b1100011 };
        end
        
        // Unknown
        default: dc_unknown = 1'b1;
        endcase
    end
    
    // Quadrant 2
    2'b10: begin
        case (opcode)
        // C.SLLI
        3'b000: begin
            // slli rd, rd, shamt[5:0]
            dc_instr = { 6'b0, q2_nzuimm, q2_r, 3'b001, q2_r, 7'b0010011 };
        end
        
        // C.FLDSP(RV32/64)/C.LQSP(RV128)
        3'b001: begin
            dc_unknown = 1'b1;
        end
        
        // C.LWSP
        3'b010: begin
            // lw rd, offset[7:2](x2)
            dc_instr = { 4'b0, q2_uimm_7, 5'd2, 3'b010, q2_r, 7'b0000011 };
        end
        
        // C.FLWSP(RV32)/C.LDSP(RV64/128)
        3'b011: begin
        `ifdef RV32
            dc_unknown = 1'b1;
        `else
            // ld rd, offset[8:3](x2)
            dc_instr = { 3'b0, q2_uimm_8, 5'd2, 3'b011, q2_r, 7'b0000011 };
        `endif
        end
        
        // C.JR/C.MV/C.EBREAK/C.JALR/C.ADD
        3'b100: begin
            if (q2_r != 5'b0 & q2_rs2 != 5'b0) begin
                // 1 ~ C.ADD -> add rd, rd, rs2
                // 0 ~ C.MV  -> add rd, x0, rs2
                dc_instr = { 7'b0, q2_rs2, q2_opcode2 ? q2_r : 5'd0, 3'b0, q2_r, 7'b0110011 };
            end else if (q2_r != 5'b0) begin
                // 1 ~ C.JALR -> jalr x1, 0(rs1)
                // 0 ~ C.JR   -> jalr x0, 0(rs1)
                dc_instr = { 12'b0, q2_r, 3'b000, q2_opcode2 ? 5'd1 : 5'd0, 7'b1100111 };
            end else begin
                if (q2_opcode2) begin
                    // C.EBREAK -> ebreak
                    dc_instr = { 12'b1, 5'b0, 3'b0, 5'b0, 7'b1110011 };
                end
            end
        end
        
        // C.FSDSP(RV32/64)/C.SQSP(RV128)
        3'b101: begin
            dc_unknown = 1'b1;
        end
        
        // C.SWSP
        3'b110: begin
            // sw rs2, offset[7:2](x2)
            dc_instr = { 4'b0, q2_uimm_7[7:5], q2_rs2, 5'd2, 3'b010, q2_uimm_7[4:0], 7'b0100011 };
        end
        
        // C.FSWSP(RV32)/C.SDSP(RV64/128)
        3'b111: begin
            `ifdef RV32
                dc_unknown = 1'b1;
            `else
                // sd rs2, offset[8:3](x2)
                dc_instr = { 3'b0, q2_uimm_8[8:5], q2_rs2, 5'd2, 3'b011, q2_uimm_8[4:0], 7'b0100011 };
            `endif
        end
        
        // Unknown
        default: dc_unknown = 1'b1;
        endcase
    end
    
    default: dc_unknown = 1'b1;
    endcase
end

endmodule

