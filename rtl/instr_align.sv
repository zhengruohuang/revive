`include "include/config.svh"
`include "include/pc.svh"
`include "include/ps.svh"
`include "include/except.svh"
`include "include/instr.svh"

module instr_align (
    input                       i_stall,
    input                       i_flush,
    
    input                       i_valid,
    input   program_counter_t   i_pc,
    input   fetch_data_t        i_data,
    input   except_t            i_except,
    
    output                      o_valid,
    output  aligned_instr_t     o_instrs    [0:`FETCH_WIDTH - 1],
    output                      o_stall,
    
    input   i_clk,
    input   i_rst_n
);

    aligned_instr_t next_instrs [0:`FETCH_WIDTH - 1];
    
    for (genvar i = 0; i < `FETCH_WIDTH; i = i + 1) begin
        wire program_counter_t  slot_pc;
        wire                    slot_valid;
        wire instr_t            slot_instr;
        
        if (`FETCH_WIDTH == 2) begin
            assign slot_pc      = { i_pc[31:3], i[0], 2'b00 };
            assign slot_valid   = i[0] ? 1'b1 : ~i_pc[2];
            assign slot_instr   = i[0] ? i_data[31:0] : i_data[63:32];
        end else begin
            initial $error("Unsupported fetch width!");
        end
        
        always_comb begin
            if (i_valid) begin
                if (i_except.valid) begin
                    next_instrs[i] = compose_aligned_instr(slot_pc, `NOP_ENCODING, i_except, 1'b1);
                end else begin
                    next_instrs[i] = compose_aligned_instr(slot_pc, slot_instr, i_except, slot_valid);
                end
            end else begin
                next_instrs[i] = compose_aligned_instr(0, 0, 0, 0);
            end
        end
    end

    logic           valid;
    aligned_instr_t instrs      [0:`FETCH_WIDTH - 1];
    assign          o_valid     = valid;
    assign          o_instrs    = instrs;
    assign          o_stall     = i_stall;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush) begin
            valid <= 1'b0;
            for (integer i = 0; i < `FETCH_WIDTH; i = i + 1) begin
                instrs[i] <= '0;
            end
        end
        
        else begin
            if (~i_stall) begin
                valid <= i_valid;
                for (integer i = 0; i < `FETCH_WIDTH; i = i + 1) begin
                    instrs[i] <= next_instrs[i];
                end
            end
            
            $display("[IA] i_stall: %d", i_stall);
        end
    end

endmodule

