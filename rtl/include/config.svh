`ifndef __CONFIG_SV__
`define __CONFIG_SV__

`define RV32

/*
 * Data width
 */
`define DATA_WIDTH          32
`define DATA_WIDTH_BITS     5

`define SHORT_INSTR_WIDTH   16
`define INSTR_WIDTH         32
`define INSTR_WIDTH_BITS    5

`define VADDR_WIDTH         32
`define PADDR_WIDTH         34
`define PC_WIDTH            32

/*
 * Memory
 */
`define PAGE_SIZE           4096
`define PAGE_SIZE_BITS      12
`define ASID_WIDTH          9

`define CACHELINE_SIZE          32      // In bytes
`define CACHELINE_SIZE_BITS     5
`define CACHELINE_WIDTH         256     // In bits
`define CACHELINE_WIDTH_BITS    8       // Num of bits to represent WIDTH

/*
 * ICache and ITLB
 */
`define ITLB_ASSOC          2
`define ITLB_SETS           32
`define ITLB_SETS_BITS      5

`define ICACHE_ASSOC        2
`define ICACHE_SETS         32
`define ICACHE_SETS_BITS    5

/*
 * DCache and DTLB
 */
`define DTLB_ASSOC          2
`define DCACHE_ASSOC        2

/*
 * Registers
 */
`define INT_ARCH_REGS               32
`define INT_ARCH_REGS_BITS          5
`define INT_ARCH_REG_READ_PORTS     4
`define INT_ARCH_REG_WRITE_PORTS    2

`define SYS_ARCH_REGS               32
`define SYS_ARCH_REGS_BITS          5
`define SYS_ARCH_REG_READ_PORTS     1
`define SYS_ARCH_REG_WRITE_PORTS    1

/*
 * Pipeline width
 */
`define FETCH_WIDTH         2
`define FETCH_WIDTH_BITS    1

`define FETCH_DATA_WIDTH        (`INSTR_WIDTH * `FETCH_WIDTH)
`define FETCH_DATA_WIDTH_BITS   (`INSTR_WIDTH_BITS + `FETCH_WIDTH_BITS)

`define ISSUE_WIDTH         2
`define ISSUE_WIDTH_BITS    1

`define WRITEBACK_WIDTH     2

`define COMMIT_WIDTH        4

/*
 * ROB
 */
`define ROB_SIZE            8
`define ROB_SIZE_BITS       3

/*
 * Misc
 */
`define INIT_PC             32'h8000

`endif

