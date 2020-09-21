`include "include/config.svh"
`include "include/instr.svh"
`include "include/rob.svh"
`include "include/reg.svh"

module instr_sched (
    input                           i_flush,
    
    input                           i_valid,
    input   decoded_instr_t         i_instrs            [0:`FETCH_WIDTH - 1],
    
    input   int_arch_reg_write_t    i_int_reg_wb        [0:`INT_ARCH_REG_WRITE_PORTS - 1],
    input   sys_arch_reg_write_t    i_sys_reg_wb        [0:`SYS_ARCH_REG_WRITE_PORTS - 1],
    
    // The two ALUs are always ready
    input                           i_mul_ready,
    input                           i_mem_ready,
    
    input                           i_rob_avail,
    input   rob_idx_t               i_rob_idx           [0:`ISSUE_WIDTH - 1],
    
    output  int_arch_reg_sel_t      o_int_reg_read      [0:`INT_ARCH_REG_READ_PORTS - 1],
    output  sys_arch_reg_sel_t      o_sys_reg_read      [0:`SYS_ARCH_REG_READ_PORTS - 1],
    
    output                          o_issued,
    output  issued_instr_t          o_instrs            [0:`ISSUE_WIDTH - 1],
    
    output                          o_stall,
    
    input   i_clk,
    input   i_rst_n
);

    // Reg states
    logic   [`INT_ARCH_REGS - 1:0]  int_reg_ready;
    logic   [`SYS_ARCH_REGS - 1:0]  sys_reg_ready;
    
    // Compose req instrs
    logic                           saved_valid;
    decoded_instr_t                 saved_instrs        [0:`FETCH_WIDTH - 1];
    wire    decoded_instr_t         req_instrs          [0:`FETCH_WIDTH - 1];
    
    assign  req_instrs[0] = saved_valid ? saved_instrs[0] : i_instrs[0];
    assign  req_instrs[1] = saved_valid ? saved_instrs[1] : i_instrs[1];

    // Determine issue port
    wire    [`ISSUE_WIDTH - 1:0]    req_issue_ports     [0:`FETCH_WIDTH - 1];
    wire                            req_switch_ports;
    
    generate
        for (genvar i = 0; i < `ISSUE_WIDTH; i = i + 1) begin
            assign req_issue_ports[0] = {
                // Port 1
                req_instrs[0].decode.unit == UNIT_ALU | req_instrs[0].decode.unit == UNIT_BR |
                req_instrs[0].decode.unit == UNIT_MEM | req_instrs[0].decode.unit == UNIT_AMO,
                // Port 0
                req_instrs[0].decode.unit == UNIT_ALU | req_instrs[0].decode.unit == UNIT_BR |
                req_instrs[0].decode.unit == UNIT_CSR | req_instrs[0].decode.unit == UNIT_MUL
            };
        end
    endgenerate
    
    // Switch ports only when instr0 can only be issued through port1
    assign  req_switch_ports = req_instrs[0].valid & req_issue_ports[0] == 2'b10;

    // Check resource avail
    wire    [`ISSUE_WIDTH - 1:0]    req_fu_ready;
    wire    [`ISSUE_WIDTH - 1:0]    req_ready;
    wire    [`ISSUE_WIDTH - 1:0]    req_grant;
    
    assign  req_fu_ready[0] = req_switch_ports ?
                                req_instrs[0].decode.unit != UNIT_MEM | i_mem_ready :
                                req_instrs[0].decode.unit != UNIT_MUL | i_mul_ready;
    assign  req_fu_ready[1] = req_switch_ports ?
                                req_instrs[0].decode.unit != UNIT_MUL | i_mul_ready :
                                req_instrs[1].decode.unit != UNIT_MEM | i_mem_ready;
    
    generate
        for (genvar i = 0; i < `ISSUE_WIDTH; i = i + 1) begin
            wire decoded_instr_t req_i = req_instrs[i];
            assign req_ready[i] = req_instrs[i].valid & req_fu_ready[i] &
                            (~req_i.decode.rd.valid  | int_reg_ready[req_i.decode.rd.idx]) & 
                            (~req_i.decode.rs1.valid | int_reg_ready[req_i.decode.rs1.idx]) &
                            (~req_i.decode.rs2.valid | int_reg_ready[req_i.decode.rs2.idx]);
        end
    endgenerate
    
    generate
        for (genvar i = 0; i < `ISSUE_WIDTH; i = i + 1) begin
            if (i == 0) begin
                assign req_grant[i] = req_ready[i] & i_rob_avail;
            end else begin
                assign req_grant[i] = req_ready[i] & i_rob_avail & req_ready[i - 1:0] == { i{1'b1} };
            end
        end
    endgenerate

    // Compose issued instr
    wire    issued_instr_t      issued_instrs_next      [0:`ISSUE_WIDTH - 1];
    
    assign  issued_instrs_next[0] = req_switch_ports ?
                compose_issued_instr(req_instrs[1], i_rob_idx[1], req_grant[1]) :
                compose_issued_instr(req_instrs[0], i_rob_idx[0], req_grant[0]);
    assign  issued_instrs_next[1] = req_switch_ports ?
                compose_issued_instr(req_instrs[0], i_rob_idx[0], req_grant[0]) :
                compose_issued_instr(req_instrs[1], i_rob_idx[1], req_grant[1]);

    // Compose reg read reqs
    wire    int_arch_reg_sel_t  int_reg_read_next       [0:`INT_ARCH_REG_READ_PORTS - 1];
    wire    sys_arch_reg_sel_t  sys_reg_read_next       [0:`SYS_ARCH_REG_READ_PORTS - 1];
    
    assign  int_reg_read_next[0] = req_switch_ports ? req_instrs[1].decode.rs1 : req_instrs[0].decode.rs1;
    assign  int_reg_read_next[1] = req_switch_ports ? req_instrs[1].decode.rs2 : req_instrs[0].decode.rs2;
    assign  int_reg_read_next[2] = req_switch_ports ? req_instrs[0].decode.rs1 : req_instrs[1].decode.rs1;
    assign  int_reg_read_next[3] = req_switch_ports ? req_instrs[0].decode.rs1 : req_instrs[1].decode.rs1;
    assign  sys_reg_read_next[0] = '0;

    // Gen output
    logic                       issued;
    issued_instr_t              issued_instrs           [0:`ISSUE_WIDTH - 1];
    int_arch_reg_sel_t          int_reg_read            [0:`INT_ARCH_REG_READ_PORTS - 1];
    sys_arch_reg_sel_t          sys_reg_read            [0:`SYS_ARCH_REG_READ_PORTS - 1];
    
    assign  o_issued = issued;
    assign  o_instrs = issued_instrs;
    assign  o_int_reg_read = int_reg_read;
    assign  o_sys_reg_read = sys_reg_read;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush) begin
            issued <= '0;
            for (integer i = 0; i < `ISSUE_WIDTH; i = i + 1) begin
                issued_instrs[i] <= '0;
            end
            for (integer i = 0; i < `INT_ARCH_REG_READ_PORTS; i = i + 1) begin
                int_reg_read[i] <= '0;
            end
            for (integer i = 0; i < `SYS_ARCH_REG_READ_PORTS; i = i + 1) begin
                sys_reg_read[i] <= '0;
            end
        end
        
        else begin
            issued <= | req_grant;
            issued_instrs <= issued_instrs_next;
            int_reg_read <= int_reg_read_next;
            sys_reg_read <= sys_reg_read_next;
        end
    end

    // Update req instrs
    wire                        saved_valid_next;
    wire    decoded_instr_t     saved_instrs_next       [0:`FETCH_WIDTH - 1];

    assign  saved_instrs_next[0] = saved_valid ?
                                    (req_grant[0] ? (~saved_instrs[1].valid | req_grant[1] ? '0 : saved_instrs[1]) : saved_instrs[0]) :
                                    (req_grant[0] ? (~i_instrs[1].valid | req_grant[1] ? '0 : i_instrs[1]) : i_instrs[0]);
    assign  saved_instrs_next[1] = saved_valid ?
                                    (req_grant[1] ? '0 : saved_instrs[1]) :
                                    (req_grant[1] ? '0 : i_instrs[1]);
    assign  saved_valid_next = saved_instrs_next[0].valid | saved_instrs_next[1].valid;

    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush) begin
            saved_valid <= '0;
            for (integer i = 0; i < `FETCH_WIDTH; i = i + 1) begin
                saved_instrs[i] <= '0;
            end
        end
        
        else begin
            saved_valid <= saved_valid_next;
            saved_instrs <= saved_instrs_next;
        end
    end

    // Stall
    assign  o_stall = saved_valid_next;

    // Update reg states
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush) begin
            int_reg_ready <= { `INT_ARCH_REGS{1'b1} };
            sys_reg_ready <= { `SYS_ARCH_REGS{1'b1} };
        end
        
        else begin
            for (integer i = 0; i < `INT_ARCH_REG_READ_PORTS; i = i + 1) begin
                if (i_int_reg_wb[i].valid) begin
                    int_reg_ready[i_int_reg_wb[i].idx] <= 1'b1;
                end
            end
            
            for (integer i = 0; i < `SYS_ARCH_REG_WRITE_PORTS; i = i + 1) begin
                if (i_sys_reg_wb[i].valid) begin
                    sys_reg_ready[i_sys_reg_wb[i].idx] <= 1'b1;
                end
            end
            
            for (integer i = 0; i < `ISSUE_WIDTH; i = i + 1) begin
                if (issued_instrs_next[i].valid & issued_instrs_next[i].decode.rd.valid) begin
                    int_reg_ready[issued_instrs_next[i].decode.rd.idx] <= 1'b0;
                end
            end
        end
    end

endmodule

