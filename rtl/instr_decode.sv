`include "include/config.svh"
`include "include/except.svh"
`include "include/instr.svh"

`include "decode/decode.sv"

module instr_decode (
    input                       i_stall,
    input                       i_flush,
    
    input                       i_can_dequeue,
    input   aligned_instr_t     i_instrs    [0:`FETCH_WIDTH - 1],
    output                      o_dequeue,
    
    output                      o_valid,
    output  decoded_instr_t     o_instrs    [0:`FETCH_WIDTH - 1],
    
    input   i_clk,
    input   i_rst_n
);

    logic               valid;
    decoded_instr_t     instrs  [0:`FETCH_WIDTH - 1];
    assign  o_dequeue   = i_can_dequeue & ~i_stall;
    assign  o_valid     = valid;
    assign  o_instrs    = instrs;
    
    wire                    valid_next  = i_instrs[0].valid;
    wire decoded_instr_t    instrs_next [0:`FETCH_WIDTH - 1];
    generate
        for (genvar i = 0; i < `FETCH_WIDTH; i = i + 1) begin
            instr_field_decoder decoder (
                .i_instr    (i_instrs[i]),
                .o_instr    (instrs_next[i])
            );
        end
    endgenerate
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush) begin
            valid <= 1'b0;
            for (integer i = 0; i < `FETCH_WIDTH; i = i + 1) begin
                instrs[i] <= '0;
            end
        end
        
        else begin
            if (~i_stall) begin
                valid <= valid_next;
                for (integer i = 0; i < `FETCH_WIDTH; i = i + 1) begin
                    instrs[i] <= instrs_next[i];
                end
            end
            
            $display("[ID] i_stall: %d", i_stall);
        end
    end

endmodule

