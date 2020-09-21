`include "include/config.svh"

`include "program_state.sv"
`include "program_counter.sv"
`include "instr_fetch1.sv"
`include "instr_fetch2.sv"
`include "caches/instr_tlb.sv"
`include "caches/instr_cache.sv"
`include "instr_align.sv"
`include "instr_queue.sv"
`include "instr_decode.sv"
`include "instr_sched.sv"
`include "instr_commit.sv"
`include "reg_file.sv"
`include "exec_port1.sv"
`include "exec_port2.sv"
`include "writeback_arbiter.sv"

module revive (
    input i_clk,
    input i_rst_n
);

    //--------------------------------------------------------------------------
    // Pipeline Stages
    //--------------------------------------------------------------------------
    // Fetch1
    // Fetch2
    // FetchQ
    // Align
    // Decode
    // IssueQ
    // Schedule
    // RF
    // ALU -> BSU / AGU -> Mem1 -> Mem2
    // Writeback
    // Completion

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
    // PC
    //--------------------------------------------------------------------------
    wire                        to_pc_stall;
    wire                        to_pc_flush;
    
    wire                        to_pc_alter;
    wire    program_counter_t   to_pc_pc;
    
    wire    program_counter_t   from_pc_pc;
    
    program_counter pc (
        .i_stall        (to_pc_stall),
        .i_alter        (to_pc_alter),
        .i_pc           (to_pc_pc),
        .o_pc           (from_pc_pc),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Instr Fetch 1
    //--------------------------------------------------------------------------
    wire                        to_if1_stall;
    wire                        to_if1_flush;
    
    wire    program_counter_t   to_if1_pc       = from_pc_pc;
    wire    program_state_t     to_if1_ps       = from_ps_ps;
    
    wire                        from_if1_valid;
    wire    program_counter_t   from_if1_pc;
    
    wire                        from_if1_itlb_read;
    wire                        from_if1_icache_read;
    wire    program_counter_t   from_if1_ram_pc;
    
    instr_fetch1 if1 (
        .i_stall        (to_if1_stall),
        .i_flush        (to_if1_flush),
        .i_pc           (to_if1_pc),
        .i_ps           (to_if1_ps),
        .o_valid        (from_if1_valid),
        .o_pc           (from_if1_pc),
        .o_itlb_read    (from_if1_itlb_read),
        .o_icache_read  (from_if1_icache_read),
        .o_ram_pc       (from_if1_ram_pc),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Instr Fetch 2
    //--------------------------------------------------------------------------
    wire                        to_if2_stall;
    wire                        to_if2_flush;
    
    wire                        to_if2_valid        = from_if1_valid;
    wire    program_counter_t   to_if2_pc           = from_if1_pc;
    wire    program_state_t     to_if2_ps           = from_ps_ps;
    
    wire    itlb_tag_entry_t    to_if2_itlb_tag     [0:`ITLB_ASSOC - 1];
    wire    itlb_data_entry_t   to_if2_itlb_data    [0:`ITLB_ASSOC - 1];
    wire    icache_tag_entry_t  to_if2_icache_tag   [0:`ICACHE_ASSOC - 1];
    wire    icache_data_entry_t to_if2_icache_data  [0:`ICACHE_ASSOC - 1];
    
    wire                        from_if2_valid;
    wire    program_counter_t   from_if2_pc;
    wire    fetch_data_t        from_if2_data;
    except_t                    from_if2_except;
    
    instr_fetch2 if2 (
        .i_stall        (to_if2_stall),
        .i_flush        (to_if2_flush),
        .i_valid        (to_if2_valid),
        .i_pc           (to_if2_pc),
        .i_ps           (to_if2_ps),
        .i_itlb_tag     (to_if2_itlb_tag),
        .i_itlb_data    (to_if2_itlb_data),
        .i_icache_tag   (to_if2_icache_tag),
        .i_icache_data  (to_if2_icache_data),
        .o_valid        (from_if2_valid),
        .o_pc           (from_if2_pc),
        .o_data         (from_if2_data),
        .o_except       (from_if2_except),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // ITLB
    //--------------------------------------------------------------------------
    wire    program_counter_t   to_itlb_pc          = from_if1_ram_pc;
    wire                        to_itlb_read        = from_if1_itlb_read;
    
    wire    itlb_tag_entry_t    from_itlb_tag       [0:`ITLB_ASSOC - 1];
    wire    itlb_data_entry_t   from_itlb_data      [0:`ITLB_ASSOC - 1];
    
    assign  to_if2_itlb_tag     = from_itlb_tag;
    assign  to_if2_itlb_data    = from_itlb_data;
    
    instr_tlb itlb (
        .i_pc           (to_itlb_pc),
        .i_read         (to_itlb_read),
        .o_itlb_tag     (from_itlb_tag),
        .o_itlb_data    (from_itlb_data),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // ICache
    //--------------------------------------------------------------------------
    wire    program_counter_t   to_icache_pc        = from_if1_ram_pc;
    wire                        to_icache_read      = from_if1_icache_read;
    
    wire    icache_tag_entry_t  from_icache_tag     [0:`ICACHE_ASSOC - 1];
    wire    icache_data_entry_t from_icache_data    [0:`ICACHE_ASSOC - 1];
    
    assign  to_if2_icache_tag   = from_icache_tag;
    assign  to_if2_icache_data  = from_icache_data;
    
    instr_cache icache (
        .i_pc           (to_icache_pc),
        .i_read         (to_icache_read),
        .o_icache_tag   (from_icache_tag),
        .o_icache_data  (from_icache_data),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Instr Align
    //--------------------------------------------------------------------------
    wire                        to_ia_stall;
    wire                        to_ia_flush;
    
    wire                        to_ia_valid     = from_if2_valid;
    wire    program_counter_t   to_ia_pc        = from_if2_pc;
    wire    fetch_data_t        to_ia_data      = from_if2_data;
    wire    except_t            to_ia_except    = from_if2_except;
    
    wire                        from_ia_valid;
    wire    aligned_instr_t     from_ia_instrs  [0:`FETCH_WIDTH - 1];
    wire                        from_ia_stall;
    
    assign  to_if2_stall        = from_ia_stall;
    assign  to_if1_stall        = from_ia_stall;
    assign  to_pc_stall         = from_ia_stall;
    
    instr_align ia (
        .i_stall        (to_ia_stall),
        .i_flush        (to_ia_flush),
        .i_valid        (to_ia_valid),
        .i_pc           (to_ia_pc),
        .i_data         (to_ia_data),
        .i_except       (to_ia_except),
        .o_valid        (from_ia_valid),
        .o_instrs       (from_ia_instrs),
        .o_stall        (from_ia_stall),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // InstrQ
    //--------------------------------------------------------------------------
    wire                        to_iq_flush;
    
    wire                        to_iq_enqueue;
    wire    aligned_instr_t     to_iq_instrs    [0:`FETCH_WIDTH - 1];
    wire                        to_iq_dequeue;
    wire    aligned_instr_t     from_iq_instrs  [0:`FETCH_WIDTH - 1];
    
    wire                        from_iq_can_enqueue;
    wire                        from_iq_can_dequeue;
    
    assign  to_iq_enqueue       = from_ia_valid;
    assign  to_iq_instrs        = from_ia_instrs;
    assign  to_ia_stall         = ~from_iq_can_enqueue;
    
    instr_queue iq (
        .i_flush        (to_iq_flush),
        .i_enqueue      (to_iq_enqueue),
        .i_instrs       (to_iq_instrs),
        .i_dequeue      (to_iq_dequeue),
        .o_instrs       (from_iq_instrs),
        .o_can_enqueue  (from_iq_can_enqueue),
        .o_can_dequeue  (from_iq_can_dequeue),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Instr Decode
    //--------------------------------------------------------------------------
    wire                        to_id_stall;
    wire                        to_id_flush;
    
    wire                        to_id_can_dequeue;
    wire    aligned_instr_t     to_id_instrs        [0:`FETCH_WIDTH - 1];
    wire                        from_id_dequeue;
    
    wire                        from_id_valid;
    wire    decoded_instr_t     from_id_instrs      [0:`FETCH_WIDTH - 1];
    
    assign  to_id_can_dequeue   = from_iq_can_dequeue;
    assign  to_id_instrs        = from_iq_instrs;
    assign  to_iq_dequeue       = from_id_dequeue;
    
    instr_decode id (
        .i_stall        (to_ia_stall),
        .i_flush        (to_ia_flush),
        .i_can_dequeue  (to_id_can_dequeue),
        .i_instrs       (to_id_instrs),
        .o_dequeue      (from_id_dequeue),
        .o_valid        (from_id_valid),
        .o_instrs       (from_id_instrs),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Instr Sched
    //--------------------------------------------------------------------------
    wire                            to_is_flush;
    
    wire                            to_is_valid     = from_id_valid;
    wire    decoded_instr_t         to_is_instrs    [0:`FETCH_WIDTH - 1];
    
    wire    int_arch_reg_write_t    to_is_int_reg_wb        [0:`INT_ARCH_REG_WRITE_PORTS - 1];
    wire    sys_arch_reg_write_t    to_is_sys_reg_wb        [0:`SYS_ARCH_REG_WRITE_PORTS - 1];
    
    wire                            to_is_mul_ready;
    wire                            to_is_mem_ready;
    
    wire                            to_is_rob_avail;
    wire    rob_idx_t               to_is_rob_idx           [0:`ISSUE_WIDTH - 1];
    
    wire    int_arch_reg_sel_t      from_is_int_reg_read    [0:`INT_ARCH_REG_READ_PORTS - 1];
    wire    int_arch_reg_sel_t      from_is_sys_reg_read    [0:`SYS_ARCH_REG_READ_PORTS - 1];
    
    wire                            from_is_issued;
    wire    issued_instr_t          from_is_instrs          [0:`ISSUE_WIDTH - 1];
    
    wire                            from_is_stall;
    
    assign  to_is_instrs            = from_id_instrs;
    assign  to_id_stall             = from_is_stall;
    
    instr_sched is (
        .i_flush        (to_iq_flush),
        .i_valid        (to_is_valid),
        .i_instrs       (to_is_instrs),
        .i_int_reg_wb   (to_is_int_reg_wb),
        .i_sys_reg_wb   (to_is_sys_reg_wb),
        .i_mul_ready    (to_is_mul_ready),
        .i_mem_ready    (to_is_mem_ready),
        .i_rob_avail    (to_is_rob_avail),
        .i_rob_idx      (to_is_rob_idx),
        .o_int_reg_read (from_is_int_reg_read),
        .o_sys_reg_read (from_is_sys_reg_read),
        .o_issued       (from_is_issued),
        .o_instrs       (from_is_instrs),
        .o_stall        (from_is_stall),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Instr Commit
    //--------------------------------------------------------------------------
    wire                            to_ic_flush;
    wire    program_state_t         to_ic_ps            = from_ps_ps;
    
    wire                            to_ic_enqueue       = from_is_issued;
    wire    issued_instr_t          to_ic_instrs        [0:`ISSUE_WIDTH - 1];
    
    wire    int_arch_reg_write_t    to_ic_int_reg_wb    [0:`INT_ARCH_REG_WRITE_PORTS - 1];
    wire    sys_arch_reg_write_t    to_ic_sys_reg_wb    [0:`SYS_ARCH_REG_WRITE_PORTS - 1];
    wire    rob_sel_t               to_ic_rob_idx       [0:`INT_ARCH_REG_WRITE_PORTS - 1];
    
    wire                            from_ic_rob_avail;
    wire    rob_idx_t               from_ic_rob_idx     [0:`ISSUE_WIDTH - 1];
    
    wire    int_arch_reg_write_t    from_ic_int_reg_wb  [0:`INT_ARCH_REG_WRITE_PORTS - 1];
    wire    sys_arch_reg_write_t    from_ic_sys_reg_wb  [0:`SYS_ARCH_REG_WRITE_PORTS - 1];
    
    wire                            from_ic_alter_ps;
    wire    program_state_t         from_ic_ps;
    wire                            from_ic_alter_pc;
    wire    program_counter_t       from_ic_pc;
    wire                            from_ic_flush;
    
    assign  to_ic_instrs            = from_is_instrs;
    assign  to_is_rob_idx           = from_ic_rob_idx;
    assign  to_is_rob_avail         = from_ic_rob_avail;
    
    instr_commit ic (
        .i_flush        (to_ic_flush),
        .i_ps           (to_ic_ps),
        .i_enqueue      (to_ic_enqueue),
        .i_instrs       (to_ic_instrs),
        .i_int_reg_wb   (to_ic_int_reg_wb),
        .i_sys_reg_wb   (to_ic_sys_reg_wb),
        .i_rob_idx      (to_ic_rob_idx),
        .o_rob_avail    (from_ic_rob_avail),
        .o_rob_idx      (from_ic_rob_idx),
        .o_int_reg_wb   (from_ic_int_reg_wb),
        .o_sys_reg_wb   (from_ic_sys_reg_wb),
        .o_alter_ps     (from_ic_alter_ps),
        .o_ps           (from_ic_ps),
        .o_alter_pc     (from_ic_alter_pc),
        .o_pc           (from_ic_pc),
        .o_flush        (from_ic_flush),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Register File
    //--------------------------------------------------------------------------
    wire                            to_rf_recover;
    
    wire                            to_rf_issued;
    wire    issued_instr_t          to_rf_instrs            [0:`ISSUE_WIDTH - 1];
    wire    issued_instr_t          from_rf_instrs          [0:`ISSUE_WIDTH - 1];
    
    wire    int_arch_reg_sel_t      to_rf_int_reg_read      [0:`INT_ARCH_REG_READ_PORTS - 1];
    wire    sys_arch_reg_sel_t      to_rf_sys_reg_read      [0:`SYS_ARCH_REG_READ_PORTS - 1];
    
    wire    reg_data_t              from_rf_int_reg_data    [0:`INT_ARCH_REG_READ_PORTS - 1];
    wire    reg_data_t              from_rf_sys_reg_data    [0:`SYS_ARCH_REG_READ_PORTS - 1];
    
    wire    int_arch_reg_write_t    to_rf_int_reg_wb_spclvt [0:`INT_ARCH_REG_WRITE_PORTS - 1];
    wire    sys_arch_reg_write_t    to_rf_sys_reg_wb_spclvt [0:`SYS_ARCH_REG_WRITE_PORTS - 1];
    
    wire    int_arch_reg_write_t    to_rf_int_reg_wb_commit [0:`INT_ARCH_REG_WRITE_PORTS - 1];
    wire    sys_arch_reg_write_t    to_rf_sys_reg_wb_commit [0:`SYS_ARCH_REG_WRITE_PORTS - 1];
    
    assign  to_rf_issued            = from_is_issued;
    assign  to_rf_instrs            = from_is_instrs;
    
    assign  to_rf_int_reg_read      = from_is_int_reg_read;
    assign  to_rf_sys_reg_read      = from_is_sys_reg_read;
    
    assign  to_rf_int_reg_wb_commit = from_ic_int_reg_wb;
    assign  to_rf_sys_reg_wb_commit = from_ic_sys_reg_wb;
    
    reg_file rf (
        .i_recover              (to_rf_recover),
        .i_issued               (to_rf_issued),
        .i_instrs               (to_rf_instrs),
        .o_instrs               (from_rf_instrs),
        .i_int_reg_read         (to_rf_int_reg_read),
        .i_sys_reg_read         (to_rf_sys_reg_read),
        .i_int_reg_wb_spclvt    (to_rf_int_reg_wb_spclvt),
        .i_sys_reg_wb_spclvt    (to_rf_sys_reg_wb_spclvt),
        .i_int_reg_wb_commit    (to_rf_int_reg_wb_commit),
        .i_sys_reg_wb_commit    (to_rf_sys_reg_wb_commit),
        .o_int_reg_data         (from_rf_int_reg_data),
        .o_sys_reg_data         (from_rf_sys_reg_data),
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Port 1
    //--------------------------------------------------------------------------
    wire                            to_ex1_flush;
    wire    program_state_t         to_ex1_ps           = from_ps_ps;
    
    wire    issued_instr_t          to_ex1_instr        = from_rf_instrs[0];
    wire    reg_data_t              to_ex1_src1_data    = from_rf_int_reg_data[0];
    wire    reg_data_t              to_ex1_src2_data    = from_rf_int_reg_data[1];
    wire    reg_data_t              to_ex1_sys_data     = from_rf_sys_reg_data[0];
    
    wire                            to_ex1_mul_grant;
    wire                            from_ex1_mul_ready;
    wire    wb2_req_t               from_ex1_alu_wb_req;
    wire    wb_req_t                from_ex1_mul_wb_req;
    
    assign  to_is_mul_ready         = from_ex1_mul_ready;
    
    exec_port1 ex1 (
        .i_flush        (to_ex1_flush),
        .i_ps           (to_ex1_ps),
        .i_instr        (to_ex1_instr),
        .i_src1_data    (to_ex1_src1_data),
        .i_src2_data    (to_ex1_src2_data),
        .i_sys_data     (to_ex1_sys_data),
        .i_mul_grant    (to_ex1_mul_grant),
        .o_mul_ready    (from_ex1_mul_ready),
        .o_alu_wb_req   (from_ex1_alu_wb_req),
        .o_mul_wb_req   (from_ex1_mul_wb_req),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Port 2
    //--------------------------------------------------------------------------
    wire                            to_ex2_flush;
    wire    program_state_t         to_ex2_ps           = from_ps_ps;
    
    wire    issued_instr_t          to_ex2_instr        = from_rf_instrs[1];
    wire    reg_data_t              to_ex2_src1_data    = from_rf_int_reg_data[2];
    wire    reg_data_t              to_ex2_src2_data    = from_rf_int_reg_data[3];
    
    wire                            to_ex2_mem_grant;
    wire                            from_ex2_mem_ready;
    wire    wb_req_t                from_ex2_alu_wb_req;
    wire    wb_req_t                from_ex2_mem_wb_req;
    
    assign  to_is_mem_ready         = from_ex2_mem_ready;
    
    exec_port2 ex2 (
        .i_flush        (to_ex2_flush),
        .i_ps           (to_ex2_ps),
        .i_instr        (to_ex2_instr),
        .i_src1_data    (to_ex2_src1_data),
        .i_src2_data    (to_ex2_src2_data),
        .i_mem_grant    (to_ex2_mem_grant),
        .o_mem_ready    (from_ex2_mem_ready),
        .o_alu_wb_req   (from_ex2_alu_wb_req),
        .o_mem_wb_req   (from_ex2_mem_wb_req),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Writeback Arbiter
    //--------------------------------------------------------------------------
    wire    wb2_req_t               to_wb_alu1_req      = from_ex1_alu_wb_req;
    wire    wb_req_t                to_wb_mul_req       = from_ex1_mul_wb_req;
    wire    wb_req_t                to_wb_alu2_req      = from_ex2_alu_wb_req;
    wire    wb_req_t                to_wb_mem_req       = from_ex2_mem_wb_req;
    
    wire                            from_wb_mul_grant;
    wire                            from_wb_mem_grant;
    
    wire    int_arch_reg_write_t    from_wb_int_reg     [0:`INT_ARCH_REG_WRITE_PORTS - 1];
    wire    sys_arch_reg_write_t    from_wb_sys_reg     [0:`SYS_ARCH_REG_WRITE_PORTS - 1];
    wire    rob_sel_t               from_wb_rob_idx     [0:`INT_ARCH_REG_WRITE_PORTS - 1];
    
    assign  to_ex1_mul_grant        = from_wb_mul_grant;
    assign  to_ex2_mem_grant        = from_wb_mem_grant;
    
    assign  to_ic_int_reg_wb        = from_wb_int_reg;
    assign  to_ic_sys_reg_wb        = from_wb_sys_reg;
    assign  to_ic_rob_idx           = from_wb_rob_idx;
    
    assign  to_rf_int_reg_wb_spclvt = from_wb_int_reg;
    assign  to_rf_sys_reg_wb_spclvt = from_wb_sys_reg;
    
    assign  to_is_int_reg_wb        = from_wb_int_reg;
    assign  to_is_sys_reg_wb        = from_wb_sys_reg;
    
    writeback_arbiter wb (
        .i_alu1_req     (to_wb_alu1_req),
        .i_mul_req      (to_wb_mul_req),
        .i_alu2_req     (to_wb_alu2_req),
        .i_mem_req      (to_wb_mem_req),
        .o_mul_grant    (from_wb_mul_grant),
        .o_mem_grant    (from_wb_mem_grant),
        .o_int_reg      (from_wb_int_reg),
        .o_sys_reg      (from_wb_sys_reg),
        .o_rob_idx      (from_wb_rob_idx),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Pipeline States
    //--------------------------------------------------------------------------
    assign  to_pc_flush             = from_ic_flush;
    assign  to_if1_flush            = from_ic_flush;
    assign  to_if2_flush            = from_ic_flush;
    assign  to_ia_flush             = from_ic_flush;
    assign  to_iq_flush             = from_ic_flush;
    assign  to_id_flush             = from_ic_flush;
    assign  to_is_flush             = from_ic_flush;
    assign  to_ic_flush             = from_ic_flush;
    assign  to_rf_recover           = from_ic_flush;
    assign  to_ex1_flush            = from_ic_flush;
    assign  to_ex2_flush            = from_ic_flush;
    
    assign  to_pc_alter             = from_ic_alter_pc;
    assign  to_pc_pc                = from_ic_pc;
    
    assign  to_ps_alter             = from_ic_alter_ps;
    assign  to_ps_ps                = from_ic_ps;

    //--------------------------------------------------------------------------
    // Cycle count
    //--------------------------------------------------------------------------
    logic [31:0] cycle_count;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n) begin
            cycle_count <= '0;
        end else begin
            cycle_count <= cycle_count + '1;
        end
    end

endmodule

