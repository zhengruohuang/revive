`include "include/config.svh"
`include "include/instr.svh"

`include "core/fu/alu.sv"
`include "core/fu/bru.sv"
`include "core/fu/agu.sv"
`include "core/fu/mdu.sv"
`include "core/fu/sys.sv"
`include "core/fu/int.sv"

module execute (
    input                       i_flush,
    input                       i_stall,
    input   program_state_t     i_ps,
    
    // From previous stage - Sched
    input   issued_instr_t      i_instr,
    input   reg_data_t          i_data_rs1,
    input   reg_data_t          i_data_rs2,
    output                      o_stall,
    
    // To next stage - Mem
    output  issued_instr_t      o_instr,
    output  reg_data_t          o_data,
    output  reg_data_t          o_data_rs2,
    
    // From CSR
    input   [11:0]              i_intp,
    input   [11:0]              i_inte,
    input   [11:0]              i_mideleg,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    /*
     * Src
     */
    wire    reg_data_t imm  = extend_imm(i_instr.decode.imm.imm20);
    wire    reg_data_t src1 = i_instr.decode.rs1_sel == RS_REG ? i_data_rs1 :
                              i_instr.decode.rs1_sel == RS_IMM ? imm :
                              i_instr.decode.rs1_sel == RS_PC ? i_instr.pc :
                              i_instr.decode.rs1_sel == RS_ZIMM ? { 27'b0, i_instr.decode.rs1.idx } : '0;
    wire    reg_data_t src2 = i_instr.decode.rs2_sel == RS_REG ? i_data_rs2 :
                              i_instr.decode.rs2_sel == RS_IMM ? imm :
                              i_instr.decode.rs2_sel == RS_PC ? i_instr.pc :
                              i_instr.decode.rs2_sel == RS_ZIMM ? { 27'b0, i_instr.decode.rs2.idx } : '0;
    
    /*
     * ALU
     */
    wire                alu_e = ~i_stall & i_instr.valid &
                                i_instr.decode.unit == UNIT_ALU &
                                i_instr.decode.op != OP_ALU_FENCE;
    wire    reg_data_t  alu_data;
    
    arithmetic_unit alu (
        .i_log_fd   (i_log_fd),
        .i_e        (alu_e),
        .i_op       (i_instr.decode.op.alu),
        .i_w32      (i_instr.decode.op_size.w32[0]),
        .i_src1     (src1),
        .i_src2     (src2),
        .o_dest     (alu_data)
    );
    
    /*
     * AGU
     */
    wire                agu_e = ~i_stall & i_instr.valid &
                                (i_instr.decode.unit == UNIT_MEM | i_instr.decode.unit == UNIT_AMO);
    wire    reg_data_t  agu_data;
    wire                agu_ld;
    wire                agu_misalign;
    
    addr_gen_unit agu (
        .i_log_fd   (i_log_fd),
        .i_e        (agu_e),
        .i_op       (i_instr.decode.op.mem),
        .i_src1     (src1),
        .i_offset   (i_instr.decode.unit == UNIT_AMO ? '0 : imm),
        .i_size     (i_instr.decode.op_size),
        .o_dest     (agu_data),
        .o_ld       (agu_ld),
        .o_misalign (agu_misalign)
    );
    
    /*
     * BRU
     */
    wire                bru_e = ~i_stall & i_instr.valid &
                                i_instr.decode.unit == UNIT_BRU;
    wire    reg_data_t  bru_data;
    wire                bru_taken;
    wire                bru_mispred = bru_taken; // Branches are predicted always not taken
    wire                bru_misalign;
    
    branch_unit bru (
        .i_log_fd       (i_log_fd),
        .i_e            (bru_e),
        .i_op           (i_instr.decode.op.bru),
        .i_invert       (i_instr.decode.op_size.invert[0]),
        .i_isa_c        (i_ps.isa_c),
        .i_pc           (i_instr.pc),
        .i_compressed   (i_instr.decode.half),
        .i_src1         (src1),
        .i_src2         (src2),
        .i_offset       (imm),
        .o_dest_pc      (bru_data),
        .o_taken        (bru_taken),
        .o_misalign     (bru_misalign)
    );
    
    /*
     * MDU
     */
    wire                mdu_e = ~i_stall & i_instr.valid &
                                i_instr.decode.unit == UNIT_MUL;
    wire                mdu_valid;
    wire    reg_data_t  mdu_data;
    
    mul_div_unit mdu (
        .i_flush        (i_flush),
        .i_stall        (i_stall),
        .i_e            (mdu_e),
        .i_op           (i_instr.decode.op.mul),
        .i_w32          (i_instr.decode.op_size.w32[0]),
        .i_src1         (src1),
        .i_src2         (src2),
        .o_valid        (mdu_valid),
        .o_dest         (mdu_data),
        .i_log_fd       (i_log_fd),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );
    
    /*
     * Flush
     */
    wire                flu_e = ~i_stall & i_instr.valid &
                                i_instr.decode.unit == UNIT_ALU &
                                i_instr.decode.op == OP_ALU_FENCE;
    
    /*
     * SYS
     */
    wire                sys_e = ~i_stall & i_instr.valid &
                                i_instr.decode.unit == UNIT_SYS;
    wire                rs1_is_zero = i_instr.decode.rs1_sel == RS_REG ? i_instr.decode.rs1.idx == '0 :
                                      i_instr.decode.rs1_sel == RS_ZIMM ? i_instr.decode.rs1.idx == '0 : 1'b0;
    wire    reg_data_t  sys_data = src1;
    wire                bad_csr;
    wire                trap;
    
    sys_unit su (
        .i_log_fd       (i_log_fd),
        .i_e            (sys_e),
        .i_op           (i_instr.decode.op.sys),
        .i_ps           (i_ps),
        .i_csr          (imm[11:0]),
        .i_rs1_is_zero  (rs1_is_zero),
        .o_bad_csr      (bad_csr),
        .o_trap         (trap)
    );
    
    /*
     * Interrupt
     */
    wire                int_e;
    wire    reg_data_t  int_data;
    
    interrupt_unit iu (
        .i_log_fd       (i_log_fd),
        .i_stall        (i_stall),
        .i_valid        (i_instr.valid),
        .i_intp         (i_intp),
        .i_inte         (i_inte),
        .i_mideleg      (i_mideleg),
        .i_ps           (i_ps),
        .o_valid        (int_e),
        .o_data         (int_data)
    );
    
    /*
     * Next
     */
    wire    reg_data_t      next_data = int_e ? int_data :
                                        alu_e ? alu_data :
                                        agu_e ? agu_data :
                                        bru_e ? bru_data :
                                        mdu_e ? mdu_data :
                                        sys_e ? sys_data :
                                        '0;
            issued_instr_t  next_instr;
    
    always_comb begin
        if (int_e) begin
            next_instr = compose_issued_instr(i_instr.pc, i_instr.decode, `EXCEPT_INTERRUPT, 1'b1);
        end
        
        else if (bru_e & bru_misalign) begin
            next_instr = compose_issued_instr(i_instr.pc, i_instr.decode, `EXCEPT_PC_MISALIGN(bru_data), 1'b1);
        end else if (bru_e & bru_mispred) begin
            next_instr = compose_issued_instr(i_instr.pc, i_instr.decode, `EXCEPT_MISPRED, 1'b1);
        end
        
        else if (flu_e) begin
            next_instr = compose_issued_instr(i_instr.pc, i_instr.decode, `EXCEPT_FLUSH, 1'b1);
        end
        
        else if (agu_e & agu_misalign) begin
            next_instr = compose_issued_instr(i_instr.pc, i_instr.decode, agu_ld ? `EXCEPT_LOAD_MISALIGN(agu_data) : `EXCEPT_STORE_MISALIGN(agu_data), 1'b1);
        end
        
        else if (mdu_e & ~mdu_valid) begin
            next_instr = compose_issued_instr(i_instr.pc, i_instr.decode, i_instr.except, 1'b0);
        end
        
        else if (sys_e & trap) begin
            next_instr = compose_issued_instr(i_instr.pc, i_instr.decode, `EXCEPT_TRAP, 1'b1);
        end else if (sys_e & bad_csr) begin
            next_instr = compose_issued_instr(i_instr.pc, i_instr.decode, `EXCEPT_INVALID_INSTR(32'b0), 1'b1);
        end else if (sys_e) begin
            next_instr = compose_issued_instr(i_instr.pc, i_instr.decode, `EXCEPT_SYS, 1'b1);
        end
        
        else begin
            next_instr = i_instr;
        end
    end
    
    /*
     * Except
     */
    logic   in_except/*verilator public*/;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_flush) begin
            in_except <= '0;
        end
        
        else if (~i_stall & next_instr.valid & next_instr.except.valid) begin
            in_except <= 1'b1;
        end
    end
    
    /*
     * Output
     */
    assign o_stall = i_stall | (mdu_e & ~mdu_valid);
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_flush) begin
            o_instr <= '0;
            o_data <= '0;
            o_data_rs2 <= '0;
        end
        
        else if (~i_stall) begin
            if (in_except) begin
                o_instr <= compose_issued_instr(i_instr.pc, i_instr.decode, `EXCEPT_NONE, 1'b0);
                
                if (i_log_fd != '0) begin
                    $fdisplay(i_log_fd, "[EXE] Valid: %d, PC @ %h, Waiting for pipeline flush",
                              1'b0, i_instr.pc);
                end
            end
            
            else begin
                o_instr <= next_instr;
                o_data <= next_data;
                o_data_rs2 <= i_data_rs2;
                
                if (i_log_fd != '0) begin
                    $fdisplay(i_log_fd, "[EXE] Valid: %d, PC @ %h, Decode: %h, RS1: %h, RS2: %h, IMM: %h, RD: %h, Mispred: %d",
                              i_instr.valid, i_instr.pc, i_instr.decode, src1, src2, imm, next_data, bru_mispred);
                end
            end
        end
    end

endmodule

