`include "include/config.svh"
`include "include/pc.svh"
`include "include/ps.svh"
`include "include/reg.svh"
`include "include/rob.svh"

module instr_commit (
    input                           i_flush,
    input   program_state_t         i_ps,
    
    // From Sched
    input                           i_enqueue,
    input   issued_instr_t          i_instrs        [0:`ISSUE_WIDTH - 1],
    
    // From WB
    input   int_arch_reg_write_t    i_int_reg_wb    [0:`INT_ARCH_REG_WRITE_PORTS - 1],
    input   sys_arch_reg_write_t    i_sys_reg_wb    [0:`SYS_ARCH_REG_WRITE_PORTS - 1],
    input   rob_sel_t               i_rob_idx       [0:`INT_ARCH_REG_WRITE_PORTS - 1],
    
    // To Sched
    output                          o_rob_avail,
    output  rob_idx_t               o_rob_idx       [0:`ISSUE_WIDTH - 1],
    
    // To Reg
    output  int_arch_reg_write_t    o_int_reg_wb    [0:`INT_ARCH_REG_WRITE_PORTS - 1],
    output  sys_arch_reg_write_t    o_sys_reg_wb    [0:`SYS_ARCH_REG_WRITE_PORTS - 1],
    
    // CPU State
    output                          o_alter_ps,
    output  program_state_t         o_ps,
    output                          o_alter_pc,
    output  program_counter_t       o_pc,
    output                          o_flush,
    
    input   i_clk,
    input   i_rst_n
);


endmodule

