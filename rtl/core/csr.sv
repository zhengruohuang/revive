`include "include/config.svh"
`include "include/instr.svh"

function logic [63:0] update_csr;
    input decode_sys_op_t   op;
    input reg_data_t        csr;
    input reg_data_t        src;
    begin
        // update_csr[63:32] = updated csr
        // update_csr[31: 0] = rd
        update_csr = op == OP_SYS_CSR_SWAP       ? { src       , csr } :
                     op == OP_SYS_CSR_READ_SET   ? { csr |  src, csr } :
                     op == OP_SYS_CSR_READ_CLEAR ? { csr & ~src, csr } : '0;
    end
endfunction

function reg_data_t set_status_to_s;
    input reg_data_t    status;
    input logic [1:0]   priv;
    begin
        set_status_to_s = {
            status[31:9],
            priv[0],        // SPP = priv
            status[7:6],
            status[1],      // SPIE = SIE
            status[4:2],
            1'b0,           // SIE = 0
            status[0]
        };
    end
endfunction

function reg_data_t set_status_to_m;
    input reg_data_t    status;
    input logic [1:0]   priv;
    begin
        set_status_to_m = {
            status[31:13],
            priv,           // MPP = priv
            status[10:8],
            status[3],      // MPIE = MIE
            status[6:4],
            1'b0,           // MIE = 0
            status[2:0]
        };
    end
endfunction

