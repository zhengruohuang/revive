`include "include/config.svh"
`include "include/instr.svh"

module sys_unit (
    input   [31:0] i_log_fd,
    
    input                       i_e,
    input   decode_sys_op_t     i_op,
    input   program_state_t     i_ps,
    
    input   [11:0]              i_csr,
    input                       i_rs1_is_zero,
    
    output                      o_bad_csr,
    output                      o_trap
);

    /*
     * Check if CSR num is valid
     */
    logic   valid_num;
    
    always_comb begin
        if (~i_e) begin
            valid_num = 1'b0;
        end else begin
            case (i_csr[11:0])
                12'h000: valid_num = 1'b0;  // ustatus
                12'h004: valid_num = 1'b0;  // uie
                12'h005: valid_num = 1'b0;  // utvec
                
                12'h040: valid_num = 1'b1;  // uscratch
                12'h041: valid_num = 1'b0;  // uepc
                12'h042: valid_num = 1'b0;  // ucause
                12'h043: valid_num = 1'b0;  // utval
                12'h044: valid_num = 1'b0;  // uip
                
                12'hc00: valid_num = 1'b1;  // cycle
                12'hc01: valid_num = 1'b1;  // time
                12'hc02: valid_num = 1'b1;  // instret
                12'hc80: valid_num = 1'b1;  // cycleh
                12'hc81: valid_num = 1'b1;  // timeh
                12'hc82: valid_num = 1'b1;  // instreth
                
                12'h100: valid_num = 1'b1;  // sstatus
                12'h102: valid_num = 1'b0;  // sedeleg
                12'h103: valid_num = 1'b0;  // sideleg
                12'h104: valid_num = 1'b1;  // sie
                12'h105: valid_num = 1'b1;  // stvec
                12'h106: valid_num = 1'b1;  // scounteren
                
                12'h140: valid_num = 1'b1;  // sscratch
                12'h141: valid_num = 1'b1;  // sepc
                12'h142: valid_num = 1'b1;  // scause
                12'h143: valid_num = 1'b1;  // stval
                12'h144: valid_num = 1'b1;  // sip
                
                12'h180: valid_num = 1'b1;  // satp
                
                12'hf11: valid_num = 1'b1;  // mvendorid
                12'hf12: valid_num = 1'b1;  // marchid
                12'hf13: valid_num = 1'b1;  // mimpid
                12'hf14: valid_num = 1'b1;  // mhartid
                
                12'h300: valid_num = 1'b1;  // mstatus
                12'h301: valid_num = 1'b1;  // misa
                12'h302: valid_num = 1'b1;  // medeleg
                12'h303: valid_num = 1'b1;  // mideleg
                12'h304: valid_num = 1'b1;  // mie
                12'h305: valid_num = 1'b1;  // mtvec
                12'h306: valid_num = 1'b1;  // mcounteren
                
                12'h340: valid_num = 1'b1;  // mscratch
                12'h341: valid_num = 1'b1;  // mepc
                12'h342: valid_num = 1'b1;  // mcause
                12'h343: valid_num = 1'b1;  // mtval
                12'h344: valid_num = 1'b1;  // mip
                
                12'h320: valid_num = 1'b1;  // mcountinhibit
                
                12'hb00: valid_num = 1'b1;  // mcycle
                12'hb02: valid_num = 1'b1;  // minstret
                
                12'h3f0: valid_num = 1'b1;  // mramstart
                12'h3f1: valid_num = 1'b1;  // mramend
                
                default: valid_num = 1'b0;
            endcase
        end
    end
    
    /*
     * Check if CSR is writable
     */
    wire    req_write = (i_op == OP_SYS_CSR_SWAP) |
                        (i_op == OP_SYS_CSR_READ_SET & ~i_rs1_is_zero) |
                        (i_op == OP_SYS_CSR_READ_CLEAR & ~i_rs1_is_zero);
    wire    read_only = req_write & i_csr[11:10] == 2'b11;
    wire    valid_write = i_e & ~read_only;
    
    /*
     * Check CSR permission
     */
    logic   valid_priv;
    
    always_comb begin
        if (~i_e) begin
            valid_priv = 1'b0;
        end else begin
            case (i_ps.priv)
                PRIV_MODE_MACHINE:      valid_priv = 1'b1;
                PRIV_MODE_SUPERVISOR:   valid_priv = (i_csr[9:8] == PRIV_MODE_SUPERVISOR) | (i_csr[9:8] == PRIV_MODE_USER);
                PRIV_MODE_USER:         valid_priv = (i_csr[9:8] == PRIV_MODE_USER);
                default:                valid_priv = 1'b0;
            endcase
        end
    end
    
    /*
     * Output
     */
    wire    valid_csr = valid_num & valid_write & valid_priv;
    
    wire    op_csr  = i_op == OP_SYS_CSR_SWAP | i_op == OP_SYS_CSR_READ_SET | i_op == OP_SYS_CSR_READ_CLEAR;
    wire    op_trap = i_op == OP_SYS_ECALL | i_op == OP_SYS_EBREAK | i_op == OP_SYS_WFI |
                      i_op == OP_SYS_MRET | i_op == OP_SYS_SRET | i_op == OP_SYS_URET;
    
    assign  o_bad_csr = i_e & op_csr & ~valid_csr;
    assign  o_trap = i_e & op_trap;

endmodule

