`include "include/config.svh"
`include "include/instr.svh"

module instr_field_decoder (
    input   aligned_instr_t     i_instr,
    output  decoded_instr_t     o_instr
);

    assign o_instr = '0;

//// Extract key fields
//wire [6:0]  opcode  = i_instr[6:0];
//wire [2:0]  opfunc  = i_instr[14:12];
//wire [6:0]  opfext  = i_instr[31:25];
//wire [4:0]  opatom  = i_instr[31:27];
//wire [4:0]  rs1     = i_instr[19:15];
//wire [4:0]  rs2     = i_instr[24:20];
//wire [4:0]  rd      = i_instr[11:7];
//wire [4:0]  shift   = i_instr[24:20];
//wire [5:0]  shift64 = i_instr[25:20];
//wire [19:0] imm_u   = i_instr[31:12];
//wire [11:0] imm_i   = i_instr[31:20];
//wire [11:0] imm_s   = { i_instr[31:25], i_instr[11:7] };
//wire [12:0] imm_b   = { i_instr[31], i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0 };
//wire [20:0] imm_j   = { i_instr[31], i_instr[19:12], i_instr[20], i_instr[30:21], 1'b0 };

//// The decoded instr
//decoded_fields_t decoded_instr;
//reg decoded_complex;

//assign o_instr = decoded_instr;
//assign o_complex = decoded_complex;

//// A const for unknown instr
//decoded_fields_t UNKOWN_INSTR = '0;