function issued_instr_t gen_jr;
    input issued_instr_t    instr;
    begin
        gen_jr = compose_issued_instr(instr.pc, `JR_DECODE(instr.decode.half), `EXCEPT_MISPRED, 1'b1);
    end
endfunction

module ctrl_status_reg (
    input                       i_flush,
    
    // From previous stage - Mem
    input   issued_instr_t      i_instr,
    input   reg_data_t          i_data,
    
    // To next stage - Writeback
    output  issued_instr_t      o_instr,
    output  reg_data_t          o_data,
    
    // Interrupt
    input                       i_int_ext,
    input                       i_int_timer,
    input                       i_int_soft,
    
    // Time
    input   [63:0]              i_mtime,    // time/mtime
    
    // To PS
    output  [1:0]               o_priv,
    output                      o_isa_c,
    output  reg_data_t          o_satp,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    /*
     * CSRs
     */
            logic           in_except;
            logic   [1:0]   priv;
    
            reg_data_t      status;         // ustatus/sstatus/mstatus
            reg_data_t      intp_sw;        // uip/sip/mip
    wire    reg_data_t      intp = intp_sw | { 20'b0, i_int_ext, 3'b0, i_int_timer, 3'b0, i_int_soft, 3'b0 };
            reg_data_t      inte;           // uie/sie/mie
    
            logic   [63:0]  perf_cycles;    // cycles/mcycles
            logic   [63:0]  perf_instrs;    // instret/minstret
    
            reg_data_t      stvec;
            reg_data_t      mtvec;
    
            reg_data_t      uscratch;
            reg_data_t      sscratch;
            reg_data_t      mscratch;
    
            reg_data_t      sepc;
            reg_data_t      mepc;
    
            reg_data_t      scause;
            reg_data_t      mcause;
    
            reg_data_t      stval;
            reg_data_t      mtval;
    
            reg_data_t      medeleg;
            reg_data_t      mideleg;
            
            reg_data_t      scounteren;
            reg_data_t      mcounteren;
            reg_data_t      mcountstop;
    
            reg_data_t      satp;
            reg_data_t      misa;
    
            reg_data_t      mramstart;
            reg_data_t      mramend;
    
    wire    logic   [31:0]  mvendorid = '0;
    wire    logic   [31:0]  marchid = '0;
    wire    logic   [31:0]  mimpid = '0;
    wire    logic   [31:0]  mhartid = '0;
    
    wire    next_except = i_instr.valid & i_instr.except.valid & `IS_STD_EXCEPT_CODE(i_instr.except.code);
//                          i_instr.except.code != EXCEPT_MISPRED &
//                          i_instr.except.code != EXCEPT_FLUSH &
//                          i_instr.except.code != EXCEPT_TRAP &
//                          i_instr.except.code != EXCEPT_INTERRUPT &
//                          i_instr.except.code != EXCEPT_SYS;
    wire    next_trap   = i_instr.valid & i_instr.except.valid & i_instr.except.code == EXCEPT_TRAP;
    wire    next_int    = i_instr.valid & i_instr.except.valid & i_instr.except.code == EXCEPT_INTERRUPT;
    wire    next_csr    = i_instr.valid & i_instr.except.valid & i_instr.except.code == EXCEPT_SYS &
                          (i_instr.decode.op.sys == OP_SYS_CSR_SWAP |
                           i_instr.decode.op.sys == OP_SYS_CSR_READ_SET |
                           i_instr.decode.op.sys == OP_SYS_CSR_READ_CLEAR);
    
    wire    logic   [31:0]  ecall_except_code = priv == PRIV_MODE_MACHINE    ? 11 :
                                                priv == PRIV_MODE_SUPERVISOR ?  9 :
                                                priv == PRIV_MODE_USER       ?  8 : 10;
    wire    logic   [31:0]  ecall_except_mask = priv == PRIV_MODE_MACHINE    ? (32'b1 << 11) :
                                                priv == PRIV_MODE_SUPERVISOR ? (32'b1 <<  9) :
                                                priv == PRIV_MODE_USER       ? (32'b1 <<  8) :
                                                                               (32'b1 << 10);
    
    wire    logic   [31:0]  std_except_mask =   i_instr.except.code == EXCEPT_PC_MISALIGN       ? (32'b1 << 0) :
                                              //i_instr.except.code == EXCEPT_PC_ACCESS_FAULT   ? (32'b1 << 1) :
                                              //i_instr.except.code == EXCEPT_UNKNOW_INSTR      ? (32'b1 << 2) :
                                                i_instr.except.code == EXCEPT_LOAD_MISALIGN     ? (32'b1 << 4) :
                                              //i_instr.except.code == EXCEPT_LOAD_ACCESS_FAULT ? (32'b1 << 5) :
                                                i_instr.except.code == EXCEPT_STORE_MISALIGN    ? (32'b1 << 6) :
                                              //i_instr.except.code == EXCEPT_STORE_ACCESS_FAULT? (32'b1 << 7) :
                                                i_instr.except.code == EXCEPT_ITLB_PAGE_FAULT   ? (32'b1 << 12) :
                                                i_instr.except.code == EXCEPT_LOAD_PAGE_FAULT   ? (32'b1 << 13) :
                                                i_instr.except.code == EXCEPT_STORE_PAGE_FAULT  ? (32'b1 << 15) : '0;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n) begin
            o_instr <= '0;
            o_data <= '0;
            
            priv <= PRIV_MODE_MACHINE;
            
            status <= '0;
            intp_sw <= '0;
            inte <= '0;
            
            stvec <= '0;
            mtvec <= '0;
            
            uscratch <= '0;
            sscratch <= '0;
            mscratch <= '0;
            
            sepc <= '0;
            mepc <= '0;
            
            scause <= '0;
            mcause <= '0;
            
            stval <= '0;
            mtval <= '0;
            
            medeleg <= '0;
            mideleg <= '0;
            
            scounteren <= '0;
            mcounteren <= '0;
            mcountstop <= '0;
            
            satp <= '0;
            misa <= 32'h40000000    |   // rv32
                    (32'b1 << 0)    |   // A
                    (32'b1 << 2)    |   // C
                    (32'b1 << 4)    |   // E
                    (32'b1 << 6)    |   // G
                    (32'b1 << 8)    |   // I
                    (32'b1 << 12)   |   // M
                    (32'b1 << 18)   |   // S
                    (32'b1 << 20);      // U
            
            mramstart <= '0;
            mramend <= '0;
        end
        
        // Flush
        else if (i_flush) begin
            o_instr <= '0;
            o_data <= '0;
        end
        
        // Except
        else if (next_except) begin
            // delegate to S
            if (((medeleg & std_except_mask) != 32'b0) & (priv == PRIV_MODE_SUPERVISOR | priv == PRIV_MODE_USER)) begin
                sepc <= i_instr.pc;
                scause <= { 27'b0, i_instr.except.code };
                stval <= i_instr.except.tval;
                status <= set_status_to_s(status, priv);
                priv <= PRIV_MODE_SUPERVISOR;
                o_instr <= gen_jr(i_instr);
                o_data <= stvec;
            end
            
            // no delegation
            else begin
                mepc <= i_instr.pc;
                mcause <= { 27'b0, i_instr.except.code };
                mtval <= i_instr.except.tval;
                status <= set_status_to_m(status, priv);
                priv <= PRIV_MODE_MACHINE;
                o_instr <= gen_jr(i_instr);
                o_data <= mtvec;
            end
            
            $display("PC @ %h, except: %d, tval: %h, priv: %d", i_instr.pc, i_instr.except.code, i_instr.except.tval, priv);
        end
        
        // Trap
        else if (next_trap) begin
            // ECALL
            if (i_instr.decode.op.sys == OP_SYS_ECALL) begin
                // delegate to S
                if (((medeleg & ecall_except_mask) != 32'b0) & (priv == PRIV_MODE_SUPERVISOR | priv == PRIV_MODE_USER)) begin
                    sepc <= i_instr.pc;
                    scause <= ecall_except_code;
                    stval <= '0;
                    status <= set_status_to_s(status, priv);
                    priv <= PRIV_MODE_SUPERVISOR;
                    o_instr <= gen_jr(i_instr);
                    o_data <= stvec;
                    
                    //$display("ecall to S");
                end
                
                // no delegation
                else begin
                    mepc <= i_instr.pc;
                    mcause <= ecall_except_code;
                    mtval <= '0;
                    status <= set_status_to_m(status, priv);
                    priv <= PRIV_MODE_MACHINE;
                    o_instr <= gen_jr(i_instr);
                    o_data <= mtvec;
                    
                    //$display("ecall to M");
                end
            end
            
            // EBREAK
            else if (i_instr.decode.op.sys == OP_SYS_EBREAK) begin
                mepc <= i_instr.pc;
                mcause <= 32'd3;
                mtval <= i_instr.pc;
                status <= set_status_to_m(status, priv);
                priv <= PRIV_MODE_MACHINE;
                o_instr <= gen_jr(i_instr);
                o_data <= mtvec;
                
                $display("ebreak");
            end
            
            // MRET
            else if (i_instr.decode.op.sys == OP_SYS_MRET) begin
                o_instr <= gen_jr(i_instr);
                o_data <= mepc & ~(misa[2] ? 32'b01 : 32'b11);
                status <= { status[31:4], status[7], status[2:0] }; // MIE = MPIE
                priv <= status[12:11]; // priv = MPP
                
                //$display("mret, priv: %d", status[12:11]);
            end
            
            // SRET
            else if (i_instr.decode.op.sys == OP_SYS_SRET) begin
                o_instr <= gen_jr(i_instr);
                o_data <= sepc & ~(misa[2] ? 32'b01 : 32'b11);
                status <= { status[31:2], status[5], status[0] }; // SIE = SPIE
                priv <= { 1'b0, status[8] }; // priv = SPP
            end
            
//            // URET
//            else if (i_instr.decode.op.sys == OP_SYS_URET) begin
//                o_instr <= i_instr;
//            end
            
            // Unknown
            else begin
                o_instr <= i_instr;
                o_data <= i_data;
                
                $display("unknown??");
            end
        end
        
        // Interrupt
        else if (next_int) begin
            o_instr <= i_instr;
            o_data <= i_data;
        end
        
        // CSR instrs
        else if (next_csr) begin
            case (i_instr.decode.imm.imm20[11:0])
            12'h040: { uscratch, o_data } <= update_csr(i_instr.decode.op.sys, uscratch, i_data );      // uscratch
            
            12'h100: { status, o_data } <= update_csr(i_instr.decode.op.sys, status, i_data );          // sstatus
            12'h104: { inte, o_data }   <= update_csr(i_instr.decode.op.sys, inte, i_data );            // sie
            12'h105: { stvec, o_data }  <= update_csr(i_instr.decode.op.sys, stvec, i_data );           // stvec
            12'h106: { scounteren, o_data }  <= update_csr(i_instr.decode.op.sys, scounteren, i_data ); // scounteren
            
            12'h140: { sscratch, o_data }  <= update_csr(i_instr.decode.op.sys, sscratch, i_data );     // sscratch
            12'h141: { sepc, o_data }  <= update_csr(i_instr.decode.op.sys, sepc, i_data );             // sepc
            12'h142: { scause, o_data }  <= update_csr(i_instr.decode.op.sys, scause, i_data );         // scause
            12'h143: { stval, o_data }  <= update_csr(i_instr.decode.op.sys, stval, i_data );           // stval
            12'h144: { intp_sw, o_data }  <= update_csr(i_instr.decode.op.sys, intp, i_data );          // sip
            
            12'h180: { satp, o_data }  <= update_csr(i_instr.decode.op.sys, satp, i_data );             // satp
            
            12'h300: { status, o_data } <= update_csr(i_instr.decode.op.sys, status, i_data );          // mstatus
            12'h301: { misa, o_data } <= update_csr(i_instr.decode.op.sys, misa, i_data );              // misa
            12'h302: { medeleg, o_data } <= update_csr(i_instr.decode.op.sys, medeleg, i_data );        // medeleg
            12'h303: { mideleg, o_data } <= update_csr(i_instr.decode.op.sys, mideleg, i_data );        // mideleg
            12'h304: { inte, o_data }   <= update_csr(i_instr.decode.op.sys, inte, i_data );            // mie
            12'h305: { mtvec, o_data }  <= update_csr(i_instr.decode.op.sys, mtvec, i_data );           // mtvec
            12'h306: { mcounteren, o_data }  <= update_csr(i_instr.decode.op.sys, mcounteren, i_data ); // mcounteren
            
            12'h340: { mscratch, o_data }  <= update_csr(i_instr.decode.op.sys, mscratch, i_data );     // mscratch
            12'h341: { mepc, o_data }  <= update_csr(i_instr.decode.op.sys, mepc, i_data );             // mepc
            12'h342: { mcause, o_data }  <= update_csr(i_instr.decode.op.sys, mcause, i_data );         // mcause
            12'h343: { mtval, o_data }  <= update_csr(i_instr.decode.op.sys, mtval, i_data );           // mtval
            12'h344: { intp_sw, o_data }  <= update_csr(i_instr.decode.op.sys, intp, i_data );          // mip
            
            12'h320: { mcountstop, o_data }  <= update_csr(i_instr.decode.op.sys, mcountstop, i_data ); // mcountinhibit
            
            12'h3f0: { mramstart, o_data }  <= update_csr(i_instr.decode.op.sys, mramstart, i_data );   // mramstart
            12'h3f1: { mramend, o_data }  <= update_csr(i_instr.decode.op.sys, mramend, i_data );       // mramend
            
            12'hc00: o_data <= perf_cycles[31:0];   // cycle
            12'hc01: o_data <= i_mtime[31:0];       // time
            12'hc02: o_data <= perf_instrs[31:0];   // instret
            12'hc80: o_data <= perf_cycles[63:32];  // cycleh
            12'hc81: o_data <= i_mtime[63:32];      // timeh
            12'hc82: o_data <= perf_instrs[63:32];  // instreth
            
            12'hf11: o_data <= mvendorid;   // mvendorid
            12'hf12: o_data <= marchid;     // marchid
            12'hf13: o_data <= mimpid;      // mimpid
            12'hf14: o_data <= mhartid;     // mhartid
            
            default: o_data <= '0;
            endcase
            
            o_instr <= i_instr;
        end
        
        // Other instrs
        else begin
            o_instr <= i_instr;
            o_data <= i_data;
        end
    end

    /*
     * Perf counters
     */
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n) begin
            perf_cycles <= '0;
            perf_instrs <= '0;
        end
        
        else begin
            perf_cycles <= perf_cycles + 64'b1;
        end
    end

    /*
     * Output
     */
    assign  o_priv = priv;
    assign  o_isa_c = misa[2];
    assign  o_satp = satp;

endmodule

