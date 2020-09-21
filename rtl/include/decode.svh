`ifndef __DECODE_SVH__
`define __DECODE_SVH__


`include "include/config.svh"
`include "include/except.svh"
`include "include/reg.svh"


/*
 * Instr Decode
 */
typedef enum logic [2:0] {
    UNIT_ALU,
    UNIT_BRU,
    UNIT_CSR,
    UNIT_MUL,
    UNIT_MEM,
    UNIT_AMO,
    UNIT_FPU,
    UNIT_FMA
} decode_fu_t;

typedef enum logic [3:0] {
    OP_ALU_NONE,
    OP_ALU_LUI,
    
    OP_ALU_ADD,
    OP_ALU_SUB,
    
    //OP_ALU_MIN,
    //OP_ALU_MAX,
    
    OP_ALU_AND,
    OP_ALU_OR,
    OP_ALU_XOR,
    
    OP_ALU_SLL,     // Shift left logical
    OP_ALU_SRL,     // Shift right logical
    OP_ALU_SRA,     // Shift right arithmetic
    
    OP_ALU_SLT,     // Set less than
    OP_ALU_SLTU,
    
    OP_ALU_FENCE
} decode_alu_op_t;

typedef enum logic [3:0] {
    OP_BRU_BEQ,
    OP_BRU_BLT,
    OP_BRU_BLTU,
    OP_BRU_JAL,
    OP_BRU_JALR
} decode_bru_op_t;

typedef enum logic [3:0] {
    OP_MDU_MUL,
    OP_MDU_MUL_HIGH,
    OP_MDU_MULSU_HIGH,
    OP_MDU_MULU_HIGH,
    OP_MDU_DIV,
    OP_MDU_DIVU,
    OP_MDU_REM,
    OP_MDU_REMU
} decode_mul_op_t;

typedef enum logic [3:0] {
    OP_CSR_SWAP,
    OP_CSR_READ_SET,
    OP_CSR_READ_CLEAR,
    
    OP_CSR_ECALL,
    OP_CSR_EBREAK,
    
    OP_CSR_URET,
    OP_CSR_SRET,
    OP_CSR_MRET,
    
    OP_CSR_WFI,
    OP_CSR_FENCE_VMA
} decode_csr_op_t;

typedef enum logic [3:0] {
    OP_MEM_LD,
    OP_MEM_LDU,
    OP_MEM_ST
} decode_mem_op_t;

typedef enum logic [3:0] {
    OP_AMO_LL,
    OP_AMO_SC,
    OP_AMO_SWAP,
    OP_AMO_ADD,
    OP_AMO_XOR,
    OP_AMO_AND,
    OP_AMO_OR,
    OP_AMO_MIN,
    OP_AMO_MAX,
    OP_AMO_MINU,
    OP_AMO_MAXU,
    
    OP_AMO_FENCE
} decode_amo_op_t;

typedef union packed {
    decode_alu_op_t alu;
    decode_bru_op_t bru;
    decode_mul_op_t mul;
    decode_csr_op_t csr;
    decode_mem_op_t mem;
    decode_amo_op_t amo;
} decode_op_t;

typedef union packed {
    logic [1:0]     mem_size;
    logic           w32;
    logic           invert;
} decode_op_size_t;

typedef struct packed {
    logic [2:0]     reserved;
    logic [11:0]    idx;
    logic [4:0]     mask;
} decode_csr_field_t;

typedef union packed {
    logic [19:0]        imm20;
    decode_csr_field_t  csr;
} decode_imm_t;

typedef enum logic [2:0] {
    RS_NONE,
    RS_REG,
    RS_IMM,
    RS_PC,
    RS_ZIMM
} decode_rs_sel_t;

typedef enum logic [2:0] {
    RD_NONE,
    RD_REG,
    RD_PC,
    RD_REG_AND_PC,
    RD_FLUSH
} decode_rd_sel_t;

typedef struct packed {
    decode_fu_t         unit;
    decode_op_t         op;
    decode_op_size_t    op_size;
    int_arch_reg_sel_t  rd;
    decode_rd_sel_t     rd_sel;
    int_arch_reg_sel_t  rs1;
    decode_rs_sel_t     rs1_sel;
    int_arch_reg_sel_t  rs2;
    decode_rs_sel_t     rs2_sel;
    decode_imm_t        imm;
    logic               half;
    logic               serialize;     // Stall sched until ROB empty
} decode_t;

function reg_data_t extend_imm;
    input decode_imm_t imm;
    begin
        extend_imm = { {12{imm.imm20[19]}}, imm.imm20 };
    end
endfunction

`define NOP_DECODE { UNIT_ALU, OP_ALU_NONE, 2'b0, `INVALID_REG, RD_NONE, `INVALID_REG, RS_NONE, `INVALID_REG, RS_NONE, 20'b0, 1'b0, 1'b0 }

`endif