//// The actual decoder
//always_comb begin
//    decoded_instr = '0;
//    decoded_complex = '0;
//    
//    case (opcode)
//    // LUI
//    7'b0110111: begin
//        decoded_instr.has_rd = 1'b1;
//        decoded_instr.has_rs1 = 1'b1;
//        decoded_instr.has_imm = 1'b1;
//        decoded_instr.rd = rd;
//        decoded_instr.rs1 = '0;
//        decoded_instr.imm = { imm_u, 12'b0 };
//        decoded_instr.unit = UNIT_ALU;
//        decoded_instr.op = OP_ALU_OR;
//        decoded_instr.op_attri[0] = 1'b1;  // FIXME: Unsigned?
//    end
//    
//    // AUIPC
//    7'b0010111: begin
//        decoded_instr.has_rd = 1'b1;
//        decoded_instr.alt_rs1 = 1'b1;
//        decoded_instr.has_imm = 1'b1;
//        decoded_instr.rd = rd;
//        decoded_instr.rs1 = '0;
//        decoded_instr.imm = { imm_u, 12'b0 };
//        decoded_instr.unit = UNIT_ALU;
//        decoded_instr.op = OP_ALU_ADD;
//        decoded_instr.op_attri[0] = 1'b1;  // FIXME: Unsigned?
//    end
//    
//    // JAL
//    7'b1101111: begin
//        decoded_instr.has_rd = 1'b1;
//        decoded_instr.has_rs1 = 1'b1;
//        decoded_instr.has_imm = 1'b1;
//        decoded_instr.rd = rd;
//        decoded_instr.rs1 = '0;
//        decoded_instr.imm = { { 11{imm_j[20]} }, imm_j };
//        decoded_instr.unit = UNIT_BR;
//        decoded_instr.op = OP_BR_JALR;
//    end
//    
//    // JALR
//    7'b1100111: begin
//        decoded_instr.has_rd = 1'b1;
//        decoded_instr.has_rs1 = 1'b1;
//        decoded_instr.has_imm = 1'b1;
//        decoded_instr.rd = rd;
//        decoded_instr.rs1 = rs1;
//        decoded_instr.imm = { { 20{imm_i[11]} }, imm_i };
//        decoded_instr.unit = UNIT_BR;
//        decoded_instr.op = OP_BR_JALR;
//    end
//    
//    // BEQ/BNE/BLT/BLTU/BGE/BGEU
//    7'b1100011: begin
//        decoded_instr.has_rs1 = 1'b1;
//        decoded_instr.has_rs2 = 1'b1;
//        decoded_instr.has_imm = 1'b1;
//        decoded_instr.rs1 = rs1;
//        decoded_instr.rs2 = rs2;
//        decoded_instr.imm = { { 19{imm_b[12]} }, imm_b };
//        decoded_instr.unit = UNIT_BR;
//        
//        case (opfunc)
//        3'b000: decoded_instr.op = OP_BR_BEQ;
//        3'b001: begin
//            decoded_instr.op = OP_BR_BEQ;   // BNE
//            decoded_instr.op_attri[1] = 1'b1;  // Invert
//        end
//        3'b100: decoded_instr.op = OP_BR_BLT;
//        3'b101: begin
//            decoded_instr.op = OP_BR_BLT;   // BGE
//            decoded_instr.op_attri[1] = 1'b1;  // Invert
//        end
//        3'b110: begin
//            decoded_instr.op = OP_BR_BLT;   // BLTU
//            decoded_instr.op_attri[0] = 1'b1;  // Unsigned
//        end
//        3'b111: begin
//            decoded_instr.op = OP_BR_BLT;   // BGEU
//            decoded_instr.op_attri[0] = 1'b1;  // Unsigned
//            decoded_instr.op_attri[1] = 1'b1;  // Invert
//        end
//        default: decoded_instr = UNKOWN_INSTR;  // Unknown
//        endcase
//    end
//        
//    // LB/LBU/LH/LHU/LW/LWU/LD
//    7'b0000011: begin
//        decoded_instr.has_rd = 1'b1;
//        decoded_instr.has_rs1 = 1'b1;
//        decoded_instr.has_imm = 1'b1;
//        decoded_instr.rd = rd;
//        decoded_instr.rs1 = rs1;
//        decoded_instr.imm = { { 20{imm_i[11]} }, imm_i };
//        decoded_instr.unit = UNIT_MEM;
//        decoded_instr.op = OP_MEM_LOAD;
//        decoded_instr.op_size = opfunc[1:0];
//        decoded_instr.op_attri[0] = opfunc[2];  // 1 = Unsigned
//        
//        if (opfunc == 3'b111) begin
//            decoded_instr = UNKOWN_INSTR;
//        end
//    end
//    
//    // SB/SH/SW/SD
//    7'b0100011: begin
//        decoded_instr.has_rs1 = 1'b1;
//        decoded_instr.has_rs2 = 1'b1;
//        decoded_instr.has_imm = 1'b1;
//        decoded_instr.rs1 = rs1;
//        decoded_instr.rs2 = rs2;
//        decoded_instr.imm = { { 20{imm_s[11]} }, imm_s };
//        decoded_instr.unit = UNIT_MEM;
//        decoded_instr.op = OP_MEM_STORE;
//        decoded_instr.op_size = opfunc[1:0];
//        
//        if (opfunc[2] == 1'b1) begin
//            decoded_instr = UNKOWN_INSTR;
//        end
//    end
//    
//    // ADDI/SLTI/SLTIU/XORI/ORI/ANDI/SLLI/SRLI/SRAI
//    7'b0010011: begin
//        decoded_instr.has_rd = 1'b1;
//        decoded_instr.has_rs1 = 1'b1;
//        decoded_instr.has_imm = 1'b1;
//        decoded_instr.rd = rd;
//        decoded_instr.rs1 = rs1;
//        decoded_instr.imm = { { 20{imm_i[11]} }, imm_i };
//        decoded_instr.unit = UNIT_ALU;
//        
//        case (opfunc)
//        3'b000: decoded_instr.op = OP_ALU_ADD;
//        3'b010: decoded_instr.op = OP_ALU_SLT;
//        3'b011: begin
//            decoded_instr.op = OP_ALU_SLT;  // SLTU
//            decoded_instr.op_attri[0] = 1'b1;  // Unsigned
//            decoded_instr.imm = { 20'b0, imm_i };
//        end
//        3'b100: decoded_instr.op = OP_ALU_XOR;
//        3'b110: decoded_instr.op = OP_ALU_OR;
//        3'b111: decoded_instr.op = OP_ALU_AND;
//        3'b001: begin
//            decoded_instr.op = OP_ALU_SLL;
//            decoded_instr.imm = { 27'b0, shift };
//        end
//        3'b101: begin
//            decoded_instr.op = opfext[5] ? OP_ALU_SRA : OP_ALU_SRL;
//            decoded_instr.imm = { 27'b0, shift };
//        end
//        default: decoded_instr = UNKOWN_INSTR;
//        endcase
//    end
//    
//    // ADDIW/SLLIW/SRLIW/SRAIW
//    7'b0011011: begin
//        decoded_instr.has_rd = 1'b1;
//        decoded_instr.has_rs1 = 1'b1;
//        decoded_instr.has_imm = 1'b1;
//        decoded_instr.rd = rd;
//        decoded_instr.rs1 = rs1;
//        decoded_instr.unit = UNIT_ALU;
//        decoded_instr.op_size[0] = 1'b1;    // 32-bit
//        
//        case (opfunc)
//        3'b000: begin
//            decoded_instr.op = OP_ALU_ADD;
//            decoded_instr.imm = { { 20{imm_i[11]} }, imm_i };
//        end
//        3'b001: begin
//            decoded_instr.op = OP_ALU_SLL;
//            decoded_instr.imm = { 27'b0, shift };
//        end
//        3'b101: begin
//            decoded_instr.op = opfext[5] ? OP_ALU_SRA : OP_ALU_SRL;
//            decoded_instr.imm = { 27'b0, shift };
//        end
//        default: decoded_instr = UNKOWN_INSTR;
//        endcase
//    end
//    
//    // ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND
//    // MUL/MULH/MULHSU/MULHU/DIV/DIVU/REM/REMU
//    7'b0110011: begin
//        decoded_instr.has_rd = 1'b1;
//        decoded_instr.has_rs1 = 1'b1;
//        decoded_instr.has_rs2 = 1'b1;
//        decoded_instr.rd = rd;
//        decoded_instr.rs1 = rs1;
//        decoded_instr.rs2 = rs2;
//        
//        // MUL/MULH/MULHSU/MULHU/DIV/DIVU/REM/REMU
//        if (opfext[0]) begin
//            decoded_instr.unit = UNIT_MUL;
//            
//            case (opfunc)
//            3'b000: decoded_instr.op = OP_MDU_MUL;
//            3'b001: begin
//                decoded_instr.op = OP_MDU_MUL;
//                decoded_instr.op_size[1] = 1'b1;    // Upper
//            end
//            3'b010: begin
//                decoded_instr.op = OP_MDU_MUL;
//                decoded_instr.op_size[1] = 1'b1;    // Upper
//                decoded_instr.op_attri[1] = 1'b1;   // Unsigned rs2
//            end
//            3'b011: begin
//                decoded_instr.op = OP_MDU_MUL;
//                decoded_instr.op_size[1] = 1'b1;    // Upper
//                decoded_instr.op_attri[1] = 1'b1;   // Unsigned rs2
//                decoded_instr.op_attri[0] = 1'b1;   // Unsigned rs1
//            end
//            3'b100: decoded_instr.op = OP_MDU_DIV;
//            3'b101: begin
//                decoded_instr.op = OP_MDU_DIV;
//                decoded_instr.op_attri[1] = 1'b1;   // Unsigned rs2
//                decoded_instr.op_attri[0] = 1'b1;   // Unsigned rs1
//            end
//            3'b110: decoded_instr.op = OP_MDU_REM;
//            3'b111: begin
//                decoded_instr.op = OP_MDU_REM;
//                decoded_instr.op_attri[1] = 1'b1;   // Unsigned rs2
//                decoded_instr.op_attri[0] = 1'b1;   // Unsigned rs1
//            end
//            default: decoded_instr = UNKOWN_INSTR;
//            endcase
//        end
//        
//        // ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND
//        else begin
//            decoded_instr.unit = UNIT_ALU;
//            
//            case (opfunc)
//            3'b000: decoded_instr.op = opfext[5] ? OP_ALU_SUB : OP_ALU_ADD;
//            3'b010: decoded_instr.op = OP_ALU_SLT;
//            3'b011: begin
//                decoded_instr.op = OP_ALU_SLT;  // SLTU
//                decoded_instr.op_attri[0] = 1'b1;  // Unsigned
//            end
//            3'b100: decoded_instr.op = OP_ALU_XOR;
//            3'b110: decoded_instr.op = OP_ALU_OR;
//            3'b111: decoded_instr.op = OP_ALU_AND;
//            3'b001: decoded_instr.op = OP_ALU_SLL;
//            3'b101: decoded_instr.op = opfext[5] ? OP_ALU_SRA : OP_ALU_SRL;
//            default: decoded_instr = UNKOWN_INSTR;
//            endcase
//        end
//    end
//    
//    // ADDW/SUBW/SLLW/SRLW/SRAW
//    // MULW/DIVW/DIVUW/REMW/REMUW
//    7'b0111011: begin
//        decoded_instr.has_rd = 1'b1;
//        decoded_instr.has_rs1 = 1'b1;
//        decoded_instr.has_rs2 = 1'b1;
//        decoded_instr.rd = rd;
//        decoded_instr.rs1 = rs1;
//        decoded_instr.rs2 = rs2;
//        decoded_instr.op_size[0] = 1'b1;    // 32-bit
//        
//        // MULW/DIVW/DIVUW/REMW/REMUW
//        if (opfext[0]) begin
//            decoded_instr.unit = UNIT_MUL;
//            
//            case (opfunc)
//            3'b000: decoded_instr.op = OP_MDU_MUL;
//            3'b100: decoded_instr.op = OP_MDU_DIV;
//            3'b101: begin
//                decoded_instr.op = OP_MDU_DIV;
//                decoded_instr.op_attri[1] = 1'b1;   // Unsigned rs2
//                decoded_instr.op_attri[0] = 1'b1;   // Unsigned rs1
//            end
//            3'b110: decoded_instr.op = OP_MDU_REM;
//            3'b111: begin
//                decoded_instr.op = OP_MDU_REM;
//                decoded_instr.op_attri[1] = 1'b1;   // Unsigned rs2
//                decoded_instr.op_attri[0] = 1'b1;   // Unsigned rs1
//            end
//            default: decoded_instr = UNKOWN_INSTR;
//            endcase
//        end
//        
//        // ADDW/SUBW/SLLW/SRLW/SRAW
//        else begin
//            decoded_instr.unit = UNIT_ALU;
//            
//            case (opfunc)
//            3'b000: decoded_instr.op = opfext[5] ? OP_ALU_SUB : OP_ALU_ADD;
//            3'b001: decoded_instr.op = OP_ALU_SLL;
//            3'b101: decoded_instr.op = opfext[5] ? OP_ALU_SRA : OP_ALU_SRL;
//            default: decoded_instr = UNKOWN_INSTR;
//            endcase
//        end
//    end
//    
//    // Atomic
//    7'b0101111: begin
//        decoded_instr.has_rd = 1'b1;
//        decoded_instr.has_rs1 = 1'b1;
//        decoded_instr.rd = rd;
//        decoded_instr.rs1 = rs1;
//        decoded_instr.unit = UNIT_MEM;
//        decoded_instr.op_size = opfunc[0] ? 2'b11 : 2'b10;
//        decoded_instr.op_attri[1:0] = opfext[1:0];
//        
//        case (opfext[6:2])
//        5'b00010: decoded_instr.op = OP_MEM_LOAD_LINK;
//        5'b00011: decoded_instr.op = OP_MEM_STORE_COND;
//        5'b00001: begin
//            decoded_instr.op = OP_MEM_LOAD_AMO; // AMO_SWAP
//            decoded_complex = 1'b1;
//        end
//        5'b00000: begin
//            decoded_instr.op = OP_MEM_LOAD_AMO; // AMO_ADD
//            decoded_complex = 1'b1;
//        end
//        5'b00100: begin
//            decoded_instr.op = OP_MEM_LOAD_AMO; // AMO_XOR
//            decoded_complex = 1'b1;
//        end
//        5'b01100: begin
//            decoded_instr.op = OP_MEM_LOAD_AMO; // AMO_AND
//            decoded_complex = 1'b1;
//        end
//        5'b01000: begin
//            decoded_instr.op = OP_MEM_LOAD_AMO; // AMO_OR
//            decoded_complex = 1'b1;
//        end
//        5'b10000: begin
//            decoded_instr.op = OP_MEM_LOAD_AMO; // AMO_MIN
//            decoded_complex = 1'b1;
//        end
//        5'b11000: begin
//            decoded_instr.op = OP_MEM_LOAD_AMO; // AMO_MIN_U
//            decoded_instr.op_attri[0] = 1'b1;      // Unsigned
//            decoded_complex = 1'b1;
//        end
//        5'b10100: begin
//            decoded_instr.op = OP_MEM_LOAD_AMO; // AMO_MAX
//            decoded_complex = 1'b1;
//        end
//        5'b11100: begin
//            decoded_instr.op = OP_MEM_LOAD_AMO; // AMO_MAX_U
//            decoded_instr.op_attri[0] = 1'b1;      // Unsigned
//            decoded_complex = 1'b1;
//        end
//        default: decoded_instr = UNKOWN_INSTR;
//        endcase
//    end
//    
//    // FENCE/FENCE.I
//    7'b0001111: begin
//        if (opfunc[0]) begin
//            decoded_instr.unit = UNIT_ALU;
//            decoded_instr.op = OP_ALU_FLUSH;
//        end
//        
//        else begin
//            decoded_instr.unit = UNIT_MEM;
//            decoded_instr.op = OP_MEM_FENCE;
//            decoded_instr.has_imm = 1'b1;
//            decoded_instr.imm = { 20'b0, imm_i };
//        end
//    end
//    
//    // SYS/CSR
//    7'b1110011: begin
//        // CSR
//        if (opfunc != 3'b000) begin
//            decoded_instr.has_rd = 1'b1;
//            decoded_instr.has_rs1 = ~opfunc[2];
//            decoded_instr.alt_rs1 = opfunc[2];
//            decoded_instr.has_imm = 1'b1;
//            decoded_instr.rd = rd;
//            decoded_instr.rs1 = rs1;
//            decoded_instr.imm = { 20'b0, imm_i };
//            decoded_instr.unit = UNIT_CSR;
//            
//            case (opfunc[1:0])
//            2'b01: decoded_instr.op = OP_CSR_SWAP;
//            2'b10: decoded_instr.op = OP_CSR_READ_SET;
//            2'b11: decoded_instr.op = OP_CSR_READ_CLEAR;
//            default: decoded_instr = UNKOWN_INSTR;
//            endcase
//        end
//        
//        // SFENCE.WMA
//        else if (opfext == 7'b0001001) begin
//            decoded_instr = UNKOWN_INSTR;
//        end
//        
//        // WFI
//        else if (opfext == 7'b0001000) begin
//            decoded_instr = UNKOWN_INSTR;
//        end
//        
//        // Trap-RET
//        else if (imm_i[4:0] == 5'b00010) begin
//            decoded_instr.unit = UNIT_BR;
//            decoded_instr.op = OP_BR_TRAP_RET;
//            decoded_instr.op_attri[1:0] = opfext[4:3];
//        end
//        
//        // ECALL/EBREAK
//        else begin
//            decoded_instr.unit = UNIT_BR;
//            decoded_instr.op = imm_i[0] ? OP_BR_EBREAK : OP_BR_ECALL;
//        end
//    end
//    
//    // Unknown
//    default: decoded_instr = UNKOWN_INSTR;
//    endcase
//end

endmodule

