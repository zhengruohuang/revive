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
    UNIT_BR,
    UNIT_CSR,
    UNIT_MUL,
    UNIT_MEM,
    UNIT_AMO,
    UNIT_FP
} decode_fu_t;

typedef enum logic [3:0] {
    OP_ALU_ADD,
    OP_ALU_SUB,
    
    OP_ALU_MIN,
    OP_ALU_MAX,
    
    OP_ALU_AND,
    OP_ALU_OR,
    OP_ALU_XOR,
    
    OP_ALU_SLL,     // Shift left logical
    OP_ALU_SRL,     // Shift right logical
    OP_ALU_SRA,     // Shift right arithmetic
    
    OP_ALU_SLT,     // Set less than
    OP_ALU_SLTU,
    
    OP_ALU_FLUSH
} decode_alu_op_t;

typedef enum logic [2:0] {
    OP_BR_BEQ,
    OP_BR_BNE,
    OP_BR_BLT,
    OP_BR_BLTU,
    OP_BR_JALR
} decode_br_op_t;

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

typedef enum logic [1:0] {
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
    decode_mul_op_t mul;
    decode_csr_op_t csr;
    decode_mem_op_t mem;
    decode_amo_op_t amo;
} decode_op_t;

typedef union packed {
    logic [1:0]     mem_size;
    logic           w32;
} decode_op_size_t;

typedef struct packed {
    logic [11:0]    idx;
    logic [4:0]     mask;
} decode_csr_field_t;

typedef union packed {
`ifdef RV32
    logic [4:0]         shift;
`else
    logic [5:0]         shift;
`endif
    logic [4:0]         shift32;
    logic [19:0]        imm;
    decode_csr_field_t  csr;
} decode_imm_fields_t;

typedef struct packed {
    decode_imm_fields_t fields;
    logic               valid;
} decode_imm_t;

typedef struct packed {
    decode_fu_t         unit;
    decode_op_t         op;
    decode_op_size_t    op_size;
    int_arch_reg_sel_t  rd;
    int_arch_reg_sel_t  rs1;
    int_arch_reg_sel_t  rs2;
    decode_imm_t        imm;
    except_t            except;
    logic               serial;     // Stall sched until ROB empty
} decode_t;


`endif

