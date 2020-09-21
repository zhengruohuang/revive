`include "include/config.svh"
`include "include/instr.svh"
`include "include/reg.svh"
`include "include/rob.svh"

module reg_file (
    input                               i_recover,
    
    input                               i_issued,
    input   issued_instr_t              i_instrs            [0:`ISSUE_WIDTH - 1],
    output  issued_instr_t              o_instrs            [0:`ISSUE_WIDTH - 1],
    
    input   int_arch_reg_sel_t          i_int_reg_read      [0:`INT_ARCH_REG_READ_PORTS - 1],
    input   sys_arch_reg_sel_t          i_sys_reg_read      [0:`SYS_ARCH_REG_READ_PORTS - 1],
    
    input   int_arch_reg_write_t        i_int_reg_wb_spclvt [0:`INT_ARCH_REG_WRITE_PORTS - 1],
    input   sys_arch_reg_write_t        i_sys_reg_wb_spclvt [0:`SYS_ARCH_REG_WRITE_PORTS - 1],
    
    input   int_arch_reg_write_t        i_int_reg_wb_commit [0:`INT_ARCH_REG_WRITE_PORTS - 1],
    input   sys_arch_reg_write_t        i_sys_reg_wb_commit [0:`SYS_ARCH_REG_WRITE_PORTS - 1],
    
    output  reg_data_t                  o_int_reg_data      [0:`INT_ARCH_REG_READ_PORTS - 1],
    output  reg_data_t                  o_sys_reg_data      [0:`SYS_ARCH_REG_READ_PORTS - 1],
    
    input   i_clk,
    input   i_rst_n
);

    // Use in-flight or committed register file
    logic   [`INT_ARCH_REGS - 1:0]      int_reg_committed;
    logic   [`SYS_ARCH_REGS - 1:0]      sys_reg_committed;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_recover) begin
            int_reg_committed <= { `INT_ARCH_REGS{1'b1} };
            int_reg_committed <= { `SYS_ARCH_REGS{1'b1} };
        end
        
        else begin
            for (integer i = 0; i < `INT_ARCH_REG_WRITE_PORTS; i = i + 1) begin
                if (i_int_reg_wb_spclvt[i].valid) begin
                    int_reg_committed[i_int_reg_wb_spclvt[i].idx] <= 1'b0;
                end
            end
            
            for (integer i = 0; i < `SYS_ARCH_REG_WRITE_PORTS; i = i + 1) begin
                if (i_sys_reg_wb_spclvt[i].valid) begin
                    sys_reg_committed[i_sys_reg_wb_spclvt[i].idx] <= 1'b0;
                end
            end
        end
    end


endmodule

