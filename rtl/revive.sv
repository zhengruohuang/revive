`include "include/config.svh"
`include "include/instr.svh"

`include "core/program_state.sv"
`include "core/program_counter.sv"
`include "core/fetch.sv"
`include "core/align.sv"
`include "core/decode.sv"
`include "core/sched.sv"
`include "core/reg_fetch.sv"
`include "core/exec.sv"
`include "core/lsu.sv"
`include "core/writeback.sv"

module revive (
    input   program_counter_t   i_init_pc,
    
    input   i_clk,
    input   i_rst_n
);

    //--------------------------------------------------------------------------
    // Pipeline Stages
    //--------------------------------------------------------------------------
    // Fetch
    // Align
    // Decode
    // Sched
    // RF
    // EX/AGU
    // Mem
    // Writeback

    //--------------------------------------------------------------------------
    // Program State
    //--------------------------------------------------------------------------
    wire                        to_ps_alter;
    wire    program_state_t     to_ps_ps;
    
    wire    program_state_t     from_ps_ps;
    
    program_state ps (
        .i_alter        (to_ps_alter),
        .i_ps           (to_ps_ps),
        .o_ps           (from_ps_ps),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Program Counter
    //--------------------------------------------------------------------------
    wire                        to_pc_stall;
    wire                        to_pc_flush;
    
    wire                        to_pc_alter;
    wire    program_counter_t   to_pc_pc;
    
    wire    program_counter_t   from_pc_pc;
    
    program_counter pc (
        .i_stall        (to_pc_stall),
        .i_init_pc      (i_init_pc),
        .i_alter        (to_pc_alter),
        .i_pc           (to_pc_pc),
        .o_pc           (from_pc_pc),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Fetch
    //--------------------------------------------------------------------------
    wire                        to_if_stall;
    wire                        to_if_flush;
    
    wire    program_counter_t   to_if_pc = from_pc_pc;
    wire    program_state_t     to_if_ps = from_ps_ps;
    
    wire                        from_if_stall;
    wire    fetched_data_t      from_if_data;
    
    fetch ifetch (
        .i_stall        (to_if_stall),
        .i_flush        (to_if_flush),
        .i_pc           (to_if_pc),
        .i_ps           (to_if_ps),
        .o_stall        (from_if_stall),
        .o_data         (from_if_data),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Align
    //--------------------------------------------------------------------------
    wire                        to_ia_stall;
    wire                        to_ia_flush;
    
    wire    fetched_data_t      to_ia_data = from_if_data;
    
    wire                        from_ia_stall;
    wire    aligned_instr_t     from_ia_instr;
    
    align ia (
        .i_stall        (to_ia_stall),
        .i_flush        (to_ia_flush),
        .i_data         (to_ia_data),
        .o_stall        (from_ia_stall),
        .o_instr        (from_ia_instr),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Decode
    //--------------------------------------------------------------------------
    wire                        to_id_stall;
    wire                        to_id_flush;
    
    wire    aligned_instr_t     to_id_instr = from_ia_instr;
    
    wire    decoded_instr_t     from_id_instr;
    
    decode id (
        .i_stall        (to_id_stall),
        .i_flush        (to_id_flush),
        .i_instr        (to_id_instr),
        .o_instr        (from_id_instr),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Sched
    //--------------------------------------------------------------------------
    wire                        to_is_stall;
    wire                        to_is_flush;
    
    wire    decoded_instr_t     to_is_instr = from_id_instr;
    wire    int_arch_reg_wb_t   to_is_int_reg_wb;
    
    wire                        from_is_stall;
    wire    issued_instr_t      from_is_instr;
    
    schedule isched (
        .i_stall        (to_is_stall),
        .i_flush        (to_is_flush),
        .i_instr        (to_is_instr),
        .o_stall        (from_is_stall),
        .o_instr        (from_is_instr),
        .i_int_reg_wb   (to_is_int_reg_wb),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Register Fetch
    //--------------------------------------------------------------------------
    wire                        to_rf_stall;
    wire                        to_rf_flush;
    
    wire    issued_instr_t      to_rf_instr = from_is_instr;
    wire    int_arch_reg_wb_t   to_rf_int_reg_wb;
    
    wire    issued_instr_t      from_rf_instr;
    wire    reg_data_t          from_rf_data_rs1;
    wire    reg_data_t          from_rf_data_rs2;
    
    reg_fetch rf (
        .i_stall        (to_rf_stall),
        .i_flush        (to_rf_flush),
        .i_instr        (to_rf_instr),
        .o_instr        (from_rf_instr),
        .o_data_rs1     (from_rf_data_rs1),
        .o_data_rs2     (from_rf_data_rs2),
        .i_int_reg_wb   (to_rf_int_reg_wb),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Execute
    //--------------------------------------------------------------------------
    wire                        to_ex_stall;
    wire                        to_ex_flush;
    wire    program_state_t     to_ex_ps = from_ps_ps;
    
    wire    issued_instr_t      to_ex_instr = from_rf_instr;
    wire    reg_data_t          to_ex_data_rs1 = from_rf_data_rs1;
    wire    reg_data_t          to_ex_data_rs2 = from_rf_data_rs2;
    wire                        from_ex_stall;
    
    wire    issued_instr_t      from_ex_instr;
    wire    reg_data_t          from_ex_data;
    wire    reg_data_t          from_ex_data_rs2;
    
    execute exec (
        .i_stall        (to_ex_stall),
        .i_flush        (to_ex_flush),
        .i_ps           (to_ex_ps),
        .i_instr        (to_ex_instr),
        .i_data_rs1     (to_ex_data_rs1),
        .i_data_rs2     (to_ex_data_rs2),
        .o_stall        (from_ex_stall),
        .o_instr        (from_ex_instr),
        .o_data         (from_ex_data),
        .o_data_rs2     (from_ex_data_rs2),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Load/Store Unit
    //--------------------------------------------------------------------------
    wire                        to_ls_flush;
    wire    program_state_t     to_ls_ps = from_ps_ps;
    
    wire    issued_instr_t      to_ls_instr = from_ex_instr;
    wire    reg_data_t          to_ls_data = from_ex_data;
    wire    reg_data_t          to_ls_data_rs2 = from_ex_data_rs2;
    
    wire                        from_ls_stall;
    wire    issued_instr_t      from_ls_instr;
    wire    reg_data_t          from_ls_data;
    
    ldst_unit lsu (
        .i_flush        (to_ls_flush),
        .i_ps           (to_ls_ps),
        .i_instr        (to_ls_instr),
        .i_data         (to_ls_data),
        .i_data_rs2     (to_ls_data_rs2),
        .o_stall        (from_ls_stall),
        .o_instr        (from_ls_instr),
        .o_data         (from_ls_data),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Writeback
    //--------------------------------------------------------------------------
    wire    program_state_t     to_wb_ps = from_ps_ps;
    
    wire    issued_instr_t      to_wb_instr = from_ls_instr;
    wire    reg_data_t          to_wb_data = from_ls_data;
    
    wire    int_arch_reg_wb_t   from_wb_int_reg_wb;
    wire                        from_wb_flush;
    wire                        from_wb_ps_alter;
    wire    program_state_t     from_wb_ps;
    wire                        from_wb_pc_alter;
    wire    program_counter_t   from_wb_pc;
    
    writeback wb (
        .i_ps           (to_wb_ps),
        .i_instr        (to_wb_instr),
        .i_data         (to_wb_data),
        .o_int_reg_wb   (from_wb_int_reg_wb),
        .o_flush        (from_wb_flush),
        .o_ps_alter     (from_wb_ps_alter),
        .o_ps           (from_wb_ps),
        .o_pc_alter     (from_wb_pc_alter),
        .o_pc           (from_wb_pc),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Pipeline Control
    //--------------------------------------------------------------------------
    assign  to_ps_alter         = from_wb_ps_alter;
    assign  to_ps_ps            = from_wb_ps;
    
    assign  to_pc_stall         = from_if_stall;
    assign  to_pc_flush         = from_wb_flush;
    assign  to_pc_alter         = from_wb_pc_alter;
    assign  to_pc_pc            = from_wb_pc;
    
    assign  to_if_stall         = from_ia_stall;
    assign  to_if_flush         = from_wb_flush;
    
    assign  to_ia_stall         = from_is_stall;
    assign  to_ia_flush         = from_wb_flush;
    
    assign  to_id_stall         = from_is_stall;
    assign  to_id_flush         = from_wb_flush;
    
    assign  to_is_stall         = from_ex_stall;
    assign  to_is_flush         = from_wb_flush;
    assign  to_is_int_reg_wb    = from_wb_int_reg_wb;
    
    assign  to_rf_stall         = from_ex_stall;
    assign  to_rf_flush         = from_wb_flush;
    assign  to_rf_int_reg_wb    = from_wb_int_reg_wb;
    
    assign  to_ex_stall         = from_ls_stall;
    assign  to_ex_flush         = from_wb_flush;
    
    assign  to_ls_flush         = from_wb_flush;

endmodule

