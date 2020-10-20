`include "include/config.svh"
`include "include/instr.svh"

module instr_field_decoder (
    input   aligned_instr_t     i_instr,
    input                       i_half,
    output  decode_t            o_decode,
    output                      o_unknown
);

    // Output
    decode_t    fields;
    logic       unknown;
    
    assign o_decode = fields;
    assign o_unknown = unknown;

    // Extract key fields
    wire [6:0]  opcode  = i_instr.instr[6:0];
    wire [2:0]  opfunc  = i_instr.instr[14:12];
    wire [6:0]  opfext  = i_instr.instr[31:25];
    wire [4:0]  opatom  = i_instr.instr[31:27];
    wire [4:0]  rs1     = i_instr.instr[19:15];
    wire [4:0]  rs2     = i_instr.instr[24:20];
    wire [4:0]  rd      = i_instr.instr[11:7];
`ifdef RV32
    wire [19:0] shamt   = { {15{1'b0}}, i_instr.instr[24:20] };
`else
    wire [19:0] shamt   = { {14{1'b0}}, i_instr.instr[25:20] };
`endif
    wire [19:0] imm_u   = i_instr.instr[31:12];
    wire [19:0] imm_i   = { {8{i_instr.instr[31]}}, i_instr.instr[31:20] };
    wire [19:0] imm_s   = { {8{i_instr.instr[31]}}, i_instr.instr[31:25], i_instr.instr[11:7] };
    wire [19:0] imm_b   = { {8{i_instr.instr[31]}}, i_instr.instr[31], i_instr.instr[7], i_instr.instr[30:25], i_instr.instr[11:8] };
    wire [19:0] imm_j   = { i_instr.instr[31], i_instr.instr[19:12], i_instr.instr[20], i_instr.instr[30:21] };
    
    wire [19:0] imm_amo = { 18'b0, i_instr.instr[26:25] };
    wire [19:0] imm_mf  = { 12'b0, i_instr.instr[27:20] };
    wire [19:0] imm_csr = {  8'b0, i_instr.instr[31:20] };

    // The actual decoder
    always_comb begin
        fields = '0;
        unknown = '0;
        
        fields.half = i_half;
        
        case (opcode)
            // LUI
            7'b0110111: begin
                fields.unit = UNIT_ALU;
                fields.op = OP_ALU_LUI;
                fields.op_size = '0;
                fields.rd = compose_int_reg_sel(rd, 1'b1);
                fields.rd_sel = RD_REG;
                fields.rs1 = compose_int_reg_sel(5'b0, 1'b1);
                fields.rs1_sel = RS_REG;
                fields.rs2 = `INVALID_REG;
                fields.rs2_sel = RS_IMM;
                fields.imm = imm_u;
                fields.serialize = 1'b0;
            end
            
            // AUIPC
            7'b0010111: begin
                fields.unit = UNIT_ALU;
                fields.op = OP_ALU_LUI;
                fields.op_size = '0;
                fields.rd = compose_int_reg_sel(rd, 1'b1);
                fields.rd_sel = RD_REG;
                fields.rs1 = `INVALID_REG;
                fields.rs1_sel = RS_PC;
                fields.rs2 = `INVALID_REG;
                fields.rs2_sel = RS_IMM;
                fields.imm = imm_u;
                fields.serialize = 1'b0;
            end
            
            // JAL
            7'b1101111: begin
                fields.unit = UNIT_BRU;
                fields.op = OP_BRU_JAL;
                fields.op_size = '0;
                fields.rd = compose_int_reg_sel(rd, 1'b1);
                fields.rd_sel = RD_REG_AND_PC;
                fields.rs1 = `INVALID_REG;
                fields.rs1_sel = RS_PC;
                fields.rs2 = `INVALID_REG;
                fields.rs2_sel = RS_IMM;
                fields.imm = imm_j;
                fields.serialize = 1'b0;
            end
            
            // JALR
            7'b1100111: begin
                fields.unit = UNIT_BRU;
                fields.op = OP_BRU_JALR;
                fields.op_size = '0;
                fields.rd = compose_int_reg_sel(rd, 1'b1);
                fields.rd_sel = RD_REG_AND_PC;
                fields.rs1 = compose_int_reg_sel(rs1, 1'b1);
                fields.rs1_sel = RS_REG;
                fields.rs2 = `INVALID_REG;
                fields.rs2_sel = RS_IMM;
                fields.imm = imm_i;
                fields.serialize = 1'b0;
            end
            
            // BEQ/BNE/BLT/BLTU/BGE/BGEU
            7'b1100011: begin
                fields.unit = UNIT_BRU;
                fields.rd = `INVALID_REG;
                fields.rd_sel = RD_PC;
                fields.rs1 = compose_int_reg_sel(rs1, 1'b1);
                fields.rs1_sel = RS_REG;
                fields.rs2 = compose_int_reg_sel(rs2, 1'b1);
                fields.rs2_sel = RS_REG;
                fields.imm = imm_b;
                fields.serialize = 1'b0;
                
                case (opfunc)
                    3'b000: fields.op = OP_BRU_BEQ;
                    3'b001: begin
                        fields.op = OP_BRU_BEQ; // BNE
                        fields.op_size = '1;    // Invert
                    end
                    3'b100: fields.op = OP_BRU_BLT;
                    3'b101: begin
                        fields.op = OP_BRU_BLT; // BGE
                        fields.op_size = '1;    // Invert
                    end
                    3'b110: fields.op = OP_BRU_BLTU;
                    3'b111: begin
                        fields.op = OP_BRU_BLTU;// BGEU
                        fields.op_size = '1;    // Invert
                    end
                    default: begin
                        fields = `NOP_DECODE;
                        unknown = 1'b1;         // Unknown
                    end
                endcase
            end
                
            // LB/LBU/LH/LHU/LW/LWU/LD
            7'b0000011: begin
                if (opfunc == 3'b111) begin
                    fields = `NOP_DECODE;
                    unknown = 1'b1; // Unknown
                end else begin
                    fields.unit = UNIT_MEM;
                    fields.op = opfunc[2] ? OP_MEM_LDU : OP_MEM_LD;
                    fields.op_size = opfunc[1:0];
                    fields.rd = compose_int_reg_sel(rd, 1'b1);
                    fields.rd_sel = RD_REG;
                    fields.rs1 = compose_int_reg_sel(rs1, 1'b1);
                    fields.rs1_sel = RS_REG;
                    fields.rs2 = `INVALID_REG;
                    fields.rs2_sel = RS_IMM;
                    fields.imm = imm_i;
                    fields.serialize = 1'b0;
                end
            end
            
            // SB/SH/SW/SD
            7'b0100011: begin
                if (opfunc[2] == 1'b1) begin
                    fields = `NOP_DECODE;
                    unknown = 1'b1; // Unknown
                end else begin
                    fields.unit = UNIT_MEM;
                    fields.op = OP_MEM_ST;
                    fields.op_size = opfunc[1:0];
                    fields.rd = `INVALID_REG;
                    fields.rd_sel = RD_NONE;
                    fields.rs1 = compose_int_reg_sel(rs1, 1'b1);
                    fields.rs1_sel = RS_REG;
                    fields.rs2 = compose_int_reg_sel(rs2, 1'b1);
                    fields.rs2_sel = RS_REG;
                    fields.imm = imm_s;
                    fields.serialize = 1'b0;
                end
            end
            
            // ADDI/SLTI/SLTIU/XORI/ORI/ANDI/SLLI/SRLI/SRAI
            7'b0010011: begin
                fields.unit = UNIT_ALU;
                fields.op_size = '0;
                fields.rd = compose_int_reg_sel(rd, 1'b1);
                fields.rd_sel = RD_REG;
                fields.rs1 = compose_int_reg_sel(rs1, 1'b1);
                fields.rs1_sel = RS_REG;
                fields.rs2 = `INVALID_REG;
                fields.rs2_sel = RS_IMM;
                fields.serialize = 1'b0;
                
                if (opfunc == 3'b001) begin
                    fields.imm = shamt;
                    fields.op = OP_ALU_SLL;
                end else if (opfunc == 3'b101) begin
                    fields.imm = shamt;
                    fields.op = opfext[5] ? OP_ALU_SRA : OP_ALU_SRL;
                end else begin
                    fields.imm = imm_i;
                    case (opfunc)
                        3'b000: fields.op = OP_ALU_ADD;
                        3'b010: fields.op = OP_ALU_SLT;
                        3'b011: fields.op = OP_ALU_SLTU;
                        3'b100: fields.op = OP_ALU_XOR;
                        3'b110: fields.op = OP_ALU_OR;
                        3'b111: fields.op = OP_ALU_AND;
                        default: begin
                            fields = `NOP_DECODE;
                            unknown = 1'b1; // unknown
                        end
                    endcase
                end
            end
            
            // ADDIW/SLLIW/SRLIW/SRAIW
            7'b0011011: begin
                fields.unit = UNIT_ALU;
                fields.op_size = '1; // 32-bit
                fields.rd = compose_int_reg_sel(rd, 1'b1);
                fields.rd_sel = RD_REG;
                fields.rs1 = compose_int_reg_sel(rs1, 1'b1);
                fields.rs1_sel = RS_REG;
                fields.rs2 = `INVALID_REG;
                fields.rs2_sel = RS_IMM;
                fields.serialize = 1'b0;
                
                case (opfunc)
                    3'b000: begin
                        fields.op = OP_ALU_ADD;
                        fields.imm = imm_i;
                    end
                    3'b001: begin
                        fields.op = OP_ALU_SLL;
                        fields.imm = shamt;
                    end
                    3'b101: begin
                        fields.op = opfext[5] ? OP_ALU_SRA : OP_ALU_SRL;
                        fields.imm = shamt;
                    end
                    default: begin
                        fields = `NOP_DECODE;
                        unknown = 1'b1; // Unknown
                    end
                endcase
            end
            
            // ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND
            // MUL/MULH/MULHSU/MULHU/DIV/DIVU/REM/REMU
            7'b0110011: begin
                fields.op_size = '0;
                fields.rd = compose_int_reg_sel(rd, 1'b1);
                fields.rd_sel = RD_REG;
                fields.rs1 = compose_int_reg_sel(rs1, 1'b1);
                fields.rs1_sel = RS_REG;
                fields.rs2 = compose_int_reg_sel(rs2, 1'b1);
                fields.rs2_sel = RS_REG;
                fields.imm = '0;
                fields.serialize = 1'b0;
                
                // MUL/MULH/MULHSU/MULHU/DIV/DIVU/REM/REMU
                if (opfext[0]) begin
                    fields.unit = UNIT_MUL;
                    
                    case (opfunc)
                        3'b000: fields.op = OP_MDU_MUL;
                        3'b001: fields.op = OP_MDU_MUL_HIGH;
                        3'b010: fields.op = OP_MDU_MULSU_HIGH;
                        3'b011: fields.op = OP_MDU_MULU_HIGH;
                        3'b100: fields.op = OP_MDU_DIV;
                        3'b101: fields.op = OP_MDU_DIVU;
                        3'b110: fields.op = OP_MDU_REM;
                        3'b111: fields.op = OP_MDU_REMU;
                        //default: begin fields = `NOP_DECODE; unknown = 1'b1; end // unknown
                    endcase
                end
                
                // ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND
                else begin
                    fields.unit = UNIT_ALU;
                    
                    case (opfunc)
                        3'b000: fields.op = opfext[5] ? OP_ALU_SUB : OP_ALU_ADD;
                        3'b010: fields.op = OP_ALU_SLT;
                        3'b011: fields.op = OP_ALU_SLTU;
                        3'b100: fields.op = OP_ALU_XOR;
                        3'b110: fields.op = OP_ALU_OR;
                        3'b111: fields.op = OP_ALU_AND;
                        3'b001: fields.op = OP_ALU_SLL;
                        3'b101: fields.op = opfext[5] ? OP_ALU_SRA : OP_ALU_SRL;
                        //default: begin fields = `NOP_DECODE; unknown = 1'b1; end // unknown
                    endcase
                end
            end
            
            // ADDW/SUBW/SLLW/SRLW/SRAW
            // MULW/DIVW/DIVUW/REMW/REMUW
            7'b0111011: begin
                fields.op_size = '1; // 32-bit
                fields.rd = compose_int_reg_sel(rd, 1'b1);
                fields.rd_sel = RD_REG;
                fields.rs1 = compose_int_reg_sel(rs1, 1'b1);
                fields.rs1_sel = RS_REG;
                fields.rs2 = compose_int_reg_sel(rs2, 1'b1);
                fields.rs2_sel = RS_REG;
                fields.imm = '0;
                fields.serialize = 1'b0;
                
                // MULW/DIVW/DIVUW/REMW/REMUW
                if (opfext[0]) begin
                    fields.unit = UNIT_MUL;
                    
                    case (opfunc)
                        3'b000: fields.op = OP_MDU_MUL;
                        3'b100: fields.op = OP_MDU_DIV;
                        3'b101: fields.op = OP_MDU_DIVU;
                        3'b110: fields.op = OP_MDU_REM;
                        3'b111: fields.op = OP_MDU_REMU;
                        default: begin
                            fields = `NOP_DECODE;
                            unknown = 1'b1; // unknown
                        end
                    endcase
                end
                
                // ADDW/SUBW/SLLW/SRLW/SRAW
                else begin
                    fields.unit = UNIT_ALU;
                    
                    case (opfunc)
                        3'b000: fields.op = opfext[5] ? OP_ALU_SUB : OP_ALU_ADD;
                        3'b001: fields.op = OP_ALU_SLL;
                        3'b101: fields.op = opfext[5] ? OP_ALU_SRA : OP_ALU_SRL;
                        default: begin
                            fields = `NOP_DECODE;
                            unknown = 1'b1; // unknown
                        end
                    endcase
                end
            end
            
            // AMO
            7'b0101111: begin
                fields.unit = UNIT_AMO;
                fields.op_size = opfunc[0] ? '1 : '0;
                fields.rd = compose_int_reg_sel(rd, 1'b1);
                fields.rd_sel = RD_REG;
                fields.rs1 = compose_int_reg_sel(rs1, 1'b1);
                fields.rs1_sel = RS_REG;
                fields.rs2 = compose_int_reg_sel(rs2, 1'b1);
                fields.rs2_sel = RS_REG;
                fields.imm = imm_amo;
                fields.serialize = 1'b0;
                
                case (opfext[6:2])
                    5'b00010: fields.op = OP_AMO_LL;
                    5'b00011: fields.op = OP_AMO_SC;
                    5'b00001: fields.op = OP_AMO_SWAP;
                    5'b00000: fields.op = OP_AMO_ADD;
                    5'b00100: fields.op = OP_AMO_XOR;
                    5'b01100: fields.op = OP_AMO_AND;
                    5'b01000: fields.op = OP_AMO_OR;
                    5'b10000: fields.op = OP_AMO_MIN;
                    5'b11000: fields.op = OP_AMO_MINU;
                    5'b10100: fields.op = OP_AMO_MAX;
                    5'b11100: fields.op = OP_AMO_MAXU;
                    default: begin
                        fields = `NOP_DECODE;
                        unknown = 1'b1; // unknown
                    end
                endcase
            end
            
            // FENCE/FENCE.I
            7'b0001111: begin
                fields.op_size = '0;
                fields.rd = `INVALID_REG;
                fields.rd_sel = RD_NONE;
                fields.rs1 = `INVALID_REG;
                fields.rs1_sel = RS_NONE;
                fields.rs2 = `INVALID_REG;
                fields.rs2_sel = RS_NONE;
                fields.serialize = 1'b0;
                
                if (opfunc[0]) begin
                    fields.unit = UNIT_ALU;
                    fields.op = OP_ALU_FENCE;
                    fields.imm = '0;
                end
                
                else begin
                    fields.unit = UNIT_AMO;
                    fields.op = OP_AMO_FENCE;
                    fields.imm = imm_mf;
                end
            end
            
            // SYS/CSR
            7'b1110011: begin
                // CSR
                if (opfunc != 3'b000) begin
                    fields.unit = UNIT_SYS;
                    fields.op_size = '0;
                    fields.rd = compose_int_reg_sel(rd, 1'b1);
                    fields.rd_sel = RD_REG;
                    fields.rs1 = opfunc[2] ? compose_int_reg_sel(rs1, 1'b0) : compose_int_reg_sel(rs1, 1'b1);
                    fields.rs1_sel = opfunc[2] ? RS_ZIMM : RS_REG;
                    fields.rs2 = `INVALID_REG;
                    fields.rs2_sel = RS_NONE;
                    fields.imm = imm_csr;
                    fields.serialize = 1'b0;
                    
                    case (opfunc[1:0])
                        2'b01: fields.op = OP_SYS_CSR_SWAP;
                        2'b10: fields.op = OP_SYS_CSR_READ_SET;
                        2'b11: fields.op = OP_SYS_CSR_READ_CLEAR;
                        default: begin
                            fields = `NOP_DECODE;
                            unknown = 1'b1; // unknown
                        end
                    endcase
                end
                
                // SFENCE.WMA
                else if (opfext == 7'b0001001) begin
                    fields.unit = UNIT_SYS;
                    fields.op = OP_SYS_FENCE_VMA;
                    fields.op_size = '0;
                    fields.rd = `INVALID_REG;
                    fields.rd_sel = RD_NONE;
                    fields.rs1 = compose_int_reg_sel(rs1, 1'b1);
                    fields.rs1_sel = RS_REG;
                    fields.rs2 = compose_int_reg_sel(rs2, 1'b1);
                    fields.rs2_sel = RS_REG;
                    fields.imm = '0;
                    fields.serialize = 1'b0;
                end
                
                // WFI
                else if (imm_i[11:0] == 12'b000100000101) begin
                    fields.unit = UNIT_SYS;
                    fields.op = OP_SYS_WFI;
                    fields.op_size = '0;
                    fields.rd = `INVALID_REG;
                    fields.rd_sel = RD_NONE;
                    fields.rs1 = `INVALID_REG;
                    fields.rs1_sel = RS_NONE;
                    fields.rs2 = `INVALID_REG;
                    fields.rs2_sel = RS_NONE;
                    fields.imm = '0;
                    fields.serialize = 1'b0;
                end
                
                // Trap-RET
                else if (imm_i[4:0] == 5'b00010) begin
                    fields.unit = UNIT_SYS;
                    fields.op_size = '0;
                    fields.rd = `INVALID_REG;
                    fields.rd_sel = RD_NONE;
                    fields.rs1 = `INVALID_REG;
                    fields.rs1_sel = RS_NONE;
                    fields.rs2 = `INVALID_REG;
                    fields.rs2_sel = RS_NONE;
                    fields.imm = '0;
                    fields.serialize = 1'b0;
                    
                    case (opfext[4:3])
                        //2'b00: fields.op = OP_SYS_URET;
                        2'b01: fields.op = OP_SYS_SRET;
                        2'b11: fields.op = OP_SYS_MRET;
                        default: begin
                            fields = `NOP_DECODE;
                            unknown = 1'b1; // unknown
                        end
                    endcase
                end
                
                // EBREAK
                else if (imm_i[11:0] == 12'b1) begin
                    fields.unit = UNIT_SYS;
                    fields.op = OP_SYS_EBREAK;
                    fields.op_size = '0;
                    fields.rd = `INVALID_REG;
                    fields.rd_sel = RD_NONE;
                    fields.rs1 = `INVALID_REG;
                    fields.rs1_sel = RS_NONE;
                    fields.rs2 = `INVALID_REG;
                    fields.rs2_sel = RS_NONE;
                    fields.imm = '0;
                    fields.serialize = 1'b0;
                end
                
                // ECALL
                else if (imm_i[11:0] == 12'b0) begin
                    fields.unit = UNIT_SYS;
                    fields.op = OP_SYS_ECALL;
                    fields.op_size = '0;
                    fields.rd = `INVALID_REG;
                    fields.rd_sel = RD_NONE;
                    fields.rs1 = `INVALID_REG;
                    fields.rs1_sel = RS_NONE;
                    fields.rs2 = `INVALID_REG;
                    fields.rs2_sel = RS_NONE;
                    fields.imm = '0;
                    fields.serialize = 1'b0;
                end
                
                // Unknown
                else begin
                    fields = `NOP_DECODE;
                    unknown = 1'b1; // unknown
                end
            end
            
            // Unknown
            default: begin
                fields = `NOP_DECODE;
                unknown = 1'b1; // unknown
            end
        endcase
    end

endmodule

